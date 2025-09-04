import 'package:cloud_firestore/cloud_firestore.dart';

/// Data models for NeuroGraph V2 analytics system
/// Maps to existing Firestore schema with additional computed fields

/// Attempt data model - maps to Firestore 'attempts' collection
class Attempt {
  final String userId;
  final String testId;
  final String questionId;
  final String topicId;
  final String? bloom; // Optional Bloom's taxonomy level
  final bool isCorrect;
  final double score; // 0.0 to 1.0
  final int responseMs; // Response time in milliseconds
  final DateTime timestamp;
  final double? confidencePct; // Optional confidence percentage (0-100)

  const Attempt({
    required this.userId,
    required this.testId,
    required this.questionId,
    required this.topicId,
    this.bloom,
    required this.isCorrect,
    required this.score,
    required this.responseMs,
    required this.timestamp,
    this.confidencePct,
  });

  /// Create from Firestore document
  factory Attempt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Attempt(
      userId: data['userId'] ?? '',
      testId: data['testId'] ?? '',
      questionId: data['questionId'] ?? '',
      topicId: data['topicId'] ?? '',
      bloom: data['bloom'],
      isCorrect: data['isCorrect'] ?? false,
      score: (data['score'] ?? 0.0).toDouble(),
      responseMs: data['responseMs'] ?? 0,
      timestamp: (data['ts'] as Timestamp).toDate(),
      confidencePct: data['confidencePct']?.toDouble(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'testId': testId,
        'questionId': questionId,
        'topicId': topicId,
        'bloom': bloom,
        'isCorrect': isCorrect,
        'score': score,
        'responseMs': responseMs,
        'ts': Timestamp.fromDate(timestamp),
        'confidencePct': confidencePct,
      };

  /// Create with estimated score from isCorrect if score is missing
  factory Attempt.withEstimatedScore({
    required String userId,
    required String testId,
    required String questionId,
    required String topicId,
    String? bloom,
    required bool isCorrect,
    double? score,
    required int responseMs,
    required DateTime timestamp,
    double? confidencePct,
  }) {
    final estimatedScore = score ?? (isCorrect ? 1.0 : 0.0);
    return Attempt(
      userId: userId,
      testId: testId,
      questionId: questionId,
      topicId: topicId,
      bloom: bloom,
      isCorrect: isCorrect,
      score: estimatedScore,
      responseMs: responseMs,
      timestamp: timestamp,
      confidencePct: confidencePct,
    );
  }

  Attempt copyWith({
    String? userId,
    String? testId,
    String? questionId,
    String? topicId,
    String? bloom,
    bool? isCorrect,
    double? score,
    int? responseMs,
    DateTime? timestamp,
    double? confidencePct,
  }) =>
      Attempt(
        userId: userId ?? this.userId,
        testId: testId ?? this.testId,
        questionId: questionId ?? this.questionId,
        topicId: topicId ?? this.topicId,
        bloom: bloom ?? this.bloom,
        isCorrect: isCorrect ?? this.isCorrect,
        score: score ?? this.score,
        responseMs: responseMs ?? this.responseMs,
        timestamp: timestamp ?? this.timestamp,
        confidencePct: confidencePct ?? this.confidencePct,
      );
}

/// Session data model - maps to Firestore 'sessions' collection (optional)
class Session {
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int itemsSeen;
  final int itemsCorrect;

  const Session({
    required this.userId,
    required this.startedAt,
    this.endedAt,
    required this.itemsSeen,
    required this.itemsCorrect,
  });

  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      userId: data['userId'] ?? '',
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      endedAt: data['endedAt'] != null ? (data['endedAt'] as Timestamp).toDate() : null,
      itemsSeen: data['itemsSeen'] ?? 0,
      itemsCorrect: data['itemsCorrect'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
        'itemsSeen': itemsSeen,
        'itemsCorrect': itemsCorrect,
      };
}

/// Question data model - maps to Firestore 'questions' collection (optional)
class Question {
  final String questionId;
  final String topicId;
  final String? bloom;

  const Question({
    required this.questionId,
    required this.topicId,
    this.bloom,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      questionId: data['questionId'] ?? '',
      topicId: data['topicId'] ?? '',
      bloom: data['bloom'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'questionId': questionId,
        'topicId': topicId,
        'bloom': bloom,
      };
}

/// Computed data models for charts

/// Daily accuracy point for learning curve
class DailyPoint {
  final DateTime date;
  final double accuracy;
  final int totalAttempts;
  final int correctAttempts;

  const DailyPoint({
    required this.date,
    required this.accuracy,
    required this.totalAttempts,
    required this.correctAttempts,
  });

  DailyPoint copyWith({
    DateTime? date,
    double? accuracy,
    int? totalAttempts,
    int? correctAttempts,
  }) =>
      DailyPoint(
        date: date ?? this.date,
        accuracy: accuracy ?? this.accuracy,
        totalAttempts: totalAttempts ?? this.totalAttempts,
        correctAttempts: correctAttempts ?? this.correctAttempts,
      );
}

/// Recall model for spaced review
class RecallModel {
  final String questionId;
  final DateTime lastSuccess;
  final int repetitions;
  final double lambda;
  final double pRecall;
  final DateTime nextReviewDate;
  final bool isDue;
  final int daysSinceLastSuccess;

  const RecallModel({
    required this.questionId,
    required this.lastSuccess,
    required this.repetitions,
    required this.lambda,
    required this.pRecall,
    required this.nextReviewDate,
    required this.isDue,
    required this.daysSinceLastSuccess,
  });

  RecallModel copyWith({
    String? questionId,
    DateTime? lastSuccess,
    int? repetitions,
    double? lambda,
    double? pRecall,
    DateTime? nextReviewDate,
    bool? isDue,
    int? daysSinceLastSuccess,
  }) =>
      RecallModel(
        questionId: questionId ?? this.questionId,
        lastSuccess: lastSuccess ?? this.lastSuccess,
        repetitions: repetitions ?? this.repetitions,
        lambda: lambda ?? this.lambda,
        pRecall: pRecall ?? this.pRecall,
        nextReviewDate: nextReviewDate ?? this.nextReviewDate,
        isDue: isDue ?? this.isDue,
        daysSinceLastSuccess: daysSinceLastSuccess ?? this.daysSinceLastSuccess,
      );
}

/// Weekly point for retrieval practice
class WeekPoint {
  final DateTime weekStart;
  final int retrievalSessions;
  final double? nextExamScore;
  final double? scoreDelta;

  const WeekPoint({
    required this.weekStart,
    required this.retrievalSessions,
    this.nextExamScore,
    this.scoreDelta,
  });

  WeekPoint copyWith({
    DateTime? weekStart,
    int? retrievalSessions,
    double? nextExamScore,
    double? scoreDelta,
  }) =>
      WeekPoint(
        weekStart: weekStart ?? this.weekStart,
        retrievalSessions: retrievalSessions ?? this.retrievalSessions,
        nextExamScore: nextExamScore ?? this.nextExamScore,
        scoreDelta: scoreDelta ?? this.scoreDelta,
      );
}

/// Calibration bin
class CalibrationBin {
  final double confidenceMin;
  final double confidenceMax;
  final double actualAccuracy;
  final int count;
  final double weight;

  const CalibrationBin({
    required this.confidenceMin,
    required this.confidenceMax,
    required this.actualAccuracy,
    required this.count,
    required this.weight,
  });

  CalibrationBin copyWith({
    double? confidenceMin,
    double? confidenceMax,
    double? actualAccuracy,
    int? count,
    double? weight,
  }) =>
      CalibrationBin(
        confidenceMin: confidenceMin ?? this.confidenceMin,
        confidenceMax: confidenceMax ?? this.confidenceMax,
        actualAccuracy: actualAccuracy ?? this.actualAccuracy,
        count: count ?? this.count,
        weight: weight ?? this.weight,
      );
}

/// Calibration summary
class CalibrationSummary {
  final List<CalibrationBin> bins;
  final double brierScore;
  final double expectedCalibrationError;

  const CalibrationSummary({
    required this.bins,
    required this.brierScore,
    required this.expectedCalibrationError,
  });

  CalibrationSummary copyWith({
    List<CalibrationBin>? bins,
    double? brierScore,
    double? expectedCalibrationError,
  }) =>
      CalibrationSummary(
        bins: bins ?? this.bins,
        brierScore: brierScore ?? this.brierScore,
        expectedCalibrationError: expectedCalibrationError ?? this.expectedCalibrationError,
      );
}

/// Mastery state enum
enum MasteryState { new_, practicing, mastered }

/// Mastery stack for weekly progress
class WeekStack {
  final DateTime weekStart;
  final double newPercentage;
  final double practicingPercentage;
  final double masteredPercentage;
  final int totalItems;

  const WeekStack({
    required this.weekStart,
    required this.newPercentage,
    required this.practicingPercentage,
    required this.masteredPercentage,
    required this.totalItems,
  });

  WeekStack copyWith({
    DateTime? weekStart,
    double? newPercentage,
    double? practicingPercentage,
    double? masteredPercentage,
    int? totalItems,
  }) =>
      WeekStack(
        weekStart: weekStart ?? this.weekStart,
        newPercentage: newPercentage ?? this.newPercentage,
        practicingPercentage: practicingPercentage ?? this.practicingPercentage,
        masteredPercentage: masteredPercentage ?? this.masteredPercentage,
        totalItems: totalItems ?? this.totalItems,
      );
}

/// Consistency heatmap data
class ConsistencyHeat {
  final DateTime date;
  final double intensity; // 0.0 to 1.0
  final int attempts;
  final bool studied;

  const ConsistencyHeat({
    required this.date,
    required this.intensity,
    required this.attempts,
    required this.studied,
  });

  ConsistencyHeat copyWith({
    DateTime? date,
    double? intensity,
    int? attempts,
    bool? studied,
  }) =>
      ConsistencyHeat(
        date: date ?? this.date,
        intensity: intensity ?? this.intensity,
        attempts: attempts ?? this.attempts,
        studied: studied ?? this.studied,
      );
}

/// Filter options for charts
class NeuroGraphFilters {
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String> topics;
  final List<String> tests;
  final bool includeBloom;

  const NeuroGraphFilters({
    this.fromDate,
    this.toDate,
    this.topics = const [],
    this.tests = const [],
    this.includeBloom = false,
  });

  NeuroGraphFilters copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? topics,
    List<String>? tests,
    bool? includeBloom,
  }) =>
      NeuroGraphFilters(
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        topics: topics ?? this.topics,
        tests: tests ?? this.tests,
        includeBloom: includeBloom ?? this.includeBloom,
      );
}
