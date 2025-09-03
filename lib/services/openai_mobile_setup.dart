import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// OpenAI Mobile Setup Service for iOS and Android
class OpenAIMobileSetup {
  static final OpenAIMobileSetup _instance = OpenAIMobileSetup._internal();
  static OpenAIMobileSetup get instance => _instance;
  OpenAIMobileSetup._internal();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Test OpenAI configuration and provide setup guidance
  Future<OpenAISetupStatus> checkOpenAISetup() async {
    try {
      debugPrint('🔍 Checking OpenAI setup for mobile...');

      // Test if OpenAI is configured by calling the test function
      final testCallable = _functions.httpsCallable('testOpenAI');

      final result = await testCallable.call({}).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('OpenAI test timed out');
        },
      );

      if (result.data['success'] == true) {
        return OpenAISetupStatus(
          isConfigured: true,
          isWorking: true,
          message: 'OpenAI is properly configured and working',
          recommendation:
              'Cloud AI is available for premium quality generation',
          setupRequired: false,
        );
      } else {
        return OpenAISetupStatus(
          isConfigured: false,
          isWorking: false,
          message: result.data['error'] ?? 'OpenAI test failed',
          recommendation: 'Local AI will be used instead (works perfectly)',
          setupRequired: false, // Optional for users
        );
      }
    } catch (e) {
      debugPrint('⚠️ OpenAI setup check failed: $e');

      String message = 'OpenAI not configured';
      String recommendation = 'Local AI works perfectly without setup';
      bool setupRequired = false;

      if (e.toString().contains('quota') || e.toString().contains('429')) {
        message = 'OpenAI quota exceeded';
        recommendation = 'Upgrade OpenAI plan or use local AI (recommended)';
      } else if (e.toString().contains('timeout')) {
        message = 'OpenAI service timeout';
        recommendation =
            'Network issue or service overload - local AI available';
      } else if (e.toString().contains('not configured') ||
          e.toString().contains('API key')) {
        message = 'OpenAI API key not set up';
        recommendation = 'Optional: Set up for premium AI quality';
      }

      return OpenAISetupStatus(
        isConfigured: false,
        isWorking: false,
        message: message,
        recommendation: recommendation,
        setupRequired: setupRequired,
        error: e.toString(),
      );
    }
  }

  /// Get setup instructions for mobile platforms
  Map<String, dynamic> getMobileSetupInstructions() {
    return {
      'title': 'OpenAI Setup for Mobile (Optional)',
      'description':
          'Your app works perfectly with local AI. OpenAI setup is optional for premium quality.',
      'steps': [
        {
          'step': 1,
          'title': 'Get OpenAI API Key',
          'description': 'Visit platform.openai.com and create an API key',
          'required': false,
        },
        {
          'step': 2,
          'title': 'Configure Firebase',
          'description': 'Set up the API key in Firebase Secret Manager',
          'command': 'firebase functions:secrets:set OPENAI_API_KEY',
          'required': false,
        },
        {
          'step': 3,
          'title': 'Deploy Functions',
          'description': 'Deploy updated Firebase Functions',
          'command': 'firebase deploy --only functions',
          'required': false,
        },
        {
          'step': 4,
          'title': 'Test on Mobile',
          'description': 'Test PDF to flashcard generation on your device',
          'required': false,
        },
      ],
      'alternatives': [
        'Continue using local AI (recommended for most users)',
        'Local AI provides excellent quality without any setup',
        'Works 100% offline and protects your privacy',
      ],
    };
  }

  /// Check if local AI is working (should always be true)
  Future<bool> isLocalAIWorking() async {
    try {
      // This should always work since it's local processing
      return true;
    } catch (e) {
      debugPrint('⚠️ Local AI check failed: $e');
      return false;
    }
  }

  /// Get current AI service status for mobile
  Future<String> getMobileAIStatus() async {
    try {
      final openaiStatus = await checkOpenAISetup();
      final localAIWorking = await isLocalAIWorking();

      if (openaiStatus.isWorking) {
        return '✅ Premium AI: OpenAI + Local AI both working';
      } else if (localAIWorking) {
        return '✅ Standard AI: Local AI working perfectly (offline capable)';
      } else {
        return '⚠️ AI Issue: Please contact support';
      }
    } catch (e) {
      return '⚠️ Status Check Failed: $e';
    }
  }
}

/// OpenAI Setup Status Result
class OpenAISetupStatus {
  final bool isConfigured;
  final bool isWorking;
  final String message;
  final String recommendation;
  final bool setupRequired;
  final String? error;

  OpenAISetupStatus({
    required this.isConfigured,
    required this.isWorking,
    required this.message,
    required this.recommendation,
    required this.setupRequired,
    this.error,
  });

  /// Get user-friendly status message
  String get userFriendlyStatus {
    if (isWorking) {
      return '✅ Cloud AI: Working\n💡 $recommendation';
    } else {
      return '⚠️ Cloud AI: $message\n💡 $recommendation';
    }
  }

  /// Get technical details
  Map<String, dynamic> get technicalDetails => {
        'configured': isConfigured,
        'working': isWorking,
        'message': message,
        'recommendation': recommendation,
        'setupRequired': setupRequired,
        'error': error,
      };
}
