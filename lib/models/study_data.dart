import 'package:mindload/models/storage_models.dart';

class StudySet {
  final String id;
  final String title;
  final String content;
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quizQuestions; // Direct quiz questions for generation
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
  };

  factory StudySet.fromJson(Map<String, dynamic> json) => StudySet(
    id: json['id'],
    title: json['title'],
    content: json['content'] ?? '',
    flashcards: (json['flashcards'] as List? ?? []).map((f) => Flashcard.fromJson(f)).toList(),
    quizQuestions: (json['quizQuestions'] as List? ?? []).map((q) => QuizQuestion.fromJson(q)).toList(),
    quizzes: (json['quizzes'] as List? ?? []).map((q) => Quiz.fromJson(q)).toList(),
    createdDate: DateTime.parse(json['createdDate']),
    lastStudied: DateTime.parse(json['lastStudied']),
    notificationsEnabled: json['notificationsEnabled'] ?? true,
    deadlineDate: json['deadlineDate'] != null ? DateTime.parse(json['deadlineDate']) : null,
    category: json['category'],
    description: json['description'],
    sourceType: json['sourceType'],
    sourceLength: json['sourceLength'],
    tags: (json['tags'] as List?)?.cast<String>() ?? [],
    isArchived: json['isArchived'] ?? false,
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
  }) => StudySet(
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
  
  bool get isOverdue => deadlineDate != null && deadlineDate!.isBefore(DateTime.now());
  
  bool get isDeadlineToday {
    if (deadlineDate == null) return false;
    final now = DateTime.now();
    final deadline = deadlineDate!;
    return deadline.year == now.year && deadline.month == now.month && deadline.day == now.day;
  }
  
  bool get isDeadlineTomorrow {
    if (deadlineDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final deadline = deadlineDate!;
    return deadline.year == tomorrow.year && deadline.month == tomorrow.month && deadline.day == tomorrow.day;
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

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final DifficultyLevel difficulty;
  final DateTime? lastReviewed;
  final int reviewCount;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.difficulty,
    this.lastReviewed,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'difficulty': difficulty.name,
    'lastReviewed': lastReviewed?.toIso8601String(),
    'reviewCount': reviewCount,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'],
    question: json['question'],
    answer: json['answer'],
    difficulty: DifficultyLevel.values.firstWhere((e) => e.name == json['difficulty']),
    lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed']) : null,
    reviewCount: json['reviewCount'] ?? 0,
  );

  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    DifficultyLevel? difficulty,
    DateTime? lastReviewed,
    int? reviewCount,
  }) => Flashcard(
    id: id ?? this.id,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    difficulty: difficulty ?? this.difficulty,
    lastReviewed: lastReviewed ?? this.lastReviewed,
    reviewCount: reviewCount ?? this.reviewCount,
  );
}

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final QuizType type;
  final List<QuizResult> results;
  final DateTime createdDate;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    required this.type,
    required this.results,
    required this.createdDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'questions': questions.map((q) => q.toJson()).toList(),
    'type': type.name,
    'results': results.map((r) => r.toJson()).toList(),
    'createdDate': createdDate.toIso8601String(),
  };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    id: json['id'],
    title: json['title'],
    questions: (json['questions'] as List).map((q) => QuizQuestion.fromJson(q)).toList(),
    type: QuizType.values.firstWhere((e) => e.name == json['type']),
    results: (json['results'] as List).map((r) => QuizResult.fromJson(r)).toList(),
    createdDate: DateTime.parse(json['createdDate']),
  );
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final QuizType type;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'type': type.name,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: json['id'],
    question: json['question'],
    options: List<String>.from(json['options']),
    correctAnswer: json['correctAnswer'],
    type: QuizType.values.firstWhere((e) => e.name == json['type']),
  );
}

class QuizResult {
  final String id;
  final int score;
  final int totalQuestions;
  final Duration timeTaken;
  final DateTime completedDate;
  final List<String> incorrectAnswers;

  QuizResult({
    required this.id,
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
    required this.completedDate,
    required this.incorrectAnswers,
  });

  double get percentage => (score / totalQuestions) * 100;

  Map<String, dynamic> toJson() => {
    'id': id,
    'score': score,
    'totalQuestions': totalQuestions,
    'timeTaken': timeTaken.inMilliseconds,
    'completedDate': completedDate.toIso8601String(),
    'incorrectAnswers': incorrectAnswers,
  };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    id: json['id'],
    score: json['score'],
    totalQuestions: json['totalQuestions'],
    timeTaken: Duration(milliseconds: json['timeTaken']),
    completedDate: DateTime.parse(json['completedDate']),
    incorrectAnswers: List<String>.from(json['incorrectAnswers']),
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
    recentResults: (json['recentResults'] as List).map((r) => QuizResult.fromJson(r)).toList(),
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
  }) => UserProgress(
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

enum DifficultyLevel { easy, medium, hard }

enum QuizType { multipleChoice, trueFalse, shortAnswer }

enum StudySetType {
  quiz,
  flashcards,
  both,
}