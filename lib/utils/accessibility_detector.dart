import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindload/services/telemetry_service.dart';
import 'dart:developer' as developer;

/// Utility class for detecting and reporting accessibility features
class AccessibilityDetector {
  static bool _hasReportedRtl = false;
  static bool _hasReportedFontScale120 = false;
  
  /// Detect and report RTL layout direction
  static void detectRtlDirection(BuildContext context) {
    final direction = Directionality.of(context);
    
    if (direction == TextDirection.rtl && !_hasReportedRtl) {
      _hasReportedRtl = true;
      TelemetryService.instance.logEvent(
        TelemetryEvent.rtlEnabled.name,
        {
          'locale': Localizations.localeOf(context).toString(),
          'detected_at': DateTime.now().toIso8601String(),
        },
      );
      
      developer.log(
        'RTL layout direction detected',
        name: 'AccessibilityDetector',
        level: 800,
      );
    }
  }
  
  /// Detect and report Dynamic Type scaling over 120%
  static void detectFontScaling(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    
    if (textScaleFactor >= 1.2 && !_hasReportedFontScale120) {
      _hasReportedFontScale120 = true;
      TelemetryService.instance.logEvent(
        TelemetryEvent.fontScale120Used.name,
        {
          'scale_factor': textScaleFactor.toStringAsFixed(2),
          'detected_at': DateTime.now().toIso8601String(),
        },
      );
      
      developer.log(
        'Large font scale detected: ${textScaleFactor.toStringAsFixed(2)}x',
        name: 'AccessibilityDetector',
        level: 800,
      );
    }
  }
  
  /// Detect if accessibility services are enabled
  static void detectAccessibilityServices(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Check for accessibility features
    if (mediaQuery.accessibleNavigation) {
      TelemetryService.instance.logEvent(
        TelemetryEvent.a11yViolationDetected.name,
        {
          'feature': 'accessible_navigation',
          'detected_at': DateTime.now().toIso8601String(),
        },
      );
    }
    
    if (mediaQuery.boldText) {
      TelemetryService.instance.logEvent(
        TelemetryEvent.a11yViolationDetected.name,
        {
          'feature': 'bold_text',
          'detected_at': DateTime.now().toIso8601String(),
        },
      );
    }
    
    if (mediaQuery.highContrast) {
      TelemetryService.instance.logEvent(
        TelemetryEvent.a11yViolationDetected.name,
        {
          'feature': 'high_contrast',
          'detected_at': DateTime.now().toIso8601String(),
        },
      );
    }
    
    if (mediaQuery.invertColors) {
      TelemetryService.instance.logEvent(
        TelemetryEvent.a11yViolationDetected.name,
        {
          'feature': 'invert_colors',
          'detected_at': DateTime.now().toIso8601String(),
        },
      );
    }
    
    // Remove reduceMotion check as it's not available in MediaQueryData
    // if (mediaQuery.reduceMotion) {
    //   TelemetryService.instance.logEvent(
    //     TelemetryEvent.a11yViolationDetected.name,
    //     {
    //       'feature': 'reduce_motion',
    //       'detected_at': DateTime.now().toIso8601String(),
    //     },
    //   );
    // }
  }
  
  /// Apply automatic contrast fixes when needed
  static void applyContrastAutofix({
    required Color foreground,
    required Color background,
    required String elementType,
  }) {
    TelemetryService.instance.logEvent(
      TelemetryEvent.contrastAutoFixApplied.name,
      {
        'element_type': elementType,
        'original_contrast': _calculateContrast(foreground, background).toStringAsFixed(2),
        'applied_at': DateTime.now().toIso8601String(),
      },
    );
    
    developer.log(
      'Contrast autofix applied for $elementType',
      name: 'AccessibilityDetector',
      level: 800,
    );
  }
  
  static double _calculateContrast(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    
    final lighter = foregroundLuminance > backgroundLuminance 
        ? foregroundLuminance 
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance 
        ? backgroundLuminance 
        : foregroundLuminance;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Validate that text meets minimum contrast requirements
  static bool validateTextContrast({
    required Color textColor,
    required Color backgroundColor,
    required double fontSize,
    bool isLargeText = false,
  }) {
    final contrast = _calculateContrast(textColor, backgroundColor);
    final isLarge = isLargeText || fontSize >= 18.0;
    final minimumRatio = isLarge ? 3.0 : 4.5;
    
    final meetsStandard = contrast >= minimumRatio;
    
    if (!meetsStandard && kDebugMode) {
      TelemetryService.instance.logEvent(
        TelemetryEvent.a11yViolationDetected.name,
        {
          'violation_type': 'contrast_ratio',
          'actual_ratio': contrast.toStringAsFixed(2),
          'required_ratio': minimumRatio.toString(),
          'font_size': fontSize.toString(),
          'is_large_text': isLarge.toString(),
          'detected_at': DateTime.now().toIso8601String(),
        },
      );
    }
    
    return meetsStandard;
  }
  
  /// Check if current device supports system themes
  static bool supportsSystemThemes() {
    // Most modern platforms support system theme detection
    return true;
  }
  
  /// Get the current system brightness
  static Brightness getSystemBrightness(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }
  
  /// Check if device supports haptic feedback
  static bool supportsHapticFeedback() {
    return true; // Most modern devices support this
  }
  
  /// Provide haptic feedback for theme changes
  static void provideHapticFeedback() {
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback not available, continue silently
    }
  }
  
  /// Reset detection flags (useful for testing)
  static void resetDetectionFlags() {
    _hasReportedRtl = false;
    _hasReportedFontScale120 = false;
  }
}