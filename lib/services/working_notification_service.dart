import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart' show TimeOfDay, Color;
import 'package:mindload/services/user_profile_service.dart';
import 'package:mindload/services/notification_style_service.dart';

/// Enhanced notification service with style-based personalization
/// This is the core notification engine that applies user's preferred style
/// to all notifications throughout the application
class WorkingNotificationService {
  static final WorkingNotificationService _instance =
      WorkingNotificationService._();
  static WorkingNotificationService get instance => _instance;
  WorkingNotificationService._();

  // Notification channels
  static const String _studyRemindersChannel = 'study_reminders';
  static const String _popQuizChannel = 'pop_quiz';
  static const String _deadlinesChannel = 'deadlines';
  static const String _promotionsChannel = 'promotions';
  static const String _achievementsChannel = 'achievements';
  static const String _generalChannel = 'general';

  // Flutter Local Notifications plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize settings for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize settings for iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combine initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ WorkingNotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize WorkingNotificationService: $e');
      }
    }
  }

  /// Create notification channels for different types
  Future<void> _createNotificationChannels() async {
    try {
      // Study Reminders Channel
      const AndroidNotificationChannel studyRemindersChannel =
          AndroidNotificationChannel(
        _studyRemindersChannel,
        'Study Reminders',
        description: 'Notifications for study sessions and learning reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Pop Quiz Channel
      const AndroidNotificationChannel popQuizChannel =
          AndroidNotificationChannel(
        _popQuizChannel,
        'Pop Quizzes',
        description: 'Surprise quiz and challenge notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Deadlines Channel
      const AndroidNotificationChannel deadlinesChannel =
          AndroidNotificationChannel(
        _deadlinesChannel,
        'Deadlines',
        description: 'Important deadline and time-sensitive notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Promotions Channel
      const AndroidNotificationChannel promotionsChannel =
          AndroidNotificationChannel(
        _promotionsChannel,
        'Promotions',
        description: 'Special offers and promotional notifications',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      // Achievements Channel
      const AndroidNotificationChannel achievementsChannel =
          AndroidNotificationChannel(
        _achievementsChannel,
        'Achievements',
        description: 'Achievement unlocked and milestone notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // General Channel
      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
        _generalChannel,
        'General',
        description: 'General application notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: false,
        showBadge: false,
      );

      // Create all channels
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(studyRemindersChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(popQuizChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(deadlinesChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(promotionsChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(achievementsChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);

      if (kDebugMode) {
        debugPrint('✅ Notification channels created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to create notification channels: $e');
      }
    }
  }

  /// Show notification immediately with style-based personalization
  Future<void> showNotificationNow({
    required String title,
    required String body,
    String? payload,
    bool isHighPriority = false,
    String? channelType,
    bool timeSensitive = false,
    String? subject,
    String? deadline,
    int? streakDays,
    String? achievement,
    String? timeContext,
  }) async {
    try {
      // Check if in quiet hours
      if (UserProfileService.instance.isInQuietHours) {
        if (kDebugMode) {
          debugPrint('🔇 Notification suppressed during quiet hours');
        }
        return;
      }

      // Get user's notification style and nickname
      final userProfile = UserProfileService.instance;
      final style = userProfile.notificationStyle;
      final nickname = userProfile.displayName;

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: title,
        baseBody: body,
        nickname: nickname,
        style: style,
        subject: subject,
        deadline: deadline,
        streakDays: streakDays,
        achievement: achievement,
        timeContext: timeContext,
      );

      // Get style-specific properties
      final styleInfo = NotificationStyleService.getStyleInfo(style);
      final isHighPriorityStyle =
          styleInfo['priority'] as bool || isHighPriority;
      final urgency = styleInfo['urgency'] as int;

      // Determine channel type
      final finalChannelType = channelType ?? _generalChannel;
      final styleChannel =
          NotificationStyleService.getStyleChannel(style, finalChannelType);

      // Create notification details
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          styleChannel,
          '${styleInfo['name']} Notifications',
          channelDescription: '${styleInfo['description']}',
          importance: isHighPriorityStyle ? Importance.max : Importance.low,
          priority: isHighPriorityStyle ? Priority.high : Priority.low,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: urgency >= 3,
          enableLights: urgency >= 4,
          color: _getStyleColor(style),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(''),
          channelShowBadge: true,
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
          usesChronometer: timeSensitive,
          chronometerCountDown: timeSensitive,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
          categoryIdentifier: 'mindload_notifications',
          threadIdentifier: 'mindload_thread',
        ),
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch,
        styledNotification['title']!,
        styledNotification['body']!,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint('✅ Styled notification sent: ${styleInfo['name']} style');
        debugPrint('   Title: ${styledNotification['title']}');
        debugPrint('   Body: ${styledNotification['body']}');
        debugPrint('   Style: $style (${styleInfo['intensity']} intensity)');
        debugPrint('   Channel: $styleChannel');
        debugPrint('   Priority: $isHighPriorityStyle');
        debugPrint('   Urgency: $urgency');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to show styled notification: $e');
      }
    }
  }

  /// Schedule notification with style-based personalization
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool isHighPriority = false,
    String? channelType,
    bool timeSensitive = false,
    String? timezoneName,
    String? subject,
    String? deadline,
    int? streakDays,
    String? achievement,
    String? timeContext,
  }) async {
    try {
      // Get user's notification style and nickname
      final userProfile = UserProfileService.instance;
      final style = userProfile.notificationStyle;
      final nickname = userProfile.displayName;

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: title,
        baseBody: body,
        nickname: nickname,
        style: style,
        subject: subject,
        deadline: deadline,
        streakDays: streakDays,
        achievement: achievement,
        timeContext: timeContext,
      );

      // Get style-specific properties
      final styleInfo = NotificationStyleService.getStyleInfo(style);
      final isHighPriorityStyle =
          styleInfo['priority'] as bool || isHighPriority;
      final urgency = styleInfo['urgency'] as int;

      // Determine channel type
      final finalChannelType = channelType ?? _generalChannel;
      final styleChannel =
          NotificationStyleService.getStyleChannel(style, finalChannelType);

      // Create notification details
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          styleChannel,
          '${styleInfo['name']} Notifications',
          channelDescription: '${styleInfo['description']}',
          importance: isHighPriorityStyle ? Importance.max : Importance.low,
          priority: isHighPriorityStyle ? Priority.high : Priority.low,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: urgency >= 3,
          enableLights: urgency >= 4,
          color: _getStyleColor(style),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: const BigTextStyleInformation(''),
          channelShowBadge: true,
          showWhen: true,
          when: scheduledTime.millisecondsSinceEpoch,
          usesChronometer: timeSensitive,
          chronometerCountDown: timeSensitive,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
          categoryIdentifier: 'mindload_notifications',
          threadIdentifier: 'mindload_thread',
        ),
      );

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch,
        styledNotification['title']!,
        styledNotification['body']!,
        tz.TZDateTime.from(
            scheduledTime, tz.getLocation(timezoneName ?? 'UTC')),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint(
            '✅ Styled notification scheduled: ${styleInfo['name']} style');
        debugPrint('   Title: ${styledNotification['title']}');
        debugPrint('   Scheduled for: $scheduledTime');
        debugPrint('   Style: $style (${styleInfo['intensity']} intensity)');
        debugPrint('   Channel: $styleChannel');
        debugPrint('   Priority: $isHighPriorityStyle');
        debugPrint('   Urgency: $urgency');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to schedule styled notification: $e');
      }
    }
  }

  /// Show daily study reminder with style personalization
  Future<void> scheduleDailyReminder({
    String? customMessage,
    TimeOfDay? time,
    String? subject,
  }) async {
    try {
      final userProfile = UserProfileService.instance;
      final nickname = userProfile.displayName;
      final style = userProfile.notificationStyle;
      final styleInfo = NotificationStyleService.getStyleInfo(style);

      final baseTitle = 'Daily Study Reminder';
      final baseBody = customMessage ?? 'Time for your daily learning session';

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: baseTitle,
        baseBody: baseBody,
        nickname: nickname,
        style: style,
        subject: subject,
        timeContext: 'daily',
      );

      // Schedule for daily delivery
      final now = DateTime.now();
      final scheduledTime = time != null
          ? DateTime(now.year, now.month, now.day, time.hour, time.minute)
          : DateTime(now.year, now.month, now.day, 9, 0); // Default 9 AM

      await scheduleNotification(
        title: styledNotification['title']!,
        body: styledNotification['body']!,
        scheduledTime: scheduledTime,
        payload: 'daily_study_reminder',
        channelType: _studyRemindersChannel,
        subject: subject,
        timeContext: 'daily',
      );

      if (kDebugMode) {
        debugPrint(
            '✅ Daily study reminder scheduled with ${styleInfo['name']} style');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to schedule daily study reminder: $e');
      }
    }
  }

  /// Show pop quiz notification with style personalization
  Future<void> showPopQuiz(String quizType) async {
    try {
      final userProfile = UserProfileService.instance;
      final nickname = userProfile.displayName;
      final style = userProfile.notificationStyle;
      final styleInfo = NotificationStyleService.getStyleInfo(style);

      final baseTitle = 'Pop Quiz Alert';
      final baseBody = 'Surprise quiz: $quizType';

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: baseTitle,
        baseBody: baseBody,
        nickname: nickname,
        style: style,
        subject: quizType,
        timeContext: 'pop_quiz',
      );

      await showNotificationNow(
        title: styledNotification['title']!,
        body: styledNotification['body']!,
        payload: 'pop_quiz:$quizType',
        isHighPriority: true,
        channelType: _popQuizChannel,
        subject: quizType,
        timeContext: 'pop_quiz',
      );

      if (kDebugMode) {
        debugPrint(
            '✅ Pop quiz notification sent with ${styleInfo['name']} style');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to show pop quiz notification: $e');
      }
    }
  }

  /// Show streak reminder with style personalization
  Future<void> showStreakReminder(int streakDays) async {
    try {
      final userProfile = UserProfileService.instance;
      final nickname = userProfile.displayName;
      final style = userProfile.notificationStyle;
      final styleInfo = NotificationStyleService.getStyleInfo(style);

      final baseTitle = 'Learning Streak';
      final baseBody = 'You\'re on a $streakDays-day learning streak!';

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: baseTitle,
        baseBody: baseBody,
        nickname: nickname,
        style: style,
        streakDays: streakDays,
        timeContext: 'streak',
      );

      await showNotificationNow(
        title: styledNotification['title']!,
        body: styledNotification['body']!,
        payload: 'streak_reminder:$streakDays',
        channelType: _achievementsChannel,
        streakDays: streakDays,
        timeContext: 'streak',
      );

      if (kDebugMode) {
        debugPrint('✅ Streak reminder sent with ${styleInfo['name']} style');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to show streak reminder: $e');
      }
    }
  }

  /// Show achievement unlocked with style personalization
  Future<void> showAchievementUnlocked(String achievement) async {
    try {
      final userProfile = UserProfileService.instance;
      final nickname = userProfile.displayName;
      final style = userProfile.notificationStyle;
      final styleInfo = NotificationStyleService.getStyleInfo(style);

      final baseTitle = 'Achievement Unlocked';
      final baseBody = 'Congratulations! You\'ve earned: $achievement';

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: baseTitle,
        baseBody: baseBody,
        nickname: nickname,
        style: style,
        achievement: achievement,
        timeContext: 'achievement',
      );

      await showNotificationNow(
        title: styledNotification['title']!,
        body: styledNotification['body']!,
        payload: 'achievement:$achievement',
        channelType: _achievementsChannel,
        achievement: achievement,
        timeContext: 'achievement',
      );

      if (kDebugMode) {
        debugPrint(
            '✅ Achievement notification sent with ${styleInfo['name']} style');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to show achievement notification: $e');
      }
    }
  }

  /// Show study session reminder with style personalization
  Future<void> showStudySessionReminder({
    required String subject,
    required int durationMinutes,
    String? customMessage,
  }) async {
    try {
      final userProfile = UserProfileService.instance;
      final nickname = userProfile.displayName;
      final style = userProfile.notificationStyle;
      final styleInfo = NotificationStyleService.getStyleInfo(style);

      final baseTitle = 'Study Session Ready';
      final baseBody = customMessage ??
          'Time to study $subject for $durationMinutes minutes';

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: baseTitle,
        baseBody: baseBody,
        nickname: nickname,
        style: style,
        subject: subject,
        timeContext: 'study_session',
      );

      await showNotificationNow(
        title: styledNotification['title']!,
        body: styledNotification['body']!,
        payload: 'study_session:$subject:$durationMinutes',
        channelType: _studyRemindersChannel,
        subject: subject,
        timeContext: 'study_session',
      );

      if (kDebugMode) {
        debugPrint(
            '✅ Study session reminder sent with ${styleInfo['name']} style');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to show study session reminder: $e');
      }
    }
  }

  /// Show deadline reminder with style personalization
  Future<void> showDeadlineReminder({
    required String title,
    required DateTime deadline,
    String? subject,
  }) async {
    try {
      final userProfile = UserProfileService.instance;
      final nickname = userProfile.displayName;
      final style = userProfile.notificationStyle;
      final styleInfo = NotificationStyleService.getStyleInfo(style);

      final timeUntilDeadline = deadline.difference(DateTime.now());
      final daysLeft = timeUntilDeadline.inDays;
      final hoursLeft = timeUntilDeadline.inHours % 24;

      String urgencyText;
      if (daysLeft > 0) {
        urgencyText = '$daysLeft days remaining';
      } else if (hoursLeft > 0) {
        urgencyText = '$hoursLeft hours remaining';
      } else {
        urgencyText = 'Due very soon!';
      }

      final baseTitle = 'Deadline Alert';
      final baseBody = '$title - $urgencyText';

      // Apply style-based personalization
      final styledNotification = NotificationStyleService.applyStyle(
        baseTitle: baseTitle,
        baseBody: baseBody,
        nickname: nickname,
        style: style,
        subject: subject,
        deadline: deadline.toIso8601String(),
        timeContext: 'deadline',
      );

      await showNotificationNow(
        title: styledNotification['title']!,
        body: styledNotification['body']!,
        payload: 'deadline:$title',
        isHighPriority: true,
        channelType: _deadlinesChannel,
        subject: subject,
        deadline: deadline.toIso8601String(),
        timeContext: 'deadline',
      );

      if (kDebugMode) {
        debugPrint('✅ Deadline reminder sent with ${styleInfo['name']} style');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to show deadline reminder: $e');
      }
    }
  }

  /// Get style-specific color for Android notifications
  Color _getStyleColor(String style) {
    switch (style) {
      case 'mindful':
        return const Color(0xFF4CAF50); // Green
      case 'coach':
        return const Color(0xFF2196F3); // Blue
      case 'toughlove':
        return const Color(0xFFFF9800); // Orange
      case 'cram':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('📱 Notification tapped: ${response.payload}');
    }
    // TODO: Handle notification taps
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if permissions are granted (placeholder - implement actual permission check)
  bool get hasPermissions => true;

  /// Check if Firebase is available (placeholder - implement actual Firebase check)
  bool get hasFirebase => false;

  /// Check current notification permissions
  Future<Map<String, dynamic>> checkNotificationPermissions() async {
    try {
      final Map<String, dynamic> permissions = {};
      
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iOSPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        
        if (iOSPlugin != null) {
          // Check if we can request permissions
          final bool? canRequest = await iOSPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          
          permissions['canRequest'] = canRequest;
          permissions['platform'] = 'iOS';
          
          if (kDebugMode) {
            debugPrint('📱 iOS notification permissions check:');
            debugPrint('   Can request permissions: $canRequest');
          }
        }
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        permissions['platform'] = 'Android';
        // Android permissions are handled differently
        permissions['canRequest'] = true;
      }
      
      permissions['isInitialized'] = _isInitialized;
      permissions['timestamp'] = DateTime.now().toIso8601String();
      
      return permissions;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to check notification permissions: $e');
      }
      return {
        'error': e.toString(),
        'platform': defaultTargetPlatform.toString(),
        'isInitialized': _isInitialized,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Send test notification with enhanced debugging
  Future<bool> sendTestNotification() async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          debugPrint('⚠️ Service not initialized, initializing now...');
        }
        await initialize();
      }

      // Check permissions first
      final permissions = await checkNotificationPermissions();
      if (kDebugMode) {
        debugPrint('🔍 Permission check before test notification: $permissions');
      }

      // Create notification details
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannel,
          'Test Notifications',
          channelDescription: 'Test notifications for debugging',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          color: const Color(0xFF2196F3),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
          categoryIdentifier: 'test_notification',
          threadIdentifier: 'test_thread',
          // Add iOS-specific settings for better compatibility
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch,
        '🧪 Test Notification',
        'This is a test notification to verify the system is working.',
        notificationDetails,
        payload: 'test_notification',
      );

      if (kDebugMode) {
        debugPrint('✅ Test notification sent successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Test notification failed: $e');
      }
      return false;
    }
  }

  /// Get system status
  Map<String, dynamic> getSystemStatus() {
    return {
      'initialized': _isInitialized,
      'channels': [
        _studyRemindersChannel,
        _popQuizChannel,
        _deadlinesChannel,
        _promotionsChannel,
        _achievementsChannel,
        _generalChannel,
      ],
      'user_profile_available': true,
      'notification_styles_supported': true,
      'quiet_hours_integration': true,
      'style_personalization': true,
    };
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      if (kDebugMode) {
        debugPrint('✅ All notifications cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to cancel notifications: $e');
      }
    }
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      if (kDebugMode) {
        debugPrint('✅ Notification $id cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to cancel notification $id: $e');
      }
    }
  }
}
