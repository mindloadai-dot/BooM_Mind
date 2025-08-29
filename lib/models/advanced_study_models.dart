import 'package:mindload/models/study_data.dart';

/// Enhanced Flashcard model supporting the new advanced schema
/// with anchors, hints, explanations, and Bloom's taxonomy
class AdvancedFlashcard {
  final String id;
  final String type; // mcq, qa, truefalse
  final String bloom; // Understand, Apply, Analyze, Evaluate, Create
  final String difficulty; // easy, medium, hard
  final String question;
  final List<String> choices; // Empty for QA type
  final int correctIndex; // 0 for QA type
  final String answerExplanation;
  final String hint;
  final List<String> anchors; // For spaced repetition/tagging
  final String sourceSpan; // Reference to source material

  // Learning tracking fields
  DateTime? lastReviewed;
  int reviewCount;
  int consecutiveCorrectAnswers;
  double confidenceScore; // 0.0 to 1.0

  AdvancedFlashcard({
    required this.id,
    required this.type,
    required this.bloom,
    required this.difficulty,
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.answerExplanation,
    required this.hint,
    required this.anchors,
    required this.sourceSpan,
    this.lastReviewed,
    this.reviewCount = 0,
    this.consecutiveCorrectAnswers = 0,
    this.confidenceScore = 0.0,
  });

  /// Convert from legacy Flashcard model
  factory AdvancedFlashcard.fromLegacyFlashcard(Flashcard flashcard) {
    return AdvancedFlashcard(
      id: flashcard.id,
      type: 'qa',
      bloom: _mapDifficultyToBloom(flashcard.difficulty),
      difficulty: _mapDifficultyLevelToString(flashcard.difficulty),
      question: flashcard.question,
      choices: [],
      correctIndex: 0,
      answerExplanation: flashcard.answer,
      hint: 'Think about the key concepts involved.',
      anchors: _extractAnchorsFromQuestion(flashcard.question),
      sourceSpan: 'Converted from legacy flashcard',
      lastReviewed: flashcard.lastReviewed,
      reviewCount: flashcard.reviewCount,
      consecutiveCorrectAnswers: flashcard.consecutiveCorrectAnswers,
      confidenceScore: _calculateConfidenceScore(
        flashcard.consecutiveCorrectAnswers,
        flashcard.reviewCount,
      ),
    );
  }

  /// Convert from generation schema
  factory AdvancedFlashcard.fromGenerationSchema(Map<String, dynamic> schema) {
    return AdvancedFlashcard(
      id: schema['id'] as String,
      type: schema['type'] as String,
      bloom: schema['bloom'] as String,
      difficulty: schema['difficulty'] as String,
      question: schema['question'] as String,
      choices: List<String>.from(schema['choices'] ?? []),
      correctIndex: schema['correct_index'] as int? ?? 0,
      answerExplanation: schema['answer_explanation'] as String,
      hint: schema['hint'] as String,
      anchors: List<String>.from(schema['anchors'] ?? []),
      sourceSpan: schema['source_span'] as String? ?? 'Generated content',
    );
  }

  /// Update learning metrics based on performance
  void updateLearningMetrics(bool wasCorrect, Duration responseTime) {
    lastReviewed = DateTime.now();
    reviewCount++;

    if (wasCorrect) {
      consecutiveCorrectAnswers++;

      // Boost confidence based on consecutive correct answers
      confidenceScore = (confidenceScore + 0.2).clamp(0.0, 1.0);

      // Additional boost for quick responses
      if (responseTime.inSeconds < 10) {
        confidenceScore = (confidenceScore + 0.1).clamp(0.0, 1.0);
      }
    } else {
      consecutiveCorrectAnswers = 0;

      // Reduce confidence
      confidenceScore = (confidenceScore - 0.3).clamp(0.0, 1.0);
    }
  }

  /// Get the correct answer text
  String get correctAnswer {
    if (type == 'qa') {
      return answerExplanation;
    } else if (choices.isNotEmpty && correctIndex < choices.length) {
      return choices[correctIndex];
    }
    return 'No answer available';
  }

  /// Check if this is a scenario-based question
  bool get isScenarioBased {
    final questionLower = question.toLowerCase();
    return questionLower.contains('scenario') ||
        questionLower.contains('situation') ||
        questionLower.contains('if you') ||
        questionLower.contains('what would happen') ||
        questionLower.contains('in the case');
  }

  /// Get Bloom level as enum for easier handling
  BloomLevel get bloomLevel {
    switch (bloom.toLowerCase()) {
      case 'understand':
        return BloomLevel.understand;
      case 'apply':
        return BloomLevel.apply;
      case 'analyze':
        return BloomLevel.analyze;
      case 'evaluate':
        return BloomLevel.evaluate;
      case 'create':
        return BloomLevel.create;
      default:
        return BloomLevel.understand;
    }
  }

  /// Get difficulty as enum
  CardDifficulty get cardDifficulty {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return CardDifficulty.easy;
      case 'medium':
        return CardDifficulty.medium;
      case 'hard':
        return CardDifficulty.hard;
      default:
        return CardDifficulty.medium;
    }
  }

  /// Convert to legacy Flashcard for compatibility
  Flashcard toLegacyFlashcard() {
    return Flashcard(
      id: id,
      question: question,
      answer: correctAnswer,
      difficulty: _mapStringToDifficultyLevel(difficulty),
      lastReviewed: lastReviewed,
      reviewCount: reviewCount,
      consecutiveCorrectAnswers: consecutiveCorrectAnswers,
      questionType: type == 'mcq'
          ? QuestionType.multipleChoice
          : QuestionType.shortAnswer,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'bloom': bloom,
        'difficulty': difficulty,
        'question': question,
        'choices': choices,
        'correct_index': correctIndex,
        'answer_explanation': answerExplanation,
        'hint': hint,
        'anchors': anchors,
        'source_span': sourceSpan,
        'last_reviewed': lastReviewed?.toIso8601String(),
        'review_count': reviewCount,
        'consecutive_correct_answers': consecutiveCorrectAnswers,
        'confidence_score': confidenceScore,
      };

  factory AdvancedFlashcard.fromJson(Map<String, dynamic> json) =>
      AdvancedFlashcard(
        id: json['id'] as String,
        type: json['type'] as String,
        bloom: json['bloom'] as String,
        difficulty: json['difficulty'] as String,
        question: json['question'] as String,
        choices: List<String>.from(json['choices'] ?? []),
        correctIndex: json['correct_index'] as int? ?? 0,
        answerExplanation: json['answer_explanation'] as String,
        hint: json['hint'] as String,
        anchors: List<String>.from(json['anchors'] ?? []),
        sourceSpan: json['source_span'] as String? ?? '',
        lastReviewed: json['last_reviewed'] != null
            ? DateTime.parse(json['last_reviewed'])
            : null,
        reviewCount: json['review_count'] as int? ?? 0,
        consecutiveCorrectAnswers:
            json['consecutive_correct_answers'] as int? ?? 0,
        confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      );

  AdvancedFlashcard copyWith({
    String? id,
    String? type,
    String? bloom,
    String? difficulty,
    String? question,
    List<String>? choices,
    int? correctIndex,
    String? answerExplanation,
    String? hint,
    List<String>? anchors,
    String? sourceSpan,
    DateTime? lastReviewed,
    int? reviewCount,
    int? consecutiveCorrectAnswers,
    double? confidenceScore,
  }) =>
      AdvancedFlashcard(
        id: id ?? this.id,
        type: type ?? this.type,
        bloom: bloom ?? this.bloom,
        difficulty: difficulty ?? this.difficulty,
        question: question ?? this.question,
        choices: choices ?? this.choices,
        correctIndex: correctIndex ?? this.correctIndex,
        answerExplanation: answerExplanation ?? this.answerExplanation,
        hint: hint ?? this.hint,
        anchors: anchors ?? this.anchors,
        sourceSpan: sourceSpan ?? this.sourceSpan,
        lastReviewed: lastReviewed ?? this.lastReviewed,
        reviewCount: reviewCount ?? this.reviewCount,
        consecutiveCorrectAnswers:
            consecutiveCorrectAnswers ?? this.consecutiveCorrectAnswers,
        confidenceScore: confidenceScore ?? this.confidenceScore,
      );

  // Helper methods
  static String _mapDifficultyToBloom(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Understand';
      case DifficultyLevel.intermediate:
        return 'Apply';
      case DifficultyLevel.advanced:
        return 'Analyze';
      case DifficultyLevel.expert:
        return 'Evaluate';
    }
  }

  static String _mapDifficultyLevelToString(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'easy';
      case DifficultyLevel.intermediate:
        return 'medium';
      case DifficultyLevel.advanced:
      case DifficultyLevel.expert:
        return 'hard';
    }
  }

  static DifficultyLevel _mapStringToDifficultyLevel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.beginner;
      case 'medium':
        return DifficultyLevel.intermediate;
      case 'hard':
        return DifficultyLevel.advanced;
      default:
        return DifficultyLevel.intermediate;
    }
  }

  static List<String> _extractAnchorsFromQuestion(String question) {
    final words = question.split(' ');
    final anchors = <String>[];

    for (final word in words) {
      if (word.length > 4 && !_isStopWord(word.toLowerCase())) {
        anchors.add(word.replaceAll(RegExp(r'[^\w]'), ''));
        if (anchors.length >= 3) break;
      }
    }

    return anchors;
  }

  static bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'a',
      'an',
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
      'is',
      'are',
      'was',
      'were',
      'what',
      'when',
      'where',
      'why',
      'how',
      'which',
      'this',
      'that',
      'these',
      'those'
    };
    return stopWords.contains(word.toLowerCase());
  }

  static double _calculateConfidenceScore(int consecutive, int total) {
    if (total == 0) return 0.0;
    final ratio = consecutive / total;
    return (ratio * 0.8 + (consecutive >= 3 ? 0.2 : 0.0)).clamp(0.0, 1.0);
  }
}

/// Enhanced Quiz model supporting advanced question types
class AdvancedQuiz {
  final String id;
  final String title;
  final List<AdvancedFlashcard> questions;
  final int numQuestions;
  final Map<String, double> typeMix; // mcq, qa, truefalse percentages
  final int timeLimitSeconds;
  final double passThreshold;
  final DateTime createdDate;
  final List<AdvancedQuizResult> results;

  // Bloom's taxonomy distribution
  final Map<String, double> bloomMix;
  final int difficulty; // 1-7 scale

  AdvancedQuiz({
    required this.id,
    required this.title,
    required this.questions,
    required this.numQuestions,
    required this.typeMix,
    required this.timeLimitSeconds,
    required this.passThreshold,
    required this.createdDate,
    this.results = const [],
    this.bloomMix = const {},
    this.difficulty = 3,
  });

  /// Convert from legacy Quiz model
  factory AdvancedQuiz.fromLegacyQuiz(Quiz quiz) {
    return AdvancedQuiz(
      id: quiz.id,
      title: quiz.title,
      questions: quiz.questions
          .map((q) => _convertQuizQuestionToAdvancedFlashcard(q))
          .toList(),
      numQuestions: quiz.questions.length,
      typeMix: {'mcq': 1.0, 'qa': 0.0, 'truefalse': 0.0},
      timeLimitSeconds: quiz.questions.length * 60, // 1 minute per question
      passThreshold: 0.7,
      createdDate: quiz.createdDate,
      results: quiz.results
          .map((r) => AdvancedQuizResult.fromLegacyResult(r))
          .toList(),
      difficulty: _mapDifficultyLevelToInt(quiz.overallDifficulty),
    );
  }

  /// Create from generation schema
  factory AdvancedQuiz.fromGenerationSchema(
    String id,
    String title,
    List<AdvancedFlashcard> allCards,
    Map<String, dynamic> quizConfig,
  ) {
    final numQuestions = quizConfig['num_questions'] as int;
    final selectedQuestions = allCards.take(numQuestions).toList();

    return AdvancedQuiz(
      id: id,
      title: title,
      questions: selectedQuestions,
      numQuestions: numQuestions,
      typeMix: Map<String, double>.from(quizConfig['mix'] ?? {}),
      timeLimitSeconds: quizConfig['time_limit_seconds'] as int? ?? 600,
      passThreshold: (quizConfig['pass_threshold'] as num?)?.toDouble() ?? 0.7,
      createdDate: DateTime.now(),
      bloomMix: _calculateBloomMix(selectedQuestions),
    );
  }

  /// Calculate overall difficulty based on questions
  int get calculatedDifficulty {
    if (questions.isEmpty) return 1;

    final difficultySum = questions.map((q) {
      switch (q.difficulty) {
        case 'easy':
          return 1;
        case 'medium':
          return 2;
        case 'hard':
          return 3;
        default:
          return 2;
      }
    }).reduce((a, b) => a + b);

    final avgDifficulty = difficultySum / questions.length;
    return (avgDifficulty * 2.33).round().clamp(1, 7); // Scale to 1-7
  }

  /// Get questions by Bloom level
  List<AdvancedFlashcard> getQuestionsByBloomLevel(BloomLevel level) {
    return questions.where((q) => q.bloomLevel == level).toList();
  }

  /// Get questions by difficulty
  List<AdvancedFlashcard> getQuestionsByDifficulty(CardDifficulty difficulty) {
    return questions.where((q) => q.cardDifficulty == difficulty).toList();
  }

  /// Convert to legacy Quiz for compatibility
  Quiz toLegacyQuiz() {
    return Quiz(
      id: id,
      title: title,
      questions: questions
          .map((q) => _convertAdvancedFlashcardToQuizQuestion(q))
          .toList(),
      type: QuestionType.multipleChoice,
      createdDate: createdDate,
      results: results.map((r) => r.toLegacyResult()).toList(),
      overallDifficulty: _mapIntToDifficultyLevel(calculatedDifficulty),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'num_questions': numQuestions,
        'type_mix': typeMix,
        'time_limit_seconds': timeLimitSeconds,
        'pass_threshold': passThreshold,
        'created_date': createdDate.toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
        'bloom_mix': bloomMix,
        'difficulty': difficulty,
      };

  factory AdvancedQuiz.fromJson(Map<String, dynamic> json) => AdvancedQuiz(
        id: json['id'] as String,
        title: json['title'] as String,
        questions: (json['questions'] as List)
            .map((q) => AdvancedFlashcard.fromJson(q))
            .toList(),
        numQuestions: json['num_questions'] as int,
        typeMix: Map<String, double>.from(json['type_mix'] ?? {}),
        timeLimitSeconds: json['time_limit_seconds'] as int? ?? 600,
        passThreshold: (json['pass_threshold'] as num?)?.toDouble() ?? 0.7,
        createdDate: DateTime.parse(json['created_date']),
        results: (json['results'] as List? ?? [])
            .map((r) => AdvancedQuizResult.fromJson(r))
            .toList(),
        bloomMix: Map<String, double>.from(json['bloom_mix'] ?? {}),
        difficulty: json['difficulty'] as int? ?? 3,
      );

  // Helper methods
  static AdvancedFlashcard _convertQuizQuestionToAdvancedFlashcard(
      QuizQuestion q) {
    return AdvancedFlashcard(
      id: q.id,
      type: 'mcq',
      bloom: 'Apply',
      difficulty: _mapDifficultyLevelToString(q.difficulty),
      question: q.question,
      choices: q.options,
      correctIndex: q.options.indexOf(q.correctAnswer),
      answerExplanation: 'The correct answer is ${q.correctAnswer}.',
      hint: 'Consider all the options carefully.',
      anchors: AdvancedFlashcard._extractAnchorsFromQuestion(q.question),
      sourceSpan: 'Converted from legacy quiz question',
    );
  }

  static QuizQuestion _convertAdvancedFlashcardToQuizQuestion(
      AdvancedFlashcard card) {
    return QuizQuestion(
      id: card.id,
      question: card.question,
      options: card.choices.isNotEmpty ? card.choices : ['True', 'False'],
      correctAnswer: card.correctAnswer,
      type: card.type == 'mcq'
          ? QuestionType.multipleChoice
          : QuestionType.trueFalse,
      difficulty:
          AdvancedFlashcard._mapStringToDifficultyLevel(card.difficulty),
    );
  }

  static String _mapDifficultyLevelToString(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'easy';
      case DifficultyLevel.intermediate:
        return 'medium';
      case DifficultyLevel.advanced:
      case DifficultyLevel.expert:
        return 'hard';
    }
  }

  static int _mapDifficultyLevelToInt(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 2;
      case DifficultyLevel.intermediate:
        return 4;
      case DifficultyLevel.advanced:
        return 6;
      case DifficultyLevel.expert:
        return 7;
    }
  }

  static DifficultyLevel _mapIntToDifficultyLevel(int difficulty) {
    if (difficulty <= 2) return DifficultyLevel.beginner;
    if (difficulty <= 4) return DifficultyLevel.intermediate;
    if (difficulty <= 6) return DifficultyLevel.advanced;
    return DifficultyLevel.expert;
  }

  static Map<String, double> _calculateBloomMix(
      List<AdvancedFlashcard> questions) {
    if (questions.isEmpty) return {};

    final bloomCounts = <String, int>{};
    for (final question in questions) {
      bloomCounts[question.bloom] = (bloomCounts[question.bloom] ?? 0) + 1;
    }

    final bloomMix = <String, double>{};
    for (final entry in bloomCounts.entries) {
      bloomMix[entry.key] = entry.value / questions.length;
    }

    return bloomMix;
  }
}

/// Enhanced Quiz Result with detailed analytics
class AdvancedQuizResult {
  final String questionId;
  final bool wasCorrect;
  final DateTime answeredAt;
  final Duration responseTime;
  final String selectedAnswer;
  final double confidenceLevel; // 0.0 to 1.0
  final String bloomLevel;
  final String difficulty;

  AdvancedQuizResult({
    required this.questionId,
    required this.wasCorrect,
    required this.answeredAt,
    required this.responseTime,
    required this.selectedAnswer,
    this.confidenceLevel = 0.5,
    this.bloomLevel = 'Apply',
    this.difficulty = 'medium',
  });

  factory AdvancedQuizResult.fromLegacyResult(QuizResult result) {
    return AdvancedQuizResult(
      questionId: result.questionId,
      wasCorrect: result.wasCorrect,
      answeredAt: result.answeredAt,
      responseTime: result.responseTime ?? Duration.zero,
      selectedAnswer: 'Unknown',
      confidenceLevel: result.wasCorrect ? 0.8 : 0.2,
    );
  }

  QuizResult toLegacyResult() {
    return QuizResult(
      questionId: questionId,
      wasCorrect: wasCorrect,
      answeredAt: answeredAt,
      responseTime: responseTime,
    );
  }

  double get percentage => wasCorrect ? 100.0 : 0.0;

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'was_correct': wasCorrect,
        'answered_at': answeredAt.toIso8601String(),
        'response_time': responseTime.inMilliseconds,
        'selected_answer': selectedAnswer,
        'confidence_level': confidenceLevel,
        'bloom_level': bloomLevel,
        'difficulty': difficulty,
      };

  factory AdvancedQuizResult.fromJson(Map<String, dynamic> json) =>
      AdvancedQuizResult(
        questionId: json['question_id'] as String,
        wasCorrect: json['was_correct'] as bool,
        answeredAt: DateTime.parse(json['answered_at']),
        responseTime:
            Duration(milliseconds: json['response_time'] as int? ?? 0),
        selectedAnswer: json['selected_answer'] as String? ?? '',
        confidenceLevel: (json['confidence_level'] as num?)?.toDouble() ?? 0.5,
        bloomLevel: json['bloom_level'] as String? ?? 'Apply',
        difficulty: json['difficulty'] as String? ?? 'medium',
      );
}

/// Bloom's Taxonomy levels
enum BloomLevel {
  understand,
  apply,
  analyze,
  evaluate,
  create,
}

/// Card difficulty levels
enum CardDifficulty {
  easy,
  medium,
  hard,
}

/// Enhanced Study Set with advanced features
class AdvancedStudySet {
  final String id;
  final String title;
  final String content;
  final String sourceSummary;
  final List<String> tags;
  final int difficulty; // 1-7 scale
  final Map<String, double> bloomMix;
  final List<AdvancedFlashcard> cards;
  final AdvancedQuiz? quiz;
  final DateTime createdDate;
  final DateTime lastStudied;
  final bool notificationsEnabled;
  final DateTime? deadlineDate;
  final bool isArchived;

  AdvancedStudySet({
    required this.id,
    required this.title,
    required this.content,
    required this.sourceSummary,
    required this.tags,
    required this.difficulty,
    required this.bloomMix,
    required this.cards,
    this.quiz,
    required this.createdDate,
    required this.lastStudied,
    this.notificationsEnabled = true,
    this.deadlineDate,
    this.isArchived = false,
  });

  /// Convert from generation schema
  factory AdvancedStudySet.fromGenerationSchema(
    String id,
    String title,
    String content,
    Map<String, dynamic> schema,
  ) {
    final cards = (schema['cards'] as List)
        .map((cardData) => AdvancedFlashcard.fromGenerationSchema(cardData))
        .toList();

    final quizConfig = schema['quiz'] as Map<String, dynamic>;
    final quiz = AdvancedQuiz.fromGenerationSchema(
      '${id}_quiz',
      '$title Quiz',
      cards,
      quizConfig,
    );

    return AdvancedStudySet(
      id: id,
      title: title,
      content: content,
      sourceSummary: schema['source_summary'] as String,
      tags: List<String>.from(schema['tags'] ?? []),
      difficulty: schema['difficulty'] as int,
      bloomMix: Map<String, double>.from(schema['bloom_mix'] ?? {}),
      cards: cards,
      quiz: quiz,
      createdDate: DateTime.now(),
      lastStudied: DateTime.now(),
    );
  }

  /// Convert to legacy StudySet for compatibility
  StudySet toLegacyStudySet() {
    return StudySet(
      id: id,
      title: title,
      content: content,
      flashcards: cards.map((c) => c.toLegacyFlashcard()).toList(),
      quizzes: quiz != null ? [quiz!.toLegacyQuiz()] : [],
      createdDate: createdDate,
      lastStudied: lastStudied,
      notificationsEnabled: notificationsEnabled,
      deadlineDate: deadlineDate,
      tags: tags,
      isArchived: isArchived,
    );
  }

  /// Get cards by Bloom level
  List<AdvancedFlashcard> getCardsByBloomLevel(BloomLevel level) {
    return cards.where((c) => c.bloomLevel == level).toList();
  }

  /// Get cards by difficulty
  List<AdvancedFlashcard> getCardsByDifficulty(CardDifficulty difficulty) {
    return cards.where((c) => c.cardDifficulty == difficulty).toList();
  }

  /// Get cards by anchor
  List<AdvancedFlashcard> getCardsByAnchor(String anchor) {
    return cards.where((c) => c.anchors.contains(anchor)).toList();
  }

  /// Get all unique anchors
  List<String> get allAnchors {
    final anchors = <String>{};
    for (final card in cards) {
      anchors.addAll(card.anchors);
    }
    return anchors.toList()..sort();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'source_summary': sourceSummary,
        'tags': tags,
        'difficulty': difficulty,
        'bloom_mix': bloomMix,
        'cards': cards.map((c) => c.toJson()).toList(),
        'quiz': quiz?.toJson(),
        'created_date': createdDate.toIso8601String(),
        'last_studied': lastStudied.toIso8601String(),
        'notifications_enabled': notificationsEnabled,
        'deadline_date': deadlineDate?.toIso8601String(),
        'is_archived': isArchived,
      };

  factory AdvancedStudySet.fromJson(Map<String, dynamic> json) =>
      AdvancedStudySet(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        sourceSummary: json['source_summary'] as String? ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        difficulty: json['difficulty'] as int? ?? 3,
        bloomMix: Map<String, double>.from(json['bloom_mix'] ?? {}),
        cards: (json['cards'] as List? ?? [])
            .map((c) => AdvancedFlashcard.fromJson(c))
            .toList(),
        quiz: json['quiz'] != null ? AdvancedQuiz.fromJson(json['quiz']) : null,
        createdDate: DateTime.parse(json['created_date']),
        lastStudied: DateTime.parse(json['last_studied']),
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        deadlineDate: json['deadline_date'] != null
            ? DateTime.parse(json['deadline_date'])
            : null,
        isArchived: json['is_archived'] as bool? ?? false,
      );
}
