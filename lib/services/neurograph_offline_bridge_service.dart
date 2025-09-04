import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../neurograph_v2/neurograph_offline_repo.dart';
import '../neurograph_v2/neurograph_models.dart';

/// Completely offline bridge service for NeuroGraph V2
/// Saves all quiz and study data to local SQLite storage
/// No network dependencies - works entirely offline
class NeuroGraphOfflineBridgeService {
  static final NeuroGraphOfflineBridgeService _instance =
      NeuroGraphOfflineBridgeService._internal();
  factory NeuroGraphOfflineBridgeService() => _instance;
  static NeuroGraphOfflineBridgeService get instance => _instance;
  NeuroGraphOfflineBridgeService._internal();

  final NeuroGraphOfflineRepository _offlineRepo =
      NeuroGraphOfflineRepository.instance;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _offlineRepo.initialize();
      debugPrint('✅ NeuroGraph offline bridge service initialized');
    } catch (e) {
      debugPrint(
          '❌ Failed to initialize NeuroGraph offline bridge service: $e');
    }
  }

  /// Save individual quiz question attempts to local storage (completely offline)
  Future<void> saveQuizAttempts({
    required String quizId,
    required String quizTitle,
    required List<Map<String, dynamic>> questionAttempts,
    required DateTime quizStartTime,
    required DateTime quizEndTime,
  }) async {
    try {
      final userId = AuthService.instance.currentUserId;
      if (userId == null) {
        debugPrint('❌ Cannot save quiz attempts: No authenticated user');
        return;
      }

      await _offlineRepo.initialize();

      // Save individual question attempts locally
      for (int i = 0; i < questionAttempts.length; i++) {
        final attemptData = questionAttempts[i];

        final attempt = Attempt(
          userId: userId,
          testId: quizId,
          questionId: attemptData['questionId'] ?? 'q_${i}_$quizId',
          topicId: _extractTopicFromTitle(quizTitle),
          bloom: _inferBloomLevel(
              attemptData['questionType'] ?? 'multiple_choice'),
          isCorrect: attemptData['isCorrect'] ?? false,
          score: attemptData['isCorrect'] == true ? 1.0 : 0.0,
          responseMs: attemptData['responseTimeMs'] ?? 3000,
          timestamp: attemptData['timestamp'] ?? DateTime.now(),
          confidencePct: attemptData['confidence']?.toDouble(),
        );

        await _offlineRepo.saveAttempt(attempt);

        // Save question metadata locally
        final question = Question(
          questionId: attemptData['questionId'] ?? 'q_${i}_$quizId',
          topicId: _extractTopicFromTitle(quizTitle),
          bloom: _inferBloomLevel(
              attemptData['questionType'] ?? 'multiple_choice'),
          difficulty: attemptData['difficulty'] ?? 3,
          text: attemptData['questionText'] ?? 'Quiz question ${i + 1}',
        );

        await _offlineRepo.saveQuestion(question);
      }

      // Save session data locally
      final correctAnswers =
          questionAttempts.where((a) => a['isCorrect'] == true).length;

      final session = Session(
        userId: userId,
        startedAt: quizStartTime,
        endedAt: quizEndTime,
        itemsSeen: questionAttempts.length,
        itemsCorrect: correctAnswers,
        testId: quizId,
        sessionType: 'quiz',
        subject: quizTitle,
      );

      await _offlineRepo.saveSession(session);

      debugPrint(
          '✅ Saved ${questionAttempts.length} quiz attempts locally to NeuroGraph V2');
    } catch (e) {
      debugPrint('❌ Failed to save quiz attempts locally to NeuroGraph V2: $e');
    }
  }

  /// Save flashcard study session attempts to local storage
  Future<void> saveFlashcardAttempts({
    required String studySetId,
    required String studySetTitle,
    required List<Map<String, dynamic>> flashcardAttempts,
    required DateTime sessionStartTime,
    required DateTime sessionEndTime,
  }) async {
    try {
      final userId = AuthService.instance.currentUserId;
      if (userId == null) {
        debugPrint('❌ Cannot save flashcard attempts: No authenticated user');
        return;
      }

      await _offlineRepo.initialize();

      // Save individual flashcard attempts locally
      for (int i = 0; i < flashcardAttempts.length; i++) {
        final attemptData = flashcardAttempts[i];

        final attempt = Attempt(
          userId: userId,
          testId: studySetId,
          questionId: attemptData['flashcardId'] ?? 'fc_${i}_$studySetId',
          topicId: _extractTopicFromTitle(studySetTitle),
          bloom: 'remember', // Flashcards are typically recall-based
          isCorrect: attemptData['wasCorrect'] ??
              true, // Assume correct if not specified
          score: attemptData['wasCorrect'] == true ? 1.0 : 0.0,
          responseMs: attemptData['responseTimeMs'] ?? 5000,
          timestamp: attemptData['timestamp'] ?? DateTime.now(),
          confidencePct: attemptData['confidence']?.toDouble(),
        );

        await _offlineRepo.saveAttempt(attempt);

        // Save question metadata for flashcards
        final question = Question(
          questionId: attemptData['flashcardId'] ?? 'fc_${i}_$studySetId',
          topicId: _extractTopicFromTitle(studySetTitle),
          bloom: 'remember',
          difficulty: attemptData['difficulty'] ?? 2,
          text: attemptData['front'] ?? 'Flashcard ${i + 1}',
        );

        await _offlineRepo.saveQuestion(question);
      }

      // Save session data locally
      final correctAnswers =
          flashcardAttempts.where((a) => a['wasCorrect'] != false).length;

      final session = Session(
        userId: userId,
        startedAt: sessionStartTime,
        endedAt: sessionEndTime,
        itemsSeen: flashcardAttempts.length,
        itemsCorrect: correctAnswers,
        testId: studySetId,
        sessionType: 'flashcard_study',
        subject: studySetTitle,
      );

      await _offlineRepo.saveSession(session);

      debugPrint(
          '✅ Saved ${flashcardAttempts.length} flashcard attempts locally to NeuroGraph V2');
    } catch (e) {
      debugPrint(
          '❌ Failed to save flashcard attempts locally to NeuroGraph V2: $e');
    }
  }

  /// Extract topic from study set or quiz title
  String _extractTopicFromTitle(String title) {
    // Simple topic extraction - could be enhanced with more sophisticated logic
    final cleanTitle =
        title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    final words = cleanTitle.split(' ');

    // Take first meaningful word as topic
    for (final word in words) {
      if (word.length > 3 && !_commonWords.contains(word)) {
        return word;
      }
    }

    return words.isNotEmpty ? words.first : 'general';
  }

  /// Infer Bloom's taxonomy level from question type
  String _inferBloomLevel(String questionType) {
    switch (questionType.toLowerCase()) {
      case 'multiple_choice':
      case 'true_false':
        return 'remember';
      case 'short_answer':
      case 'fill_blank':
        return 'understand';
      case 'essay':
      case 'long_answer':
        return 'analyze';
      case 'problem_solving':
        return 'apply';
      default:
        return 'remember';
    }
  }

  /// Common words to ignore when extracting topics
  static const Set<String> _commonWords = {
    'the',
    'and',
    'or',
    'but',
    'in',
    'on',
    'at',
    'to',
    'for',
    'of',
    'with',
    'by',
    'from',
    'up',
    'about',
    'into',
    'through',
    'during',
    'before',
    'after',
    'above',
    'below',
    'between',
    'among',
    'this',
    'that',
    'these',
    'those',
    'quiz',
    'test',
    'study',
    'set',
    'flashcard',
    'card',
    'review'
  };

  /// Create sample data for testing (completely offline)
  Future<void> createSampleData(String userId) async {
    try {
      await _offlineRepo.initialize();
      await _offlineRepo.createSampleData(userId);
      debugPrint(
          '✅ Created sample NeuroGraph V2 data locally for user $userId');
    } catch (e) {
      debugPrint('❌ Failed to create sample data locally: $e');
    }
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    try {
      await _offlineRepo.clearAllData();
      debugPrint('🗑️ Cleared all local NeuroGraph V2 data');
    } catch (e) {
      debugPrint('❌ Failed to clear local data: $e');
    }
  }

  /// Get data summary for debugging
  Future<Map<String, dynamic>> getDataSummary(String userId) async {
    try {
      await _offlineRepo.initialize();
      return await _offlineRepo.getUserDataSummary(userId);
    } catch (e) {
      debugPrint('❌ Failed to get data summary: $e');
      return {'error': e.toString(), 'dataAvailable': false};
    }
  }
}
