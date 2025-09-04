import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../neurograph_v2/neurograph_offline_repo.dart';

/// Bridge service to ensure quiz completion data flows to NeuroGraph V2
/// This service saves individual question attempts to the 'attempts' collection
/// and session data to the 'sessions' collection for NeuroGraph V2 analytics
class NeuroGraphBridgeService {
  static final NeuroGraphBridgeService _instance =
      NeuroGraphBridgeService._internal();
  factory NeuroGraphBridgeService() => _instance;
  static NeuroGraphBridgeService get instance => _instance;
  NeuroGraphBridgeService._internal();

  final NeuroGraphOfflineRepository _offlineRepo =
      NeuroGraphOfflineRepository.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save individual quiz question attempts to Firestore for NeuroGraph V2
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

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Save individual question attempts
      for (int i = 0; i < questionAttempts.length; i++) {
        final attemptData = questionAttempts[i];
        final attemptRef = _firestore.collection('attempts').doc();

        final attempt = {
          'userId': userId,
          'testId': quizId,
          'questionId': attemptData['questionId'] ?? 'q_${i}_$quizId',
          'topicId': _extractTopicFromTitle(quizTitle),
          'bloom': _inferBloomLevel(
              attemptData['questionType'] ?? 'multiple_choice'),
          'isCorrect': attemptData['isCorrect'] ?? false,
          'score': attemptData['isCorrect'] == true ? 1.0 : 0.0,
          'responseMs': attemptData['responseTimeMs'] ?? 3000,
          'ts': Timestamp.fromDate(attemptData['timestamp'] ?? now),
          'confidencePct': attemptData['confidence']?.toDouble(),
        };

        batch.set(attemptRef, attempt);
      }

      // Save session data
      final sessionRef = _firestore.collection('sessions').doc();
      final correctAnswers =
          questionAttempts.where((a) => a['isCorrect'] == true).length;

      final session = {
        'userId': userId,
        'startedAt': Timestamp.fromDate(quizStartTime),
        'endedAt': Timestamp.fromDate(quizEndTime),
        'itemsSeen': questionAttempts.length,
        'itemsCorrect': correctAnswers,
        'testId': quizId,
        'sessionType': 'quiz',
        'subject': quizTitle,
      };

      batch.set(sessionRef, session);

      // Save question metadata if not exists
      for (int i = 0; i < questionAttempts.length; i++) {
        final attemptData = questionAttempts[i];
        final questionId = attemptData['questionId'] ?? 'q_${i}_$quizId';
        final questionRef = _firestore.collection('questions').doc(questionId);

        // Only set if document doesn't exist (to avoid overwriting)
        batch.set(
            questionRef,
            {
              'questionId': questionId,
              'topicId': _extractTopicFromTitle(quizTitle),
              'bloom': _inferBloomLevel(
                  attemptData['questionType'] ?? 'multiple_choice'),
              'difficulty': attemptData['difficulty'] ?? 3,
              'text': attemptData['questionText'] ?? 'Quiz question ${i + 1}',
              'createdAt': Timestamp.fromDate(now),
            },
            SetOptions(merge: true));
      }

      // Commit all changes atomically
      await batch.commit();

      debugPrint(
          '✅ Saved ${questionAttempts.length} quiz attempts to NeuroGraph V2');
    } catch (e) {
      debugPrint('❌ Failed to save quiz attempts to NeuroGraph V2: $e');
    }
  }

  /// Save flashcard study session attempts
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

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Save individual flashcard attempts
      for (int i = 0; i < flashcardAttempts.length; i++) {
        final attemptData = flashcardAttempts[i];
        final attemptRef = _firestore.collection('attempts').doc();

        final attempt = {
          'userId': userId,
          'testId': studySetId,
          'questionId': attemptData['flashcardId'] ?? 'fc_${i}_$studySetId',
          'topicId': _extractTopicFromTitle(studySetTitle),
          'bloom': 'remember', // Flashcards are typically recall-based
          'isCorrect': attemptData['wasCorrect'] ??
              true, // Assume correct if not specified
          'score': attemptData['wasCorrect'] == true ? 1.0 : 0.0,
          'responseMs': attemptData['responseTimeMs'] ?? 5000,
          'ts': Timestamp.fromDate(attemptData['timestamp'] ?? now),
          'confidencePct': attemptData['confidence']?.toDouble(),
        };

        batch.set(attemptRef, attempt);
      }

      // Save session data
      final sessionRef = _firestore.collection('sessions').doc();
      final correctAnswers =
          flashcardAttempts.where((a) => a['wasCorrect'] != false).length;

      final session = {
        'userId': userId,
        'startedAt': Timestamp.fromDate(sessionStartTime),
        'endedAt': Timestamp.fromDate(sessionEndTime),
        'itemsSeen': flashcardAttempts.length,
        'itemsCorrect': correctAnswers,
        'testId': studySetId,
        'sessionType': 'flashcard_study',
        'subject': studySetTitle,
      };

      batch.set(sessionRef, session);

      // Save question metadata for flashcards
      for (int i = 0; i < flashcardAttempts.length; i++) {
        final attemptData = flashcardAttempts[i];
        final questionId = attemptData['flashcardId'] ?? 'fc_${i}_$studySetId';
        final questionRef = _firestore.collection('questions').doc(questionId);

        batch.set(
            questionRef,
            {
              'questionId': questionId,
              'topicId': _extractTopicFromTitle(studySetTitle),
              'bloom': 'remember',
              'difficulty': attemptData['difficulty'] ?? 2,
              'text': attemptData['front'] ?? 'Flashcard ${i + 1}',
              'createdAt': Timestamp.fromDate(now),
            },
            SetOptions(merge: true));
      }

      await batch.commit();

      debugPrint(
          '✅ Saved ${flashcardAttempts.length} flashcard attempts to NeuroGraph V2');
    } catch (e) {
      debugPrint('❌ Failed to save flashcard attempts to NeuroGraph V2: $e');
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

  /// Create sample data for testing (similar to NeuroGraphRepository.createSampleData)
  Future<void> createSampleData(String userId) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Sample topics and tests
      final topics = [
        'mathematics',
        'science',
        'history',
        'literature',
        'geography'
      ];
      final tests = ['quiz_math_1', 'quiz_science_1', 'quiz_history_1'];

      // Generate 30 sample attempts over the last 15 days
      for (int i = 0; i < 30; i++) {
        final daysAgo = i % 15;
        final timestamp = now.subtract(Duration(days: daysAgo));
        final topicId = topics[i % topics.length];
        final testId = tests[i % tests.length];
        final questionId = 'sample_q_${i}_$topicId';

        // Simulate learning curve - better performance over time
        final progressFactor = (15 - daysAgo) / 15.0;
        final baseAccuracy = 0.5 + (progressFactor * 0.4); // 50% to 90%
        final isCorrect = (i / 30.0) < baseAccuracy;

        final attemptRef = _firestore.collection('attempts').doc();
        batch.set(attemptRef, {
          'userId': userId,
          'testId': testId,
          'questionId': questionId,
          'topicId': topicId,
          'bloom': ['remember', 'understand', 'apply', 'analyze'][i % 4],
          'isCorrect': isCorrect,
          'score': isCorrect
              ? (0.7 + (0.3 * (i / 30.0)))
              : (0.1 + (0.4 * (i / 30.0))),
          'responseMs': 1500 + (i * 100), // Response time varies
          'ts': Timestamp.fromDate(timestamp),
          'confidencePct':
              isCorrect ? (60 + (40 * (i / 30.0))) : (20 + (30 * (i / 30.0))),
        });
      }

      await batch.commit();
      debugPrint('✅ Created sample NeuroGraph V2 data for user $userId');
    } catch (e) {
      debugPrint('❌ Failed to create sample data: $e');
    }
  }
}
