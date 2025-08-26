import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/firestore/firestore_data_schema.dart';
import 'package:mindload/models/study_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Firebase Helper Service providing additional utility functions
/// for advanced Firebase operations and batch processing
class FirebaseHelperService {
  static FirebaseHelperService? _instance;
  static FirebaseHelperService get instance {
    _instance ??= FirebaseHelperService._internal();
    return _instance!;
  }

  FirebaseHelperService._internal();

  final FirestoreRepository _repository = FirestoreRepository.instance;

  // MARK: - Batch Operations

  /// Batch create multiple study sets efficiently
  Future<List<String>> batchCreateStudySets({
    required List<StudySet> studySets,
    required String userId,
    Map<String, String> metadata = const {},
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final studySetIds = <String>[];

      for (final studySet in studySets) {
        final studySetId = FirebaseFirestore.instance
            .collection(FirestoreSchema.studySetsCollection)
            .doc()
            .id;
        
        final firestoreStudySet = StudySetFirestore.fromStudySet(
          StudySet(
            id: studySetId,
            title: studySet.title,
            content: studySet.content,
            flashcards: studySet.flashcards,
            quizzes: studySet.quizzes,
            createdDate: DateTime.now(),
            lastStudied: DateTime.now(),
          ),
          userId,
          metadata: metadata,
        );

        batch.set(
          FirebaseFirestore.instance
              .collection(FirestoreSchema.studySetsCollection)
              .doc(studySetId),
          firestoreStudySet.toFirestore(),
        );

        studySetIds.add(studySetId);
      }

      await batch.commit();
      if (kDebugMode) {
        debugPrint('✅ Batch created ${studySets.length} study sets');
      }
      return studySetIds;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to batch create study sets: $e');
      }
      throw Exception('Failed to batch create study sets: $e');
    }
  }

  /// Batch save quiz results with progress updates
  Future<void> batchSaveQuizResults({
    required List<QuizResult> results,
    required String userId,
    required String studySetId,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      int totalXP = 0;

      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final quizResultId = FirebaseFirestore.instance
            .collection(FirestoreSchema.quizResultsCollection)
            .doc()
            .id;
        
        final xpEarned = result.score * 10; // 10 XP per correct answer
        totalXP += xpEarned;

        final firestoreResult = QuizResultFirestore(
          id: quizResultId,
          userId: userId,
          studySetId: studySetId,
          quizId: 'quiz_$i',
          quizTitle: 'Quiz ${i + 1}',
          score: result.score,
          totalQuestions: result.totalQuestions,
          percentage: (result.score / result.totalQuestions) * 100,
          timeTaken: result.timeTaken.inMilliseconds,
          completedDate: result.completedDate,
          incorrectAnswers: result.incorrectAnswers,
          quizType: 'mixed',
          answers: {},
          xpEarned: xpEarned,
        );

        batch.set(
          FirebaseFirestore.instance
              .collection(FirestoreSchema.quizResultsCollection)
              .doc(quizResultId),
          firestoreResult.toFirestore(),
        );
      }

      // Update user progress with total XP
      batch.update(
        FirebaseFirestore.instance
            .collection(FirestoreSchema.userProgressCollection)
            .doc(userId),
        {
          'totalXP': FieldValue.increment(totalXP),
          'totalQuizzesTaken': FieldValue.increment(results.length),
          'lastStudyDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Mark study set as studied
      batch.update(
        FirebaseFirestore.instance
            .collection(FirestoreSchema.studySetsCollection)
            .doc(studySetId),
        {
          'lastStudied': FieldValue.serverTimestamp(),
          'studyCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      if (kDebugMode) {
        debugPrint('✅ Batch saved ${results.length} quiz results with $totalXP XP');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to batch save quiz results: $e');
      }
      throw Exception('Failed to batch save quiz results: $e');
    }
  }

  // MARK: - Data Analytics and Insights

  /// Get user study analytics
  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      final studySetsSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreSchema.studySetsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final quizResultsSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreSchema.quizResultsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('completedDate', descending: true)
          .limit(100)
          .get();

      final progress = await _repository.getUserProgress(userId);

      // Calculate analytics
      final studySets = studySetsSnapshot.docs
          .map((doc) => StudySetFirestore.fromFirestore(doc))
          .toList();

      final quizResults = quizResultsSnapshot.docs
          .map((doc) => QuizResultFirestore.fromFirestore(doc))
          .toList();

      final totalQuizzes = quizResults.length;
      final averageScore = totalQuizzes > 0
          ? quizResults.map((r) => r.percentage).reduce((a, b) => a + b) / totalQuizzes
          : 0.0;

      final studyFrequency = _calculateStudyFrequency(quizResults);
      final subjectPerformance = _calculateSubjectPerformance(studySets, quizResults);
      final streakData = _calculateStreakData(quizResults);

      return {
        'total_study_sets': studySets.length,
        'total_quizzes': totalQuizzes,
        'average_score': averageScore,
        'total_xp': progress.totalXP,
        'current_streak': progress.currentStreak,
        'longest_streak': progress.longestStreak,
        'study_frequency': studyFrequency,
        'subject_performance': subjectPerformance,
        'streak_data': streakData,
        'recent_activity': quizResults.take(10).map((r) => {
              'date': r.completedDate.toIso8601String(),
              'score': r.score,
              'total_questions': r.totalQuestions,
              'percentage': r.percentage,
            }).toList(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get user analytics: $e');
      }
      throw Exception('Failed to get user analytics: $e');
    }
  }

  /// Calculate study frequency patterns
  Map<String, dynamic> _calculateStudyFrequency(List<QuizResultFirestore> results) {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    
    final recentResults = results
        .where((r) => r.completedDate.isAfter(last30Days))
        .toList();

    final dailyCount = <String, int>{};
    final weeklyCount = <int, int>{};

    for (final result in recentResults) {
      final dateKey = '${result.completedDate.year}-${result.completedDate.month.toString().padLeft(2, '0')}-${result.completedDate.day.toString().padLeft(2, '0')}';
      dailyCount[dateKey] = (dailyCount[dateKey] ?? 0) + 1;

      final weekday = result.completedDate.weekday;
      weeklyCount[weekday] = (weeklyCount[weekday] ?? 0) + 1;
    }

    return {
      'daily_activity': dailyCount,
      'weekly_pattern': weeklyCount,
      'total_sessions_30d': recentResults.length,
      'average_daily': recentResults.length / 30,
    };
  }

  /// Calculate performance by subject/topic
  Map<String, dynamic> _calculateSubjectPerformance(
    List<StudySetFirestore> studySets,
    List<QuizResultFirestore> results,
  ) {
    final subjectScores = <String, List<double>>{};

    for (final result in results) {
      final studySet = studySets.firstWhere(
        (s) => s.id == result.studySetId,
        orElse: () => StudySetFirestore(
          id: '',
          userId: '',
          title: 'Unknown',
          content: '',
          originalFileName: '',
          fileType: '',
          flashcards: [],
          quizzes: [],
          createdDate: DateTime.now(),
          lastStudied: DateTime.now(),
          tags: ['general'],
        ),
      );

      final subject = studySet.tags.isNotEmpty ? studySet.tags.first : 'General';
      subjectScores.putIfAbsent(subject, () => []);
      subjectScores[subject]!.add(result.percentage);
    }

    final subjectAverages = <String, double>{};
    for (final entry in subjectScores.entries) {
      final scores = entry.value;
      if (scores.isNotEmpty) {
        subjectAverages[entry.key] = scores.reduce((a, b) => a + b) / scores.length;
      }
    }

    return subjectAverages;
  }

  /// Calculate streak patterns and trends
  Map<String, dynamic> _calculateStreakData(List<QuizResultFirestore> results) {
    if (results.isEmpty) return {'current_streak': 0, 'streak_history': []};

    results.sort((a, b) => b.completedDate.compareTo(a.completedDate));
    
    int currentStreak = 0;
    final streakHistory = <Map<String, dynamic>>[];
    DateTime? lastDate;

    for (final result in results.reversed) {
      final resultDate = DateTime(
        result.completedDate.year,
        result.completedDate.month,
        result.completedDate.day,
      );

      if (lastDate == null || resultDate.difference(lastDate).inDays <= 1) {
        if (lastDate == null || resultDate.difference(lastDate).inDays == 1) {
          currentStreak++;
        }
        lastDate = resultDate;
      } else {
        if (currentStreak > 0) {
          streakHistory.add({
            'streak_length': currentStreak,
            'end_date': lastDate.toIso8601String(),
          });
        }
        currentStreak = 1;
        lastDate = resultDate;
      }
    }

    if (currentStreak > 0) {
      streakHistory.add({
        'streak_length': currentStreak,
        'end_date': lastDate?.toIso8601String(),
      });
    }

    return {
      'current_streak': currentStreak,
      'streak_history': streakHistory,
      'longest_streak': streakHistory.isEmpty ? 0 : 
          streakHistory.map((s) => s['streak_length'] as int).reduce((a, b) => a > b ? a : b),
    };
  }

  // MARK: - Data Export and Backup

  /// Export user's complete data for backup or transfer
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final userData = await _repository.getUser(userId);
      final studySets = await _repository.getUserStudySets(userId).first;
      final progress = await _repository.getUserProgress(userId);
      final recentResults = await _repository.getUserQuizResults(userId, limit: 200).first;
      final credits = await _repository.getTodaysCredits(userId);
      final notifications = await _repository.getNotificationPreferences(userId);

      return {
        'export_metadata': {
          'exported_at': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'data_version': '1.0',
        },
        'user_profile': userData?.toFirestore(),
        'study_sets': studySets.map((s) => s.toFirestore()).toList(),
        'user_progress': progress.toFirestore(),
        'quiz_results': recentResults.map((r) => r.toFirestore()).toList(),
        'credit_usage': credits.toFirestore(),
        'notification_preferences': notifications.toFirestore(),
        'analytics': await getUserAnalytics(userId),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to export user data: $e');
      }
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Import user data from backup
  Future<void> importUserData(String userId, Map<String, dynamic> data) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Import user profile
      if (data.containsKey('user_profile') && data['user_profile'] != null) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestoreSchema.usersCollection)
              .doc(userId),
          data['user_profile'],
          SetOptions(merge: true),
        );
      }

      // Import study sets
      if (data.containsKey('study_sets') && data['study_sets'] is List) {
        final studySets = data['study_sets'] as List;
        for (final studySetData in studySets) {
          final studySetId = studySetData['id'] ?? 
              FirebaseFirestore.instance.collection(FirestoreSchema.studySetsCollection).doc().id;
          
          batch.set(
            FirebaseFirestore.instance
                .collection(FirestoreSchema.studySetsCollection)
                .doc(studySetId),
            {
              ...studySetData,
              'userId': userId, // Ensure correct user ID
              'importedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }

      // Import user progress
      if (data.containsKey('user_progress') && data['user_progress'] != null) {
        batch.set(
          FirebaseFirestore.instance
              .collection(FirestoreSchema.userProgressCollection)
              .doc(userId),
          {
            ...data['user_progress'],
            'userId': userId, // Ensure correct user ID
            'importedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      if (kDebugMode) {
        debugPrint('✅ User data imported successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to import user data: $e');
      }
      throw Exception('Failed to import user data: $e');
    }
  }

  // MARK: - Real-time Data Synchronization

  /// Sync user data across devices
  Stream<Map<String, dynamic>> getUserDataStream(String userId) {
    return FirebaseFirestore.instance
        .collection(FirestoreSchema.usersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) return {};

          final user = UserProfileFirestore.fromFirestore(userDoc);
          final progress = await _repository.getUserProgress(userId);
          final studySetsSnapshot = await FirebaseFirestore.instance
              .collection(FirestoreSchema.studySetsCollection)
              .where('userId', isEqualTo: userId)
              .limit(10)
              .get();

          final studySets = studySetsSnapshot.docs
              .map((doc) => StudySetFirestore.fromFirestore(doc))
              .toList();

          return {
            'user': user.toFirestore(),
            'progress': progress.toFirestore(),
            'recent_study_sets': studySets.map((s) => s.toFirestore()).toList(),
            'synced_at': DateTime.now().toIso8601String(),
          };
        });
  }

  // MARK: - Performance Optimization

  /// Preload user data for better performance
  Future<void> preloadUserData(String userId) async {
    try {
      // Preload critical collections in parallel
      final futures = [
        _repository.getUser(userId),
        _repository.getUserProgress(userId),
        FirebaseFirestore.instance
            .collection(FirestoreSchema.studySetsCollection)
            .where('userId', isEqualTo: userId)
            .limit(5)
            .get(),
        FirebaseFirestore.instance
            .collection(FirestoreSchema.quizResultsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('completedDate', descending: true)
            .limit(10)
            .get(),
      ];

      await Future.wait(futures);
      if (kDebugMode) {
        debugPrint('✅ User data preloaded for optimal performance');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to preload user data: $e');
      }
    }
  }

  /// Clear offline cache and force refresh
  Future<void> refreshUserData(String userId) async {
    try {
      // Clear specific cache
      await FirebaseFirestore.instance.clearPersistence();
      
      // Preload fresh data
      await preloadUserData(userId);
      
      if (kDebugMode) {
        debugPrint('✅ User data refreshed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to refresh user data: $e');
      }
    }
  }

  // MARK: - Data Validation and Health Checks

  /// Validate user data integrity
  Future<Map<String, dynamic>> validateUserData(String userId) async {
    try {
      final issues = <String>[];
      final warnings = <String>[];

      // Check user profile
      final user = await _repository.getUser(userId);
      if (user == null) {
        issues.add('User profile not found');
      } else {
        if (user.email.isEmpty) warnings.add('Empty email address');
        if (user.displayName.isEmpty) warnings.add('Empty display name');
      }

      // Check user progress
      try {
        final progress = await _repository.getUserProgress(userId);
        if (progress.totalXP < 0) issues.add('Negative XP value');
        if (progress.currentStreak < 0) issues.add('Negative streak value');
      } catch (e) {
        issues.add('User progress data corrupted: $e');
      }

      // Check study sets
      final studySetsSnapshot = await FirebaseFirestore.instance
          .collection(FirestoreSchema.studySetsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      int orphanedStudySets = 0;
      for (final doc in studySetsSnapshot.docs) {
        try {
          StudySetFirestore.fromFirestore(doc);
        } catch (e) {
          orphanedStudySets++;
        }
      }

      if (orphanedStudySets > 0) {
        warnings.add('$orphanedStudySets study sets have data issues');
      }

      return {
        'is_healthy': issues.isEmpty,
        'issues': issues,
        'warnings': warnings,
        'checked_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'is_healthy': false,
        'issues': ['Data validation failed: $e'],
        'warnings': [],
        'checked_at': DateTime.now().toIso8601String(),
      };
    }
  }

  // MARK: - Utility Methods

  /// Get Firebase connection status
  Future<Map<String, bool>> getConnectionStatus() async {
    try {
      return {
        'firestore': await _repository.isConnected(),
        'auth': FirebaseAuth.instance.currentUser != null,
        'storage': await _testStorageConnection(),
        'messaging': await _testMessagingConnection(),
      };
    } catch (e) {
      return {
        'firestore': false,
        'auth': false,
        'storage': false,
        'messaging': false,
      };
    }
  }

  /// Test Firebase Storage connection
  Future<bool> _testStorageConnection() async {
    try {
      final bucket = FirebaseStorage.instance.ref();
      await bucket.listAll();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Storage connection test failed: $e');
      }
      return false;
    }
  }

  /// Test Firebase Messaging connection
  Future<bool> _testMessagingConnection() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      return token != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Messaging connection test failed: $e');
      }
      return false;
    }
  }
}