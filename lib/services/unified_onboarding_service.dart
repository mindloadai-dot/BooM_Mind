import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_specific_storage_service.dart';
import 'auth_service.dart';

/// Unified Onboarding Service
/// Single service to handle all onboarding needs with reliable persistence
class UnifiedOnboardingService extends ChangeNotifier {
  static final UnifiedOnboardingService _instance =
      UnifiedOnboardingService._internal();
  factory UnifiedOnboardingService() => _instance;
  UnifiedOnboardingService._internal();

  // SharedPreferences keys
  static const String _onboardingCompletedKey = 'unified_onboarding_completed';
  static const String _nicknameSetKey = 'unified_nickname_set';
  static const String _featuresExplainedKey = 'unified_features_explained';
  static const String _firstLaunchDateKey = 'unified_first_launch_date';

  // Onboarding state
  bool _isOnboardingCompleted = false;
  bool _isNicknameSet = false;
  bool _areFeaturesExplained = false;
  DateTime? _firstLaunchDate;

  // Getters
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isNicknameSet => _isNicknameSet;
  bool get areFeaturesExplained => _areFeaturesExplained;
  DateTime? get firstLaunchDate => _firstLaunchDate;

  /// Check if user needs to complete onboarding
  /// Returns true ONLY if onboarding has never been completed
  /// Once completed, this will ALWAYS return false - NO EXCEPTIONS!
  bool get needsOnboarding {
    final shouldShow = !_isOnboardingCompleted;
    if (kDebugMode) {
      debugPrint('🎯 UnifiedOnboardingService.needsOnboarding: $shouldShow');
      debugPrint('   _isOnboardingCompleted: $_isOnboardingCompleted');
      debugPrint('   _isNicknameSet: $_isNicknameSet');
      debugPrint('   _areFeaturesExplained: $_areFeaturesExplained');
    }
    return shouldShow;
  }

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Ensure user-specific storage is initialized
      await UserSpecificStorageService.instance.initialize();

      // Check if user is authenticated - onboarding is user-specific
      if (!AuthService.instance.isAuthenticated) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ UnifiedOnboardingService: No authenticated user, using defaults');
        }
        // Reset to defaults for unauthenticated state
        _isOnboardingCompleted = false;
        _isNicknameSet = false;
        _areFeaturesExplained = false;
        _firstLaunchDate = null;
        notifyListeners();
        return;
      }

      final userStorage = UserSpecificStorageService.instance;

      _isOnboardingCompleted =
          (await userStorage.getBool(_onboardingCompletedKey)) ?? false;
      _isNicknameSet = (await userStorage.getBool(_nicknameSetKey)) ?? false;
      _areFeaturesExplained =
          (await userStorage.getBool(_featuresExplainedKey)) ?? false;

      final firstLaunchString =
          await userStorage.getString(_firstLaunchDateKey);
      if (firstLaunchString != null) {
        _firstLaunchDate = DateTime.parse(firstLaunchString);
      } else {
        // Set first launch date if not set
        _firstLaunchDate = DateTime.now();
        await userStorage.setString(
            _firstLaunchDateKey, _firstLaunchDate!.toIso8601String());
      }

      if (kDebugMode) {
        debugPrint('✅ UnifiedOnboardingService initialized');
        debugPrint('   Onboarding completed: $_isOnboardingCompleted');
        debugPrint('   Nickname set: $_isNicknameSet');
        debugPrint('   Features explained: $_areFeaturesExplained');
        debugPrint('   First launch: $_firstLaunchDate');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize UnifiedOnboardingService: $e');
      }
    }
  }

  /// Mark nickname as set
  Future<void> markNicknameSet() async {
    try {
      final userStorage = UserSpecificStorageService.instance;
      await userStorage.setBool(_nicknameSetKey, true);

      _isNicknameSet = true;
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
            '✅ Nickname marked as set for user: ${AuthService.instance.currentUser?.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark nickname as set: $e');
      }
    }
  }

  /// Mark features as explained
  Future<void> markFeaturesExplained() async {
    try {
      final userStorage = UserSpecificStorageService.instance;
      await userStorage.setBool(_featuresExplainedKey, true);

      _areFeaturesExplained = true;
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
            '✅ Features marked as explained for user: ${AuthService.instance.currentUser?.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark features as explained: $e');
      }
    }
  }

  /// Complete the entire onboarding process
  /// This marks onboarding as PERMANENTLY completed - it will NEVER show again
  Future<void> completeOnboarding() async {
    try {
      final userStorage = UserSpecificStorageService.instance;

      // CRITICAL: Mark onboarding as completed permanently
      await userStorage.setBool(_onboardingCompletedKey, true);
      _isOnboardingCompleted = true;

      // Also ensure all sub-components are marked as complete
      await userStorage.setBool(_nicknameSetKey, true);
      await userStorage.setBool(_featuresExplainedKey, true);
      _isNicknameSet = true;
      _areFeaturesExplained = true;

      // Force save to disk immediately
      await userStorage.reload();

      notifyListeners();

      if (kDebugMode) {
        debugPrint(
            '✅ ONBOARDING PERMANENTLY COMPLETED - WILL NEVER SHOW AGAIN');
        debugPrint('   User: ${AuthService.instance.currentUser?.uid}');
        debugPrint('   _isOnboardingCompleted: $_isOnboardingCompleted');
        debugPrint('   _isNicknameSet: $_isNicknameSet');
        debugPrint('   _areFeaturesExplained: $_areFeaturesExplained');
        debugPrint('   needsOnboarding will now ALWAYS return false');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CRITICAL ERROR: Failed to complete onboarding: $e');
      }
      // Even if there's an error, try to set the flags
      _isOnboardingCompleted = true;
      _isNicknameSet = true;
      _areFeaturesExplained = true;
      notifyListeners();
    }
  }

  /// Check if onboarding can be completed
  bool get canCompleteOnboarding => _isNicknameSet && _areFeaturesExplained;

  /// Reset onboarding (for testing or user request)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
      await prefs.remove(_nicknameSetKey);
      await prefs.remove(_featuresExplainedKey);

      _isOnboardingCompleted = false;
      _isNicknameSet = false;
      _areFeaturesExplained = false;

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Onboarding reset');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to reset onboarding: $e');
      }
    }
  }

  /// Get onboarding progress (0.0 to 1.0)
  double get onboardingProgress {
    int completedSteps = 0;
    int totalSteps = 2; // Nickname + Features

    if (_isNicknameSet) completedSteps++;
    if (_areFeaturesExplained) completedSteps++;

    return completedSteps / totalSteps;
  }

  /// Get onboarding status summary
  Map<String, dynamic> getOnboardingStatus() {
    return {
      'completed': _isOnboardingCompleted,
      'nickname_set': _isNicknameSet,
      'features_explained': _areFeaturesExplained,
      'progress': onboardingProgress,
      'first_launch': _firstLaunchDate?.toIso8601String(),
      'needs_onboarding': needsOnboarding,
      'can_complete': canCompleteOnboarding,
    };
  }
}
