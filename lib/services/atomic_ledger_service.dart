import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindload/models/atomic_ledger_models.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/enhanced_abuse_prevention_service.dart';

/// Atomic ledger service for token transactions
/// Implements the requirements from Part 4B-2
class AtomicLedgerService {
  static final AtomicLedgerService _instance = AtomicLedgerService._internal();
  static AtomicLedgerService get instance => _instance;

  AtomicLedgerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService.instance;
  final EnhancedAbusePrevention _abusePrevention = EnhancedAbusePrevention.instance;

  // Configuration constants
  static const String LEDGER_COLLECTION = 'token_ledger';
  static const String ACCOUNTS_COLLECTION = 'user_token_accounts';
  static const String RECONCILIATION_COLLECTION = 'ledger_reconciliations';
  
  // Settings (in production, these would come from Remote Config)
  static const bool ATOMIC_WRITES_ENABLED = true;
  static const bool DAILY_RECONCILE_ENABLED = true;
  static const bool ALERT_ON_MISMATCH_ENABLED = true;

  /// Write a ledger entry atomically
  /// Every debit/credit writes one immutable record
  Future<LedgerEntryResult> writeLedgerEntry({
    required String action,
    required int tokens,
    required String requestId,
    required LedgerSource source,
    Map<String, dynamic> metadata = const {},
    String? setId,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return LedgerEntryResult(
        success: false,
        error: 'User not authenticated',
        ledgerEntry: null,
      );
    }

    // Check abuse prevention before proceeding
    final deviceInfo = await _getDeviceInfo();
    final abuseCheck = await _abusePrevention.canPerformAction(
      userId: userId,
      actionType: 'ledger_write',
      deviceInfo: deviceInfo,
      setId: setId,
    );

    if (!abuseCheck.isAllowed) {
      return LedgerEntryResult(
        success: false,
        error: abuseCheck.reason,
        ledgerEntry: null,
        requiresChallenge: abuseCheck.requiresChallenge,
        blockDuration: abuseCheck.blockDuration,
      );
    }

    try {
      // Generate unique entry ID
      final entryId = _generateEntryId();
      final now = DateTime.now();

      // Create ledger entry
      final ledgerEntry = LedgerEntry(
        entryId: entryId,
        userId: userId,
        action: action,
        tokens: tokens,
        requestId: requestId,
        timestamp: now,
        source: source.name,
        metadata: metadata,
      );

      // Check for duplicate request (fast dedupe - 60s)
      if (await _isDuplicateRequest(requestId, userId)) {
        await _logTelemetry('abuse.duplicate_request_blocked', {
          'requestId': requestId,
          'userId': userId,
          'timestamp': now.toIso8601String(),
        });
        
        return LedgerEntryResult(
          success: false,
          error: 'Duplicate request detected',
          ledgerEntry: null,
        );
      }

      // Perform atomic transaction
      if (ATOMIC_WRITES_ENABLED) {
        await _firestore.runTransaction((transaction) async {
          // Write ledger entry
          final ledgerRef = _firestore
              .collection(LEDGER_COLLECTION)
              .doc(userId)
              .collection('entries')
              .doc(entryId);
          
          transaction.set(ledgerRef, ledgerEntry.toMap());

          // Update user token account
          final accountRef = _firestore.collection(ACCOUNTS_COLLECTION).doc(userId);
          final accountDoc = await transaction.get(accountRef);
          
          if (accountDoc.exists) {
            final account = UserTokenAccount.fromMap(accountDoc.data() as Map<String, dynamic>, userId);
            final updatedAccount = _updateAccountBalance(account, action, tokens);
            
            transaction.update(accountRef, {
              ...updatedAccount.toMap(),
              'lastLedgerEntryId': entryId,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } else {
            // Create new account if it doesn't exist
            final newAccount = UserTokenAccount(
              userId: userId,
              monthlyTokens: action == 'credit' ? tokens : 0,
              welcomeBonus: 20,
              freeActions: 20,
              lastLedgerEntryId: entryId,
            );
            
            transaction.set(accountRef, newAccount.toMap());
          }
        });
      } else {
        // Non-atomic fallback (not recommended for production)
        await _firestore
            .collection(LEDGER_COLLECTION)
            .doc(userId)
            .collection('entries')
            .doc(entryId)
            .set(ledgerEntry.toMap());
        
        await _updateAccountBalanceNonAtomic(userId, action, tokens, entryId);
      }

      // Log successful ledger entry
      await _logTelemetry('ledger.entry_written', {
        'entryId': entryId,
        'userId': userId,
        'action': action,
        'tokens': tokens,
        'requestId': requestId,
        'source': source.name,
        'timestamp': now.toIso8601String(),
      });

      return LedgerEntryResult(
        success: true,
        error: null,
        ledgerEntry: ledgerEntry,
      );
    } catch (e) {
      // Log error and return failure
      await _logTelemetry('ledger.write_error', {
        'userId': userId,
        'action': action,
        'tokens': tokens,
        'requestId': requestId,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return LedgerEntryResult(
        success: false,
        error: 'Failed to write ledger entry: $e',
        ledgerEntry: null,
      );
    }
  }

  /// Check for duplicate requests within 60 seconds
  Future<bool> _isDuplicateRequest(String requestId, String userId) async {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(Duration(seconds: 60));
      
      final query = await _firestore
          .collection(LEDGER_COLLECTION)
          .doc(userId)
          .collection('entries')
          .where('requestId', isEqualTo: requestId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      // If we can't check for duplicates, allow the request
      // This is a fail-open approach for availability
      return false;
    }
  }

  /// Update account balance based on action type
  UserTokenAccount _updateAccountBalance(UserTokenAccount account, String action, int tokens) {
    switch (action) {
      case 'credit':
        return account.copyWith(
          monthlyTokens: account.monthlyTokens + tokens,
        );
      case 'debit':
        return _debitFromAccount(account, tokens);
      case 'reset':
        return account.copyWith(
          monthlyTokens: tokens,
          freeActions: 20,
          welcomeBonus: 20,
        );
      default:
        return account;
    }
  }

  /// Debit tokens following consumption order: Free → Welcome Bonus → Monthly
  UserTokenAccount _debitFromAccount(UserTokenAccount account, int tokens) {
    int remaining = tokens;
    int fromFree = 0;
    int fromWelcome = 0;
    int fromMonthly = 0;

    // Consume from free actions first
    if (account.freeActions >= remaining) {
      fromFree = remaining;
      remaining = 0;
    } else {
      fromFree = account.freeActions;
      remaining -= account.freeActions;
    }

    // Then from welcome bonus
    if (remaining > 0 && account.welcomeBonus >= remaining) {
      fromWelcome = remaining;
      remaining = 0;
    } else if (remaining > 0) {
      fromWelcome = account.welcomeBonus;
      remaining -= account.welcomeBonus;
    }

    // Finally from monthly tokens
    if (remaining > 0) {
      fromMonthly = remaining;
    }

    return account.copyWith(
      freeActions: account.freeActions - fromFree,
      welcomeBonus: account.welcomeBonus - fromWelcome,
      monthlyTokens: account.monthlyTokens - fromMonthly,
    );
  }

  /// Non-atomic account balance update (fallback)
  Future<void> _updateAccountBalanceNonAtomic(String userId, String action, int tokens, String entryId) async {
    final accountRef = _firestore.collection(ACCOUNTS_COLLECTION).doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final accountDoc = await transaction.get(accountRef);
      
      if (accountDoc.exists) {
        final account = UserTokenAccount.fromMap(accountDoc.data() as Map<String, dynamic>, userId);
        final updatedAccount = _updateAccountBalance(account, action, tokens);
        
        transaction.update(accountRef, {
          ...updatedAccount.toMap(),
          'lastLedgerEntryId': entryId,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get user's ledger entries
  Future<List<LedgerEntry>> getLedgerEntries({
    String? userId,
    int limit = 100,
    DateTime? since,
  }) async {
    final targetUserId = userId ?? _authService.currentUserId;
    if (targetUserId == null) return [];

    try {
      Query query = _firestore
          .collection(LEDGER_COLLECTION)
          .doc(targetUserId)
          .collection('entries')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where('timestamp', isGreaterThan: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
          LedgerEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's current token account
  Future<UserTokenAccount?> getUserTokenAccount(String? userId) async {
    final targetUserId = userId ?? _authService.currentUserId;
    if (targetUserId == null) return null;

    try {
      final doc = await _firestore
          .collection(ACCOUNTS_COLLECTION)
          .doc(targetUserId)
          .get();

      if (doc.exists) {
        return UserTokenAccount.fromMap(doc.data() as Map<String, dynamic>, targetUserId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Perform daily reconciliation for a user
  Future<ReconciliationResult> reconcileUserLedger(String? userId) async {
    final targetUserId = userId ?? _authService.currentUserId;
    if (targetUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get all ledger entries for the user
      final ledgerEntries = await getLedgerEntries(userId: targetUserId, limit: 10000);
      
      // Calculate expected balance from ledger
      int expectedBalance = 0;
      final mismatchedEntries = <String>[];
      
      for (final entry in ledgerEntries) {
        switch (entry.action) {
          case 'credit':
            expectedBalance += entry.tokens;
            break;
          case 'debit':
            expectedBalance -= entry.tokens;
            break;
          case 'reset':
            expectedBalance = entry.tokens;
            break;
        }
      }

      // Get actual balance from account
      final account = await getUserTokenAccount(targetUserId);
      final actualBalance = account?.totalAvailableTokens ?? 0;
      
      // Calculate difference
      final difference = (expectedBalance - actualBalance).abs();
      final isBalanced = difference == 0;
      
      // Create reconciliation result
      final result = ReconciliationResult(
        userId: targetUserId,
        expectedBalance: expectedBalance,
        actualBalance: actualBalance,
        difference: difference,
        isBalanced: isBalanced,
        mismatchedEntries: mismatchedEntries,
        reconciledAt: DateTime.now(),
      );

      // Log reconciliation result
      if (isBalanced) {
        await _logTelemetry('ledger.reconcile_ok', {
          'userId': targetUserId,
          'expectedBalance': expectedBalance,
          'actualBalance': actualBalance,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        await _logTelemetry('ledger.reconcile_mismatch', {
          'userId': targetUserId,
          'expectedBalance': expectedBalance,
          'actualBalance': actualBalance,
          'difference': difference,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Store reconciliation result for review
        await _firestore
            .collection(RECONCILIATION_COLLECTION)
            .add(result.toMap());
      }

      return result;
    } catch (e) {
      throw Exception('Reconciliation failed: $e');
    }
  }

  /// Perform reconciliation for all users (admin function)
  Future<List<ReconciliationResult>> reconcileAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection(ACCOUNTS_COLLECTION).get();
      final results = <ReconciliationResult>[];
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final result = await reconcileUserLedger(userDoc.id);
          results.add(result);
        } catch (e) {
          // Continue with other users if one fails
          print('Reconciliation failed for user ${userDoc.id}: $e');
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Bulk reconciliation failed: $e');
    }
  }

  /// Get ledger statistics
  Future<Map<String, dynamic>> getLedgerStats(String? userId) async {
    final targetUserId = userId ?? _authService.currentUserId;
    if (targetUserId == null) return {};

    try {
      final ledgerEntries = await getLedgerEntries(userId: targetUserId, limit: 10000);
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      
      // Filter entries for this month
      final monthlyEntries = ledgerEntries.where(
        (entry) => entry.timestamp.isAfter(thisMonth)
      ).toList();
      
      // Calculate statistics
      int totalCredits = 0;
      int totalDebits = 0;
      int totalResets = 0;
      
      for (final entry in monthlyEntries) {
        switch (entry.action) {
          case 'credit':
            totalCredits += entry.tokens;
            break;
          case 'debit':
            totalDebits += entry.tokens;
            break;
          case 'reset':
            totalResets += entry.tokens;
            break;
        }
      }
      
      return {
        'totalEntries': monthlyEntries.length,
        'totalCredits': totalCredits,
        'totalDebits': totalDebits,
        'totalResets': totalResets,
        'netChange': totalCredits - totalDebits,
        'period': 'this_month',
        'periodStart': thisMonth.toIso8601String(),
        'periodEnd': now.toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  /// Generate unique entry ID
  String _generateEntryId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _generateRandomString(8);
    return 'entry_${timestamp}_$random';
  }

  /// Generate random string for entry ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(DateTime.now().millisecond % chars.length))
    );
  }

  /// Get device information for abuse prevention
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // In a real app, this would collect actual device information
    // For now, return a simplified version
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': _generateRandomString(16),
    };
  }

  /// Log telemetry events
  Future<void> _logTelemetry(String event, Map<String, dynamic> parameters) async {
    try {
      await _firestore.collection('telemetry_events').add({
        'event': event,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail telemetry logging to avoid breaking main functionality
      print('Telemetry logging failed: $e');
    }
  }

  /// Clean up old ledger entries (admin function)
  Future<void> cleanupOldLedgerEntries({Duration? olderThan}) async {
    final cutoff = olderThan ?? Duration(days: 90);
    final cutoffDate = DateTime.now().subtract(cutoff);
    
    try {
      final usersSnapshot = await _firestore.collection(ACCOUNTS_COLLECTION).get();
      
      for (final userDoc in usersSnapshot.docs) {
        final entriesQuery = await _firestore
            .collection(LEDGER_COLLECTION)
            .doc(userDoc.id)
            .collection('entries')
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
            .get();
        
        // Delete old entries in batches
        final batch = _firestore.batch();
        int batchCount = 0;
        
        for (final entryDoc in entriesQuery.docs) {
          batch.delete(entryDoc.reference);
          batchCount++;
          
          if (batchCount >= 500) {
            await batch.commit();
            batchCount = 0;
          }
        }
        
        if (batchCount > 0) {
          await batch.commit();
        }
      }
    } catch (e) {
      throw Exception('Cleanup failed: $e');
    }
  }
}

/// Result of writing a ledger entry
class LedgerEntryResult {
  final bool success;
  final String? error;
  final LedgerEntry? ledgerEntry;
  final bool requiresChallenge;
  final Duration? blockDuration;

  const LedgerEntryResult({
    required this.success,
    this.error,
    this.ledgerEntry,
    this.requiresChallenge = false,
    this.blockDuration,
  });
}
