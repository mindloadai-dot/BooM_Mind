import 'package:flutter/foundation.dart';
import 'package:mindload/firebase_options.dart';

/// Helper class to validate Firebase configuration for app store submission
class FirebaseTestHelper {
  static bool isFirebaseConfigured() {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      
      // Check if we're using placeholder values
      if (options.projectId.contains('placeholder') || 
          options.apiKey.contains('placeholder')) {
        return false;
      }
      
      // Check for development/test project IDs
      if (options.projectId.contains('test') || 
          options.projectId.contains('dev') ||
          options.projectId.length < 10) {
        return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase configuration check failed: $e');
      }
      return false;
    }
  }
  
  static void logFirebaseStatus() {
    if (isFirebaseConfigured()) {
      if (kDebugMode) {
        debugPrint('✅ Firebase is properly configured for production');
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ Firebase using development/placeholder configuration');
        debugPrint('   Replace firebase_options.dart with production config before App Store submission');
      }
    }
  }
  
  static Map<String, String> getConfigurationGuide() {
    return {
      'step_1': 'Create Firebase project at https://console.firebase.google.com',
      'step_2': 'Add iOS app with bundle ID: com.yourdomain.mindload',
      'step_3': 'Download GoogleService-Info.plist and place in ios/Runner/',
      'step_4': 'Add Android app with package name: com.yourdomain.mindload',
      'step_5': 'Download google-services.json and place in android/app/',
      'step_6': 'Run "flutterfire configure" to update firebase_options.dart',
      'step_7': 'Enable Authentication, Firestore, Storage, and Messaging in Firebase Console',
      'step_8': 'Update bundle identifier in pubspec.yaml and iOS/Android configs'
    };
  }
}