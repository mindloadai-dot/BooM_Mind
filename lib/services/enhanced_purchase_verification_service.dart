import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindload/models/atomic_ledger_models.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/atomic_ledger_service.dart';
import 'package:mindload/services/enhanced_abuse_prevention_service.dart';

/// Enhanced purchase verification service with server-side verification
/// Implements the requirements from Part 4B-1
class EnhancedPurchaseVerificationService {
  static final EnhancedPurchaseVerificationService _instance = EnhancedPurchaseVerificationService._internal();
  static EnhancedPurchaseVerificationService get instance => _instance;

  EnhancedPurchaseVerificationService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final AuthService _authService = AuthService.instance;
  final AtomicLedgerService _ledgerService = AtomicLedgerService.instance;
  final EnhancedAbusePrevention _abusePrevention = EnhancedAbusePrevention.instance;

  // Configuration constants
  static const bool SERVER_SIDE_VERIFICATION_ENABLED = true;
  static const bool RECEIPT_REPLAY_PROTECTION_ENABLED = true;
  static const bool IDEMPOTENT_CREDITS_ENABLED = true;

  // Cache for verified purchases to prevent duplicate processing
  final Map<String, PurchaseVerificationResult> _verifiedPurchaseCache = {};
  static const Duration _cacheTtl = Duration(hours: 24);

  /// Verify logic pack purchase with server-side verification
  /// Tokens are credited only after verification
  Future<PurchaseVerificationResult> verifyLogicPackPurchase({
    required String productId,
    required String purchaseToken,
    required String transactionId,
    required String platform,
    Map<String, dynamic> receiptData = const {},
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return PurchaseVerificationResult(
        purchaseId: transactionId,
        productId: productId,
        tokens: 0,
        isVerified: false,
        isReplay: false,
        verifiedAt: DateTime.now(),
        errorMessage: 'User not authenticated',
      );
    }

    // Check abuse prevention before proceeding
    final deviceInfo = await _getDeviceInfo();
    final abuseCheck = await _abusePrevention.canPerformAction(
      userId: userId,
      actionType: 'purchase_verification',
      deviceInfo: deviceInfo,
    );

    if (!abuseCheck.isAllowed) {
      return PurchaseVerificationResult(
        purchaseId: transactionId,
        productId: productId,
        tokens: 0,
        isVerified: false,
        isReplay: false,
        verifiedAt: DateTime.now(),
        errorMessage: abuseCheck.reason,
      );
    }

    // Check for replay protection
    if (RECEIPT_REPLAY_PROTECTION_ENABLED) {
      final replayCheck = await _checkPurchaseReplay(transactionId, userId);
      if (replayCheck != null) {
        await _logTelemetry('purchase.duplicate_ignored', {
          'purchaseId': transactionId,
          'userId': userId,
          'productId': productId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return replayCheck;
      }
    }

    // Check cache for idempotent credits
    if (IDEMPOTENT_CREDITS_ENABLED) {
      final cacheKey = _generateCacheKey(transactionId, userId);
      final cachedResult = _verifiedPurchaseCache[cacheKey];
      if (cachedResult != null && !_isCacheExpired(cachedResult.verifiedAt)) {
        await _logTelemetry('purchase.idempotent_return', {
          'purchaseId': transactionId,
          'userId': userId,
          'productId': productId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        return cachedResult;
      }
    }

    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();
      
      // Call server-side verification Cloud Function
      final result = await _functions
          .httpsCallable('verifyLogicPackPurchase')
          .call({
        'productId': productId,
        'purchaseToken': purchaseToken,
        'transactionId': transactionId,
        'platform': platform,
        'receiptData': receiptData,
        'appCheckToken': appCheckToken,
        'userId': userId,
      });

      if (result.data == null) {
        throw Exception('No data received from verification endpoint');
      }

      final verificationData = result.data as Map<String, dynamic>;
      final isVerified = verificationData['isVerified'] ?? false;
      final tokens = verificationData['tokens'] ?? 0;
      final errorMessage = verificationData['errorMessage'];

      if (isVerified && tokens > 0) {
        // Credit tokens to user's account via atomic ledger
        final requestId = _generateRequestId();
        final ledgerResult = await _ledgerService.writeLedgerEntry(
          action: 'credit',
          tokens: tokens,
          requestId: requestId,
          source: LedgerSource.purchase,
          metadata: {
            'productId': productId,
            'transactionId': transactionId,
            'platform': platform,
            'purchaseToken': purchaseToken,
          },
        );

        if (ledgerResult.success) {
          // Create verification result
          final verificationResult = PurchaseVerificationResult(
            purchaseId: transactionId,
            productId: productId,
            tokens: tokens,
            isVerified: true,
            isReplay: false,
            verifiedAt: DateTime.now(),
          );

          // Cache the result for idempotent credits
          if (IDEMPOTENT_CREDITS_ENABLED) {
            final cacheKey = _generateCacheKey(transactionId, userId);
            _verifiedPurchaseCache[cacheKey] = verificationResult;
          }

          // Log successful verification
          await _logTelemetry('purchase.logic_verified', {
            'purchaseId': transactionId,
            'userId': userId,
            'productId': productId,
            'tokens': tokens,
            'platform': platform,
            'timestamp': DateTime.now().toIso8601String(),
          });

          return verificationResult;
        } else {
          // Ledger write failed
          await _logTelemetry('purchase.ledger_write_failed', {
            'purchaseId': transactionId,
            'userId': userId,
            'productId': productId,
            'error': ledgerResult.error,
            'timestamp': DateTime.now().toIso8601String(),
          });

          return PurchaseVerificationResult(
            purchaseId: transactionId,
            productId: productId,
            tokens: 0,
            isVerified: false,
            isReplay: false,
            verifiedAt: DateTime.now(),
            errorMessage: 'Failed to credit tokens: ${ledgerResult.error}',
          );
        }
      } else {
        // Verification failed
        await _logTelemetry('purchase.logic_rejected', {
          'purchaseId': transactionId,
          'userId': userId,
          'productId': productId,
          'error': errorMessage,
          'timestamp': DateTime.now().toIso8601String(),
        });

        return PurchaseVerificationResult(
          purchaseId: transactionId,
          productId: productId,
          tokens: 0,
          isVerified: false,
          isReplay: false,
          verifiedAt: DateTime.now(),
          errorMessage: errorMessage ?? 'Verification failed',
        );
      }
    } catch (e) {
      // Log verification error
      await _logTelemetry('purchase.verification_error', {
        'purchaseId': transactionId,
        'userId': userId,
        'productId': productId,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return PurchaseVerificationResult(
        purchaseId: transactionId,
        productId: productId,
        tokens: 0,
        isVerified: false,
        isReplay: false,
        verifiedAt: DateTime.now(),
        errorMessage: 'Verification error: $e',
      );
    }
  }

  /// Check for purchase replay protection
  Future<PurchaseVerificationResult?> _checkPurchaseReplay(String transactionId, String userId) async {
    try {
      // Check if this transaction has already been processed
      final ledgerEntries = await _ledgerService.getLedgerEntries(
        userId: userId,
        limit: 1000,
      );

      for (final entry in ledgerEntries) {
        if (entry.metadata['transactionId'] == transactionId) {
          // This transaction has already been processed
          return PurchaseVerificationResult(
            purchaseId: transactionId,
            productId: entry.metadata['productId'] ?? '',
            tokens: entry.tokens,
            isVerified: true,
            isReplay: true,
            verifiedAt: entry.timestamp,
            errorMessage: 'Transaction already processed',
          );
        }
      }

      return null;
    } catch (e) {
      // If we can't check for replay, allow the request
      // This is a fail-open approach for availability
      return null;
    }
  }

  /// Restore purchases for a user
  Future<List<PurchaseVerificationResult>> restorePurchases() async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();
      
      // Call restore purchases Cloud Function
      final result = await _functions
          .httpsCallable('restoreLogicPackPurchases')
          .call({
        'appCheckToken': appCheckToken,
        'userId': userId,
      });

      if (result.data == null) return [];

      final restoreData = result.data as Map<String, dynamic>;
      final purchases = restoreData['purchases'] as List<dynamic>? ?? [];
      
      final restoredPurchases = <PurchaseVerificationResult>[];
      
      for (final purchaseData in purchases) {
        final purchase = purchaseData as Map<String, dynamic>;
        final transactionId = purchase['transactionId'] ?? '';
        final productId = purchase['productId'] ?? '';
        final tokens = purchase['tokens'] ?? 0;
        final platform = purchase['platform'] ?? '';
        
        // Check if already processed
        final replayCheck = await _checkPurchaseReplay(transactionId, userId);
        if (replayCheck != null) {
          restoredPurchases.add(replayCheck);
          continue;
        }

        // Process the purchase
        final verificationResult = await verifyLogicPackPurchase(
          productId: productId,
          purchaseToken: purchase['purchaseToken'] ?? '',
          transactionId: transactionId,
          platform: platform,
          receiptData: purchase['receiptData'] ?? {},
        );

        if (verificationResult.isVerified) {
          restoredPurchases.add(verificationResult);
        }
      }

      return restoredPurchases;
    } catch (e) {
      print('Restore purchases failed: $e');
      return [];
    }
  }

  /// Get purchase history for a user
  Future<List<PurchaseVerificationResult>> getPurchaseHistory() async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    try {
      // Get ledger entries for purchases
      final ledgerEntries = await _ledgerService.getLedgerEntries(
        userId: userId,
        limit: 1000,
      );

      final purchases = <PurchaseVerificationResult>[];
      
      for (final entry in ledgerEntries) {
        if (entry.source == LedgerSource.purchase.name) {
          purchases.add(PurchaseVerificationResult(
            purchaseId: entry.metadata['transactionId'] ?? '',
            productId: entry.metadata['productId'] ?? '',
            tokens: entry.tokens,
            isVerified: true,
            isReplay: false,
            verifiedAt: entry.timestamp,
          ));
        }
      }

      // Sort by verification date (newest first)
      purchases.sort((a, b) => b.verifiedAt.compareTo(a.verifiedAt));
      
      return purchases;
    } catch (e) {
      return [];
    }
  }

  /// Validate purchase receipt locally (basic validation)
  bool validateReceiptLocally(Map<String, dynamic> receiptData) {
    try {
      // Basic validation - in production, this would be more comprehensive
      final requiredFields = ['transactionId', 'productId', 'purchaseToken'];
      
      for (final field in requiredFields) {
        if (receiptData[field] == null || receiptData[field].toString().isEmpty) {
          return false;
        }
      }

      // Check for reasonable values
      final transactionId = receiptData['transactionId'].toString();
      if (transactionId.length < 10) return false;

      final productId = receiptData['productId'].toString();
      if (!productId.startsWith('mindload_')) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get purchase verification status
  Future<Map<String, dynamic>> getPurchaseVerificationStatus() async {
    final userId = _authService.currentUserId;
    if (userId == null) return {};

    try {
      final purchaseHistory = await getPurchaseHistory();
      final totalPurchased = purchaseHistory.fold<int>(0, (sum, purchase) => sum + purchase.tokens);
      
      return {
        'totalPurchases': purchaseHistory.length,
        'totalTokensPurchased': totalPurchased,
        'lastPurchaseDate': purchaseHistory.isNotEmpty 
            ? purchaseHistory.first.verifiedAt.toIso8601String() 
            : null,
        'verificationEnabled': SERVER_SIDE_VERIFICATION_ENABLED,
        'replayProtectionEnabled': RECEIPT_REPLAY_PROTECTION_ENABLED,
        'idempotentCreditsEnabled': IDEMPOTENT_CREDITS_ENABLED,
      };
    } catch (e) {
      return {};
    }
  }

  /// Clear purchase cache (admin function)
  void clearPurchaseCache() {
    _verifiedPurchaseCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final expired = _verifiedPurchaseCache.values.where(
      (purchase) => _isCacheExpired(purchase.verifiedAt)
    ).length;
    final valid = _verifiedPurchaseCache.values.where(
      (purchase) => !_isCacheExpired(purchase.verifiedAt)
    ).length;
    
    return {
      'totalEntries': _verifiedPurchaseCache.length,
      'validEntries': valid,
      'expiredEntries': expired,
      'cacheSize': _verifiedPurchaseCache.length,
    };
  }

  /// Clean up expired cache entries
  void cleanupExpiredCache() {
    final expiredKeys = _verifiedPurchaseCache.entries
        .where((entry) => _isCacheExpired(entry.value.verifiedAt))
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _verifiedPurchaseCache.remove(key);
    }
  }

  /// Generate cache key for idempotent credits
  String _generateCacheKey(String transactionId, String userId) {
    return '${userId}_$transactionId';
  }

  /// Check if cache entry is expired
  bool _isCacheExpired(DateTime verifiedAt) {
    return DateTime.now().difference(verifiedAt) > _cacheTtl;
  }

  /// Generate unique request ID
  String _generateRequestId() {
    return 'purchase_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate random string for request ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(DateTime.now().millisecond % chars.length))
    );
  }

  /// Get device information for abuse prevention
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // In a real app, this would collect actual device information
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': _generateRandomString(16),
    };
  }

  /// Log telemetry events
  Future<void> _logTelemetry(String event, Map<String, dynamic> parameters) async {
    try {
      await FirebaseFirestore.instance.collection('telemetry_events').add({
        'event': event,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail telemetry logging to avoid breaking main functionality
      print('Telemetry logging failed: $e');
    }
  }
}
