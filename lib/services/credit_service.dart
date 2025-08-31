import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/enhanced_storage_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/constants/product_constants.dart';
import 'package:mindload/services/entitlement_service.dart';

enum SubscriptionPlan {
  free,
  pro,
  admin,
}

class CreditLimits {
  // Monthly credit caps for different tiers
  static const int freeMonthlyQuota = ProductConstants.freeMonthlyTokens;
  // static const int proMonthlyQuota = 150; // Removed
  static const int adminMonthlyQuota = 1000;

  // Credit costs per study set generation
  static const int quizSetCost = 1;
  static const int flashcardSetCost = 1;
  static const int bothSetsCost = 2; // Quiz + Flashcards together

  // Rate limiting (unchanged)
  static const int rateLimitRequestsPerSecond = 1;
  static const int rateLimitRequestsPerMinute = 20;
  static const int rateLimitCooldownSeconds = 30;
  static const int rateLimitLockoutMinutes = 15;
  static const int rateLimitLockoutThreshold = 200;

  static const int costCapBudget = 1; // $1 monthly budget for fallback
}

class CreditUsage {
  final DateTime timestamp;
  final int creditsUsed;
  final int outputTokens;
  final String requestType;

  CreditUsage({
    required this.timestamp,
    required this.creditsUsed,
    required this.outputTokens,
    required this.requestType,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'creditsUsed': creditsUsed,
        'outputTokens': outputTokens,
        'requestType': requestType,
      };

  factory CreditUsage.fromJson(Map<String, dynamic> json) {
    return CreditUsage(
      timestamp: DateTime.parse(json['timestamp']),
      creditsUsed: json['creditsUsed'],
      outputTokens: json['outputTokens'],
      requestType: json['requestType'],
    );
  }
}

class RateLimitState {
  int requestsInLastSecond = 0;
  int requestsInLastMinute = 0;
  DateTime lastRequestTime = DateTime.now();
  DateTime? cooldownUntil;
  DateTime? lockoutUntil;
  int consecutiveRateLimitHits = 0;

  RateLimitState();

  bool get isInCooldown =>
      cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);
  bool get isInLockout =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);
  bool get isBlocked => isInCooldown || isInLockout;

  Map<String, dynamic> toJson() => {
        'requestsInLastSecond': requestsInLastSecond,
        'requestsInLastMinute': requestsInLastMinute,
        'lastRequestTime': lastRequestTime.toIso8601String(),
        'cooldownUntil': cooldownUntil?.toIso8601String(),
        'lockoutUntil': lockoutUntil?.toIso8601String(),
        'consecutiveRateLimitHits': consecutiveRateLimitHits,
      };

  factory RateLimitState.fromJson(Map<String, dynamic> json) {
    final state = RateLimitState();
    state.requestsInLastSecond = json['requestsInLastSecond'] ?? 0;
    state.requestsInLastMinute = json['requestsInLastMinute'] ?? 0;
    state.lastRequestTime = DateTime.parse(json['lastRequestTime']);
    state.cooldownUntil = json['cooldownUntil'] != null
        ? DateTime.parse(json['cooldownUntil'])
        : null;
    state.lockoutUntil = json['lockoutUntil'] != null
        ? DateTime.parse(json['lockoutUntil'])
        : null;
    state.consecutiveRateLimitHits = json['consecutiveRateLimitHits'] ?? 0;
    return state;
  }
}

class CreditService extends ChangeNotifier {
  static final CreditService _instance = CreditService._internal();
  static CreditService get instance => _instance;
  CreditService._internal();

  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  int _creditsRemaining = CreditLimits.freeMonthlyQuota;
  int _monthlyQuota = CreditLimits.freeMonthlyQuota;
  DateTime _lastRefill = DateTime.now();
  List<CreditUsage> _thisMonthUsage = [];
  RateLimitState _rateLimitState = RateLimitState();
  Timer? _refreshTimer;

  // Track last used custom study set counts
  int _lastQuizCount = 10;
  int _lastFlashcardCount = 15;

  SubscriptionPlan get currentPlan => _currentPlan;
  int get creditsRemaining => _creditsRemaining;
  int get monthlyQuota => _monthlyQuota;
  bool get hasCredits => _creditsRemaining > 0;
  bool get isRateLimited => _rateLimitState.isBlocked;
  String get creditDisplayText => _creditsRemaining == 999999
      ? 'Unlimited'
      : '$_creditsRemaining/$_monthlyQuota';
  bool get isUnlimited =>
      _currentPlan == SubscriptionPlan.pro ||
      _currentPlan == SubscriptionPlan.admin;

  List<CreditUsage> get thisMonthUsage => List.unmodifiable(_thisMonthUsage);
  int get lastQuizCount => _lastQuizCount;
  int get lastFlashcardCount => _lastFlashcardCount;
  RateLimitState get rateLimitState => _rateLimitState;

  Future<void> initialize() async {
    await _loadCreditData();
    await _checkMonthlyRefill();
    _startRefreshTimer();

    // Initialize entitlements if user is authenticated
    final authService = AuthService.instance;
    if (authService.isAuthenticated && authService.currentUser != null) {
      await EntitlementService.instance
          .initialize(authService.currentUser!.uid);
    }

    notifyListeners();
  }

  Future<void> setPlan(SubscriptionPlan plan) async {
    _currentPlan = plan;

    switch (plan) {
      case SubscriptionPlan.free:
        _monthlyQuota = CreditLimits.freeMonthlyQuota;
        break;
      case SubscriptionPlan.pro:
        // _monthlyQuota = CreditLimits.proMonthlyQuota; // Removed
        break;
      case SubscriptionPlan.admin:
        _monthlyQuota = CreditLimits.adminMonthlyQuota;
        break;
    }

    // Update remaining credits for new quota
    if (_currentPlan == SubscriptionPlan.free) {
      _creditsRemaining = _monthlyQuota - _getThisMonthUsage();
    } else {
      _creditsRemaining = _monthlyQuota; // Unlimited
    }

    await _saveCreditData();
    notifyListeners();
  }

  Future<bool> canMakeRequest({int estimatedOutputTokens = 1500}) async {
    // Check rate limiting first
    if (_rateLimitState.isBlocked) {
      return false;
    }

    // Check if we have sufficient credits
    final requiredCredits = calculateCreditsRequired(estimatedOutputTokens);
    return _creditsRemaining >= requiredCredits;
  }

  /// Check if user can generate study set(s)
  Future<bool> canGenerateStudySet(StudySetType type) async {
    if (_rateLimitState.isBlocked) {
      return false;
    }

    if (isUnlimited) {
      return true;
    }

    final creditsNeeded = _getCreditsForStudySetType(type);
    return _creditsRemaining >= creditsNeeded;
  }

  /// Use credits for study set generation
  Future<bool> useCreditsForStudySet(
      StudySetType type, int quizCount, int flashcardCount) async {
    final creditsNeeded = _getCreditsForStudySetType(type);

    if (!await canGenerateStudySet(type)) {
      return false;
    }

    // Store last used counts for quick repeat
    if (quizCount > 0) _lastQuizCount = quizCount;
    if (flashcardCount > 0) _lastFlashcardCount = flashcardCount;

    final operation = _getOperationName(type);
    return await _consumeStudySetCredits(creditsNeeded, operation);
  }

  /// Calculate credits for documents by page count.
  /// Rule: 1 credit per 5 pages (rounded up). Example: 1..5 => 1, 6..10 => 2, etc.
  int creditsForPageCount(int pageCount) {
    if (pageCount <= 0) return 0;
    return ((pageCount + 4) ~/ 5);
  }

  /// Check if the user can process a document with the given page count.
  Future<bool> canUseCreditsForDocumentPages(int pageCount) async {
    if (_rateLimitState.isBlocked) return false;
    if (isUnlimited) return true;
    final needed = creditsForPageCount(pageCount);
    return _creditsRemaining >= needed;
  }

  /// Consume credits for processing a document of the given page count.
  /// Operation name is used for telemetry/usage tracking.
  Future<bool> useCreditsForDocumentPages(
      int pageCount, String operation) async {
    final needed = creditsForPageCount(pageCount);
    return _consumeStudySetCredits(needed, operation);
  }

  /// Check if user can use a specific number of credits (for UI validation)
  Future<bool> canUseCredits(int creditsNeeded) async {
    if (_rateLimitState.isBlocked) {
      return false;
    }
    if (isUnlimited) {
      return true;
    }
    return _creditsRemaining >= creditsNeeded;
  }

  /// Calculate AI optimal counts based on user data
  Map<String, int> calculateOptimalCounts(DifficultyLevel topicDifficulty) {
    // Base optimal counts
    int optimalQuiz = 15;
    int optimalFlashcards = 25;

    // Adjust based on topic difficulty
    switch (topicDifficulty) {
      case DifficultyLevel.beginner:
        optimalQuiz = 10;
        optimalFlashcards = 20;
        break;
      case DifficultyLevel.advanced:
        optimalQuiz = 20;
        optimalFlashcards = 30;
        break;
      case DifficultyLevel.intermediate:
      case DifficultyLevel.expert:
        optimalQuiz = 15;
        optimalFlashcards = 25;
        break;
    }

    // Adjust based on remaining credits for free users
    if (!isUnlimited && _creditsRemaining < 2) {
      if (_creditsRemaining == 1) {
        // Only enough for one type
        optimalQuiz = optimalQuiz;
        optimalFlashcards = 0;
      } else {
        // No credits remaining
        optimalQuiz = 0;
        optimalFlashcards = 0;
      }
    }

    return {
      'quiz': optimalQuiz,
      'flashcards': optimalFlashcards,
    };
  }

  int _getCreditsForStudySetType(StudySetType type) {
    switch (type) {
      case StudySetType.quiz:
        return CreditLimits.quizSetCost;
      case StudySetType.flashcards:
        return CreditLimits.flashcardSetCost;
      case StudySetType.both:
        return CreditLimits.bothSetsCost;
      case StudySetType.youtube:
        return CreditLimits.bothSetsCost; // YouTube generates both types
      case StudySetType.document:
        return CreditLimits.bothSetsCost; // Documents generate both types
      case StudySetType.custom:
        return CreditLimits.flashcardSetCost; // Custom usually single type
    }
  }

  String _getOperationName(StudySetType type) {
    switch (type) {
      case StudySetType.quiz:
        return 'quiz_generation';
      case StudySetType.flashcards:
        return 'flashcard_generation';
      case StudySetType.both:
        return 'both_sets_generation';
      case StudySetType.youtube:
        return 'youtube_transcript_generation';
      case StudySetType.document:
        return 'document_generation';
      case StudySetType.custom:
        return 'custom_generation';
    }
  }

  Future<bool> _consumeStudySetCredits(
      int creditsNeeded, String operation) async {
    final now = DateTime.now();

    // Update rate limiting
    _updateRateLimit(now);

    // Check rate limits
    if (_rateLimitState.isBlocked) {
      if (kDebugMode) {
        print('Request blocked due to rate limiting');
      }
      return false;
    }

    // Check monthly refill
    await _checkMonthlyRefill();

    // Pro/Annual Pro users have unlimited credits
    if (isUnlimited) {
      // Track usage but don't deduct credits
      final usage = CreditUsage(
        timestamp: now,
        creditsUsed: 0, // Don't count against quota for unlimited users
        outputTokens: 1500, // Estimate
        requestType: operation,
      );
      _thisMonthUsage.add(usage);
      await _saveCreditData();
      notifyListeners();
      return true;
    }

    if (_creditsRemaining < creditsNeeded) {
      if (kDebugMode) {
        print(
            'Insufficient credits: need $creditsNeeded, have $_creditsRemaining');
      }
      return false;
    }

    // Sync with Firestore if user is authenticated
    final authService = AuthService.instance;
    if (authService.isAuthenticated) {
      final success = await FirestoreRepository.instance.useCredits(
        authService.currentUser!.uid,
        creditsNeeded,
        operation,
      );

      if (!success) {
        if (kDebugMode) {
          print('Firestore credit check failed');
        }
        return false;
      }
    }

    // Consume credits locally for free tier
    _creditsRemaining -= creditsNeeded;

    // Track usage
    final usage = CreditUsage(
      timestamp: now,
      creditsUsed: creditsNeeded,
      outputTokens: 1500, // Estimate for study set generation
      requestType: operation,
    );
    _thisMonthUsage.add(usage);

    // Reset consecutive rate limit hits on successful request
    _rateLimitState.consecutiveRateLimitHits = 0;

    await _saveCreditData();
    notifyListeners();

    return true;
  }

  Future<bool> consumeCredits({
    required int outputTokens,
    required String requestType,
  }) async {
    // Legacy method - redirect to new system for study set operations
    if (requestType.contains('quiz') || requestType.contains('flashcard')) {
      StudySetType type = StudySetType.quiz;
      if (requestType.contains('flashcard') && requestType.contains('quiz')) {
        type = StudySetType.both;
      } else if (requestType.contains('flashcard')) {
        type = StudySetType.flashcards;
      }
      return await _consumeStudySetCredits(
          _getCreditsForStudySetType(type), requestType);
    }

    // For non-study set operations, use old logic
    final now = DateTime.now();
    _updateRateLimit(now);

    if (_rateLimitState.isBlocked) {
      return false;
    }

    await _checkMonthlyRefill();
    final requiredCredits = calculateCreditsRequired(outputTokens);

    if (!isUnlimited && _creditsRemaining < requiredCredits) {
      return false;
    }

    // For unlimited users, don't deduct credits
    if (!isUnlimited) {
      _creditsRemaining -= requiredCredits;
    }

    final usage = CreditUsage(
      timestamp: now,
      creditsUsed: isUnlimited ? 0 : requiredCredits,
      outputTokens: outputTokens,
      requestType: requestType,
    );
    _thisMonthUsage.add(usage);

    _rateLimitState.consecutiveRateLimitHits = 0;
    await _saveCreditData();
    notifyListeners();
    return true;
  }

  int calculateCreditsRequired(int outputTokens) {
    // Base cost: 1 credit + ceil(outputTokens/1500)
    return 1 + (outputTokens / 1500).ceil();
  }

  bool shouldUseFallbackModel() {
    // Use fallback when credits are low and monthly budget is under limit
    return _creditsRemaining < 5 &&
        _getMonthlyBudgetUsed() < CreditLimits.costCapBudget;
  }

  Future<void> handleRateLimitResponse() async {
    _rateLimitState.consecutiveRateLimitHits++;

    if (_rateLimitState.consecutiveRateLimitHits >= 3) {
      // Lock out for 15 minutes after repeated 429s
      _rateLimitState.lockoutUntil = DateTime.now().add(
        Duration(minutes: CreditLimits.rateLimitLockoutMinutes),
      );
    } else if (_rateLimitState.requestsInLastMinute >
        CreditLimits.rateLimitRequestsPerMinute) {
      // Cooldown for 30 seconds if over minute limit
      _rateLimitState.cooldownUntil = DateTime.now().add(
        Duration(seconds: CreditLimits.rateLimitCooldownSeconds),
      );
    }

    await _saveCreditData();
    notifyListeners();
  }

  void _updateRateLimit(DateTime now) {
    final lastRequest = _rateLimitState.lastRequestTime;

    // Reset per-second counter if more than a second has passed
    if (now.difference(lastRequest).inSeconds >= 1) {
      _rateLimitState.requestsInLastSecond = 0;
    }

    // Reset per-minute counter if more than a minute has passed
    if (now.difference(lastRequest).inMinutes >= 1) {
      _rateLimitState.requestsInLastMinute = 0;
    }

    // Increment counters
    _rateLimitState.requestsInLastSecond++;
    _rateLimitState.requestsInLastMinute++;
    _rateLimitState.lastRequestTime = now;

    // Check if we've exceeded limits
    if (_rateLimitState.requestsInLastMinute >
        CreditLimits.rateLimitLockoutThreshold) {
      _rateLimitState.lockoutUntil = DateTime.now().add(
        Duration(minutes: CreditLimits.rateLimitLockoutMinutes),
      );
    } else if (_rateLimitState.requestsInLastMinute >
        CreditLimits.rateLimitRequestsPerMinute) {
      _rateLimitState.cooldownUntil = DateTime.now().add(
        Duration(seconds: CreditLimits.rateLimitCooldownSeconds),
      );
    }
  }

  Future<void> _checkMonthlyRefill() async {
    final now = DateTime.now();

    // Check if it's a new month since last refill
    if (_shouldRefillThisMonth()) {
      await _refillCredits();
    }
  }

  bool _shouldRefillThisMonth() {
    final now = DateTime.now();
    final lastRefill = _lastRefill;

    // Check if it's a new month
    return now.month != lastRefill.month || now.year != lastRefill.year;
  }

  Future<void> _refillCredits() async {
    if (isUnlimited) {
      _creditsRemaining = _monthlyQuota; // Unlimited
    } else {
      _creditsRemaining = _monthlyQuota;
    }
    _lastRefill = DateTime.now();
    _thisMonthUsage.clear();

    // Reset rate limiting on monthly refill
    _rateLimitState = RateLimitState();

    // Update entitlements monthly reset
    final authService = AuthService.instance;
    if (authService.isAuthenticated && authService.currentUser != null) {
      // The EntitlementService handles its own monthly reset
      // We just need to sync our local state
    }

    await _saveCreditData();

    if (kDebugMode) {
      print('Credits refilled: $_creditsRemaining/$_monthlyQuota');
    }
  }

  int _getThisMonthUsage() {
    final now = DateTime.now();
    return _thisMonthUsage
        .where((usage) =>
            usage.timestamp.month == now.month &&
            usage.timestamp.year == now.year)
        .fold(0, (sum, usage) => sum + usage.creditsUsed);
  }

  double _getMonthlyBudgetUsed() {
    // Simplified budget calculation
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final monthUsage =
        _thisMonthUsage.where((usage) => usage.timestamp.isAfter(monthStart));

    // Estimate cost based on usage (simplified)
    return monthUsage.length * 0.01; // $0.01 per request estimate
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkMonthlyRefill();

      // Clear expired rate limits
      final now = DateTime.now();
      if (_rateLimitState.cooldownUntil != null &&
          now.isAfter(_rateLimitState.cooldownUntil!)) {
        _rateLimitState.cooldownUntil = null;
        notifyListeners();
      }
      if (_rateLimitState.lockoutUntil != null &&
          now.isAfter(_rateLimitState.lockoutUntil!)) {
        _rateLimitState.lockoutUntil = null;
        notifyListeners();
      }
    });
  }

  Future<void> _saveCreditData() async {
    final data = {
      'currentPlan': _currentPlan.name,
      'creditsRemaining': _creditsRemaining,
      'monthlyQuota': _monthlyQuota,
      'lastRefill': _lastRefill.toIso8601String(),
      'thisMonthUsage': _thisMonthUsage.map((u) => u.toJson()).toList(),
      'rateLimitState': _rateLimitState.toJson(),
      'lastQuizCount': _lastQuizCount,
      'lastFlashcardCount': _lastFlashcardCount,
    };

    await EnhancedStorageService.instance.saveCreditData(data);
  }

  Future<void> _loadCreditData() async {
    try {
      final data = await EnhancedStorageService.instance.getCreditData();
      if (data != null) {
        _currentPlan = SubscriptionPlan.values.firstWhere(
          (plan) => plan.name == data['currentPlan'],
          orElse: () => SubscriptionPlan.free,
        );
        _creditsRemaining =
            data['creditsRemaining'] ?? CreditLimits.freeMonthlyQuota;
        _monthlyQuota = data['monthlyQuota'] ?? CreditLimits.freeMonthlyQuota;
        _lastRefill = DateTime.parse(data['lastRefill']);
        _lastQuizCount = data['lastQuizCount'] ?? 10;
        _lastFlashcardCount = data['lastFlashcardCount'] ?? 15;

        if (data['thisMonthUsage'] != null) {
          _thisMonthUsage = (data['thisMonthUsage'] as List)
              .map((u) => CreditUsage.fromJson(u))
              .toList();
        } else if (data['todaysUsage'] != null) {
          // Migration from old daily system
          _thisMonthUsage = (data['todaysUsage'] as List)
              .map((u) => CreditUsage.fromJson(u))
              .toList();
        }

        if (data['rateLimitState'] != null) {
          _rateLimitState = RateLimitState.fromJson(data['rateLimitState']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading credit data: $e');
      }
      // Reset to defaults on error
      await _resetToDefaults();
    }
  }

  Future<void> _resetToDefaults() async {
    _currentPlan = SubscriptionPlan.free;
    _creditsRemaining = CreditLimits.freeMonthlyQuota;
    _monthlyQuota = CreditLimits.freeMonthlyQuota;
    _lastRefill = DateTime.now();
    _lastQuizCount = 10;
    _lastFlashcardCount = 15;
    _thisMonthUsage.clear();
    _rateLimitState = RateLimitState();
    await _saveCreditData();
  }

  /// Add credits to the account (for testing or admin functions)
  Future<void> addCredits(int amount) async {
    if (amount > 0) {
      _creditsRemaining += amount;
      await _saveCreditData();
      notifyListeners();
      if (kDebugMode) {
        print('Added $amount credits. New balance: $_creditsRemaining');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
