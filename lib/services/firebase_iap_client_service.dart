import 'package:flutter/foundation.dart';
import 'package:mindload/models/iap_firebase_models.dart';
// import 'package:mindload/models/pricing_models.dart'; // Unused import removed
import 'package:mindload/services/firebase_iap_service.dart';
import 'package:mindload/services/international_iap_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-side service for Firebase IAP integration with server-side verification
/// Handles worldwide purchasing, verification, and entitlement management
class FirebaseIapClientService {
  static final FirebaseIapClientService _instance = FirebaseIapClientService._internal();
  factory FirebaseIapClientService() => _instance;
  static FirebaseIapClientService get instance => _instance;
  FirebaseIapClientService._internal();

  final FirebaseIapService _firebaseIap = FirebaseIapService.instance;
  final InternationalIapService _internationalIap = InternationalIapService.instance;
  final AuthService _authService = AuthService.instance;
  final TelemetryService _telemetry = TelemetryService.instance;

  bool _initialized = false;
  FirebaseUser? _currentUser;
  UserEntitlement? _currentEntitlement;

  // Getters
  bool get isInitialized => _initialized;
  FirebaseUser? get currentUser => _currentUser;
  UserEntitlement? get currentEntitlement => _currentEntitlement;
  
  // Helper getters for UI
  bool get isProUser {
    return false; // Pro Monthly removed
  }
  int get currentCredits => _currentUser?.credits ?? 0;
  bool get hasActiveSubscription => _currentEntitlement?.status == EntitlementStatus.active;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Initialize dependent services
      await _firebaseIap.initialize();
      await _internationalIap.initialize();
      
      // Create user document if needed
      await _firebaseIap.createUserIfNeeded();
      
      // Update user locale information
      await _updateUserLocaleInfo();
      
      // Load current user data
      await refreshUserData();
      
      // Listen for real-time updates
      _setupRealtimeListeners();
      
      _initialized = true;
      
      if (kDebugMode) {
        debugPrint('Firebase IAP Client Service initialized');
      }
      
      // Record initialization telemetry
      await _recordTelemetry(IapTelemetryEvent.paywallView, {
        'initialization': true,
        'tier': _currentUser?.tier.name,
        'credits': _currentUser?.credits,
      });
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing Firebase IAP Client Service: $e');
      }
      _initialized = false;
    }
  }

  /// Update user locale information
  Future<void> _updateUserLocaleInfo() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Use default values for locale information
      // In a production app, these would come from proper device locale detection
      String countryCode = 'US';
      String languageCode = 'en';

      // Update user document with locale info
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'countryCode': countryCode,
        'languageCode': languageCode,
        'timezone': _internationalIap.deviceTimezone,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user locale info: $e');
      }
    }
  }

  /// Set up real-time listeners for user data and entitlements
  void _setupRealtimeListeners() {
    // Listen to user data changes
    _firebaseIap.streamUserData().listen((userData) {
      _currentUser = userData;
      if (kDebugMode) {
        debugPrint('User data updated: ${userData?.tier.name} - ${userData?.credits} credits');
      }
    });

    // Listen to entitlement changes  
    _firebaseIap.streamEntitlement().listen((entitlement) {
      _currentEntitlement = entitlement;
      if (kDebugMode) {
        debugPrint('Entitlement updated: ${entitlement?.status.name}');
      }
    });
  }

  /// Refresh current user data from Firebase
  Future<void> refreshUserData() async {
    try {
      _currentUser = await _firebaseIap.getCurrentUserData();
      _currentEntitlement = await _firebaseIap.getCurrentEntitlement();
      
      if (kDebugMode) {
        debugPrint('Refreshed user data: ${_currentUser?.tier.name} - ${_currentUser?.credits} credits');
        debugPrint('Current entitlement: ${_currentEntitlement?.status.name}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing user data: $e');
      }
    }
  }

  /// Purchase a product
  Future<PurchaseResult> purchaseProduct(String productId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Call Firebase backend to process purchase
      final purchaseResult = await _firebaseIap.verifyPurchase(
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        transactionId: 'temp_transaction_id', // This would come from platform purchase
        purchaseToken: null, // Android only
        productId: productId,
      );

      if (purchaseResult?['success'] == true) {
        // Refresh user data after successful purchase
        await refreshUserData();

        // Record successful purchase telemetry
        await _recordTelemetry(IapTelemetryEvent.purchaseSuccess, {
          'product_id': productId,
          'transaction_id': purchaseResult!['transaction_id'],
          'credits_gained': purchaseResult['credits_gained'] ?? 0,
        });

        return PurchaseResult(
          success: true,
          productId: productId,
          transactionId: purchaseResult['transaction_id'],
          purchaseToken: purchaseResult['purchase_token'],
          credits: purchaseResult['credits_gained'] ?? 0,
        );
      } else {
        throw Exception(purchaseResult?['error'] ?? 'Purchase failed');
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error purchasing product $productId: $e');
      }
      
      await _recordTelemetry(IapTelemetryEvent.purchaseFail, {
        'product_id': productId,
        'error': e.toString(),
      });
      
      return PurchaseResult(
        success: false,
        error: e.toString(),
        productId: productId,
        credits: 0,
      );
    }
  }

  /// Restore purchases from store
  Future<RestoreResult> restorePurchases() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      if (kDebugMode) {
        debugPrint('Restoring purchases for user: ${user.uid}');
      }

      // Call Firebase backend to restore entitlements
      final restoreResult = await _firebaseIap.restoreEntitlements();

      if (restoreResult?['success'] == true) {
        await _recordTelemetry(IapTelemetryEvent.restoreSuccess, {
          'restored_count': restoreResult!['restored']?.length ?? 0,
        });

        // Refresh user data
        await refreshUserData();

        return RestoreResult(
          success: true,
          restoredProducts: restoreResult['restored'] ?? [],
        );
      } else {
        return RestoreResult(
          success: false,
          error: 'No purchases to restore',
        );
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error restoring purchases: $e');
      }
      return RestoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get user's credit ledger (transaction history)
  Future<List<CreditLedgerEntry>> getCreditHistory({int limit = 50}) async {
    return await _firebaseIap.getCreditLedger(limit: limit);
  }

  /// Check if user can make purchase (has payment method, etc.)
  Future<bool> canMakePurchases() async {
    try {
      // This would integrate with actual IAP packages
      return true; // Simplified
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking purchase capability: $e');
      }
      return false;
    }
  }

  /// Get subscription management URLs (only if enabled by Remote Config)
  String getManagementUrl() {
    return _internationalIap.getSubscriptionManagementUrl();
  }

  String getManagementLabel() {
    return _internationalIap.getSubscriptionManagementLabel();
  }

  /// Force reconciliation with store (for debugging)
  Future<void> forceReconciliation() async {
    try {
      await _firebaseIap.triggerReconciliation();
      await refreshUserData();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error forcing reconciliation: $e');
      }
    }
  }

  // Helper methods

  bool _isIntroProduct(String productId) {
    return false; // Pro Monthly removed
  }

  int _getCreditsForProduct(String productId) {
    switch (productId) {
      // case ProductIds.proMonthly: // Removed
      //   return 15; // Monthly credits for pro
      default:
        return 0;
    }
  }

  bool isSubscriptionProduct(String productId) {
    return false; // Pro Monthly removed
  }

  int getMonthlyCredits(String productId) {
    switch (productId) {
      // case ProductIds.proMonthly: // Removed
      //   return 15; // Monthly credits for pro
      default:
        return 0;
    }
  }

  /// Platform-specific purchase implementation
  Future<PurchaseResult> _performPlatformPurchase(String productId) async {
    // This would integrate with actual IAP packages (in_app_purchase, etc.)
    // For now, simulate a successful purchase
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    
    return PurchaseResult(
      success: true,
      productId: productId,
      transactionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      purchaseToken: defaultTargetPlatform == TargetPlatform.android ? 'test_token_${DateTime.now().millisecondsSinceEpoch}' : null,
    );
  }

  /// Record telemetry events
  Future<void> _recordTelemetry(IapTelemetryEvent event, Map<String, dynamic> parameters) async {
    try {
      await _firebaseIap.recordTelemetryEvent(event, {
        ...parameters,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'timezone': _internationalIap.deviceTimezone,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error recording telemetry: $e');
      }
    }
  }

  /// Get pricing display information
  Map<String, String> getPricingDisplay() {
    return _internationalIap.getDisplayPricing();
  }

  /// Check intro offer eligibility
  Future<bool> isIntroEligible(String productId) async {
    return await _internationalIap.isIntroOfferEligible(productId);
  }

  @override
  String toString() {
    return 'FirebaseIapClientService(initialized: $_initialized, user: ${_currentUser?.tier.name}, credits: ${_currentUser?.credits})';
  }
}

// Result classes for purchase operations
class PurchaseResult {
  final bool success;
  final String? error;
  final String productId;
  final String? transactionId;
  final String? purchaseToken;
  final int credits;

  const PurchaseResult({
    required this.success,
    this.error,
    required this.productId,
    this.transactionId,
    this.purchaseToken,
    this.credits = 0,
  });

  @override
  String toString() {
    return 'PurchaseResult(success: $success, product: $productId, credits: $credits, error: $error)';
  }
}

class RestoreResult {
  final bool success;
  final String? error;
  final List<dynamic> restoredProducts;

  const RestoreResult({
    required this.success,
    this.error,
    this.restoredProducts = const [],
  });

  @override
  String toString() {
    return 'RestoreResult(success: $success, restored: ${restoredProducts.length}, error: $error)';
  }
}