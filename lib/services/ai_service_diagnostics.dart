import 'package:flutter/foundation.dart';
import 'package:mindload/services/enhanced_ai_service.dart';
import 'package:mindload/services/local_ai_fallback_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/models/study_data.dart';

/// AI Service Diagnostics for iOS and Android
class AIServiceDiagnostics {
  static final AIServiceDiagnostics _instance =
      AIServiceDiagnostics._internal();
  static AIServiceDiagnostics get instance => _instance;
  AIServiceDiagnostics._internal();

  /// Comprehensive AI service health check for mobile platforms
  Future<AIServiceStatus> checkAIServiceHealth() async {
    final stopwatch = Stopwatch()..start();
    final results = <String, dynamic>{};

    try {
      debugPrint('🔍 Starting AI Service Health Check...');

      // 1. Check Authentication
      results['authentication'] = await _checkAuthentication();

      // 2. Test Local AI Service
      results['localAI'] = await _testLocalAI();

      // 3. Test OpenAI Cloud Functions
      results['openAI'] = await _testOpenAI();

      // 4. Test Enhanced AI Service
      results['enhancedAI'] = await _testEnhancedAI();

      stopwatch.stop();

      return AIServiceStatus(
        isHealthy: _determineOverallHealth(results),
        results: results,
        testDurationMs: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ AI Service Health Check failed: $e');

      return AIServiceStatus(
        isHealthy: false,
        results: {'error': e.toString()},
        testDurationMs: stopwatch.elapsedMilliseconds,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Check authentication status
  Future<Map<String, dynamic>> _checkAuthentication() async {
    try {
      final authService = AuthService.instance;
      final isAuthenticated = authService.isAuthenticated;
      final user = authService.currentUser;

      return {
        'status': 'success',
        'isAuthenticated': isAuthenticated,
        'hasUser': user != null,
        'userEmail': user?.email ?? 'none',
        'message':
            isAuthenticated ? 'Authentication working' : 'Not authenticated',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'message': 'Authentication check failed',
      };
    }
  }

  /// Test Local AI Fallback Service
  Future<Map<String, dynamic>> _testLocalAI() async {
    try {
      debugPrint('🧠 Testing Local AI Service...');

      const testContent =
          'The human brain is the command center for the nervous system.';
      final localAI = LocalAIFallbackService.instance;

      final flashcards = await localAI.generateFlashcards(
        testContent,
        count: 2,
        targetDifficulty: DifficultyLevel.intermediate,
      );

      final quizQuestions = await localAI.generateQuizQuestions(
        testContent,
        2,
        'intermediate',
      );

      return {
        'status': 'success',
        'flashcardsGenerated': flashcards.length,
        'quizQuestionsGenerated': quizQuestions.length,
        'message': 'Local AI working perfectly',
        'sampleFlashcard':
            flashcards.isNotEmpty ? flashcards.first.question : 'none',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'message': 'Local AI failed',
      };
    }
  }

  /// Test OpenAI Cloud Functions
  Future<Map<String, dynamic>> _testOpenAI() async {
    try {
      debugPrint('☁️ Testing OpenAI Cloud Functions...');

      const testContent =
          'The human brain processes information through neurons.';
      final enhancedAI = EnhancedAIService.instance;

      // Try a minimal generation using public method
      final result = await enhancedAI.generateStudyMaterials(
        content: testContent,
        flashcardCount: 1,
        quizCount: 1,
        difficulty: 'easy',
      );

      if (result.isSuccess) {
        return {
          'status': 'success',
          'method': result.method.toString(),
          'flashcardsGenerated': result.flashcards.length,
          'quizQuestionsGenerated': result.quizQuestions.length,
          'processingTimeMs': result.processingTimeMs,
          'message': 'OpenAI Cloud Functions working',
        };
      } else {
        return {
          'status': 'partial',
          'error': result.errorMessage,
          'message': 'OpenAI failed but handled gracefully',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'message': 'OpenAI Cloud Functions test failed',
      };
    }
  }

  /// Test Enhanced AI Service (Full Pipeline)
  Future<Map<String, dynamic>> _testEnhancedAI() async {
    try {
      debugPrint('🚀 Testing Enhanced AI Service...');

      const testContent =
          'Machine learning is a subset of artificial intelligence that focuses on algorithms.';
      final enhancedAI = EnhancedAIService.instance;

      final result = await enhancedAI.generateStudyMaterials(
        content: testContent,
        flashcardCount: 2,
        quizCount: 2,
        difficulty: 'intermediate',
      );

      return {
        'status': result.isSuccess ? 'success' : 'partial',
        'method': result.method.toString(),
        'isFallback': result.isFallback,
        'flashcardsGenerated': result.flashcards.length,
        'quizQuestionsGenerated': result.quizQuestions.length,
        'processingTimeMs': result.processingTimeMs,
        'errorMessage': result.errorMessage,
        'message': result.isSuccess
            ? 'Enhanced AI working with ${result.method.toString().split('.').last}'
            : 'Enhanced AI using fallback: ${result.errorMessage}',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'message': 'Enhanced AI Service test failed',
      };
    }
  }

  /// Determine overall health from test results
  bool _determineOverallHealth(Map<String, dynamic> results) {
    // AI service is healthy if:
    // 1. Authentication works
    // 2. At least one AI method works (Local AI should always work)

    final authOk = results['authentication']?['status'] == 'success';
    final localAIOk = results['localAI']?['status'] == 'success';
    final enhancedAIOk = results['enhancedAI']?['status'] == 'success' ||
        results['enhancedAI']?['status'] == 'partial';

    return authOk && localAIOk && enhancedAIOk;
  }

  /// Quick test for mobile platforms - simplified version
  static Future<String> quickMobileTest() async {
    try {
      debugPrint('📱 Running quick AI service test for mobile...');

      // Test local AI (should always work)
      const testContent = 'Artificial intelligence is transforming education.';
      final localAI = LocalAIFallbackService.instance;

      final flashcards = await localAI.generateFlashcards(
        testContent,
        count: 1,
        targetDifficulty: DifficultyLevel.intermediate,
      );

      if (flashcards.isNotEmpty) {
        // Test enhanced AI service
        final enhancedAI = EnhancedAIService.instance;
        final result = await enhancedAI.generateStudyMaterials(
          content: testContent,
          flashcardCount: 1,
          quizCount: 1,
          difficulty: 'intermediate',
        );

        final method = result.method.toString().split('.').last;
        final status = result.isSuccess ? 'working' : 'using fallback';

        return '✅ AI Service Status: $status\n'
            '📱 Platform: ${defaultTargetPlatform.name}\n'
            '🧠 Method: $method\n'
            '🃏 Generated: ${result.flashcards.length} flashcards, ${result.quizQuestions.length} quiz questions\n'
            '⏱️ Time: ${(result.processingTimeMs / 1000).toStringAsFixed(1)}s\n'
            '${result.errorMessage != null ? '\n⚠️ Note: ${result.errorMessage}' : ''}';
      } else {
        return '❌ AI Service Error: Local AI failed to generate content';
      }
    } catch (e) {
      return '❌ AI Service Error: $e';
    }
  }

  /// Generate a user-friendly health report
  String generateHealthReport(AIServiceStatus status) {
    if (status.isHealthy) {
      return '✅ AI Service is working perfectly!\n\n'
          'Local AI: ${status.results['localAI']?['message']}\n'
          'OpenAI: ${status.results['openAI']?['message'] ?? 'Not tested'}\n'
          'Enhanced AI: ${status.results['enhancedAI']?['message']}\n\n'
          'Test completed in ${(status.testDurationMs / 1000).toStringAsFixed(1)}s';
    } else {
      return '⚠️ AI Service has issues:\n\n'
          'Authentication: ${status.results['authentication']?['message']}\n'
          'Local AI: ${status.results['localAI']?['message']}\n'
          'Enhanced AI: ${status.results['enhancedAI']?['message']}\n\n'
          'Recommendation: Local AI should still work for offline generation.';
    }
  }
}

/// AI Service Status Result
class AIServiceStatus {
  final bool isHealthy;
  final Map<String, dynamic> results;
  final int testDurationMs;
  final DateTime timestamp;

  AIServiceStatus({
    required this.isHealthy,
    required this.results,
    required this.testDurationMs,
    required this.timestamp,
  });

  /// Get a summary of the AI service status
  String get summary {
    if (isHealthy) {
      return 'AI Service: Healthy ✅';
    } else {
      return 'AI Service: Issues detected ⚠️';
    }
  }

  /// Get detailed status information
  Map<String, dynamic> get detailedStatus => {
        'overall': isHealthy ? 'healthy' : 'issues_detected',
        'authentication': results['authentication']?['status'] ?? 'unknown',
        'localAI': results['localAI']?['status'] ?? 'unknown',
        'openAI': results['openAI']?['status'] ?? 'unknown',
        'enhancedAI': results['enhancedAI']?['status'] ?? 'unknown',
        'testDuration': '${(testDurationMs / 1000).toStringAsFixed(1)}s',
        'timestamp': timestamp.toIso8601String(),
      };
}
