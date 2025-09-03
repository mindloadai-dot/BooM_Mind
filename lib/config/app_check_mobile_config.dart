import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Mobile-specific App Check configuration for iOS and Android
class AppCheckMobileConfig {
  static bool _isInitialized = false;

  /// Initialize App Check for mobile platforms
  static Future<void> initializeForMobile() async {
    if (_isInitialized) {
      debugPrint('📱 App Check already initialized for mobile');
      return;
    }

    try {
      debugPrint('📱 Initializing App Check for mobile...');

      if (kDebugMode) {
        // For development on mobile devices
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        debugPrint('✅ App Check initialized in debug mode for mobile');
      } else {
        // For production mobile apps
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );
        debugPrint('✅ App Check initialized in production mode for mobile');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ App Check initialization failed (non-critical): $e');
      // App Check failure is non-critical - functions will still work
      _isInitialized = true; // Mark as initialized to prevent retries
    }
  }

  /// Check if App Check is working
  static Future<AppCheckStatus> checkStatus() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();

      return AppCheckStatus(
        isWorking: token != null,
        hasToken: token != null,
        message: token != null
            ? 'App Check working correctly'
            : 'App Check token not available',
        isRequired: false, // Not required for app functionality
      );
    } catch (e) {
      return AppCheckStatus(
        isWorking: false,
        hasToken: false,
        message: 'App Check error: ${e.toString()}',
        isRequired: false,
        error: e.toString(),
      );
    }
  }

  /// Get mobile-specific App Check recommendations
  static Map<String, dynamic> getMobileRecommendations() {
    return {
      'title': 'App Check Status (Security Feature)',
      'description':
          'App Check provides additional security but is not required for app functionality.',
      'status': {
        'required': false,
        'impact': 'None - app works without it',
        'benefit': 'Additional security for Firebase Functions',
      },
      'recommendations': [
        'App Check warnings can be safely ignored in development',
        'All Firebase Functions work normally without App Check',
        'Production apps can enable App Check for enhanced security',
        'No user action required - app functions normally',
      ],
    };
  }

  /// Disable App Check warnings for development
  static Future<void> disableForDevelopment() async {
    try {
      if (kDebugMode) {
        debugPrint('📱 Disabling App Check warnings for mobile development');
        // This is handled automatically by the debug provider
      }
    } catch (e) {
      debugPrint('⚠️ Could not disable App Check warnings: $e');
    }
  }
}

/// App Check Status Result
class AppCheckStatus {
  final bool isWorking;
  final bool hasToken;
  final String message;
  final bool isRequired;
  final String? error;

  AppCheckStatus({
    required this.isWorking,
    required this.hasToken,
    required this.message,
    required this.isRequired,
    this.error,
  });

  /// Get user-friendly status
  String get userFriendlyStatus {
    if (isWorking) {
      return '✅ Security: Enhanced protection active';
    } else if (!isRequired) {
      return '⚠️ Security: Basic protection (app works normally)';
    } else {
      return '❌ Security: Issue detected';
    }
  }

  /// Get technical details
  Map<String, dynamic> get details => {
        'working': isWorking,
        'hasToken': hasToken,
        'message': message,
        'required': isRequired,
        'error': error,
      };
}
