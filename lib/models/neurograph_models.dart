

// ============================================================================
// NEUROGRAPH DATA MODELS
// ============================================================================
// Structured data models for NeuroGraph analytics system
// Aligns with existing application architecture patterns

/// Study session data model
class StudySession {
  final DateTime timestamp;
  final int durationMinutes;
  final String subject;
  final int correctAnswers;
  final int totalQuestions;
  final double averageResponseTime;
  final double accuracy;

  const StudySession({
    required this.timestamp,
    required this.durationMinutes,
    required this.subject,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.averageResponseTime,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.millisecondsSinceEpoch,
        'durationMinutes': durationMinutes,
        'subject': subject,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'averageResponseTime': averageResponseTime,
        'accuracy': accuracy,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        durationMinutes: json['durationMinutes'],
        subject: json['subject'],
        correctAnswers: json['correctAnswers'],
        totalQuestions: json['totalQuestions'],
        averageResponseTime: json['averageResponseTime'].toDouble(),
        accuracy: json['accuracy'].toDouble(),
      );

  StudySession copyWith({
    DateTime? timestamp,
    int? durationMinutes,
    String? subject,
    int? correctAnswers,
    int? totalQuestions,
    double? averageResponseTime,
    double? accuracy,
  }) =>
      StudySession(
        timestamp: timestamp ?? this.timestamp,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        subject: subject ?? this.subject,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        averageResponseTime: averageResponseTime ?? this.averageResponseTime,
        accuracy: accuracy ?? this.accuracy,
      );
}

/// Daily streak data model
class StreakData {
  final String date;
  final int durationMinutes;
  final int sessions;
  final DateTime timestamp;

  const StreakData({
    required this.date,
    required this.durationMinutes,
    required this.sessions,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'durationMinutes': durationMinutes,
        'sessions': sessions,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        date: json['date'],
        durationMinutes: json['durationMinutes'],
        sessions: json['sessions'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      );

  StreakData copyWith({
    String? date,
    int? durationMinutes,
    int? sessions,
    DateTime? timestamp,
  }) =>
      StreakData(
        date: date ?? this.date,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        sessions: sessions ?? this.sessions,
        timestamp: timestamp ?? this.timestamp,
      );
}

/// Subject recall data model
class RecallData {
  final String subject;
  final double averageAccuracy;
  final int sessions;
  final DateTime lastUpdated;

  const RecallData({
    required this.subject,
    required this.averageAccuracy,
    required this.sessions,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'averageAccuracy': averageAccuracy,
        'sessions': sessions,
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      };

  factory RecallData.fromJson(Map<String, dynamic> json) => RecallData(
        subject: json['subject'],
        averageAccuracy: json['averageAccuracy'].toDouble(),
        sessions: json['sessions'],
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
      );

  RecallData copyWith({
    String? subject,
    double? averageAccuracy,
    int? sessions,
    DateTime? lastUpdated,
  }) =>
      RecallData(
        subject: subject ?? this.subject,
        averageAccuracy: averageAccuracy ?? this.averageAccuracy,
        sessions: sessions ?? this.sessions,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// Efficiency data model
class EfficiencyData {
  final DateTime timestamp;
  final double correctPerMinute;
  final double averageResponseTime;
  final int sessionDuration;

  const EfficiencyData({
    required this.timestamp,
    required this.correctPerMinute,
    required this.averageResponseTime,
    required this.sessionDuration,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.millisecondsSinceEpoch,
        'correctPerMinute': correctPerMinute,
        'averageResponseTime': averageResponseTime,
        'sessionDuration': sessionDuration,
      };

  factory EfficiencyData.fromJson(Map<String, dynamic> json) => EfficiencyData(
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        correctPerMinute: json['correctPerMinute'].toDouble(),
        averageResponseTime: json['averageResponseTime'].toDouble(),
        sessionDuration: json['sessionDuration'],
      );

  EfficiencyData copyWith({
    DateTime? timestamp,
    double? correctPerMinute,
    double? averageResponseTime,
    int? sessionDuration,
  }) =>
      EfficiencyData(
        timestamp: timestamp ?? this.timestamp,
        correctPerMinute: correctPerMinute ?? this.correctPerMinute,
        averageResponseTime: averageResponseTime ?? this.averageResponseTime,
        sessionDuration: sessionDuration ?? this.sessionDuration,
      );
}

/// Forgetting curve data model
class ForgettingData {
  final DateTime timestamp;
  final double accuracy;
  final int daysSinceCreation;
  final bool reviewed;

  const ForgettingData({
    required this.timestamp,
    required this.accuracy,
    required this.daysSinceCreation,
    required this.reviewed,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.millisecondsSinceEpoch,
        'accuracy': accuracy,
        'daysSinceCreation': daysSinceCreation,
        'reviewed': reviewed,
      };

  factory ForgettingData.fromJson(Map<String, dynamic> json) => ForgettingData(
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        accuracy: json['accuracy'].toDouble(),
        daysSinceCreation: json['daysSinceCreation'],
        reviewed: json['reviewed'],
      );

  ForgettingData copyWith({
    DateTime? timestamp,
    double? accuracy,
    int? daysSinceCreation,
    bool? reviewed,
  }) =>
      ForgettingData(
        timestamp: timestamp ?? this.timestamp,
        accuracy: accuracy ?? this.accuracy,
        daysSinceCreation: daysSinceCreation ?? this.daysSinceCreation,
        reviewed: reviewed ?? this.reviewed,
      );
}

/// Compact metrics model for analysis and tips
class NeuroGraphMetrics {
  final int totalMinutes;
  final int studyDays;
  final int streakDays;
  final int consistencyIdx;
  final int dueCount;
  final int recallRate;
  final int latencyMsP50;
  final String bestHourBand;
  final int spacedRepAdherence;
  final int masteryVelocity;
  final int coverageRatio;
  final int interruptions;
  final int notificationFrequency;
  final String bestSubject;

  const NeuroGraphMetrics({
    required this.totalMinutes,
    required this.studyDays,
    required this.streakDays,
    required this.consistencyIdx,
    required this.dueCount,
    required this.recallRate,
    required this.latencyMsP50,
    required this.bestHourBand,
    required this.spacedRepAdherence,
    required this.masteryVelocity,
    required this.coverageRatio,
    required this.interruptions,
    required this.notificationFrequency,
    required this.bestSubject,
  });

  Map<String, dynamic> toMap() => {
        'total_minutes': totalMinutes,
        'study_days': studyDays,
        'streak_days': streakDays,
        'consistency_idx': consistencyIdx,
        'due_count': dueCount,
        'recall_rate': recallRate,
        'latency_ms_p50': latencyMsP50,
        'best_hour_band': bestHourBand,
        'spaced_rep_adherence': spacedRepAdherence,
        'mastery_velocity': masteryVelocity,
        'coverage_ratio': coverageRatio,
        'interruptions': interruptions,
        'notification_frequency': notificationFrequency,
        'best_subject': bestSubject,
      };

  factory NeuroGraphMetrics.fromMap(Map<String, dynamic> map) =>
      NeuroGraphMetrics(
        totalMinutes: map['total_minutes'] ?? 0,
        studyDays: map['study_days'] ?? 0,
        streakDays: map['streak_days'] ?? 0,
        consistencyIdx: map['consistency_idx'] ?? 0,
        dueCount: map['due_count'] ?? 0,
        recallRate: map['recall_rate'] ?? 0,
        latencyMsP50: map['latency_ms_p50'] ?? 2000,
        bestHourBand: map['best_hour_band'] ?? '9-11 AM',
        spacedRepAdherence: map['spaced_rep_adherence'] ?? 85,
        masteryVelocity: map['mastery_velocity'] ?? 75,
        coverageRatio: map['coverage_ratio'] ?? 0,
        interruptions: map['interruptions'] ?? 0,
        notificationFrequency: map['notification_frequency'] ?? 2,
        bestSubject: map['best_subject'] ?? 'General',
      );

  NeuroGraphMetrics copyWith({
    int? totalMinutes,
    int? studyDays,
    int? streakDays,
    int? consistencyIdx,
    int? dueCount,
    int? recallRate,
    int? latencyMsP50,
    String? bestHourBand,
    int? spacedRepAdherence,
    int? masteryVelocity,
    int? coverageRatio,
    int? interruptions,
    int? notificationFrequency,
    String? bestSubject,
  }) =>
      NeuroGraphMetrics(
        totalMinutes: totalMinutes ?? this.totalMinutes,
        studyDays: studyDays ?? this.studyDays,
        streakDays: streakDays ?? this.streakDays,
        consistencyIdx: consistencyIdx ?? this.consistencyIdx,
        dueCount: dueCount ?? this.dueCount,
        recallRate: recallRate ?? this.recallRate,
        latencyMsP50: latencyMsP50 ?? this.latencyMsP50,
        bestHourBand: bestHourBand ?? this.bestHourBand,
        spacedRepAdherence: spacedRepAdherence ?? this.spacedRepAdherence,
        masteryVelocity: masteryVelocity ?? this.masteryVelocity,
        coverageRatio: coverageRatio ?? this.coverageRatio,
        interruptions: interruptions ?? this.interruptions,
        notificationFrequency:
            notificationFrequency ?? this.notificationFrequency,
        bestSubject: bestSubject ?? this.bestSubject,
      );
}

/// Analysis result model
class NeuroGraphAnalysis {
  final List<String> insights;
  final List<String> quickTips;
  final DateTime generatedAt;
  final String metricsHash;

  const NeuroGraphAnalysis({
    required this.insights,
    required this.quickTips,
    required this.generatedAt,
    required this.metricsHash,
  });

  Map<String, dynamic> toJson() => {
        'insights': insights,
        'quickTips': quickTips,
        'generatedAt': generatedAt.millisecondsSinceEpoch,
        'metricsHash': metricsHash,
      };

  factory NeuroGraphAnalysis.fromJson(Map<String, dynamic> json) =>
      NeuroGraphAnalysis(
        insights: List<String>.from(json['insights']),
        quickTips: List<String>.from(json['quickTips']),
        generatedAt: DateTime.fromMillisecondsSinceEpoch(json['generatedAt']),
        metricsHash: json['metricsHash'],
      );

  NeuroGraphAnalysis copyWith({
    List<String>? insights,
    List<String>? quickTips,
    DateTime? generatedAt,
    String? metricsHash,
  }) =>
      NeuroGraphAnalysis(
        insights: insights ?? this.insights,
        quickTips: quickTips ?? this.quickTips,
        generatedAt: generatedAt ?? this.generatedAt,
        metricsHash: metricsHash ?? this.metricsHash,
      );
}

/// NeuroGraph data summary model
class NeuroGraphDataSummary {
  final DateTime lastUpdated;
  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final double averageAccuracy;
  final List<String> subjects;
  final bool hasData;

  const NeuroGraphDataSummary({
    required this.lastUpdated,
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.averageAccuracy,
    required this.subjects,
    required this.hasData,
  });

  Map<String, dynamic> toJson() => {
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'currentStreak': currentStreak,
        'averageAccuracy': averageAccuracy,
        'subjects': subjects,
        'hasData': hasData,
      };

  factory NeuroGraphDataSummary.fromJson(Map<String, dynamic> json) =>
      NeuroGraphDataSummary(
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['lastUpdated']),
        totalSessions: json['totalSessions'],
        totalMinutes: json['totalMinutes'],
        currentStreak: json['currentStreak'],
        averageAccuracy: json['averageAccuracy'].toDouble(),
        subjects: List<String>.from(json['subjects']),
        hasData: json['hasData'],
      );

  NeuroGraphDataSummary copyWith({
    DateTime? lastUpdated,
    int? totalSessions,
    int? totalMinutes,
    int? currentStreak,
    double? averageAccuracy,
    List<String>? subjects,
    bool? hasData,
  }) =>
      NeuroGraphDataSummary(
        lastUpdated: lastUpdated ?? this.lastUpdated,
        totalSessions: totalSessions ?? this.totalSessions,
        totalMinutes: totalMinutes ?? this.totalMinutes,
        currentStreak: currentStreak ?? this.currentStreak,
        averageAccuracy: averageAccuracy ?? this.averageAccuracy,
        subjects: subjects ?? this.subjects,
        hasData: hasData ?? this.hasData,
      );
}
