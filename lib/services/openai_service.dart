import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/auth_service.dart';

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
    String difficulty,
  ) async {
    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      // Call Cloud Function for secure API access
      final result = await _functions.httpsCallable('generateFlashcards').call({
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
                question: data['question']?.toString() ?? 'Question not available',
                answer: data['answer']?.toString() ?? 'Answer not available',
                difficulty: _parseDifficulty(data['difficulty']?.toString() ?? difficulty),
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
      return [];
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

  // Legacy method name for compatibility
  Future<List<Flashcard>> generateFlashcards(
    String content, {
    required int count,
  }) async {
    return generateFlashcardsFromContent(content, count, 'medium');
  }

  // Legacy method name for compatibility
  Future<List<QuizQuestion>> generateQuiz(
    String content, {
    required int count,
  }) async {
    return generateQuizQuestions(content, count, 'medium');
  }

  // Generate quiz questions from content
  Future<List<QuizQuestion>> generateQuizQuestions(
    String content,
    int count,
    String difficulty,
  ) async {
    try {
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      // Call Cloud Function for secure API access
      final result = await _functions.httpsCallable('generateQuizQuestions').call({
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
                question: data['question']?.toString() ?? 'Question not available',
                options: List<String>.from(data['options'] ?? []),
                correctAnswer: data['correctAnswer']?.toString() ?? '',
                type: QuizType.multipleChoice, // Default to multiple choice
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
      return [];
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
      // Get App Check token for security
      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      // Call Cloud Function for secure API access
      final result = await _functions.httpsCallable('generateStudyMaterial').call({
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

  // Helper methods for fallback content
  DifficultyLevel _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'medium':
        return DifficultyLevel.medium;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.medium;
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
}