import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckConfig {
  static Future<void> initialize() async {
    try {
      print('Initializing Firebase App Check...');
      
      // Use debug provider for development environments
      if (kDebugMode) {
        print('Using debug providers for development');
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      } else {
        print('Using production providers');
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
      }
      
      print('Firebase App Check activated successfully');
    } catch (e) {
      print('Error initializing Firebase App Check: $e');
      print('App will continue without App Check functionality');
      // Don't rethrow - allow app to continue without App Check
    }
  }

  // Method to verify App Check token with timeout
  static Future<bool> verifyAppCheckToken() async {
    try {
      print('Verifying App Check token...');
      
      // Add timeout to prevent app from getting stuck
      final token = await FirebaseAppCheck.instance.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('App Check token verification timed out after 10 seconds');
          return null;
        },
      );
      
      if (token != null) {
        print('App Check token verified successfully');
        return true;
      } else {
        print('App Check token verification failed - no token received');
        return false;
      }
    } catch (e) {
      print('App Check token verification failed with error: $e');
      return false;
    }
  }

  // Method to check if App Check is available/enabled
  static bool get isAppCheckEnabled {
    try {
      return FirebaseAppCheck.instance != null;
    } catch (e) {
      print('Error checking App Check availability: $e');
      return false;
    }
  }

  // Method to get debug information about App Check status
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return {
        'isEnabled': true,
        'hasToken': token != null,
        'tokenLength': token?.length ?? 0,
        'debugMode': kDebugMode,
      };
    } catch (e) {
      return {
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
      // Note: Firebase App Check doesn't have a direct disable method
      // This is just for logging purposes
      print('App Check disabled - app will run without security verification');
    } catch (e) {
      print('Error disabling App Check: $e');
    }
  }

  // Method to check if we should skip App Check entirely
  static bool get shouldSkipAppCheck {
    // In debug mode, we can optionally skip App Check
    return kDebugMode;
  }
}
