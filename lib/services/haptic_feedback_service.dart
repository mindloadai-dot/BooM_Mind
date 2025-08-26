import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing haptic feedback throughout the application
class HapticFeedbackService {
  static const String _hapticEnabledKey = 'haptic_feedback_enabled';

  static final HapticFeedbackService _instance =
      HapticFeedbackService._internal();
  factory HapticFeedbackService() => _instance;
  HapticFeedbackService._internal();

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  /// Initialize the service and load user preference
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_hapticEnabledKey) ?? true;
    } catch (e) {
      // Default to enabled if there's an error
      _isEnabled = true;
    }
  }

  /// Toggle haptic feedback on/off
  Future<void> toggleHapticFeedback(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticEnabledKey, enabled);
    } catch (e) {
      // Silently fail if we can't save preference
    }
  }

  /// Light haptic feedback for subtle interactions
  void lightImpact() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Medium haptic feedback for standard interactions
  void mediumImpact() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Heavy haptic feedback for important interactions
  void heavyImpact() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Selection haptic feedback for selection changes
  void selectionClick() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Vibration haptic feedback for notifications
  void vibrate() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.vibrate();
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Success haptic feedback for positive actions
  void success() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Error haptic feedback for negative actions
  void error() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }

  /// Warning haptic feedback for caution actions
  void warning() {
    if (!_isEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail if haptic feedback is not available
    }
  }
}
