import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/firestore/firestore_data_schema.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/openai_service.dart';
import 'package:mindload/services/credit_service.dart';

/// Firebase-integrated Study Service
/// Manages study sets, progress tracking, and cloud synchronization
class FirebaseStudyService extends ChangeNotifier {
  static FirebaseStudyService? _instance;
  static FirebaseStudyService get instance {
    _instance ??= FirebaseStudyService._internal();
    return _instance!;
  }

  FirebaseStudyService._internal();

  final FirestoreRepository _repository = FirestoreRepository.instance;
  final AuthService _authService = AuthService.instance;
  final OpenAIService _openAIService = OpenAIService.instance;
  final CreditService _creditService = CreditService.instance;

  List<StudySet> _studySets = [];
  UserProgress? _userProgress;
  bool _isLoading = false;

  List<StudySet> get studySets => _studySets;
  UserProgress? get userProgress => _userProgress;
  bool get isLoading => _isLoading;

  /// Initialize the service and load user data
  Future<void> initialize() async {
    if (_authService.isAuthenticated) {
      await loadUserStudySets();
      await loadUserProgress();
    }
  }

  /// Load user's study sets from Firestore
  Future<void> loadUserStudySets() async {
    if (!_authService.isAuthenticated) return;

    try {
      _isLoading = true;
      notifyListeners();

      final userId = _authService.currentUser!.uid;
      _repository.getUserStudySets(userId).listen((firestoreStudySets) {
        _studySets = firestoreStudySets.map((fs) => fs.toStudySet()).toList();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error loading study sets: $e');
      }
      rethrow;
    }
  }

  /// Create a new study set from document content
  Future<StudySet> createStudySet({
    required String title,
    required String content,
    required String fileName,
    required String fileType,
    List<String> tags = const [],
    String difficulty = 'medium',
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('User must be authenticated to create study sets');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _authService.currentUser!.uid;
      
      // Check if user has enough credits
      final canUseCredits = await _creditService.canUseCredits(3); // Estimate 3 credits for generation
      if (!canUseCredits) {
        throw Exception('Insufficient credits. Please upgrade your plan or wait until tomorrow.');
      }

      // Generate study content with OpenAI
      final flashcards = await _generateFlashcards(content);
      final quizzes = await _generateQuizzes(content);

      // Create study set
      final studySet = StudySet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        flashcards: flashcards,
        quizzes: quizzes,
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
      );

      // Save to Firestore
      final firestoreStudySet = StudySetFirestore.fromStudySet(
        studySet,
        userId,
        originalFileName: fileName,
        fileType: fileType,
        tags: tags,
        difficulty: difficulty,
      );

      await _repository.createStudySet(firestoreStudySet);
      
      // Update user progress
      await _addXP(userId, 50, 'Study Set Created');
      
      _isLoading = false;
      notifyListeners();
      
      return studySet;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error creating study set: $e');
      }
      rethrow;
    }
  }

  /// Generate flashcards using OpenAI
  Future<List<Flashcard>> _generateFlashcards(String content) async {
    try {
      final prompt = """
Generate 10 high-quality flashcards from this content. Return as JSON array with structure:
[{"question": "...", "answer": "...", "difficulty": "easy|medium|hard"}]

Content:
$content
""";

      // Check if user can generate flashcards
      if (!await _creditService.canGenerateStudySet(StudySetType.flashcards)) {
        throw Exception('Not enough credits to generate flashcards');
      }
      
      final flashcards = await _openAIService.generateFlashcards(content, count: 10);
      return flashcards;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating flashcards: $e');
      }
      // Return sample flashcards if generation fails
      // Try to generate AI flashcards if content is available
      if (content.isNotEmpty) {
        return await _generateAIFlashcards(content);
      }
      return [];
    }
  }

  /// Generate quizzes using OpenAI
  Future<List<Quiz>> _generateQuizzes(String content) async {
    try {
      // Check if user can generate quiz
      if (!await _creditService.canGenerateStudySet(StudySetType.quiz)) {
        throw Exception('Not enough credits to generate quiz');
      }
      
      final List<Quiz> quizzes = [];
      
      // Generate different types of quizzes using the OpenAI service
      final mcQuestions = await _openAIService.generateQuiz(content, count: 5);
      final tfQuestions = await _openAIService.generateQuiz(content, count: 5);
      final saQuestions = await _openAIService.generateQuiz(content, count: 5);
      
      // Create Quiz objects from the question lists
      if (mcQuestions.isNotEmpty) {
        quizzes.add(Quiz(
          id: 'mc_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Multiple Choice Quiz',
          questions: mcQuestions,
          type: QuizType.multipleChoice,
          results: [],
          createdDate: DateTime.now(),
        ));
      }
      
      if (tfQuestions.isNotEmpty) {
        quizzes.add(Quiz(
          id: 'tf_${DateTime.now().millisecondsSinceEpoch}',
          title: 'True/False Quiz',
          questions: tfQuestions,
          type: QuizType.trueFalse,
          results: [],
          createdDate: DateTime.now(),
        ));
      }
      
      if (saQuestions.isNotEmpty) {
        quizzes.add(Quiz(
          id: 'sa_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Short Answer Quiz',
          questions: saQuestions,
          type: QuizType.shortAnswer,
          results: [],
          createdDate: DateTime.now(),
        ));
      }
      
      return quizzes;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating quizzes: $e');
      }
      // Return sample quizzes if generation fails
      // Try to generate AI quizzes if content is available
      if (content.isNotEmpty) {
        return await _generateAIQuizzes(content);
      }
      return [];
    }
  }

  /// Mark study set as studied and update progress
  Future<void> markAsStudied(String studySetId) async {
    if (!_authService.isAuthenticated) return;

    try {
      await _repository.markStudySetAsStudied(studySetId);
      
      final userId = _authService.currentUser!.uid;
      await _addXP(userId, 25, 'Study Session');
      await _updateStreak(userId);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error marking study set as studied: $e');
      }
      rethrow;
    }
  }

  /// Save quiz result
  Future<void> saveQuizResult(String studySetId, QuizResult result) async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.uid;
      
      final firestoreResult = QuizResultFirestore(
        id: result.id,
        userId: userId,
        studySetId: studySetId,
        quizId: DateTime.now().millisecondsSinceEpoch.toString(),
        quizTitle: 'Quiz Result',
        score: result.score,
        totalQuestions: result.totalQuestions,
        percentage: result.percentage,
        timeTaken: result.timeTaken.inMilliseconds,
        completedDate: result.completedDate,
        incorrectAnswers: result.incorrectAnswers,
        quizType: 'mixed',
        answers: {},
        xpEarned: _calculateXPFromQuiz(result),
      );
      
      await _repository.saveQuizResult(firestoreResult);
      
      // Update user progress with XP
      await _addXP(userId, firestoreResult.xpEarned, 'Quiz Completed');
      
    } catch (e) {
      if (kDebugMode) {
        print('Error saving quiz result: $e');
      }
      rethrow;
    }
  }

  /// Load user progress from Firestore
  Future<void> loadUserProgress() async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.uid;
      final firestoreProgress = await _repository.getUserProgress(userId);
      
      // Get recent quiz results
      final recentResults = await _repository.getUserQuizResults(userId, limit: 10)
          .first
          .then((results) => results.map((r) => r.toQuizResult()).toList());
      
      _userProgress = firestoreProgress.toUserProgress(recentResults);
      notifyListeners();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user progress: $e');
      }
    }
  }

  /// Delete a study set
  Future<void> deleteStudySet(String studySetId) async {
    if (!_authService.isAuthenticated) return;

    try {
      await _repository.deleteStudySet(studySetId);
      _studySets.removeWhere((set) => set.id == studySetId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting study set: $e');
      }
      rethrow;
    }
  }

  // MARK: - Helper Methods

  /// Add XP to user progress
  Future<void> _addXP(String userId, int xp, String reason) async {
    try {
      await _repository.addXP(userId, xp);
      await loadUserProgress(); // Refresh progress
    } catch (e) {
      if (kDebugMode) {
        print('Error adding XP: $e');
      }
    }
  }

  /// Update user study streak
  Future<void> _updateStreak(String userId) async {
    try {
      final progress = await _repository.getUserProgress(userId);
      final now = DateTime.now();
      final lastStudy = progress.lastStudyDate;
      
      final daysDiff = now.difference(lastStudy).inDays;
      
      int newStreak;
      if (daysDiff == 0) {
        // Same day, keep streak
        newStreak = progress.currentStreak;
      } else if (daysDiff == 1) {
        // Next day, increment streak
        newStreak = progress.currentStreak + 1;
      } else {
        // Streak broken, reset to 1
        newStreak = 1;
      }
      
      final longestStreak = newStreak > progress.longestStreak ? newStreak : progress.longestStreak;
      
      await _repository.updateStreak(userId, newStreak, longestStreak);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating streak: $e');
      }
    }
  }

  /// Calculate XP earned from quiz performance
  int _calculateXPFromQuiz(QuizResult result) {
    final baseXP = result.totalQuestions * 10;
    final performanceMultiplier = result.percentage / 100;
    final timeBonus = result.timeTaken.inMinutes < 5 ? 20 : 0;
    
    return (baseXP * performanceMultiplier + timeBonus).round();
  }

  /// Parse difficulty string to enum
  DifficultyLevel _parseDifficulty(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.medium;
    }
  }


  /// Generate flashcards using AI from study content
  Future<List<Flashcard>> _generateAIFlashcards(String content, {int count = 10}) async {
    try {
      // Call Firebase Cloud Function for AI generation
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('generateFlashcards').call({
        'content': content,
        'count': count,
        'difficulty': 'mixed', // Generate mixed difficulty levels
      });

      final flashcardsData = result.data['flashcards'] as List<dynamic>? ?? [];
      
      return flashcardsData.map((data) => Flashcard(
        id: '${DateTime.now().millisecondsSinceEpoch}_${flashcardsData.indexOf(data)}',
        question: data['question'] ?? 'Generated question',
        answer: data['answer'] ?? 'Generated answer',
        difficulty: _parseDifficulty(data['difficulty']),
      )).toList();
    } catch (e) {
      debugPrint('Error generating AI flashcards: $e');
      // Return empty list instead of sample data
      return [];
    }
  }

  /// Generate quizzes using AI from study content
  Future<List<Quiz>> _generateAIQuizzes(String content, {int questionCount = 5}) async {
    try {
      // Call Firebase Cloud Function for AI generation
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('generateQuiz').call({
        'content': content,
        'questionCount': questionCount,
        'type': 'multipleChoice',
      });

      final quizData = result.data['quiz'] as Map<String, dynamic>? ?? {};
      final questionsData = quizData['questions'] as List<dynamic>? ?? [];
      
      if (questionsData.isNotEmpty) {
        final questions = questionsData.map((q) => QuizQuestion(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}_${questionsData.indexOf(q)}',
          question: q['question'] ?? 'Generated question',
          options: List<String>.from(q['options'] ?? ['Option A', 'Option B', 'Option C', 'Option D']),
          correctAnswer: q['correctAnswer'] ?? 'Option A',
          type: QuizType.multipleChoice,
        )).toList();

        return [
          Quiz(
            id: '${DateTime.now().millisecondsSinceEpoch}_ai_generated',
            title: quizData['title'] ?? 'AI Generated Quiz',
            questions: questions,
            type: QuizType.multipleChoice,
            results: [],
            createdDate: DateTime.now(),
          ),
        ];
      }
      
      return [];
    } catch (e) {
      debugPrint('Error generating AI quiz: $e');
      // Return empty list instead of sample data
      return [];
    }
  }





  /// Clear all data when user logs out
  void clearData() {
    _studySets.clear();
    _userProgress = null;
    _isLoading = false;
    notifyListeners();
  }
}