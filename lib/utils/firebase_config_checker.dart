import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Utility class to diagnose Firebase configuration issues
class FirebaseConfigChecker {
  static const String _placeholderProjectId = 'placeholder-project-id';
  
  /// Check if Firebase configuration is valid
  static Future<FirebaseConfigStatus> checkConfiguration() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      
      // Check for placeholder values
      if (_hasPlaceholderValues(options)) {
        return FirebaseConfigStatus(
          isValid: false,
          issues: [
            'Firebase configuration contains placeholder values',
            'Project ID appears to be a placeholder: ${options.projectId}',
            'You need to update firebase_options.dart with your actual Firebase project details'
          ],
          recommendations: [
            'Run: flutterfire configure',
            'Or manually update firebase_options.dart with your Firebase project details',
            'Ensure you have a valid Firebase project created in the Firebase Console'
          ]
        );
      }
      
      // Check for missing required fields
      final missingFields = _getMissingRequiredFields(options);
      if (missingFields.isNotEmpty) {
        return FirebaseConfigStatus(
          isValid: false,
          issues: [
            'Firebase configuration is missing required fields:',
            ...missingFields.map((field) => '- $field')
          ],
          recommendations: [
            'Run: flutterfire configure',
            'Ensure all required Firebase services are enabled in your project',
            'Check that your Firebase project has Firestore Database enabled'
          ]
        );
      }
      
      // Test Firebase initialization
      try {
        await Firebase.initializeApp(options: options);
        await Firebase.app().delete();
        
        return FirebaseConfigStatus(
          isValid: true,
          issues: [],
          recommendations: ['Firebase configuration is valid and ready to use']
        );
      } catch (e) {
        return FirebaseConfigStatus(
          isValid: false,
          issues: [
            'Firebase initialization test failed: $e',
            'This may indicate network or permission issues'
          ],
          recommendations: [
            'Check your internet connection',
            'Verify Firebase project permissions',
            'Ensure your app has the correct API keys and permissions'
          ]
        );
      }
      
    } catch (e) {
      return FirebaseConfigStatus(
        isValid: false,
        issues: [
          'Failed to check Firebase configuration: $e',
          'firebase_options.dart may be corrupted or missing'
        ],
        recommendations: [
          'Run: flutterfire configure',
          'Check that firebase_options.dart exists and is properly formatted',
          'Verify your Firebase project is properly set up'
        ]
      );
    }
  }
  
  /// Check if configuration has placeholder values
  static bool _hasPlaceholderValues(FirebaseOptions options) {
    return options.projectId == _placeholderProjectId ||
           options.projectId.contains('placeholder') ||
           options.projectId.contains('example') ||
           options.appId.contains('example');
  }
  
  /// Get list of missing required fields
  static List<String> _getMissingRequiredFields(FirebaseOptions options) {
    final missing = <String>[];
    
    if (options.projectId.isEmpty) {
      missing.add('projectId');
    }
    
    if (options.apiKey.isEmpty) {
      missing.add('apiKey');
    }
    
    if (options.appId.isEmpty) {
      missing.add('appId');
    }
    
    if (options.messagingSenderId.isEmpty) {
      missing.add('messagingSenderId');
    }
    
    // Check for Firestore-specific fields
    if (options.storageBucket?.isEmpty ?? true) {
      missing.add('storageBucket');
    }
    
    return missing;
  }
  
  /// Get detailed configuration information
  static Map<String, dynamic> getConfigurationDetails() {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      return {
        'projectId': options.projectId,
        'apiKey': options.apiKey.isNotEmpty ? '${options.apiKey.substring(0, 10)}...' : 'MISSING',
        'appId': options.appId,
        'messagingSenderId': options.messagingSenderId,
        'storageBucket': options.storageBucket,
        'databaseURL': options.databaseURL ?? 'NOT SET',
        'authDomain': options.authDomain ?? 'NOT SET',
        'hasPlaceholderValues': _hasPlaceholderValues(options),
        'missingFields': _getMissingRequiredFields(options),
      };
    } catch (e) {
      return {
        'error': 'Failed to read configuration: $e',
        'hasPlaceholderValues': true,
        'missingFields': ['configuration_file']
      };
    }
  }
}

/// Status of Firebase configuration check
class FirebaseConfigStatus {
  final bool isValid;
  final List<String> issues;
  final List<String> recommendations;
  
  const FirebaseConfigStatus({
    required this.isValid,
    required this.issues,
    required this.recommendations,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Firebase Configuration Status: ${isValid ? "✅ VALID" : "❌ INVALID"}');
    
    if (issues.isNotEmpty) {
      buffer.writeln('\nIssues Found:');
      for (final issue in issues) {
        buffer.writeln('• $issue');
      }
    }
    
    if (recommendations.isNotEmpty) {
      buffer.writeln('\nRecommendations:');
      for (final recommendation in recommendations) {
        buffer.writeln('• $recommendation');
      }
    }
    
    return buffer.toString();
  }
}
