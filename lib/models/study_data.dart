import 'package:mindload/models/storage_models.dart';

class StudySet {
  final String id;
  final String title;
  final String content;
  final List<Flashcard> flashcards;
  final List<QuizQuestion>
      quizQuestions; // Direct quiz questions for generation
  final List<Quiz> quizzes; // Full quiz objects
  final DateTime createdDate;
  final DateTime lastStudied;
  final bool notificationsEnabled;
  final DateTime? deadlineDate;
  // Additional fields used by generation dialog
  final String? category;
  final String? description;
  final String? sourceType;
  final int? sourceLength;
  final List<String> tags;
  final bool isArchived;
  final String? sourceUrl;
  final StudySetType? type;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? themeColor; // Semantic theme color for the study set

  StudySet({
    required this.id,
    required this.title,
    this.content = '',
    required this.flashcards,
    this.quizQuestions = const [],
    this.quizzes = const [],
    required this.createdDate,
    required this.lastStudied,
    this.notificationsEnabled = true,
    this.deadlineDate,
    this.category,
    this.description,
    this.sourceType,
    this.sourceLength,
    this.tags = const [],
    this.isArchived = false,
    this.sourceUrl,
    this.type,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.themeColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'quizQuestions': quizQuestions.map((q) => q.toJson()).toList(),
        'quizzes': quizzes.map((q) => q.toJson()).toList(),
        'createdDate': createdDate.toIso8601String(),
        'lastStudied': lastStudied.toIso8601String(),
        'notificationsEnabled': notificationsEnabled,
        'deadlineDate': deadlineDate?.toIso8601String(),
        'category': category,
        'description': description,
        'sourceType': sourceType,
        'sourceLength': sourceLength,
        'tags': tags,
        'isArchived': isArchived,
        'sourceUrl': sourceUrl,
        'type': type?.name,
        'metadata': metadata,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'themeColor': themeColor,
      };

  factory StudySet.fromJson(Map<String, dynamic> json) => StudySet(
        id: json['id'],
        title: json['title'],
        content: json['content'] ?? '',
        flashcards: (json['flashcards'] as List? ?? [])
            .map((f) => Flashcard.fromJson(f))
            .toList(),
        quizQuestions: (json['quizQuestions'] as List? ?? [])
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
        quizzes: (json['quizzes'] as List? ?? [])
            .map((q) => Quiz.fromJson(q))
            .toList(),
        createdDate: DateTime.parse(json['createdDate']),
        lastStudied: DateTime.parse(json['lastStudied']),
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        deadlineDate: json['deadlineDate'] != null
            ? DateTime.parse(json['deadlineDate'])
            : null,
        category: json['category'],
        description: json['description'],
        sourceType: json['sourceType'],
        sourceLength: json['sourceLength'],
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        isArchived: json['isArchived'] ?? false,
        sourceUrl: json['sourceUrl'],
        type: json['type'] != null
            ? StudySetType.values.firstWhere((e) => e.name == json['type'])
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        themeColor: json['themeColor'] as String?,
      );

  StudySet copyWith({
    String? id,
    String? title,
    String? content,
    List<Flashcard>? flashcards,
    List<QuizQuestion>? quizQuestions,
    List<Quiz>? quizzes,
    DateTime? createdDate,
    DateTime? lastStudied,
    bool? notificationsEnabled,
    DateTime? deadlineDate,
    String? category,
    String? description,
    String? sourceType,
    int? sourceLength,
    List<String>? tags,
    bool? isArchived,
    String? themeColor,
  }) =>
      StudySet(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        flashcards: flashcards ?? this.flashcards,
        quizQuestions: quizQuestions ?? this.quizQuestions,
        quizzes: quizzes ?? this.quizzes,
        createdDate: createdDate ?? this.createdDate,
        lastStudied: lastStudied ?? this.lastStudied,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        deadlineDate: deadlineDate ?? this.deadlineDate,
        category: category ?? this.category,
        description: description ?? this.description,
        sourceType: sourceType ?? this.sourceType,
        sourceLength: sourceLength ?? this.sourceLength,
        tags: tags ?? this.tags,
        isArchived: isArchived ?? this.isArchived,
        themeColor: themeColor ?? this.themeColor,
      );

  // Convert to StudySetMetadata for storage
  StudySetMetadata toMetadata() {
    return StudySetMetadata(
      setId: id,
      title: title,
      content: content,
      isPinned: false, // Default value
      bytes: content.length,
      items: flashcards.length + quizQuestions.length + quizzes.length,
      lastOpenedAt: lastStudied,
      lastStudied: lastStudied,
      createdAt: createdDate,
      updatedAt: lastStudied,
      isArchived: isArchived,
    );
  }

  // Deadline utility methods
  bool get hasDeadline => deadlineDate != null;

  bool get isOverdue =>
      deadlineDate != null && deadlineDate!.isBefore(DateTime.now());

  bool get isDeadlineToday {
    if (deadlineDate == null) return false;
    final now = DateTime.now();
    final deadline = deadlineDate!;
    return deadline.year == now.year &&
        deadline.month == now.month &&
        deadline.day == now.day;
  }

  bool get isDeadlineTomorrow {
    if (deadlineDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final deadline = deadlineDate!;
    return deadline.year == tomorrow.year &&
        deadline.month == tomorrow.month &&
        deadline.day == tomorrow.day;
  }

  Duration? get timeUntilDeadline {
    if (deadlineDate == null) return null;
    final now = DateTime.now();
    if (deadlineDate!.isBefore(now)) return Duration.zero;
    return deadlineDate!.difference(now);
  }

  int? get daysUntilDeadline {
    final duration = timeUntilDeadline;
    if (duration == null) return null;
    return duration.inDays;
  }
}

enum DifficultyLevel { beginner, intermediate, advanced, expert }

enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  conceptualChallenge
}

class Flashcard {
  final String id;
  final String question;
  final String answer;
  DifficultyLevel difficulty;
  DateTime? lastReviewed;
  int reviewCount;
  int consecutiveCorrectAnswers;
  QuestionType questionType;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.difficulty = DifficultyLevel.beginner,
    this.lastReviewed,
    this.reviewCount = 0,
    this.consecutiveCorrectAnswers = 0,
    this.questionType = QuestionType.shortAnswer,
  });

  void updateDifficulty(bool wasCorrect) {
    lastReviewed = DateTime.now();
    reviewCount++;

    if (wasCorrect) {
      consecutiveCorrectAnswers++;

      // Adaptive difficulty progression
      if (consecutiveCorrectAnswers >= 3) {
        switch (difficulty) {
          case DifficultyLevel.beginner:
            difficulty = DifficultyLevel.intermediate;
            break;
          case DifficultyLevel.intermediate:
            difficulty = DifficultyLevel.advanced;
            break;
          case DifficultyLevel.advanced:
            difficulty = DifficultyLevel.expert;
            break;
          case DifficultyLevel.expert:
            // Maintain expert level
            break;
        }
        consecutiveCorrectAnswers = 0;
      }
    } else {
      consecutiveCorrectAnswers = 0;

      // Difficulty regression
      switch (difficulty) {
        case DifficultyLevel.expert:
          difficulty = DifficultyLevel.advanced;
          break;
        case DifficultyLevel.advanced:
          difficulty = DifficultyLevel.intermediate;
          break;
        case DifficultyLevel.intermediate:
          difficulty = DifficultyLevel.beginner;
          break;
        case DifficultyLevel.beginner:
          // Maintain beginner level
          break;
      }
    }
  }

  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    DifficultyLevel? difficulty,
    DateTime? lastReviewed,
    int? reviewCount,
    int? consecutiveCorrectAnswers,
    QuestionType? questionType,
  }) =>
      Flashcard(
        id: id ?? this.id,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        difficulty: difficulty ?? this.difficulty,
        lastReviewed: lastReviewed ?? this.lastReviewed,
        reviewCount: reviewCount ?? this.reviewCount,
        consecutiveCorrectAnswers:
            consecutiveCorrectAnswers ?? this.consecutiveCorrectAnswers,
        questionType: questionType ?? this.questionType,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'difficulty': difficulty.name,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'reviewCount': reviewCount,
        'consecutiveCorrectAnswers': consecutiveCorrectAnswers,
        'questionType': questionType.name,
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'],
        question: json['question'],
        answer: json['answer'],
        difficulty: DifficultyLevel.values
            .firstWhere((e) => e.name == json['difficulty']),
        lastReviewed: json['lastReviewed'] != null
            ? DateTime.parse(json['lastReviewed'])
            : null,
        reviewCount: json['reviewCount'] ?? 0,
        consecutiveCorrectAnswers: json['consecutiveCorrectAnswers'] ?? 0,
        questionType: QuestionType.values
            .firstWhere((e) => e.name == json['questionType']),
      );
}

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final QuestionType type;
  final List<QuizResult> results;
  final DateTime createdDate;
  final DifficultyLevel overallDifficulty;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    this.type = QuestionType.multipleChoice,
    this.results = const [],
    required this.createdDate,
    this.overallDifficulty = DifficultyLevel.intermediate,
  });

  DifficultyLevel calculateOverallDifficulty() {
    if (questions.isEmpty) return DifficultyLevel.beginner;

    final avgDifficulty =
        questions.map((q) => q.difficulty.index).reduce((a, b) => a + b) /
            questions.length;

    if (avgDifficulty < 1) return DifficultyLevel.beginner;
    if (avgDifficulty < 2) return DifficultyLevel.intermediate;
    if (avgDifficulty < 3) return DifficultyLevel.advanced;
    return DifficultyLevel.expert;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'type': type.name,
        'results': results.map((r) => r.toJson()).toList(),
        'createdDate': createdDate.toIso8601String(),
        'overallDifficulty': overallDifficulty.name,
      };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'],
        title: json['title'],
        questions: (json['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
        type: QuestionType.values.firstWhere((e) => e.name == json['type']),
        results: (json['results'] as List)
            .map((r) => QuizResult.fromJson(r))
            .toList(),
        createdDate: DateTime.parse(json['createdDate']),
        overallDifficulty: DifficultyLevel.values
            .firstWhere((e) => e.name == json['overallDifficulty']),
      );
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final QuestionType type;
  DifficultyLevel difficulty;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.type = QuestionType.multipleChoice,
    this.difficulty = DifficultyLevel.intermediate,
  });

  void adjustDifficulty(bool wasCorrect) {
    if (wasCorrect) {
      switch (difficulty) {
        case DifficultyLevel.beginner:
          difficulty = DifficultyLevel.intermediate;
          break;
        case DifficultyLevel.intermediate:
          difficulty = DifficultyLevel.advanced;
          break;
        case DifficultyLevel.advanced:
          difficulty = DifficultyLevel.expert;
          break;
        case DifficultyLevel.expert:
          // Maintain expert level
          break;
      }
    } else {
      switch (difficulty) {
        case DifficultyLevel.expert:
          difficulty = DifficultyLevel.advanced;
          break;
        case DifficultyLevel.advanced:
          difficulty = DifficultyLevel.intermediate;
          break;
        case DifficultyLevel.intermediate:
          difficulty = DifficultyLevel.beginner;
          break;
        case DifficultyLevel.beginner:
          // Maintain beginner level
          break;
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'type': type.name,
        'difficulty': difficulty.name,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'],
        question: json['question'],
        options: List<String>.from(json['options']),
        correctAnswer: json['correctAnswer'],
        type: QuestionType.values.firstWhere((e) => e.name == json['type']),
        difficulty: DifficultyLevel.values
            .firstWhere((e) => e.name == json['difficulty']),
      );
}

class QuizResult {
  final String questionId;
  final bool wasCorrect;
  final DateTime answeredAt;
  final Duration? responseTime;

  QuizResult({
    required this.questionId,
    required this.wasCorrect,
    required this.answeredAt,
    this.responseTime,
  });

  // Add percentage getter
  double get percentage => wasCorrect ? 100.0 : 0.0;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'wasCorrect': wasCorrect,
        'answeredAt': answeredAt.toIso8601String(),
        'responseTime': responseTime?.inMilliseconds,
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        questionId: json['questionId'],
        wasCorrect: json['wasCorrect'],
        answeredAt: DateTime.parse(json['answeredAt']),
        responseTime: json['responseTime'] != null
            ? Duration(milliseconds: json['responseTime'])
            : null,
      );
}

class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final int totalXP;
  final int totalStudyTime;
  final List<QuizResult> recentResults;
  final DateTime lastStudyDate;
  final Map<String, int> subjectXP;

  UserProgress({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXP,
    required this.totalStudyTime,
    required this.recentResults,
    required this.lastStudyDate,
    required this.subjectXP,
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalXP': totalXP,
        'totalStudyTime': totalStudyTime,
        'recentResults': recentResults.map((r) => r.toJson()).toList(),
        'lastStudyDate': lastStudyDate.toIso8601String(),
        'subjectXP': subjectXP,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        currentStreak: json['currentStreak'],
        longestStreak: json['longestStreak'],
        totalXP: json['totalXP'],
        totalStudyTime: json['totalStudyTime'],
        recentResults: (json['recentResults'] as List)
            .map((r) => QuizResult.fromJson(r))
            .toList(),
        lastStudyDate: DateTime.parse(json['lastStudyDate']),
        subjectXP: Map<String, int>.from(json['subjectXP']),
      );

  UserProgress copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalXP,
    int? totalStudyTime,
    List<QuizResult>? recentResults,
    DateTime? lastStudyDate,
    Map<String, int>? subjectXP,
  }) =>
      UserProgress(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        totalXP: totalXP ?? this.totalXP,
        totalStudyTime: totalStudyTime ?? this.totalStudyTime,
        recentResults: recentResults ?? this.recentResults,
        lastStudyDate: lastStudyDate ?? this.lastStudyDate,
        subjectXP: subjectXP ?? this.subjectXP,
      );

  int get level => (totalXP / 1000).floor() + 1;
  int get xpToNextLevel => 1000 - (totalXP % 1000);
}

enum StudySetType {
  quiz,
  flashcards,
  both,
  youtube,
  document,
  custom,
}
