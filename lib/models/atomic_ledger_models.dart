import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindload/constants/product_constants.dart';

/// Atomic ledger entry for all token transactions
/// Every debit/credit writes one immutable record
class LedgerEntry {
  final String entryId;
  final String userId;
  final String action;
  final int tokens;
  final String requestId;
  final DateTime timestamp;
  final String source;
  final Map<String, dynamic> metadata;

  const LedgerEntry({
    required this.entryId,
    required this.userId,
    required this.action,
    required this.tokens,
    required this.requestId,
    required this.timestamp,
    required this.source,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'tokens': tokens,
      'requestId': requestId,
      'timestamp': Timestamp.fromDate(timestamp),
      'source': source,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map, String entryId) {
    return LedgerEntry(
      entryId: entryId,
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      tokens: map['tokens'] ?? 0,
      requestId: map['requestId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      source: map['source'] ?? '',
      metadata: map['metadata'] ?? {},
    );
  }

  LedgerEntry copyWith({
    String? entryId,
    String? userId,
    String? action,
    int? tokens,
    String? requestId,
    DateTime? timestamp,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return LedgerEntry(
      entryId: entryId ?? this.entryId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      tokens: tokens ?? this.tokens,
      requestId: requestId ?? this.requestId,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Ledger source types for categorization
enum LedgerSource {
  purchase,      // Logic pack purchases
  generate,      // AI content generation
  regenerate,    // Content regeneration
  reOrganize,    // Content reorganization
  freeAction,    // Free monthly actions
  welcomeBonus,  // New user bonus
  monthlyReset,  // Monthly token reset
  refund,        // Purchase refunds
  adjustment,    // Manual adjustments
}

/// Ledger action types
enum LedgerAction {
  credit,        // Add tokens
  debit,         // Remove tokens
  reset,         // Reset to base amount
  transfer,      // Move between accounts
}

/// Purchase verification result for replay protection
class PurchaseVerificationResult {
  final String purchaseId;
  final String productId;
  final int tokens;
  final bool isVerified;
  final bool isReplay;
  final DateTime verifiedAt;
  final String? errorMessage;

  const PurchaseVerificationResult({
    required this.purchaseId,
    required this.productId,
    required this.tokens,
    required this.isVerified,
    required this.isReplay,
    required this.verifiedAt,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'purchaseId': purchaseId,
      'productId': productId,
      'tokens': tokens,
      'isVerified': isVerified,
      'isReplay': isReplay,
      'verifiedAt': Timestamp.fromDate(verifiedAt),
      'errorMessage': errorMessage,
    };
  }

  factory PurchaseVerificationResult.fromMap(Map<String, dynamic> map) {
    return PurchaseVerificationResult(
      purchaseId: map['purchaseId'] ?? '',
      productId: map['productId'] ?? '',
      tokens: map['tokens'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isReplay: map['isReplay'] ?? false,
      verifiedAt: (map['verifiedAt'] as Timestamp).toDate(),
      errorMessage: map['errorMessage'],
    );
  }
}

/// User token account with atomic balance tracking
class UserTokenAccount {
  final String userId;
  final int monthlyTokens;
  final int welcomeBonus;
  final int freeActions;
  final DateTime lastResetDate;
  final String lastLedgerEntryId;
  final DateTime lastUpdated;

  UserTokenAccount({
    required this.userId,
    this.monthlyTokens = 0,
    this.welcomeBonus = ProductConstants.freeMonthlyTokens,
    this.freeActions = ProductConstants.freeMonthlyTokens,
    DateTime? lastResetDate,
    this.lastLedgerEntryId = '',
    DateTime? lastUpdated,
  }) : lastResetDate = lastResetDate ?? DateTime(2024, 1, 1),
       lastUpdated = lastUpdated ?? DateTime(2024, 1, 1);

  Map<String, dynamic> toMap() {
    return {
      'monthlyTokens': monthlyTokens,
      'welcomeBonus': welcomeBonus,
      'freeActions': freeActions,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'lastLedgerEntryId': lastLedgerEntryId,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory UserTokenAccount.fromMap(Map<String, dynamic> map, String userId) {
    return UserTokenAccount(
      userId: userId,
      monthlyTokens: map['monthlyTokens'] ?? 0,
      welcomeBonus: map['welcomeBonus'] ?? ProductConstants.freeMonthlyTokens,
      freeActions: map['freeActions'] ?? ProductConstants.freeMonthlyTokens,
      lastResetDate: (map['lastResetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLedgerEntryId: map['lastLedgerEntryId'] ?? '',
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Check if user can afford an action
  bool canAffordAction(int requiredTokens) {
    final availableTokens = freeActions + welcomeBonus + monthlyTokens;
    return availableTokens >= requiredTokens;
  }

  /// Get total available tokens
  int get totalAvailableTokens => freeActions + welcomeBonus + monthlyTokens;

  /// Get consumption order breakdown
  Map<String, int> getConsumptionBreakdown(int requiredTokens) {
    int remaining = requiredTokens;
    int fromFree = 0;
    int fromWelcome = 0;
    int fromMonthly = 0;

    // Consume from free actions first
    if (freeActions >= remaining) {
      fromFree = remaining;
      remaining = 0;
    } else {
      fromFree = freeActions;
      remaining -= freeActions;
    }

    // Then from welcome bonus
    if (remaining > 0 && welcomeBonus >= remaining) {
      fromWelcome = remaining;
      remaining = 0;
    } else if (remaining > 0) {
      fromWelcome = welcomeBonus;
      remaining -= welcomeBonus;
    }

    // Finally from monthly tokens
    if (remaining > 0) {
      fromMonthly = remaining;
    }

    return {
      'fromFree': fromFree,
      'fromWelcome': fromWelcome,
      'fromMonthly': fromMonthly,
      'total': requiredTokens,
    };
  }

  UserTokenAccount copyWith({
    String? userId,
    int? monthlyTokens,
    int? welcomeBonus,
    int? freeActions,
    DateTime? lastResetDate,
    String? lastLedgerEntryId,
    DateTime? lastUpdated,
  }) {
    return UserTokenAccount(
      userId: userId ?? this.userId,
      monthlyTokens: monthlyTokens ?? this.monthlyTokens,
      welcomeBonus: welcomeBonus ?? this.welcomeBonus,
      freeActions: freeActions ?? this.freeActions,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      lastLedgerEntryId: lastLedgerEntryId ?? this.lastLedgerEntryId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Reconciliation result for daily ledger verification
class ReconciliationResult {
  final String userId;
  final int expectedBalance;
  final int actualBalance;
  final int difference;
  final bool isBalanced;
  final List<String> mismatchedEntries;
  final DateTime reconciledAt;

  const ReconciliationResult({
    required this.userId,
    required this.expectedBalance,
    required this.actualBalance,
    required this.difference,
    required this.isBalanced,
    required this.mismatchedEntries,
    required this.reconciledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'expectedBalance': expectedBalance,
      'actualBalance': actualBalance,
      'difference': difference,
      'isBalanced': isBalanced,
      'mismatchedEntries': mismatchedEntries,
      'reconciledAt': Timestamp.fromDate(reconciledAt),
    };
  }

  factory ReconciliationResult.fromMap(Map<String, dynamic> map) {
    return ReconciliationResult(
      userId: map['userId'] ?? '',
      expectedBalance: map['expectedBalance'] ?? 0,
      actualBalance: map['actualBalance'] ?? 0,
      difference: map['difference'] ?? 0,
      isBalanced: map['isBalanced'] ?? false,
      mismatchedEntries: List<String>.from(map['mismatchedEntries'] ?? []),
      reconciledAt: (map['reconciledAt'] as Timestamp).toDate(),
    );
  }
}
