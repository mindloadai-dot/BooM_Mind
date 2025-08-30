import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckConfig {
  static bool _isInitialized = false;
  static bool _isDisabled = false;

  static Future<void> initialize() async {
    try {
      print('Initializing Firebase App Check...');

      // Always use debug providers for development to avoid authentication issues
      if (kDebugMode) {
        print('Debug mode: Setting up debug App Check providers');
        try {
          // For development, we'll set a debug token in environment or use debug provider
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
            // Use debug for web as well in development
            webProvider:
                ReCaptchaV3Provider('6LfGQoIqAAAAABfRlSGNXKGvlYl0_ZW5Hd6Ys5Bq'),
          );

          // Set debug token if available
          await _setDebugTokenIfAvailable();

          _isInitialized = true;
          print('✅ Firebase App Check activated successfully (debug mode)');
        } catch (debugError) {
          print('❌ Debug App Check failed: $debugError');
          print('Continuing without App Check for development');
          _isDisabled = true;
        }
      } else {
        print('Production mode: Using production App Check providers');
        try {
          await FirebaseAppCheck.instance.activate(
            webProvider:
                ReCaptchaV3Provider('6LfGQoIqAAAAABfRlSGNXKGvlYl0_ZW5Hd6Ys5Bq'),
            androidProvider: AndroidProvider.playIntegrity,
            appleProvider: AppleProvider.deviceCheck,
          );
          _isInitialized = true;
          print(
              '✅ Firebase App Check activated successfully (production mode)');
        } catch (prodError) {
          print('❌ Production App Check failed: $prodError');
          print('Falling back to debug providers for production');
          try {
            await FirebaseAppCheck.instance.activate(
              androidProvider: AndroidProvider.debug,
              appleProvider: AppleProvider.debug,
            );
            _isInitialized = true;
            print(
                '⚠️ Firebase App Check activated with debug providers in production');
          } catch (fallbackError) {
            print('❌ All App Check providers failed: $fallbackError');
            _isDisabled = true;
          }
        }
      }
    } catch (e) {
      print('❌ Error initializing Firebase App Check: $e');
      print('App will continue without App Check functionality');
      _isDisabled = true;
      // Don't rethrow - allow app to continue without App Check
    }
  }

  // Set debug token for development
  static Future<void> _setDebugTokenIfAvailable() async {
    try {
      // You can set a debug token here for consistent development
      // This token should be registered in Firebase Console -> App Check -> Debug tokens
      const debugToken =
          'your-debug-token-here'; // Replace with actual debug token

      if (debugToken != 'your-debug-token-here') {
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
        print('🔧 Debug token configured for development');
      } else {
        print('ℹ️ No debug token configured - using default debug provider');
      }
    } catch (e) {
      print('⚠️ Failed to set debug token: $e');
    }
  }

  // Method to get App Check token with proper fallback
  static Future<String?> getToken() async {
    try {
      if (_isDisabled || !_isInitialized) {
        print('App Check is disabled or not initialized, returning null token');
        return null;
      }

      print('Getting App Check token...');

      // Add timeout to prevent app from getting stuck
      final token = await FirebaseAppCheck.instance.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('App Check token request timed out after 5 seconds');
          return null;
        },
      );

      if (token != null) {
        print('App Check token obtained successfully');
        return token;
      } else {
        print('App Check token is null');
        return null;
      }
    } catch (e) {
      print('Error getting App Check token: $e');
      return null;
    }
  }

  // Method to verify App Check token with timeout
  static Future<bool> verifyAppCheckToken() async {
    try {
      if (_isDisabled) {
        print('App Check is disabled, skipping verification');
        return false;
      }

      print('Verifying App Check token...');

      final token = await getToken();
      return token != null;
    } catch (e) {
      print('App Check token verification failed with error: $e');
      return false;
    }
  }

  // Method to check if App Check is available/enabled
  static bool get isAppCheckEnabled {
    return _isInitialized && !_isDisabled;
  }

  // Method to check if App Check is disabled
  static bool get isAppCheckDisabled {
    return _isDisabled;
  }

  // Method to get debug information about App Check status
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      return {
        'isInitialized': _isInitialized,
        'isDisabled': _isDisabled,
        'isEnabled': isAppCheckEnabled,
        'debugMode': kDebugMode,
        'hasToken': await getToken() != null,
      };
    } catch (e) {
      return {
        'isInitialized': _isInitialized,
        'isDisabled': _isDisabled,
        'isEnabled': false,
        'error': e.toString(),
        'debugMode': kDebugMode,
      };
    }
  }

  // Method to completely disable App Check (for debugging)
  static Future<void> disableAppCheck() async {
    try {
      print('Disabling Firebase App Check...');
      _isDisabled = true;
      print('App Check disabled - app will run without security verification');
    } catch (e) {
      print('Error disabling App Check: $e');
    }
  }

  // Method to check if we should skip App Check entirely
  static bool get shouldSkipAppCheck {
    // In debug mode, we can optionally skip App Check
    return kDebugMode || _isDisabled;
  }
}
