import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindload/models/study_data.dart';

/// Firestore Data Schema for CogniFlow App
/// 
/// Collections:
/// - users: User profile and settings data
/// - study_sets: User's study materials and generated content  
/// - quiz_results: Results from completed quizzes
/// - user_progress: User's learning progress, streaks, and XP
/// - credit_usage: Daily credit usage tracking for the credit system
/// - notifications: Push notification preferences and history
/// - notification_preferences: Comprehensive notification settings per user
/// - notification_records: History of sent notifications with analytics
/// - notification_schedules: Computed 48-hour notification schedules
/// - schedule_recompute: Flags for triggering schedule recomputation

class FirestoreSchema {
  static const String usersCollection = 'users';
  static const String studySetsCollection = 'study_sets';
  static const String quizResultsCollection = 'quiz_results';
  static const String userProgressCollection = 'user_progress';
  static const String creditUsageCollection = 'credit_usage';
  static const String notificationsCollection = 'notifications';
  static const String notificationPreferencesCollection = 'notification_preferences';
  static const String notificationRecordsCollection = 'notification_records';
  static const String notificationSchedulesCollection = 'notification_schedules';
  static const String scheduleRecomputeCollection = 'schedule_recompute';
}

/// User Profile Document Structure
class UserProfileFirestore {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String provider; // 'email', 'google', 'apple', 'microsoft'
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic> preferences;
  final String subscriptionPlan; // 'free', 'pro', 'annual_pro'
  final bool isActive;

  UserProfileFirestore({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phoneNumber,
    required this.provider,
    required this.createdAt,
    required this.lastLoginAt,
    required this.preferences,
    this.subscriptionPlan = 'free',
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'phoneNumber': phoneNumber,
    'provider': provider,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    'preferences': preferences,
    'subscriptionPlan': subscriptionPlan,
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory UserProfileFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfileFirestore(
      uid: data['uid'],
      email: data['email'],
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      provider: data['provider'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      preferences: data['preferences'] ?? {},
      subscriptionPlan: data['subscriptionPlan'] ?? 'free',
      isActive: data['isActive'] ?? true,
    );
  }
}

/// Study Set Document Structure (Enhanced for Firestore)
class StudySetFirestore {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String originalFileName;
  final String fileType; // 'pdf', 'txt', 'docx', 'epub', 'mobi'
  final List<Map<String, dynamic>> flashcards;
  final List<Map<String, dynamic>> quizzes;
  final DateTime createdDate;
  final DateTime lastStudied;
  final int studyCount;
  final List<String> tags;
  final String difficulty; // 'easy', 'medium', 'hard'
  final bool isPublic;
  final Map<String, dynamic> metadata;

  StudySetFirestore({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.originalFileName,
    required this.fileType,
    required this.flashcards,
    required this.quizzes,
    required this.createdDate,
    required this.lastStudied,
    this.studyCount = 0,
    this.tags = const [],
    this.difficulty = 'medium',
    this.isPublic = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'originalFileName': originalFileName,
    'fileType': fileType,
    'flashcards': flashcards,
    'quizzes': quizzes,
    'createdDate': Timestamp.fromDate(createdDate),
    'lastStudied': Timestamp.fromDate(lastStudied),
    'studyCount': studyCount,
    'tags': tags,
    'difficulty': difficulty,
    'isPublic': isPublic,
    'metadata': metadata,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory StudySetFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudySetFirestore(
      id: data['id'],
      userId: data['userId'],
      title: data['title'],
      content: data['content'],
      originalFileName: data['originalFileName'] ?? '',
      fileType: data['fileType'] ?? 'txt',
      flashcards: List<Map<String, dynamic>>.from(data['flashcards'] ?? []),
      quizzes: List<Map<String, dynamic>>.from(data['quizzes'] ?? []),
      createdDate: (data['createdDate'] as Timestamp).toDate(),
      lastStudied: (data['lastStudied'] as Timestamp).toDate(),
      studyCount: data['studyCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      difficulty: data['difficulty'] ?? 'medium',
      isPublic: data['isPublic'] ?? false,
      metadata: data['metadata'] ?? {},
    );
  }

  // Convert to local StudySet model
  StudySet toStudySet() {
    return StudySet(
      id: id,
      title: title,
      content: content,
      flashcards: flashcards.map((f) => Flashcard.fromJson(f)).toList(),
      quizzes: quizzes.map((q) => Quiz.fromJson(q)).toList(),
      createdDate: createdDate,
      lastStudied: lastStudied,
    );
  }

  // Create from local StudySet model
  factory StudySetFirestore.fromStudySet(StudySet studySet, String userId, {
    String originalFileName = '',
    String fileType = 'txt',
    List<String> tags = const [],
    String difficulty = 'medium',
    bool isPublic = false,
    Map<String, dynamic> metadata = const {},
  }) {
    return StudySetFirestore(
      id: studySet.id,
      userId: userId,
      title: studySet.title,
      content: studySet.content,
      originalFileName: originalFileName,
      fileType: fileType,
      flashcards: studySet.flashcards.map((f) => f.toJson()).toList(),
      quizzes: studySet.quizzes.map((q) => q.toJson()).toList(),
      createdDate: studySet.createdDate,
      lastStudied: studySet.lastStudied,
      tags: tags,
      difficulty: difficulty,
      isPublic: isPublic,
      metadata: metadata,
    );
  }
}

/// Quiz Result Document Structure
class QuizResultFirestore {
  final String id;
  final String userId;
  final String studySetId;
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final double percentage;
  final int timeTaken; // in milliseconds
  final DateTime completedDate;
  final List<String> incorrectAnswers;
  final String quizType; // 'multipleChoice', 'trueFalse', 'shortAnswer'
  final Map<String, dynamic> answers; // Question ID -> User Answer
  final int xpEarned;

  QuizResultFirestore({
    required this.id,
    required this.userId,
    required this.studySetId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.timeTaken,
    required this.completedDate,
    required this.incorrectAnswers,
    required this.quizType,
    required this.answers,
    required this.xpEarned,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'userId': userId,
    'studySetId': studySetId,
    'quizId': quizId,
    'quizTitle': quizTitle,
    'score': score,
    'totalQuestions': totalQuestions,
    'percentage': percentage,
    'timeTaken': timeTaken,
    'completedDate': Timestamp.fromDate(completedDate),
    'incorrectAnswers': incorrectAnswers,
    'quizType': quizType,
    'answers': answers,
    'xpEarned': xpEarned,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory QuizResultFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizResultFirestore(
      id: data['id'],
      userId: data['userId'],
      studySetId: data['studySetId'],
      quizId: data['quizId'],
      quizTitle: data['quizTitle'],
      score: data['score'],
      totalQuestions: data['totalQuestions'],
      percentage: data['percentage'].toDouble(),
      timeTaken: data['timeTaken'],
      completedDate: (data['completedDate'] as Timestamp).toDate(),
      incorrectAnswers: List<String>.from(data['incorrectAnswers'] ?? []),
      quizType: data['quizType'],
      answers: data['answers'] ?? {},
      xpEarned: data['xpEarned'] ?? 0,
    );
  }

  // Convert to local QuizResult model
  QuizResult toQuizResult() {
    return QuizResult(
      id: id,
      score: score,
      totalQuestions: totalQuestions,
      timeTaken: Duration(milliseconds: timeTaken),
      completedDate: completedDate,
      incorrectAnswers: incorrectAnswers,
    );
  }
}

/// User Progress Document Structure
class UserProgressFirestore {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int totalXP;
  final int totalStudyTime; // in minutes
  final DateTime lastStudyDate;
  final Map<String, int> subjectXP;
  final Map<String, dynamic> achievements;
  final int totalQuizzesTaken;
  final int totalFlashcardsReviewed;
  final double averageQuizScore;
  final int level;
  final List<String> unlockedFeatures;

  UserProgressFirestore({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXP,
    required this.totalStudyTime,
    required this.lastStudyDate,
    required this.subjectXP,
    this.achievements = const {},
    this.totalQuizzesTaken = 0,
    this.totalFlashcardsReviewed = 0,
    this.averageQuizScore = 0.0,
    this.level = 1,
    this.unlockedFeatures = const [],
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'totalXP': totalXP,
    'totalStudyTime': totalStudyTime,
    'lastStudyDate': Timestamp.fromDate(lastStudyDate),
    'subjectXP': subjectXP,
    'achievements': achievements,
    'totalQuizzesTaken': totalQuizzesTaken,
    'totalFlashcardsReviewed': totalFlashcardsReviewed,
    'averageQuizScore': averageQuizScore,
    'level': level,
    'unlockedFeatures': unlockedFeatures,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory UserProgressFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProgressFirestore(
      userId: data['userId'],
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalXP: data['totalXP'] ?? 0,
      totalStudyTime: data['totalStudyTime'] ?? 0,
      lastStudyDate: (data['lastStudyDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subjectXP: Map<String, int>.from(data['subjectXP'] ?? {}),
      achievements: data['achievements'] ?? {},
      totalQuizzesTaken: data['totalQuizzesTaken'] ?? 0,
      totalFlashcardsReviewed: data['totalFlashcardsReviewed'] ?? 0,
      averageQuizScore: (data['averageQuizScore'] ?? 0.0).toDouble(),
      level: data['level'] ?? 1,
      unlockedFeatures: List<String>.from(data['unlockedFeatures'] ?? []),
    );
  }

  // Convert to local UserProgress model
  UserProgress toUserProgress(List<QuizResult> recentResults) {
    return UserProgress(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalXP: totalXP,
      totalStudyTime: totalStudyTime,
      recentResults: recentResults,
      lastStudyDate: lastStudyDate,
      subjectXP: subjectXP,
    );
  }
}

/// Credit Usage Document Structure
class CreditUsageFirestore {
  final String userId;
  final DateTime date;
  final int creditsUsed;
  final int dailyQuota;
  final String subscriptionPlan;
  final List<Map<String, dynamic>> transactions;
  final int remainingCredits;
  final DateTime? quotaResetTime;

  CreditUsageFirestore({
    required this.userId,
    required this.date,
    required this.creditsUsed,
    required this.dailyQuota,
    required this.subscriptionPlan,
    required this.transactions,
    required this.remainingCredits,
    this.quotaResetTime,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'creditsUsed': creditsUsed,
    'dailyQuota': dailyQuota,
    'subscriptionPlan': subscriptionPlan,
    'transactions': transactions,
    'remainingCredits': remainingCredits,
    'quotaResetTime': quotaResetTime != null 
        ? Timestamp.fromDate(quotaResetTime!)
        : null,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory CreditUsageFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditUsageFirestore(
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      creditsUsed: data['creditsUsed'] ?? 0,
      dailyQuota: data['dailyQuota'] ?? 20,
      subscriptionPlan: data['subscriptionPlan'] ?? 'free',
      transactions: List<Map<String, dynamic>>.from(data['transactions'] ?? []),
      remainingCredits: data['remainingCredits'] ?? 0,
      quotaResetTime: (data['quotaResetTime'] as Timestamp?)?.toDate(),
    );
  }
}

/// Notification Preferences Document Structure
class NotificationFirestore {
  final String userId;
  final bool dailyReminders;
  final bool surpriseQuizzes;
  final bool streakReminders;
  final bool achievementAlerts;
  final String reminderTime; // e.g., "19:00"
  final List<String> deviceTokens;
  final Map<String, dynamic> preferences;

  NotificationFirestore({
    required this.userId,
    this.dailyReminders = true,
    this.surpriseQuizzes = true,
    this.streakReminders = true,
    this.achievementAlerts = true,
    this.reminderTime = '19:00',
    this.deviceTokens = const [],
    this.preferences = const {},
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'dailyReminders': dailyReminders,
    'surpriseQuizzes': surpriseQuizzes,
    'streakReminders': streakReminders,
    'achievementAlerts': achievementAlerts,
    'reminderTime': reminderTime,
    'deviceTokens': deviceTokens,
    'preferences': preferences,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory NotificationFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationFirestore(
      userId: data['userId'],
      dailyReminders: data['dailyReminders'] ?? true,
      surpriseQuizzes: data['surpriseQuizzes'] ?? true,
      streakReminders: data['streakReminders'] ?? true,
      achievementAlerts: data['achievementAlerts'] ?? true,
      reminderTime: data['reminderTime'] ?? '19:00',
      deviceTokens: List<String>.from(data['deviceTokens'] ?? []),
      preferences: data['preferences'] ?? {},
    );
  }
}

/// Notification Preferences Document Structure (Comprehensive)
class NotificationPreferencesFirestore {
  final String uid;
  final String notificationStyle; // 'cram', 'coach', 'mindful'
  final int frequencyPerDay;
  final List<Map<String, String>> timeWindows;
  final Map<String, String> quietHours;
  final String timezone;
  final bool allowTimeSensitive;
  final List<Map<String, dynamic>> exams;
  final Map<String, dynamic> analytics;
  final List<Map<String, dynamic>> pushTokens;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferencesFirestore({
    required this.uid,
    required this.notificationStyle,
    required this.frequencyPerDay,
    required this.timeWindows,
    required this.quietHours,
    required this.timezone,
    required this.allowTimeSensitive,
    required this.exams,
    required this.analytics,
    required this.pushTokens,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'notificationStyle': notificationStyle,
    'frequencyPerDay': frequencyPerDay,
    'timeWindows': timeWindows,
    'quietHours': quietHours,
    'timezone': timezone,
    'allowTimeSensitive': allowTimeSensitive,
    'exams': exams,
    'analytics': analytics,
    'pushTokens': pushTokens,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory NotificationPreferencesFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationPreferencesFirestore(
      uid: data['uid'],
      notificationStyle: data['notificationStyle'] ?? 'coach',
      frequencyPerDay: data['frequencyPerDay'] ?? 5,
      timeWindows: List<Map<String, String>>.from(data['timeWindows'] ?? []),
      quietHours: Map<String, String>.from(data['quietHours'] ?? {}),
      timezone: data['timezone'] ?? 'America/Chicago',
      allowTimeSensitive: data['allowTimeSensitive'] ?? true,
      exams: List<Map<String, dynamic>>.from(data['exams'] ?? []),
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
      pushTokens: List<Map<String, dynamic>>.from(data['pushTokens'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Notification Record Document Structure  
class NotificationRecordFirestore {
  final String id;
  final String uid;
  final String title;
  final String body;
  final String style;
  final String category;
  final DateTime sentAt;
  final DateTime? openedAt;
  final String? action;
  final String? deepLink;
  final String platform;
  final Map<String, dynamic>? metadata;

  NotificationRecordFirestore({
    required this.id,
    required this.uid,
    required this.title,
    required this.body,
    required this.style,
    required this.category,
    required this.sentAt,
    this.openedAt,
    this.action,
    this.deepLink,
    required this.platform,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'uid': uid,
    'title': title,
    'body': body,
    'style': style,
    'category': category,
    'sentAt': Timestamp.fromDate(sentAt),
    'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
    'action': action,
    'deepLink': deepLink,
    'platform': platform,
    'metadata': metadata,
  };

  factory NotificationRecordFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationRecordFirestore(
      id: data['id'],
      uid: data['uid'],
      title: data['title'],
      body: data['body'],
      style: data['style'],
      category: data['category'],
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      openedAt: data['openedAt'] != null ? (data['openedAt'] as Timestamp).toDate() : null,
      action: data['action'],
      deepLink: data['deepLink'],
      platform: data['platform'],
      metadata: data['metadata'],
    );
  }
}

/// Notification Schedule Document Structure
class NotificationScheduleFirestore {
  final String uid;
  final List<Map<String, dynamic>> next48h;
  final DateTime computedAt;

  NotificationScheduleFirestore({
    required this.uid,
    required this.next48h,
    required this.computedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'next48h': next48h,
    'computedAt': Timestamp.fromDate(computedAt),
  };

  factory NotificationScheduleFirestore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationScheduleFirestore(
      uid: data['uid'],
      next48h: List<Map<String, dynamic>>.from(data['next48h'] ?? []),
      computedAt: (data['computedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}