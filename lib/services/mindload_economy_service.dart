import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/mindload_economy_models.dart';
import 'package:mindload/services/storage_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/services/firebase_client_service.dart';

/// Global Credits Economy Service
/// Enforces all tier limits, budgets, and constraints uniformly across the app
class MindloadEconomyService extends ChangeNotifier {
  static final MindloadEconomyService _instance =
      MindloadEconomyService._internal();
  static MindloadEconomyService get instance => _instance;
  MindloadEconomyService._internal();

  MindloadUserEconomy? _userEconomy;
  MindloadBudgetController _budgetController = MindloadBudgetController(
    monthlySpent: 0.0,
    state: BudgetState.normal,
    lastReset: DateTime.now(),
    nextResetDate: _calculateNextResetDate(DateTime.now()),
  );

  bool _isInitialized = false;
  Timer? _refreshTimer;

  // Getters
  MindloadUserEconomy? get userEconomy => _userEconomy;
  MindloadBudgetController get budgetController => _budgetController;
  bool get isInitialized => _isInitialized;

  // User state getters
  MindloadTier get currentTier => _userEconomy?.tier ?? MindloadTier.free;
  int get creditsRemaining => _userEconomy?.creditsRemaining ?? 0;
  int get exportsRemaining => _userEconomy?.exportsRemaining ?? 0;
  bool get hasCredits => creditsRemaining > 0;
  bool get hasExports => exportsRemaining > 0;
  bool get isPaidUser => currentTier != MindloadTier.free;

  // Warning thresholds
  static const int warnThreshold = 2;
  bool get isLowCredits =>
      creditsRemaining <= warnThreshold && creditsRemaining > 0;
  bool get isEmptyCredits => creditsRemaining == 0;

  // Budget state getters
  BudgetState get budgetState => _budgetController.state;
  bool get canGenerate => _budgetController.canGenerate();
  bool get isInSavingsMode => budgetState == BudgetState.savingsMode;
  bool get isPaused => budgetState == BudgetState.paused;

  /// Initialize the economy service
  Future<void> initialize() async {
    try {
      await _loadUserEconomy();
      await _loadBudgetController();
      await _checkMonthlyResets();

      _startRefreshTimer();
      _isInitialized = true;
      notifyListeners();

      if (kDebugMode) {
        print(
            'Economy initialized: ${currentTier.displayName}, $creditsRemaining credits');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing economy: $e');
      }
      _isInitialized = true; // Use defaults
    }
  }

  /// Update user's subscription tier
  Future<void> updateUserTier(MindloadTier newTier,
      {DateTime? expiryDate}) async {
    if (_userEconomy == null) return;

    final now = DateTime.now();
    final newQuota = MindloadEconomyConfig.monthlyCredits[newTier]!;
    final newExportQuota = MindloadEconomyConfig.monthlyExportLimits[newTier]!;

    // Calculate new credits (immediate effect)
    int newCredits = newQuota;
    if (newTier != MindloadTier.free && _userEconomy!.hasRollover) {
      newCredits += _userEconomy!.rolloverCredits;
    }

    _userEconomy = _userEconomy!.copyWith(
      tier: newTier,
      creditsRemaining: newCredits,
      exportsRemaining: newExportQuota,
      subscriptionExpiry: expiryDate,
      isActive: true,
    );

    await _saveUserEconomy();
    notifyListeners();

    if (kDebugMode) {
      print('Tier updated to ${newTier.displayName}: $newCredits credits');
    }
  }

  /// ENFORCEMENT: Check if user can generate content
  EnforcementResult canGenerateContent(GenerationRequest request) {
    try {
      // Ensure we have a working state
      if (_userEconomy == null) {
        print('⚠️ User economy not loaded, creating default state');
        _userEconomy = MindloadUserEconomy.createDefault('fallback');
      }

      // Check budget controller first
      if (!canGenerate) {
        print(
            '⚠️ Budget controller blocking generation: ${_budgetController.statusMessage}');
        return EnforcementResult.block(
          reason: _budgetController.statusMessage,
          actions: ['Try next cycle'],
        );
      }

      // Check credits - be more lenient for free tier
      int creditsNeeded =
          request.isRecreate && request.lastAttemptFailed ? 0 : 1;
      if (creditsNeeded > 0 && _userEconomy!.creditsRemaining < creditsNeeded) {
        // For free tier, allow some generation even without credits
        if (currentTier == MindloadTier.free &&
            _userEconomy!.creditsRemaining == 0) {
          print(
              '🆓 Free tier user with no credits - allowing limited generation');
          return EnforcementResult
              .allow(); // Allow limited generation for free users
        }

        print(
            '❌ Insufficient credits: need $creditsNeeded, have ${_userEconomy!.creditsRemaining}');
        return EnforcementResult.block(
          reason:
              'Insufficient credits (need $creditsNeeded, have ${_userEconomy!.creditsRemaining})',
          actions: _getOutOfCreditsActions(),
          showBuyCredits: true,
          showUpgrade: !isPaidUser,
        );
      }

      // Check paste cap - be more lenient
      final pasteLimit = _userEconomy!.getPasteCharLimit(budgetState);
      if (request.sourceCharCount > pasteLimit) {
        // For small overages, allow with warning (now 5% since we have 100k limit)
        if (request.sourceCharCount <= pasteLimit * 1.05) {
          // Allow 5% overage
          print(
              '⚠️ Text slightly over limit (${request.sourceCharCount} > $pasteLimit), allowing with warning');
          return EnforcementResult.allow(); // Allow with warning
        }

        final autoSplitCredits =
            calculateAutoSplitCredits(request.sourceCharCount);
        final actions = <String>[
          'Trim text',
          if (canAffordAutoSplit(request.sourceCharCount))
            'Auto-Split ($autoSplitCredits credits)'
          else
            'Buy Credits',
          'Upgrade tier',
        ];

        print('❌ Text too long: ${request.sourceCharCount} > $pasteLimit');
        return EnforcementResult.block(
          reason:
              'Text too long (${_formatCharCount(request.sourceCharCount)} chars, limit ${_formatCharCount(pasteLimit)})',
          actions: actions,
          showUpgrade: true,
          showBuyCredits: !canAffordAutoSplit(request.sourceCharCount),
        );
      }

      // Check PDF page cap - be more lenient
      if (request.pdfPageCount != null) {
        final pdfLimit = _userEconomy!.pdfPageLimit;
        if (request.pdfPageCount! > pdfLimit) {
          // For small overages, allow with warning
          if (request.pdfPageCount! <= pdfLimit + 2) {
            // Allow 2 pages overage
            print(
                '⚠️ PDF slightly over limit ($pdfLimit + 2), allowing with warning');
            return EnforcementResult.allow(); // Allow with warning
          }

          print('❌ PDF too large: ${request.pdfPageCount} > $pdfLimit');
          return EnforcementResult.block(
            reason:
                'PDF too large (${request.pdfPageCount} pages, limit $pdfLimit)',
            actions: ['Split PDF', 'Extract key pages', 'Upgrade tier'],
            showUpgrade: true,
          );
        }
      }

      // Check active set limit (for new sets) - be more lenient
      if (!request.isRecreate &&
          _userEconomy!.activeSetCount >= _userEconomy!.activeSetLimit) {
        // Allow some overage for active users
        if (_userEconomy!.activeSetCount <= _userEconomy!.activeSetLimit + 1) {
          print('⚠️ Active set limit reached but allowing +1 overage');
          return EnforcementResult.allow(); // Allow +1 overage
        }

        print(
            '❌ Too many active sets: ${_userEconomy!.activeSetCount}/${_userEconomy!.activeSetLimit}');
        return EnforcementResult.block(
          reason:
              'Too many active sets (${_userEconomy!.activeSetCount}/${_userEconomy!.activeSetLimit})',
          actions: ['Archive sets', 'Upgrade tier'],
          showUpgrade: true,
        );
      }

      print('✅ Content generation allowed');
      return EnforcementResult.allow();
    } catch (e) {
      print('❌ Error in canGenerateContent: $e');
      // In case of error, allow generation to prevent blocking the app
      return EnforcementResult.allow();
    }
  }

  /// ENFORCEMENT: Check if user can export content
  EnforcementResult canExportContent(ExportRequest request) {
    if (_userEconomy == null) {
      return EnforcementResult.block(reason: 'User not initialized');
    }

    // Check export quota
    if (_userEconomy!.exportsRemaining <= 0) {
      return EnforcementResult.block(
        reason:
            'No exports remaining (${_userEconomy!.exportsRemaining}/${_userEconomy!.monthlyExports})',
        actions: _getOutOfExportsActions(),
        showUpgrade: true,
      );
    }

    return EnforcementResult.allow();
  }

  /// ENFORCEMENT: Check if user can ingest YouTube videos
  EnforcementResult canIngestYouTube(String videoId, {int? estimatedDuration}) {
    if (_userEconomy == null) {
      return EnforcementResult.block(reason: 'User not initialized');
    }

    // Check if user has YouTube access
    final tierConfig = MindloadEconomyConfig.tierConfigs[_userEconomy!.tier];
    if (tierConfig == null || tierConfig.monthlyYoutubeIngests <= 0) {
      return EnforcementResult.block(
        reason: 'YouTube video processing not available on your plan',
        actions: ['Upgrade to Axon Monthly or higher'],
        showUpgrade: true,
      );
    }

    // Check monthly YouTube ingest limit (this would need to be tracked separately)
    // For now, we'll assume the user can ingest if they have access
    // TODO: Implement monthly YouTube ingest tracking

    // Check video duration limits based on tier
    if (estimatedDuration != null) {
      final maxDuration = _getMaxVideoDurationForTier(_userEconomy!.tier);
      if (estimatedDuration > maxDuration) {
        return EnforcementResult.block(
          reason:
              'Video too long (${_formatDuration(estimatedDuration)}, max ${_formatDuration(maxDuration)})',
          actions: ['Choose shorter video', 'Upgrade plan for longer videos'],
          showUpgrade: true,
        );
      }
    }

    return EnforcementResult.allow();
  }

  /// Use credits for generation (after validation)
  Future<bool> useCreditsForGeneration(GenerationRequest request) async {
    final enforcement = canGenerateContent(request);
    if (!enforcement.canProceed) return false;

    // Free retry if last attempt failed
    int creditsToUse = request.isRecreate && request.lastAttemptFailed ? 0 : 1;

    if (creditsToUse > 0 && _userEconomy != null) {
      _userEconomy = _userEconomy!.copyWith(
        creditsRemaining: _userEconomy!.creditsRemaining - creditsToUse,
        creditsUsedThisMonth: _userEconomy!.creditsUsedThisMonth + creditsToUse,
      );

      // Increment active set count for new sets
      if (!request.isRecreate) {
        _userEconomy = _userEconomy!.copyWith(
          activeSetCount: _userEconomy!.activeSetCount + 1,
        );
      }

      await _saveUserEconomy();
      notifyListeners();

      if (kDebugMode) {
        print(
            'Used $creditsToUse credits, ${_userEconomy!.creditsRemaining} remaining');
      }
    }

    return true;
  }

  /// Use export quota
  Future<bool> useExport(ExportRequest request) async {
    final enforcement = canExportContent(request);
    if (!enforcement.canProceed || _userEconomy == null) return false;

    _userEconomy = _userEconomy!.copyWith(
      exportsRemaining: _userEconomy!.exportsRemaining - 1,
      exportsUsedThisMonth: _userEconomy!.exportsUsedThisMonth + 1,
    );

    await _saveUserEconomy();
    notifyListeners();

    if (kDebugMode) {
      print('Used 1 export, ${_userEconomy!.exportsRemaining} remaining');
    }

    return true;
  }

  /// Use YouTube ingest (after validation)
  Future<bool> useYouTubeIngest(String videoId,
      {int? estimatedDuration}) async {
    final enforcement =
        canIngestYouTube(videoId, estimatedDuration: estimatedDuration);
    if (!enforcement.canProceed) return false;

    // TODO: Implement YouTube ingest tracking
    // This would involve:
    // 1. Recording the ingest in Firestore
    // 2. Updating monthly counts
    // 3. Syncing with the server

    if (kDebugMode) {
      print('YouTube ingest consumed for video: $videoId');
    }

    return true;
  }

  /// Record budget usage (from actual OpenAI costs)
  Future<void> recordBudgetUsage(double costUsd) async {
    final newSpent = _budgetController.monthlySpent + costUsd;
    final newState = _calculateBudgetState(newSpent);

    _budgetController = _budgetController.copyWith(
      monthlySpent: newSpent,
      state: newState,
      useEfficientModel: newState == BudgetState.savingsMode,
    );

    await _saveBudgetController();
    notifyListeners();

    if (kDebugMode) {
      print(
          'Budget usage: \$${newSpent.toStringAsFixed(2)}/\$${_budgetController.monthlyLimit}, state: ${newState.name}');
    }
  }

  /// Archive a study set (reduces active count)
  Future<void> archiveStudySet(String setId) async {
    if (_userEconomy != null && _userEconomy!.activeSetCount > 0) {
      _userEconomy = _userEconomy!.copyWith(
        activeSetCount: _userEconomy!.activeSetCount - 1,
      );

      await _saveUserEconomy();
      notifyListeners();
    }
  }

  /// Get output counts based on current tier and budget state
  Map<String, int> getOutputCounts() {
    if (_userEconomy == null) {
      return {'flashcards': 50, 'quiz': 30}; // Default
    }

    return {
      'flashcards': _userEconomy!.getFlashcardsPerCredit(budgetState),
      'quiz': _userEconomy!.getQuizPerCredit(budgetState),
    };
  }

  /// Get current limits summary
  Map<String, dynamic> getCurrentLimits() {
    if (_userEconomy == null) {
      return {};
    }

    return {
      'tier': currentTier.displayName,
      'creditsRemaining': _userEconomy!.creditsRemaining,
      'monthlyQuota': _userEconomy!.monthlyQuota,
      'exportsRemaining': _userEconomy!.exportsRemaining,
      'monthlyExports': _userEconomy!.monthlyExports,
      'pasteCharLimit': _userEconomy!.getPasteCharLimit(budgetState),
      'pdfPageLimit': _userEconomy!.pdfPageLimit,
      'activeSetCount': _userEconomy!.activeSetCount,
      'activeSetLimit': _userEconomy!.activeSetLimit,
      'queuePriority': _userEconomy!.queuePriority.name,
      'budgetState': budgetState.name,
      'outputCounts': getOutputCounts(),
    };
  }

  /// Get upgrade options for current tier
  List<TierUpgradeInfo> getUpgradeOptions() {
    return TierUpgradeInfo.getUpgradeOptions(currentTier);
  }

  /// Calculate credits needed for auto-split based on content size
  int calculateAutoSplitCredits(int totalCharCount) {
    final pasteLimit = _userEconomy?.getPasteCharLimit(budgetState) ?? 100000;
    if (totalCharCount <= pasteLimit) return 0;

    // Calculate how many chunks we need
    final chunks = (totalCharCount / pasteLimit).ceil();
    return chunks; // 1 credit per chunk
  }

  /// Check if user can afford auto-split
  bool canAffordAutoSplit(int totalCharCount) {
    final creditsNeeded = calculateAutoSplitCredits(totalCharCount);
    return creditsRemaining >= creditsNeeded;
  }

  // Helper methods
  List<String> _getOutOfCreditsActions() {
    final actions = <String>['Buy Credits'];
    if (!isPaidUser) {
      actions.add('Upgrade');
    }
    actions.addAll(['Try next cycle', 'Archive sets']);
    return actions;
  }

  String _formatCharCount(int charCount) {
    if (charCount >= 1000) {
      return '${(charCount / 1000).toStringAsFixed(1)}k';
    }
    return charCount.toString();
  }

  List<String> _getOutOfExportsActions() {
    final actions = <String>[];
    if (!isPaidUser) {
      actions.add('Upgrade');
    }
    actions.addAll(['Try next cycle']);
    return actions;
  }

  BudgetState _calculateBudgetState(double spent) {
    final percentage = spent / _budgetController.monthlyLimit;
    if (percentage >= MindloadEconomyConfig.pausedThreshold) {
      return BudgetState.paused;
    } else if (percentage >= MindloadEconomyConfig.savingsModeThreshold) {
      return BudgetState.savingsMode;
    }
    return BudgetState.normal;
  }

  Future<void> _checkMonthlyResets() async {
    final now = DateTime.now();

    // Check user economy reset
    if (_userEconomy != null && now.isAfter(_userEconomy!.nextResetDate)) {
      await _resetUserEconomy();
    }

    // Check budget controller reset
    if (now.isAfter(_budgetController.nextResetDate)) {
      await _resetBudgetController();
    }
  }

  Future<void> _resetUserEconomy() async {
    if (_userEconomy == null) return;

    final now = DateTime.now();
    final newQuota = MindloadEconomyConfig.monthlyCredits[_userEconomy!.tier]!;
    final newExportQuota =
        MindloadEconomyConfig.monthlyExportLimits[_userEconomy!.tier]!;

    // Calculate rollover for paid tiers
    int rolloverToAdd = 0;
    if (_userEconomy!.hasRollover && _userEconomy!.creditsRemaining > 0) {
      rolloverToAdd =
          _userEconomy!.creditsRemaining.clamp(0, _userEconomy!.rolloverLimit);
    }

    _userEconomy = _userEconomy!.copyWith(
      creditsRemaining: newQuota + rolloverToAdd,
      creditsUsedThisMonth: 0,
      rolloverCredits: rolloverToAdd,
      exportsRemaining: newExportQuota,
      exportsUsedThisMonth: 0,
      lastCreditRefill: now,
      nextResetDate: _calculateNextResetDate(now),
    );

    await _saveUserEconomy();
    notifyListeners();

    if (kDebugMode) {
      print(
          'User economy reset: ${newQuota + rolloverToAdd} credits ($rolloverToAdd rolled over)');
    }
  }

  Future<void> _resetBudgetController() async {
    final now = DateTime.now();
    _budgetController = MindloadBudgetController(
      monthlySpent: 0.0,
      state: BudgetState.normal,
      lastReset: now,
      nextResetDate: _calculateNextResetDate(now),
    );

    await _saveBudgetController();
    notifyListeners();

    if (kDebugMode) {
      print('Budget controller reset');
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkMonthlyResets();
    });
  }

  static DateTime _calculateNextResetDate(DateTime current) {
    // Reset on 1st of next month at 00:00 America/Chicago (UTC-6/UTC-5)
    var nextMonth = DateTime(current.year, current.month + 1, 1);
    return nextMonth.toUtc().add(const Duration(hours: 6));
  }

  // Persistence
  Future<void> _loadUserEconomy() async {
    try {
      final authService = AuthService.instance;
      if (!authService.isAuthenticated) {
        // Create default for anonymous user
        _userEconomy = MindloadUserEconomy.createDefault('anonymous');
        return;
      }

      final userId = authService.currentUser!.uid;
      final data = await StorageService.instance.getUserEconomyData(userId);

      if (data != null) {
        _userEconomy = MindloadUserEconomy.fromJson(data);
      } else {
        // Create default for new user
        _userEconomy = MindloadUserEconomy.createDefault(userId);
        await _saveUserEconomy();
      }

      // Sync with Firestore if authenticated
      await _syncWithFirestore();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user economy: $e');
      }
      // Use default
      _userEconomy = MindloadUserEconomy.createDefault('anonymous');
    }
  }

  Future<void> _saveUserEconomy() async {
    if (_userEconomy == null) return;

    try {
      await StorageService.instance
          .saveUserEconomyData(_userEconomy!.userId, _userEconomy!.toJson());

      // Sync to Firestore if authenticated and Firebase is ready
      final authService = AuthService.instance;
      if (authService.isAuthenticated &&
          FirebaseClientService.instance.isFirebaseConfigured) {
        try {
          await FirestoreRepository.instance.updateUserEconomy(_userEconomy!);
        } catch (firestoreError) {
          if (kDebugMode) {
            print(
                'Firestore sync failed, but local save succeeded: $firestoreError');
          }
          // Continue without Firestore sync - local data is saved
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user economy: $e');
      }
      // Continue without save - app can still function
    }
  }

  Future<void> _loadBudgetController() async {
    try {
      final data = await StorageService.instance.getBudgetControllerData();
      if (data != null) {
        _budgetController = MindloadBudgetController.fromJson(data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading budget controller: $e');
      }
    }
  }

  Future<void> _saveBudgetController() async {
    try {
      await StorageService.instance
          .saveBudgetControllerData(_budgetController.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving budget controller: $e');
      }
    }
  }

  Future<void> _syncWithFirestore() async {
    try {
      final authService = AuthService.instance;
      if (!authService.isAuthenticated || _userEconomy == null) return;

      // Check if Firebase is properly configured and ready
      if (!FirebaseClientService.instance.isFirebaseConfigured) {
        if (kDebugMode) {
          print('Firebase not configured, skipping Firestore sync');
        }
        return;
      }

      // Additional check to ensure Firebase app is initialized
      try {
        await FirestoreRepository.instance.getUserEconomy(_userEconomy!.userId);
      } catch (firebaseError) {
        if (kDebugMode) {
          print('Firebase not ready for Firestore sync: $firebaseError');
        }
        return; // Skip sync if Firebase isn't ready
      }

      final firestoreData = await FirestoreRepository.instance
          .getUserEconomy(_userEconomy!.userId);
      if (firestoreData != null) {
        // Use server data if more recent
        if (firestoreData.lastCreditRefill
            .isAfter(_userEconomy!.lastCreditRefill)) {
          _userEconomy = firestoreData;
          await _saveUserEconomy(); // Save to local
        } else {
          // Push local data to server
          await FirestoreRepository.instance.updateUserEconomy(_userEconomy!);
        }
      } else {
        // Create new server record
        await FirestoreRepository.instance.updateUserEconomy(_userEconomy!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing with Firestore: $e');
      }
      // Continue without Firestore sync - app can still function with local data
    }
  }

  /// Get flashcards per credit for a tier
  int getFlashcardsPerCredit(MindloadTier tier) {
    switch (tier) {
      case MindloadTier.free:
        return 50; // Free tier
      case MindloadTier.axon:
      case MindloadTier.neuron:
        return 70; // Paid tiers
      case MindloadTier.cortex:
      case MindloadTier.singularity:
      case MindloadTier.synapse:
        return 100; // Advanced tiers
    }
  }

  /// Get quiz questions per credit for a tier
  int getQuizPerCredit(MindloadTier tier) {
    switch (tier) {
      case MindloadTier.free:
        return 30; // Free tier
      case MindloadTier.axon:
      case MindloadTier.neuron:
        return 50; // Paid tiers
      case MindloadTier.cortex:
      case MindloadTier.singularity:
      case MindloadTier.synapse:
        return 70; // Advanced tiers
    }
  }

  /// Get maximum video duration for a tier (in minutes)
  int _getMaxVideoDurationForTier(MindloadTier tier) {
    switch (tier) {
      case MindloadTier.free:
        return 0; // No YouTube access
      case MindloadTier.axon:
        return 10; // 10 minutes
      case MindloadTier.neuron:
        return 30; // 30 minutes
      case MindloadTier.cortex:
        return 60; // 1 hour
      case MindloadTier.singularity:
        return 120; // 2 hours
      case MindloadTier.synapse:
        return 45; // Legacy tier: 45 minutes
    }
  }

  /// Format duration in minutes to human-readable string
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes < 120) {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hours';
    } else {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hours';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Extension methods for StorageService
extension MindloadStorageExtension on StorageService {
  Future<Map<String, dynamic>?> getUserEconomyData(String userId) async {
    return await getJsonData('mindload_user_economy_$userId');
  }

  Future<void> saveUserEconomyData(
      String userId, Map<String, dynamic> data) async {
    await saveJsonData('mindload_user_economy_$userId', data);
  }

  Future<Map<String, dynamic>?> getBudgetControllerData() async {
    return await getJsonData('mindload_budget_controller');
  }

  Future<void> saveBudgetControllerData(Map<String, dynamic> data) async {
    await saveJsonData('mindload_budget_controller', data);
  }
}
