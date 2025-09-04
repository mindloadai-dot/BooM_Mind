import 'package:flutter/foundation.dart';
import 'package:mindload/constants/product_constants.dart';
import 'package:mindload/services/unified_storage_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/firestore/firestore_repository.dart';

/// EntitlementService manages user token allowances and monthly resets
/// Handles the 20-token monthly allowance for new users
class EntitlementService extends ChangeNotifier {
  static final EntitlementService _instance = EntitlementService._internal();
  factory EntitlementService() => _instance;
  static EntitlementService get instance => _instance;
  EntitlementService._internal();

  // User entitlements
  UserEntitlements _currentEntitlements = UserEntitlements.initial();
  bool _isInitialized = false;

  UserEntitlements get currentEntitlements => _currentEntitlements;
  bool get isInitialized => _isInitialized;

  // Token allowance getters
  int get monthlyAllowanceRemaining =>
      _currentEntitlements.monthlyAllowanceRemaining;
  int get logicPackBalance => _currentEntitlements.logicPackBalance;
  int get totalAvailableTokens => monthlyAllowanceRemaining + logicPackBalance;

  // Reset schedule info
  DateTime get nextResetDate => _calculateNextResetDate();
  Duration get timeUntilReset => nextResetDate.difference(DateTime.now());

  /// Initialize entitlements for a user
  Future<void> initialize(String userId) async {
    try {
      await _loadEntitlements(userId);
      await _checkMonthlyReset();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing entitlements: $e');
      }
      // Create default entitlements on error
      await _createDefaultEntitlements(userId);
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Bootstrap entitlements for new user on first sign-in
  Future<void> bootstrapNewUser(String userId) async {
    if (_currentEntitlements.userId.isNotEmpty) {
      // User already has entitlements
      return;
    }

    // Check if user is admin and give them 1000 tokens instead of 20
    final isAdmin = _isAdminUser(userId);
    _currentEntitlements =
        UserEntitlements.initial(userId: userId, isAdmin: isAdmin);
    await _saveEntitlements();
    notifyListeners();
  }

  /// Check if user is admin based on email
  bool _isAdminUser(String userId) {
    // Get current user from AuthService to check if admin
    final currentUser = AuthService.instance.currentUser;
    return currentUser?.email == 'admin@mindload.test';
  }

  /// Auto-create missing entitlements before token-metered flows
  Future<void> ensureEntitlementsExist(String userId) async {
    if (_currentEntitlements.userId.isEmpty || !_isInitialized) {
      await bootstrapNewUser(userId);
    }
  }

  /// Check if user can afford a token operation
  Future<bool> canAffordTokens(int requiredTokens) async {
    await _checkMonthlyReset();
    return totalAvailableTokens >= requiredTokens;
  }

  /// Consume tokens (monthly allowance first, then Logic Pack balance)
  Future<bool> consumeTokens(int tokensToConsume) async {
    if (tokensToConsume <= 0) return true;

    await _checkMonthlyReset();

    if (totalAvailableTokens < tokensToConsume) {
      return false;
    }

    // Consume from monthly allowance first
    if (_currentEntitlements.monthlyAllowanceRemaining >= tokensToConsume) {
      _currentEntitlements.monthlyAllowanceRemaining -= tokensToConsume;
    } else {
      // Use remaining monthly allowance
      final remainingFromAllowance =
          _currentEntitlements.monthlyAllowanceRemaining;
      _currentEntitlements.monthlyAllowanceRemaining = 0;

      // Use Logic Pack balance for the rest
      final remainingFromLogicPack = tokensToConsume - remainingFromAllowance;
      _currentEntitlements.logicPackBalance -= remainingFromLogicPack;
    }

    await _saveEntitlements();
    notifyListeners();
    return true;
  }

  /// Add Logic Pack tokens to balance
  Future<void> addLogicPackTokens(int tokens) async {
    if (tokens > 0) {
      _currentEntitlements.logicPackBalance += tokens;
      await _saveEntitlements();
      notifyListeners();
    }
  }

  /// Check if monthly reset is needed and perform it
  Future<void> _checkMonthlyReset() async {
    final now = DateTime.now();
    final lastReset = _currentEntitlements.lastMonthlyReset;

    if (_shouldResetThisMonth(now, lastReset)) {
      await _performMonthlyReset();
    }
  }

  /// Determine if monthly reset should occur
  bool _shouldResetThisMonth(DateTime now, DateTime lastReset) {
    // Reset on 1st of month at 00:00 America/Chicago
    final chicagoTime = _convertToChicagoTime(now);
    final lastResetChicago = _convertToChicagoTime(lastReset);

    // Check if it's a new month since last reset
    return chicagoTime.year != lastResetChicago.year ||
        chicagoTime.month != lastResetChicago.month;
  }

  /// Convert UTC time to America/Chicago time
  DateTime _convertToChicagoTime(DateTime utcTime) {
    // America/Chicago is UTC-6 (CST) or UTC-5 (CDT)
    // For simplicity, we'll use UTC-6 as the base
    // In production, you might want to use a proper timezone library
    return utcTime.subtract(const Duration(hours: 6));
  }

  /// Calculate next reset date (1st of next month at 00:00 America/Chicago)
  DateTime _calculateNextResetDate() {
    final now = DateTime.now();
    final chicagoTime = _convertToChicagoTime(now);

    // Get 1st of next month
    DateTime nextMonth;
    if (chicagoTime.month == 12) {
      nextMonth = DateTime(chicagoTime.year + 1, 1, 1);
    } else {
      nextMonth = DateTime(chicagoTime.year, chicagoTime.month + 1, 1);
    }

    // Convert back to UTC (add 6 hours to get UTC time)
    return nextMonth.add(const Duration(hours: 6));
  }

  /// Perform monthly reset of allowances
  Future<void> _performMonthlyReset() async {
    // Check if user is admin and reset accordingly
    final isAdmin = _isAdminUser(_currentEntitlements.userId);
    final resetAmount = isAdmin ? 1000 : ProductConstants.freeMonthlyTokens;

    // Reset monthly allowance to appropriate amount
    _currentEntitlements.monthlyAllowanceRemaining = resetAmount;

    // Update last reset timestamp
    _currentEntitlements.lastMonthlyReset = DateTime.now();

    // Logic Pack balance persists (does not reset)

    await _saveEntitlements();
    notifyListeners();

    if (kDebugMode) {
      print(
          'Monthly allowance reset: $resetAmount tokens available for ${isAdmin ? 'admin' : 'regular'} user');
    }
  }

  /// Create default entitlements for new user
  Future<void> _createDefaultEntitlements(String userId) async {
    final isAdmin = _isAdminUser(userId);
    _currentEntitlements =
        UserEntitlements.initial(userId: userId, isAdmin: isAdmin);
    await _saveEntitlements();
  }

  /// Load entitlements from storage
  Future<void> _loadEntitlements(String userId) async {
    try {
      // Try to load from local storage first
      final localData =
          await UnifiedStorageService.instance.getUserEntitlements(userId);
      if (localData != null) {
        _currentEntitlements = UserEntitlements.fromJson(localData);
        return;
      }

      // Try to load from Firestore if online
      if (!AuthService.instance.isLocalMode) {
        final firestoreData =
            await FirestoreRepository.instance.getUserEntitlements(userId);
        if (firestoreData != null) {
          _currentEntitlements = UserEntitlements.fromJson(firestoreData);
          // Save to local storage
          await UnifiedStorageService.instance
              .saveUserEntitlements(userId, firestoreData);
          return;
        }
      }

      // Create default entitlements if none exist
      await _createDefaultEntitlements(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading entitlements: $e');
      }
      await _createDefaultEntitlements(userId);
    }
  }

  /// Save entitlements to storage
  Future<void> _saveEntitlements() async {
    try {
      final data = _currentEntitlements.toJson();

      // Save to local storage
      await UnifiedStorageService.instance
          .saveUserEntitlements(_currentEntitlements.userId, data);

      // Save to Firestore if online
      if (!AuthService.instance.isLocalMode) {
        await FirestoreRepository.instance.saveUserEntitlements(
          _currentEntitlements.userId,
          data,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving entitlements: $e');
      }
    }
  }

  /// Get status message for UI
  String getStatusMessage() {
    if (monthlyAllowanceRemaining == 0 && logicPackBalance == 0) {
      return 'No ${ProductConstants.tokenUnitName} remaining. Get more with a Logic Pack or upgrade to ${ProductConstants.axonMonthlyName}.';
    }

    if (monthlyAllowanceRemaining <= 5) {
      return 'Running low on monthly allowance. Consider a Logic Pack for immediate access.';
    }

    return '';
  }

  /// Get detailed entitlement info for UI
  Map<String, dynamic> getEntitlementInfo() {
    return {
      'monthlyAllowanceRemaining': monthlyAllowanceRemaining,
      'logicPackBalance': logicPackBalance,
      'totalAvailable': totalAvailableTokens,
      'nextReset': nextResetDate,
      'timeUntilReset': timeUntilReset,
      'statusMessage': getStatusMessage(),
    };
  }
}

/// User entitlements data model
class UserEntitlements {
  final String userId;
  int monthlyAllowanceRemaining;
  int logicPackBalance;
  DateTime lastMonthlyReset;
  DateTime createdAt;
  DateTime updatedAt;

  UserEntitlements({
    required this.userId,
    required this.monthlyAllowanceRemaining,
    required this.logicPackBalance,
    required this.lastMonthlyReset,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create initial entitlements for new user
  factory UserEntitlements.initial({String userId = '', bool isAdmin = false}) {
    final now = DateTime.now();
    final monthlyTokens = isAdmin ? 1000 : ProductConstants.freeMonthlyTokens;
    return UserEntitlements(
      userId: userId,
      monthlyAllowanceRemaining: monthlyTokens,
      logicPackBalance: 0,
      lastMonthlyReset: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from JSON data
  factory UserEntitlements.fromJson(Map<String, dynamic> json) {
    return UserEntitlements(
      userId: json['userId'] ?? '',
      monthlyAllowanceRemaining: json['monthlyAllowanceRemaining'] ??
          ProductConstants.freeMonthlyTokens,
      logicPackBalance: json['logicPackBalance'] ?? 0,
      lastMonthlyReset: DateTime.parse(json['lastMonthlyReset']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'monthlyAllowanceRemaining': monthlyAllowanceRemaining,
      'logicPackBalance': logicPackBalance,
      'lastMonthlyReset': lastMonthlyReset.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  UserEntitlements copyWith({
    String? userId,
    int? monthlyAllowanceRemaining,
    int? logicPackBalance,
    DateTime? lastMonthlyReset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntitlements(
      userId: userId ?? this.userId,
      monthlyAllowanceRemaining:
          monthlyAllowanceRemaining ?? this.monthlyAllowanceRemaining,
      logicPackBalance: logicPackBalance ?? this.logicPackBalance,
      lastMonthlyReset: lastMonthlyReset ?? this.lastMonthlyReset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
