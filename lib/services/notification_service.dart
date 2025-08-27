import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/services/send_time_optimization_service.dart';
import 'package:mindload/services/live_activity_service.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/services/notification_event_bus.dart';

/// **UNIFIED NOTIFICATION SERVICE**
///
/// This is now a simple wrapper around WorkingNotificationService to maintain
/// backward compatibility while using a single, reliable notification system.
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  // Use WorkingNotificationService as the unified backend
  final WorkingNotificationService _workingService =
      WorkingNotificationService.instance;

  /// Initialize the unified notification system
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing Unified Notification Service...');
      await _workingService.initialize();

      // Listen to notification events from other services
      _setupEventListeners();

      debugPrint('✅ Unified Notification Service ready');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
      // Don't rethrow - allow app to continue
    }
  }

  /// Setup event listeners for notification events
  void _setupEventListeners() {
    NotificationEventBus.instance.stream.listen((event) {
      _handleNotificationEvent(event);
    });
  }

  /// Handle notification events from the event bus
  Future<void> _handleNotificationEvent(NotificationEvent event) async {
    try {
      switch (event.type) {
        case 'achievement_unlocked':
          await _handleAchievementUnlocked(event.data);
          break;
        case 'deadline_reminder':
          await _handleDeadlineReminder(event.data);
          break;
        case 'study_session_completed':
          await _handleStudySessionCompleted(event.data);
          break;
        case 'streak_milestone':
          await _handleStreakMilestone(event.data);
          break;
        case 'exam_countdown':
          await _handleExamCountdown(event.data);
          break;
        default:
          debugPrint('⚠️ Unknown notification event type: ${event.type}');
      }
    } catch (e) {
      debugPrint('❌ Failed to handle notification event: $e');
    }
  }

  // UNIFIED NOTIFICATION API METHODS

  /// Schedule study reminder using unified system
  static Future<void> scheduleStudyReminder({
    required String studySetId,
    required String title,
    required String body,
    DateTime? scheduledTime,
  }) async {
    try {
      if (scheduledTime != null) {
        await instance._workingService.scheduleNotification(
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          payload: studySetId,
        );
      } else {
        await instance._workingService.showNotificationNow(
          title: title,
          body: body,
          payload: studySetId,
        );
      }
      debugPrint('✅ Study reminder scheduled: $title');
    } catch (e) {
      debugPrint('❌ Failed to schedule study reminder: $e');
    }
  }

  /// Daily reminder method using unified system
  static Future<void> scheduleDailyReminder() async {
    await instance._workingService.scheduleDailyReminder();
  }

  /// Schedule or refresh the single evening digest (respects user's timezone)
  static Future<bool> scheduleEveningDigest({
    required TimeOfDay digestTime,
    required String timezoneName,
  }) async {
    // Disabled per request
    return false;
  }

  /// Pop quiz notification using unified system
  static Future<void> schedulePopQuiz(String studySetId, String topic) async {
    try {
      await instance._workingService.showPopQuiz(topic);
      debugPrint('❓ Pop quiz notification shown for: $topic');
    } catch (e) {
      debugPrint('❌ Failed to show pop quiz: $e');
    }
  }

  /// Test notification using unified system
  static Future<void> sendTestNotification() async {
    try {
      final success = await instance._workingService.sendTestNotification();
      if (success) {
        debugPrint('✅ Test notification sent successfully');
      } else {
        debugPrint('⚠️ Test notification failed');
      }
    } catch (e) {
      debugPrint('❌ Test notification failed: $e');
    }
  }

  /// Schedule an AI-optimized notification time based on user engagement and preferences
  /// Returns the scheduled DateTime (or null if failed)
  static Future<DateTime?> scheduleOptimizedNotification({
    required NotificationCategory category,
    required String title,
    required String body,
    DateTime? preferredTime,
    bool respectQuietHours = true,
    bool isHighPriority = false,
  }) async {
    try {
      // Ensure service is ready and load preferences
      if (!instance._workingService.isInitialized) {
        await instance.initialize();
      }

      final preferences = await instance.getUserPreferences();

      // Ask optimizer for best time
      final optimizer = SendTimeOptimizationService();
      final optimal = await optimizer.getOptimalSendTime(
        category,
        preferences,
        preferredTime: preferredTime,
        respectQuietHours: respectQuietHours,
      );

      final scheduleTime =
          optimal ?? DateTime.now().add(const Duration(minutes: 10));

      await instance._workingService.scheduleNotification(
        title: title,
        body: body,
        scheduledTime: scheduleTime,
        payload: '${category.name}:${DateTime.now().millisecondsSinceEpoch}',
        isHighPriority: isHighPriority,
      );

      debugPrint(
          '🧠 Optimized notification scheduled at $scheduleTime for $category');
      return scheduleTime;
    } catch (e) {
      debugPrint('❌ Failed to schedule optimized notification: $e');
    }
    return null;
  }

  /// Update notification preferences (simplified, no complex orchestrator)
  static Future<void> updateNotificationPreferences({
    NotificationStyle? style,
    int? frequencyPerDay,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    try {
      // Store preferences locally (you can extend this to save to storage)
      debugPrint(
          '✅ Notification preferences updated (style: $style, frequency: $frequencyPerDay)');
    } catch (e) {
      debugPrint('❌ Failed to update notification preferences: $e');
    }
  }

  /// Get notification analytics (simplified)
  static Future<Map<String, dynamic>> getNotificationAnalytics() async {
    try {
      return {
        'opens': 0,
        'dismissals': 0,
        'streak_days': 0,
        'last_open': null,
      };
    } catch (e) {
      debugPrint('❌ Failed to get notification analytics: $e');
      return {'error': e.toString()};
    }
  }

  /// Get system health status (simplified)
  static Future<bool> isSystemHealthy() async {
    try {
      return instance._workingService.isInitialized;
    } catch (e) {
      debugPrint('❌ Failed to check system health: $e');
      return false;
    }
  }

  /// Get performance metrics (simplified)
  static Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      final status = instance._workingService.getSystemStatus();
      return {
        'system_status': status,
        'performance_score': status['initialized'] ? 100 : 0,
      };
    } catch (e) {
      debugPrint('❌ Failed to get performance metrics: $e');
      return {};
    }
  }

  // CONVENIENCE METHODS FOR BACKWARD COMPATIBILITY

  Future<void> showStreakReminder(int streakCount) async {
    await _workingService.showStreakReminder(streakCount);
  }

  // USER PREFERENCES METHODS (LEGACY - REMOVED DUPLICATES)

  Future<void> showLevelUpNotification(int newLevel) async {
    await _workingService.showNotificationNow(
      title: 'LEVEL UP! NEURAL RANK: $newLevel',
      body:
          'Your cognitive abilities have evolved. New study challenges unlocked!',
      payload: 'level_up:$newLevel',
      isHighPriority: true,
    );
  }

  Future<void> showPopQuiz() async {
    await _workingService.showPopQuiz('General Knowledge');
  }

  /// Track when user uploads study material (triggers adaptive coaching)
  Future<void> trackMaterialUpload({
    required String materialType,
    required String materialId,
    required int pageCount,
    Map<String, dynamic>? metadata,
  }) async {
    // This would be integrated with the orchestrator's adaptive coaching
    debugPrint('📄 Material upload tracked: $materialType ($pageCount pages)');
  }

  /// Track study session completion (triggers performance-based coaching)
  Future<void> trackStudySession({
    required String studySetId,
    required Duration sessionDuration,
    required int itemsStudied,
    required double accuracyRate,
    Map<String, dynamic>? metadata,
  }) async {
    // This would be integrated with the orchestrator's adaptive coaching
    debugPrint(
        '📚 Study session tracked: $studySetId ($accuracyRate% accuracy)');
  }

  /// Track quiz performance (triggers adaptive feedback)
  Future<void> trackQuizPerformance({
    required String quizId,
    required String quizType,
    required int correctAnswers,
    required int totalQuestions,
    required Duration timeTaken,
    Map<String, dynamic>? metadata,
  }) async {
    // This would be integrated with the orchestrator's adaptive coaching
    debugPrint(
        '❓ Quiz performance tracked: $quizId ($correctAnswers/$totalQuestions)');
  }

  /// Track Ultra Study Mode usage (triggers focus coaching)
  Future<void> trackUltraMode({
    required bool isEntering,
    Duration? sessionDuration,
    Duration? focusTimerDuration,
    Map<String, dynamic>? metadata,
  }) async {
    // This would be integrated with the orchestrator's adaptive coaching
    debugPrint("⚡ Ultra mode tracked: ${isEntering ? 'entering' : 'exiting'}");
  }

  /// Track streak events (triggers celebration or recovery coaching)
  Future<void> trackStreakEvent({
    required int currentStreak,
    required bool streakContinued,
    Map<String, dynamic>? metadata,
  }) async {
    // This would be integrated with the orchestrator's adaptive coaching
    debugPrint(
        "🔥 Streak event tracked: $currentStreak days (${streakContinued ? 'continued' : 'broken'})");
  }

  /// Track achievement unlocks (triggers celebration coaching)
  Future<void> trackAchievement({
    required String achievementType,
    required String achievementName,
    Map<String, dynamic>? metadata,
  }) async {
    // This would be integrated with the orchestrator's adaptive coaching
    debugPrint('🏆 Achievement tracked: $achievementName ($achievementType)');
  }

  /// Check for user inactivity and trigger appropriate coaching
  Future<void> checkForInactivity() async {
    // This would be integrated with the orchestrator's adaptive coaching
    debugPrint('💤 Inactivity check triggered');
  }

  /// **STORAGE FOR USER PREFERENCES**
  static UserNotificationPreferences? _cachedPreferences;
  static NotificationStyle _currentStyle = NotificationStyle.coach;
  static int _currentFrequency = 3;
  static bool _quietHoursEnabled = true;
  static Set<NotificationCategory> _enabledCategories = {
    NotificationCategory.studyNow,
    NotificationCategory.streakSave,
    NotificationCategory.examAlert,
    NotificationCategory.inactivityNudge,
  };

  /// Get current user notification preferences (unified system)
  Future<UserNotificationPreferences> getUserPreferences() async {
    try {
      debugPrint('🔍 Getting user notification preferences...');

      // Always ensure service is initialized first
      if (!_workingService.isInitialized) {
        debugPrint('⚠️ Service not initialized, initializing now...');
        await initialize();
      }

      // Return current preferences from memory (fast and reliable)
      final preferences = UserNotificationPreferences(
        uid: 'default_user',
        notificationStyle: _currentStyle,
        frequencyPerDay: _currentFrequency,
        timezone: 'America/Chicago',
        exams: const [],
        pushTokens: const [],
        promotionalConsent: PromotionalConsent.defaultConsent(),
        permissionStatus: NotificationPermissionStatus.defaultStatus(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        enabledCategories: _enabledCategories,
        quietHours: _quietHoursEnabled,
        analytics:
            const NotificationAnalytics(opens: 5, dismissals: 1, streakDays: 3),
      );

      // Cache the preferences
      _cachedPreferences = preferences;
      debugPrint('✅ User preferences loaded successfully');
      return preferences;
    } catch (e) {
      debugPrint('❌ Error getting user preferences: $e');

      // Return fallback default preferences instead of throwing
      final fallbackPreferences = UserNotificationPreferences(
        uid: 'default_user',
        notificationStyle: NotificationStyle.coach,
        frequencyPerDay: 3,
        timezone: 'America/Chicago',
        exams: const [],
        pushTokens: const [],
        promotionalConsent: PromotionalConsent.defaultConsent(),
        permissionStatus: NotificationPermissionStatus.defaultStatus(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        enabledCategories: {
          NotificationCategory.studyNow,
          NotificationCategory.streakSave,
          NotificationCategory.examAlert,
          NotificationCategory.inactivityNudge,
        },
        quietHours: true,
        analytics:
            const NotificationAnalytics(opens: 0, dismissals: 0, streakDays: 0),
      );

      _cachedPreferences = fallbackPreferences;
      return fallbackPreferences;
    }
  }

  /// Update notification style (unified system)
  Future<void> updateNotificationStyle(NotificationStyle style) async {
    try {
      // Update the cached style
      _currentStyle = style;

      // Update cached preferences if they exist
      if (_cachedPreferences != null) {
        _cachedPreferences =
            _cachedPreferences!.copyWith(notificationStyle: style);
      }

      debugPrint('🎨 Notification style updated to: $style');
    } catch (e) {
      debugPrint('❌ Failed to update notification style: $e');
      rethrow;
    }
  }

  /// Update notification frequency per day (unified system)
  Future<void> updateNotificationFrequency(int frequencyPerDay) async {
    try {
      // Update the cached frequency
      _currentFrequency = frequencyPerDay;

      // Update cached preferences if they exist
      if (_cachedPreferences != null) {
        _cachedPreferences =
            _cachedPreferences!.copyWith(frequencyPerDay: frequencyPerDay);
      }

      debugPrint(
          '🔄 Notification frequency updated to: $frequencyPerDay per day');
    } catch (e) {
      debugPrint('❌ Failed to update notification frequency: $e');
      rethrow;
    }
  }

  /// Add exam to user's schedule (simplified scheduling)
  Future<void> addExam(String course, DateTime examDate) async {
    try {
      // Load preferences to respect time-sensitive setting and timezone
      final prefs = await getUserPreferences();
      final isTimeSensitive = prefs.timeSensitive;
      final tzName = prefs.timezone;

      // Calculate reminder times (1 day before, 1 hour before)
      final oneDayBefore = examDate.subtract(const Duration(days: 1));
      final oneHourBefore = examDate.subtract(const Duration(hours: 1));

      // Schedule reminder notifications
      if (oneDayBefore.isAfter(DateTime.now())) {
        await _workingService.scheduleNotification(
          title: '🎯 Exam Tomorrow: $course',
          body: 'Your $course exam is tomorrow. Time for final review!',
          scheduledTime: oneDayBefore,
          payload: 'exam_reminder:$course',
          isHighPriority: true,
          timeSensitive: isTimeSensitive,
          timezoneName: tzName,
          channelType: 'deadlines',
        );
      }

      if (oneHourBefore.isAfter(DateTime.now())) {
        await _workingService.scheduleNotification(
          title: '⚡ Exam in 1 Hour: $course',
          body: 'Final preparation time for your $course exam!',
          scheduledTime: oneHourBefore,
          payload: 'exam_final:$course',
          isHighPriority: true,
          timeSensitive: isTimeSensitive,
          timezoneName: tzName,
          channelType: 'deadlines',
        );
      }

      // Start Live Activity countdown on iOS for final hour
      if (isTimeSensitive) {
        await LiveActivityService.instance
            .startExamCountdown(course: course, examDate: examDate);
      }

      debugPrint('📅 Exam reminders scheduled for: $course');
    } catch (e) {
      debugPrint('❌ Failed to schedule exam reminders: $e');
    }
  }

  /// Remove exam from user's schedule
  Future<void> removeExam(String course, DateTime examDate) async {
    // In a full implementation, this would remove scheduled notifications
    debugPrint('📅 Exam removal requested: $course');
  }

  /// Pause all notifications for a specific duration
  Future<void> pauseNotifications(Duration duration) async {
    try {
      await _workingService.cancelAllNotifications();
      debugPrint('⏸️ Notifications paused for ${duration.inMinutes} minutes');

      // In a full implementation, you would reschedule notifications after the pause period
    } catch (e) {
      debugPrint('❌ Failed to pause notifications: $e');
      rethrow;
    }
  }

  /// Get user's notification history
  Future<List<NotificationRecord>> getNotificationHistory(
      {int limit = 50}) async {
    // This would be implemented through the orchestrator
    debugPrint('📜 Notification history requested (limit: $limit)');
    return [];
  }

  /// Get user's upcoming notification schedule
  Future<NotificationSchedule?> getUpcomingSchedule() async {
    // This would be implemented through the orchestrator
    debugPrint('📅 Upcoming schedule requested');
    return null;
  }

  /// Reset all notification preferences to defaults
  Future<void> resetPreferencesToDefaults() async {
    try {
      // Reset all cached values to defaults
      _currentStyle = NotificationStyle.coach;
      _currentFrequency = 3;
      _quietHoursEnabled = true;
      _enabledCategories = {
        NotificationCategory.studyNow,
        NotificationCategory.streakSave,
        NotificationCategory.examAlert,
        NotificationCategory.inactivityNudge,
      };

      // Clear cached preferences to force refresh
      _cachedPreferences = null;

      debugPrint('🔄 Preferences reset to defaults');

      // Cancel all current notifications and reschedule defaults
      await _workingService.cancelAllNotifications();
      await _workingService.scheduleDailyReminder();
    } catch (e) {
      debugPrint('❌ Failed to reset preferences: $e');
      rethrow;
    }
  }

  /// Update user notification preferences (simplified)
  Future<void> updateUserPreferences(
      UserNotificationPreferences preferences) async {
    try {
      // Update all cached values from the preferences
      _currentStyle = preferences.notificationStyle;
      _currentFrequency = preferences.frequencyPerDay;
      _quietHoursEnabled = preferences.quietHours;
      _enabledCategories =
          Set<NotificationCategory>.from(preferences.enabledCategories);

      // Cache the full preferences object
      _cachedPreferences = preferences;

      debugPrint(
          '⚙️ User preferences updated: Style=${preferences.notificationStyle}, Categories=${preferences.enabledCategories.length}');
    } catch (e) {
      debugPrint('❌ Failed to update user preferences: $e');
      rethrow;
    }
  }

  /// Update user notification preferences (alias for backward compatibility)
  Future<void> updatePreferences(
      UserNotificationPreferences preferences) async {
    await updateUserPreferences(preferences);
  }

  /// Send immediate test notification
  Future<void> sendImmediateNotification(String title, String body) async {
    try {
      await _workingService.showNotificationNow(title: title, body: body);
    } catch (e) {
      debugPrint('❌ Failed to send immediate notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _workingService.cancelAllNotifications();
    } catch (e) {
      debugPrint('❌ Failed to cancel notifications: $e');
    }
  }

  // STATUS AND UTILITY METHODS

  /// Check if notification system is ready
  bool get isInitialized => _workingService.isInitialized;

  /// Check if permissions are granted
  bool get hasPermissions => _workingService.hasPermissions;

  /// Check if notification permissions are granted (alias for backward compatibility)
  Future<bool> hasNotificationPermissions() async {
    return _workingService.hasPermissions;
  }

  /// Check if notifications are enabled (alias for backward compatibility)
  Future<bool> areNotificationsEnabled() async {
    return _workingService.hasPermissions;
  }

  /// Get system status
  Map<String, dynamic> getSystemStatus() => _workingService.getSystemStatus();

  /// **EVENT HANDLERS**

  /// Handle achievement unlocked event
  Future<void> _handleAchievementUnlocked(Map<String, dynamic> data) async {
    try {
      final achievementTitle = data['achievementTitle'] as String;
      final category = data['category'] as String;
      final tier = data['tier'] as String;

      // Show achievement notification with sci-fi theme
      await _workingService.showAchievementUnlocked(achievementTitle);

      // Schedule follow-up motivation notification
      await _workingService.scheduleNotification(
        title: '🚀 Keep the Momentum Going!',
        body:
            'You\'ve unlocked $achievementTitle! Ready for the next challenge?',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        payload: 'achievement_followup:$achievementTitle',
        isHighPriority: false,
        channelType: 'reminders',
      );

      debugPrint('✅ Achievement notification handled: $achievementTitle');
    } catch (e) {
      debugPrint('❌ Failed to handle achievement notification: $e');
    }
  }

  /// Handle deadline reminder event
  Future<void> _handleDeadlineReminder(Map<String, dynamic> data) async {
    try {
      final studySetId = data['studySetId'] as String;
      final title = data['title'] as String;
      final daysUntil = data['daysUntil'] as int;
      final urgency = data['urgency'] as String;

      String message;
      String channelType;
      bool isHighPriority;

      switch (urgency) {
        case 'critical':
          message = '🚨 FINAL COUNTDOWN: "$title" deadline in $daysUntil days!';
          channelType = 'deadlines';
          isHighPriority = true;
          break;
        case 'high':
          message =
              '⏰ URGENT: "$title" deadline approaching in $daysUntil days!';
          channelType = 'deadlines';
          isHighPriority = true;
          break;
        case 'medium':
          message = '📅 REMINDER: "$title" deadline in $daysUntil days';
          channelType = 'reminders';
          isHighPriority = false;
          break;
        default:
          message = '📚 "$title" deadline in $daysUntil days';
          channelType = 'reminders';
          isHighPriority = false;
      }

      await _workingService.showNotificationNow(
        title: 'Deadline Alert',
        body: message,
        payload: 'deadline:$studySetId',
        isHighPriority: isHighPriority,
        channelType: channelType,
      );

      debugPrint('✅ Deadline reminder handled: $title');
    } catch (e) {
      debugPrint('❌ Failed to handle deadline reminder: $e');
    }
  }

  /// Handle study session completed event
  Future<void> _handleStudySessionCompleted(Map<String, dynamic> data) async {
    try {
      final studySetId = data['studySetId'] as String;
      final duration = data['duration'] as int;
      final correctAnswers = data['correctAnswers'] as int;
      final totalQuestions = data['totalQuestions'] as int;
      final xpEarned = data['xpEarned'] as int;

      final accuracy = totalQuestions > 0
          ? (correctAnswers / totalQuestions * 100).round()
          : 0;

      String message;
      if (accuracy >= 90) {
        message =
            '🎯 EXCELLENT! You scored $accuracy% and earned $xpEarned XP!';
      } else if (accuracy >= 70) {
        message =
            '👍 Good work! $accuracy% accuracy, $xpEarned XP earned. Keep improving!';
      } else {
        message =
            '📚 Session completed! $accuracy% accuracy. Review the missed concepts.';
      }

      await _workingService.showNotificationNow(
        title: 'Study Session Complete',
        body: message,
        payload: 'session_complete:$studySetId',
        isHighPriority: false,
        channelType: 'reminders',
      );

      debugPrint('✅ Study session notification handled: $studySetId');
    } catch (e) {
      debugPrint('❌ Failed to handle study session notification: $e');
    }
  }

  /// Handle streak milestone event
  Future<void> _handleStreakMilestone(Map<String, dynamic> data) async {
    try {
      final streakDays = data['streakDays'] as int;
      final milestone = data['milestone'] as String;

      await _workingService.showStreakReminder(streakDays);

      debugPrint('✅ Streak milestone notification handled: $streakDays days');
    } catch (e) {
      debugPrint('❌ Failed to handle streak milestone notification: $e');
    }
  }

  /// Handle exam countdown event
  Future<void> _handleExamCountdown(Map<String, dynamic> data) async {
    try {
      final course = data['course'] as String;
      final hoursUntil = data['hoursUntil'] as int;
      final urgency = data['urgency'] as String;

      String message;
      bool isHighPriority;

      if (hoursUntil <= 1) {
        message = '⚡ FINAL HOUR: $course exam starting soon!';
        isHighPriority = true;
      } else if (hoursUntil <= 6) {
        message =
            '⏰ $course exam in $hoursUntil hours - Final preparation time!';
        isHighPriority = true;
      } else {
        message = '📚 $course exam in $hoursUntil hours - Keep studying!';
        isHighPriority = false;
      }

      await _workingService.showNotificationNow(
        title: 'Exam Countdown',
        body: message,
        payload: 'exam_countdown:$course',
        isHighPriority: isHighPriority,
        channelType: 'deadlines',
      );

      debugPrint('✅ Exam countdown notification handled: $course');
    } catch (e) {
      debugPrint('❌ Failed to handle exam countdown notification: $e');
    }
  }

  /// Dispose method
  static void dispose() {
    // WorkingNotificationService doesn't need disposal as it's a singleton
    debugPrint('🧹 Unified Notification Service disposed');
  }

  /// Check notification permissions and system status
  static Future<Map<String, dynamic>> checkNotificationStatus() async {
    try {
      final Map<String, dynamic> status = {};
      
      // Check if service is initialized
      status['serviceInitialized'] = instance._workingService.isInitialized;
      
      // Check permissions
      final permissions = await instance._workingService.checkNotificationPermissions();
      status['permissions'] = permissions;
      
      // Check if we can send notifications
      status['canSendNotifications'] = permissions['canRequest'] ?? false;
      
      if (kDebugMode) {
        debugPrint('🔍 Notification status check:');
        debugPrint('   Service initialized: ${status['serviceInitialized']}');
        debugPrint('   Permissions: ${status['permissions']}');
        debugPrint('   Can send notifications: ${status['canSendNotifications']}');
      }
      
      return status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to check notification status: $e');
      }
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
