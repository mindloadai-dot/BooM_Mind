import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// Removed import: firebase_notification_manager - service removed
import 'package:mindload/services/notification_service.dart';

/// Adaptive AI coaching service that triggers contextual notifications based on user behavior
class AdaptiveCoachingService {
  static final AdaptiveCoachingService _instance = AdaptiveCoachingService._internal();
  factory AdaptiveCoachingService() => _instance;
  AdaptiveCoachingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  // Removed: FirebaseNotificationManager - service removed
  final NotificationService _notificationService = NotificationService.instance;

  // Behavior tracking
  DateTime? _lastStudySession;
  DateTime? _lastQuizSession;
  DateTime? _lastUploadSession;
  int _consecutiveCorrectAnswers = 0;
  int _consecutiveWrongAnswers = 0;
  bool _isInUltraMode = false;
  
  /// Initialize the adaptive coaching system
  Future<void> initialize() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('ℹ️ No user logged in, skipping adaptive coaching initialization');
        return;
      }

      // Load user's behavior history with error handling
      try {
        await _loadUserBehaviorHistory(user.uid);
        debugPrint('🧠 Adaptive Coaching Service initialized for user: ${user.uid}');
      } catch (e) {
        debugPrint('⚠️ Failed to load behavior history: $e, continuing with empty state');
      }
      
      debugPrint('✅ Adaptive Coaching Service ready');
    } catch (e) {
      debugPrint('❌ Failed to initialize adaptive coaching: $e');
      // Don't rethrow - allow app to continue without adaptive coaching
    }
  }

  /// Track when user uploads study material
  Future<void> trackMaterialUpload({
    required String materialType,  // 'pdf', 'text'
    required String materialId,
    required int pageCount,
    Map<String, dynamic>? metadata,
  }) async {
    _lastUploadSession = DateTime.now();
    
    await _analytics.logEvent(
      name: 'material_uploaded',
      parameters: {
        'material_type': materialType,
        'material_id': materialId,
        'page_count': pageCount,
        'timestamp': Timestamp.now().millisecondsSinceEpoch,
        if (metadata != null) ...metadata,
      },
    );

    // Trigger coaching based on upload behavior
    await _triggerPostUploadCoaching(materialType, pageCount);
  }

  /// Track study session activity
  Future<void> trackStudySession({
    required String studySetId,
    required Duration sessionDuration,
    required int itemsStudied,
    required double accuracyRate,
    Map<String, dynamic>? metadata,
  }) async {
    _lastStudySession = DateTime.now();
    
    await _analytics.logEvent(
      name: 'study_session_completed',
      parameters: {
        'study_set_id': studySetId,
        'duration_minutes': sessionDuration.inMinutes,
        'items_studied': itemsStudied,
        'accuracy_rate': accuracyRate,
        'timestamp': Timestamp.now().millisecondsSinceEpoch,
        if (metadata != null) ...metadata,
      },
    );

    // Update behavior counters
    if (accuracyRate >= 0.8) {
      _consecutiveCorrectAnswers++;
      _consecutiveWrongAnswers = 0;
    } else if (accuracyRate < 0.5) {
      _consecutiveWrongAnswers++;
      _consecutiveCorrectAnswers = 0;
    }

    // Trigger adaptive coaching
    await _triggerPostStudyCoaching(sessionDuration, accuracyRate, itemsStudied);
  }

  /// Track quiz performance
  Future<void> trackQuizPerformance({
    required String quizId,
    required String quizType,  // 'mcq', 'true_false', 'short_answer'
    required int correctAnswers,
    required int totalQuestions,
    required Duration timeTaken,
    Map<String, dynamic>? metadata,
  }) async {
    _lastQuizSession = DateTime.now();
    final accuracy = correctAnswers / totalQuestions;
    
    await _analytics.logEvent(
      name: 'quiz_completed',
      parameters: {
        'quiz_id': quizId,
        'quiz_type': quizType,
        'correct_answers': correctAnswers,
        'total_questions': totalQuestions,
        'accuracy': accuracy,
        'time_taken_seconds': timeTaken.inSeconds,
        'timestamp': Timestamp.now().millisecondsSinceEpoch,
        if (metadata != null) ...metadata,
      },
    );

    // Update streaks based on performance
    if (accuracy >= 0.7) {
      _consecutiveCorrectAnswers++;
      _consecutiveWrongAnswers = 0;
    } else {
      _consecutiveWrongAnswers++;
      _consecutiveCorrectAnswers = 0;
    }

    // Trigger adaptive coaching
    await _triggerPostQuizCoaching(quizType, accuracy, totalQuestions);
  }

  /// Track Ultra Study Mode usage
  Future<void> trackUltraMode({
    required bool isEntering,
    Duration? sessionDuration,
    Duration? focusTimerDuration,
    Map<String, dynamic>? metadata,
  }) async {
    _isInUltraMode = isEntering;
    
    await _analytics.logEvent(
      name: isEntering ? 'ultra_mode_entered' : 'ultra_mode_exited',
      parameters: {
        if (sessionDuration != null) 'session_duration_minutes': sessionDuration.inMinutes,
        if (focusTimerDuration != null) 'focus_timer_minutes': focusTimerDuration.inMinutes,
        'timestamp': Timestamp.now().millisecondsSinceEpoch,
        if (metadata != null) ...metadata,
      },
    );

    // Trigger coaching for ultra mode
    if (isEntering) {
      await _triggerUltraModeEntryCoaching();
    } else if (sessionDuration != null) {
      await _triggerUltraModeExitCoaching(sessionDuration);
    }
  }

  /// Track user inactivity
  Future<void> checkForInactivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    
    // Check various inactivity scenarios
    if (_lastStudySession != null) {
      final daysSinceStudy = now.difference(_lastStudySession!).inDays;
      
      if (daysSinceStudy >= 1) {
        await _triggerInactivityCoaching(daysSinceStudy);
      }
    }

    // Check for incomplete study sessions
    await _checkForIncompleteStudySessions();
    
    // Check for upcoming deadlines
    await _checkForUpcomingDeadlines();
  }

  /// Track streak events
  Future<void> trackStreakEvent({
    required int currentStreak,
    required bool streakContinued,
    Map<String, dynamic>? metadata,
  }) async {
    await _analytics.logEvent(
      name: streakContinued ? 'streak_continued' : 'streak_broken',
      parameters: {
        'current_streak': currentStreak,
        'timestamp': Timestamp.now().millisecondsSinceEpoch,
        if (metadata != null) ...metadata,
      },
    );

    if (streakContinued) {
      await _triggerStreakCelebration(currentStreak);
    } else {
      await _triggerStreakRecoveryCoaching();
    }
  }

  /// Track achievement unlocks
  Future<void> trackAchievement({
    required String achievementType,
    required String achievementName,
    Map<String, dynamic>? metadata,
  }) async {
    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'achievement_type': achievementType,
        'achievement_name': achievementName,
        'timestamp': Timestamp.now().millisecondsSinceEpoch,
        if (metadata != null) ...metadata,
      },
    );

    await _triggerAchievementCelebration(achievementType, achievementName);
  }

  /// PRIVATE COACHING TRIGGER METHODS

  /// Trigger coaching after material upload
  Future<void> _triggerPostUploadCoaching(String materialType, int pageCount) async {
    try {
      if (pageCount > 50) {
        debugPrint('📚 Large document detected, suggesting study planning');
        // TODO: Implement study planning suggestions
      }
      
      if (materialType == 'pdf') {
        debugPrint('📄 PDF uploaded, checking for text extraction quality');
        // TODO: Implement PDF quality assessment
      }
    } catch (e) {
      debugPrint('❌ Error in post-upload coaching: $e');
    }
  }

  /// Trigger coaching after study session
  Future<void> _triggerPostStudyCoaching(Duration sessionDuration, double accuracyRate, int itemsStudied) async {
    try {
      if (sessionDuration.inMinutes > 120) {
        debugPrint('⏰ Long study session detected, suggesting breaks');
        // TODO: Implement break suggestions
      }
      
      if (accuracyRate < 0.6) {
        debugPrint('📉 Low accuracy detected, suggesting review strategies');
        // TODO: Implement review suggestions
      }
      
      if (itemsStudied > 100) {
        debugPrint('📚 High volume study detected, suggesting spaced repetition');
        // TODO: Implement spaced repetition suggestions
      }
    } catch (e) {
      debugPrint('❌ Error in post-study coaching: $e');
    }
  }

  /// Trigger coaching after quiz completion
  Future<void> _triggerPostQuizCoaching(String quizType, double accuracy, int totalQuestions) async {
    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    String title = "Quiz Complete";
    String body;
    if (accuracy == 1.0) {
      body = "Flawless! Your neural pathways are firing perfectly!";
    } else if (accuracy >= 0.8) {
      body = "Excellent quiz performance with ${(accuracy * 100).toInt()}% accuracy!";
    } else if (accuracy >= 0.6) {
      body = "Good quiz results with ${(accuracy * 100).toInt()}% accuracy. Keep it up!";
    } else {
      body = "Let's review the concepts you missed. Practice makes perfect!";
    }
    await _notificationService.sendImmediateNotification(title, body);

    // Suggest immediate review for poor performance
    if (accuracy < 0.5) {
      await _suggestImmediateReview({});
    }
  }

  /// Trigger coaching for Ultra Mode entry
  Future<void> _triggerUltraModeEntryCoaching() async {
    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    await _notificationService.sendImmediateNotification(
      "Ultra Mode Activated",
      "Deep focus mode engaged! Your mind is about to operate at peak efficiency. Take deep breaths and let the binaural beats guide your focus."
    );
  }

  /// Trigger coaching for Ultra Mode exit
  Future<void> _triggerUltraModeExitCoaching(Duration sessionDuration) async {
    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    String title = "Ultra Mode Session";
    String body;
    if (sessionDuration.inMinutes >= 25) {
      body = "Incredible focus! Your brain has absorbed maximum knowledge in ${sessionDuration.inMinutes} minutes.";
    } else {
      body = "Every focused minute counts! Ready to go deeper next time? Session: ${sessionDuration.inMinutes} minutes.";
    }
    await _notificationService.sendImmediateNotification(title, body);
  }

  /// Trigger inactivity coaching
  Future<void> _triggerInactivityCoaching(int daysSinceLastActivity) async {
    final preferences = await _notificationService.getUserPreferences();
    // Preferences are now always available from unified service

    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    String title = "Welcome Back!";
    String body;
    if (daysSinceLastActivity == 1) {
      body = "Your neural networks miss you! Quick session to stay sharp?";
    } else if (daysSinceLastActivity <= 3) {
      body = "Time to reactivate those brain cells! Your knowledge awaits.";
    } else if (daysSinceLastActivity <= 7) {
      body = "A week away from learning? Let's gently restart your mind.";
    } else {
      body = "Welcome back! Your brain is ready to grow again.";
    }
    await _notificationService.sendImmediateNotification(title, body);
  }

  /// Trigger streak celebration
  Future<void> _triggerStreakCelebration(int streakCount) async {
    String title = "Streak Milestone!";
    String body;
    if (streakCount % 30 == 0) {
      body = "LEGENDARY! $streakCount days of consistent growth!";
    } else if (streakCount % 7 == 0) {
      body = "Week ${streakCount ~/ 7} complete! Your dedication is inspiring!";
    } else if (streakCount >= 3) {
      body = "Momentum is building! $streakCount days strong!";
    } else {
      return; // Don't celebrate very short streaks
    }

    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    await _notificationService.sendImmediateNotification(title, body);
  }

  /// Trigger streak recovery coaching
  Future<void> _triggerStreakRecoveryCoaching() async {
    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    await _notificationService.sendImmediateNotification(
      "Streak Reset",
      "Every master has faced setbacks. Ready to build an even stronger streak? Your next streak could be your best yet!"
    );
  }

  /// Trigger achievement celebration
  Future<void> _triggerAchievementCelebration(String type, String name) async {
    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    await _notificationService.sendImmediateNotification(
      "Achievement Unlocked!",
      "NEW ACHIEVEMENT: $name! Your skills are evolving!"
    );
  }

  /// Helper methods for specific coaching scenarios

  Future<void> _suggestBreak() async {
    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    await _notificationService.sendImmediateNotification(
      "Break Time",
      "Excellent focus session! A 5-minute break will help consolidate learning. Walk, stretch, or just breathe deeply."
    );
  }

  Future<void> _suggestImmediateReview(Map<String, dynamic> context) async {
    // Replace triggerAdaptiveCoaching with sendImmediateNotification
    await _notificationService.sendImmediateNotification(
      "Review Needed",
      "Strike while the iron is hot! Review those missed concepts now."
    );
  }

  Future<void> _checkForIncompleteStudySessions() async {
    // Implementation would check for study sessions that were started but not completed
    // This would require tracking session state in Firestore
  }

  Future<void> _checkForUpcomingDeadlines() async {
    final preferences = await _notificationService.getUserPreferences();
    // Preferences are now always available from unified service

    final now = DateTime.now();
    
    for (final exam in preferences.exams) {
      final daysUntilExam = exam.examDate.difference(now).inDays;
      
      if (daysUntilExam <= 7 && daysUntilExam > 0) {
        // Replace triggerAdaptiveCoaching with sendImmediateNotification
        await _notificationService.sendImmediateNotification(
          "Exam Approaching",
          "${exam.course} exam is in $daysUntilExam days. Time to intensify your preparation!"
        );
      }
    }
  }

  Future<void> _scheduleConditionalReminder({
    required Duration delay,
    required String condition,
    required Map<String, dynamic> context,
  }) async {
    // This would implement conditional reminder logic
    // For now, we'll just log the intent
    debugPrint('📅 Conditional reminder scheduled: $condition in ${delay.inMinutes} minutes');
  }

  Future<void> _loadUserBehaviorHistory(String userId) async {
    try {
      // Load recent activity from Firestore
      final recentActivityQuery = await _firestore
          .collection('user_activity')
          .doc(userId)
          .collection('recent')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (final doc in recentActivityQuery.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        
        switch (data['type']) {
          case 'study_session':
            _lastStudySession = timestamp;
            break;
          case 'quiz_session':
            _lastQuizSession = timestamp;
            break;
          case 'material_upload':
            _lastUploadSession = timestamp;
            break;
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load user behavior history: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🧹 Adaptive Coaching Service disposed');
  }
}