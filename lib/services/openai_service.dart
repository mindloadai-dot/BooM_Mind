import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/local_ai_fallback_service.dart';

class OpenAIService {
  static OpenAIService? _instance;
  static OpenAIService get instance => _instance ??= OpenAIService._();
  OpenAIService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final AuthService _authService = AuthService.instance;

  // Rate limiting state
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  static const int _maxRequestsPerMinute = 20;

  // Method overload for generation dialog - returns flashcards from content
  Future<List<Flashcard>> generateFlashcardsFromContent(
    String content,
    int count,
    String difficulty, {
    String? questionTypes, // e.g., "concept, application, analysis, synthesis"
    String?
        cognitiveLevel, // e.g., "remember, understand, apply, analyze, evaluate, create"
    String?
        realWorldContext, // e.g., "business, healthcare, technology, daily life"
    String? challengeLevel, // e.g., "basic, intermediate, advanced, expert"
    String? learningStyle, // e.g., "visual, auditory, kinesthetic, reading"
    String? promptEnhancement, // Custom additional instructions
  }) async {
    try {
      // Allow both authenticated and unauthenticated requests
      final currentUser = _authService.currentUser;
      debugPrint(
          'Generating flashcards for user: ${currentUser?.uid ?? 'anonymous'}');

      // Get App Check token for security (with fallback)
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (e) {
        debugPrint('App Check token failed: $e');
        appCheckToken = null; // Continue without token
      }

      // Ensure user is signed in before making OpenAI calls
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint(
            '⚠️ User not authenticated, attempting anonymous sign-in...');
        try {
          await FirebaseAuth.instance.signInAnonymously();
          debugPrint('✅ Anonymous sign-in successful');
        } catch (e) {
          debugPrint('❌ Anonymous sign-in failed: $e');
        }
      }

      // Get Firebase ID token for authentication
      String? idToken;
      try {
        // Get the actual Firebase User object to access getIdToken()
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          idToken = await firebaseUser.getIdToken(true); // Force refresh
          debugPrint('✅ Firebase ID token obtained');
        } else {
          debugPrint('❌ No Firebase user available');
        }
      } catch (e) {
        debugPrint('Failed to get ID token: $e');
      }

      // Call Cloud Function for secure API access
      final callable = _functions.httpsCallable('generateFlashcards');

      // Debug authentication status
      debugPrint(
          '🔐 Auth status - Firebase User: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint(
          '🔐 Auth status - AuthService User: ${_authService.currentUser?.uid}');
      debugPrint('🔐 ID Token available: ${idToken != null}');
      debugPrint('🔐 App Check Token available: ${appCheckToken != null}');

      // Ensure we have a valid Firebase user before making the call
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated Firebase user available');
      }

      final result = await callable.call({
        'content': content,
        'count': count,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });

      if (result.data != null) {
        try {
          final responseData = result.data as Map<String, dynamic>;
          if (responseData.containsKey('flashcards')) {
            final flashcardsList = responseData['flashcards'] as List;
            return flashcardsList.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              // Create a Flashcard with generated ID and safe parsing
              return Flashcard(
                id: 'generated_${DateTime.now().millisecondsSinceEpoch}_$index',
                question:
                    data['question']?.toString() ?? 'Question not available',
                answer: data['answer']?.toString() ?? 'Answer not available',
                difficulty: _parseDifficulty(
                    data['difficulty']?.toString() ?? difficulty),
              );
            }).toList();
          }
        } catch (parseError) {
          debugPrint('Error parsing flashcards response: $parseError');
        }
      }

      // Fallback: return empty list if parsing fails
      return [];
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      debugPrint('🔄 Attempting local fallback for flashcards...');

      // Try local fallback when Cloud Functions fail
      try {
        return await LocalAIFallbackService.instance.generateFlashcards(content,
            count: count, targetDifficulty: _parseDifficulty(difficulty));
      } catch (fallbackError) {
        debugPrint('❌ Local fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  // Generate study material from content
  Future<String?> generateStudyMaterial(
    String content,
    String materialType,
    String difficulty,
  ) async {
    try {
      return await _makeSecureAPICall(
        content: content,
        materialType: materialType,
        difficulty: difficulty,
      );
    } catch (e) {
      debugPrint('Error generating study material: $e');
      return null;
    }
  }

  // Legacy method name for compatibility
  Future<List<QuizQuestion>> generateQuizQuestionsFromContent(
    String content,
    int count,
    String difficulty,
  ) async {
    return generateQuizQuestions(content, count, difficulty);
  }

  // Note: Legacy methods removed - now using Cloud Functions for secure OpenAI access

  // Generate quiz questions from content
  Future<List<QuizQuestion>> generateQuizQuestions(
    String content,
    int count,
    String difficulty, {
    String?
        questionTypes, // e.g., "multipleChoice, trueFalse, fillInBlanks, scenario"
    String?
        cognitiveLevel, // e.g., "remember, understand, apply, analyze, evaluate, create"
    String?
        realWorldContext, // e.g., "business, healthcare, technology, daily life"
    String? challengeLevel, // e.g., "basic, intermediate, advanced, expert"
    String? learningStyle, // e.g., "visual, auditory, kinesthetic, reading"
    String? promptEnhancement, // Custom additional instructions
  }) async {
    try {
      // Allow both authenticated and unauthenticated requests
      final currentUser = _authService.currentUser;
      debugPrint(
          'Generating quiz questions for user: ${currentUser?.uid ?? 'anonymous'}');

      // Get App Check token for security (with fallback)
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (e) {
        debugPrint('App Check token failed: $e');
        appCheckToken = null; // Continue without token
      }

      // Ensure user is signed in before making OpenAI calls
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint(
            '⚠️ Quiz: User not authenticated, attempting anonymous sign-in...');
        try {
          await FirebaseAuth.instance.signInAnonymously();
          debugPrint('✅ Quiz: Anonymous sign-in successful');
        } catch (e) {
          debugPrint('❌ Quiz: Anonymous sign-in failed: $e');
        }
      }

      // Get Firebase ID token for authentication
      String? idToken;
      try {
        // Get the actual Firebase User object to access getIdToken()
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          idToken = await firebaseUser.getIdToken(true); // Force refresh
          debugPrint('✅ Quiz: Firebase ID token obtained');
        } else {
          debugPrint('❌ Quiz: No Firebase user available');
        }
      } catch (e) {
        debugPrint('Failed to get ID token: $e');
      }

      // Call Cloud Function for secure API access
      final callable = _functions.httpsCallable('generateQuiz');

      // Debug authentication status
      debugPrint(
          '🔐 Quiz Auth status - Firebase User: ${FirebaseAuth.instance.currentUser?.uid}');
      debugPrint(
          '🔐 Quiz Auth status - AuthService User: ${_authService.currentUser?.uid}');
      debugPrint('🔐 Quiz ID Token available: ${idToken != null}');
      debugPrint('🔐 Quiz App Check Token available: ${appCheckToken != null}');

      // Ensure we have a valid Firebase user before making the call
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception(
            'No authenticated Firebase user available for quiz generation');
      }

      final result = await callable.call({
        'content': content,
        'count': count,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });

      if (result.data != null) {
        try {
          final responseData = result.data as Map<String, dynamic>;
          if (responseData.containsKey('questions')) {
            final questionsList = responseData['questions'] as List;
            return questionsList.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value as Map<String, dynamic>;

              return QuizQuestion(
                id: 'generated_${DateTime.now().millisecondsSinceEpoch}_$index',
                question:
                    data['question']?.toString() ?? 'Question not available',
                options: List<String>.from(data['options'] ?? []),
                correctAnswer: data['correctAnswer']?.toString() ?? '',
                difficulty: _parseDifficulty(
                    data['difficulty']?.toString() ?? difficulty),
                type: QuestionType.multipleChoice, // Default to multiple choice
              );
            }).toList();
          }
        } catch (parseError) {
          debugPrint('Error parsing quiz questions response: $parseError');
        }
      }

      // Fallback: return empty list if parsing fails
      return [];
    } catch (e) {
      debugPrint('Error generating quiz questions: $e');
      debugPrint('🔄 Attempting local fallback for quiz questions...');

      // Try local fallback when Cloud Functions fail
      try {
        return await LocalAIFallbackService.instance
            .generateQuizQuestions(content, count, difficulty);
      } catch (fallbackError) {
        debugPrint('❌ Local fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  // Check rate limiting
  bool _checkRateLimit() {
    final now = DateTime.now();

    if (_lastRequestTime == null) {
      _lastRequestTime = now;
      _requestCount = 1;
      return true;
    }

    final timeDiff = now.difference(_lastRequestTime!);

    if (timeDiff.inMinutes >= 1) {
      // Reset counter after 1 minute
      _lastRequestTime = now;
      _requestCount = 1;
      return true;
    }

    if (_requestCount >= _maxRequestsPerMinute) {
      return false;
    }

    _requestCount++;
    return true;
  }

  Future<String?> _makeSecureAPICall({
    required String content,
    required String materialType,
    required String difficulty,
  }) async {
    try {
      // Get App Check token for security (with fallback)
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } catch (e) {
        debugPrint('App Check token failed: $e');
        appCheckToken = null; // Continue without token
      }

      // Call Cloud Function for secure API access
      final result =
          await _functions.httpsCallable('generateStudyMaterial').call({
        'content': content,
        'materialType': materialType,
        'difficulty': difficulty,
        'appCheckToken': appCheckToken,
      });

      if (result.data != null) {
        final responseData = result.data as Map<String, dynamic>;
        return responseData['content'] as String?;
      }

      return null;
    } catch (e) {
      debugPrint('Secure API call failed: $e');
      return null;
    }
  }

  /// Parse difficulty string to enum
  DifficultyLevel _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'intermediate':
        return DifficultyLevel.intermediate;
      case 'advanced':
        return DifficultyLevel.advanced;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }

  // Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'isConfigured': true,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
      'requestCount': _requestCount,
      'maxRequestsPerMinute': _maxRequestsPerMinute,
      'canMakeRequest': _checkRateLimit(),
    };
  }

  // Convenience method for generating intelligent flashcards
  Future<List<Flashcard>> generateIntelligentFlashcards(
    String content,
    int count, {
    String difficulty = 'medium',
    String cognitiveLevel = 'analyze, evaluate, create',
    String realWorldContext = 'business, technology, daily life',
    String challengeLevel = 'intermediate',
  }) async {
    return generateFlashcardsFromContent(
      content,
      count,
      difficulty,
      questionTypes: 'concept, application, analysis, synthesis',
      cognitiveLevel: cognitiveLevel,
      realWorldContext: realWorldContext,
      challengeLevel: challengeLevel,
      learningStyle: 'visual, auditory, reading',
      promptEnhancement:
          'Focus on critical thinking and real-world applications',
    );
  }

  // Convenience method for generating challenging quiz questions
  Future<List<QuizQuestion>> generateChallengingQuiz(
    String content,
    int count, {
    String difficulty = 'hard',
    String cognitiveLevel = 'analyze, evaluate, create',
    String realWorldContext = 'business, healthcare, technology',
    String challengeLevel = 'advanced',
  }) async {
    return generateQuizQuestions(
      content,
      count,
      difficulty,
      questionTypes: 'multipleChoice, scenario, analysis',
      cognitiveLevel: cognitiveLevel,
      realWorldContext: realWorldContext,
      challengeLevel: challengeLevel,
      learningStyle: 'visual, reading',
      promptEnhancement:
          'Create questions that require deep understanding and application',
    );
  }

  // Build enhanced prompt for more intelligent content generation

  /// Map string difficulty to enum
  DifficultyLevel _mapStringToDifficultyLevel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return DifficultyLevel.beginner;
      case 'intermediate':
        return DifficultyLevel.intermediate;
      case 'advanced':
        return DifficultyLevel.advanced;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }

  /// Map string question type to enum
  QuestionType _mapStringToQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'multiplechoice':
        return QuestionType.multipleChoice;
      case 'truefalse':
        return QuestionType.trueFalse;
      case 'shortanswer':
        return QuestionType.shortAnswer;
      case 'conceptualchallenge':
        return QuestionType.conceptualChallenge;
      default:
        return QuestionType.multipleChoice;
    }
  }

  // Note: Direct OpenAI API calls removed - now using secure Cloud Functions
}
