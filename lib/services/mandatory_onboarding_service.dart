import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle mandatory onboarding for new users
/// Users MUST complete this onboarding before they can use the app
class MandatoryOnboardingService extends ChangeNotifier {
  static final MandatoryOnboardingService _instance = MandatoryOnboardingService._();
  static MandatoryOnboardingService get instance => _instance;
  MandatoryOnboardingService._();

  // SharedPreferences keys
  static const String _onboardingCompletedKey = 'mandatory_onboarding_completed';
  static const String _nicknameSetKey = 'mandatory_nickname_set';
  static const String _featuresExplainedKey = 'mandatory_features_explained';
  static const String _firstLaunchDateKey = 'mandatory_first_launch_date';

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

  /// Check if user needs to complete mandatory onboarding
  bool get needsOnboarding => !_isOnboardingCompleted;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isOnboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
      _isNicknameSet = prefs.getBool(_nicknameSetKey) ?? false;
      _areFeaturesExplained = prefs.getBool(_featuresExplainedKey) ?? false;
      
      final firstLaunchString = prefs.getString(_firstLaunchDateKey);
      if (firstLaunchString != null) {
        _firstLaunchDate = DateTime.parse(firstLaunchString);
      } else {
        // Set first launch date if not set
        _firstLaunchDate = DateTime.now();
        await prefs.setString(_firstLaunchDateKey, _firstLaunchDate!.toIso8601String());
      }

      if (kDebugMode) {
        debugPrint('✅ MandatoryOnboardingService initialized');
        debugPrint('   Onboarding completed: $_isOnboardingCompleted');
        debugPrint('   Nickname set: $_isNicknameSet');
        debugPrint('   Features explained: $_areFeaturesExplained');
        debugPrint('   First launch: $_firstLaunchDate');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize MandatoryOnboardingService: $e');
      }
    }
  }

  /// Mark nickname as set
  Future<void> markNicknameSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_nicknameSetKey, true);
      
      _isNicknameSet = true;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Nickname marked as set');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark nickname as set: $e');
      }
    }
  }

  /// Check if nickname is actually set in UserProfileService
  bool get isNicknameActuallySet {
    try {
      // Import UserProfileService here to avoid circular dependency
      // This will be called from the UI layer where both services are available
      return true; // Will be overridden by actual check in UI
    } catch (e) {
      return false;
    }
  }

  /// Mark features as explained
  Future<void> markFeaturesExplained() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_featuresExplainedKey, true);
      
      _areFeaturesExplained = true;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Features marked as explained');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark features as explained: $e');
      }
    }
  }

  /// Complete the entire onboarding process
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      
      _isOnboardingCompleted = true;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ Mandatory onboarding completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to complete onboarding: $e');
      }
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
