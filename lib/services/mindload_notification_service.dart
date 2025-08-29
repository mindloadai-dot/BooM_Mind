import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart' as ftz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/// MindLoad Notification Service
///
/// Single source of truth for all local notifications in the app.
/// Works 100% offline with no network dependencies.
///
/// Usage:
/// ```dart
/// // Initialize once at app start
/// await MindLoadNotificationService.initialize();
///
/// // Send instant notification
/// await MindLoadNotificationService.scheduleInstant(
///   "Title",
///   "Body message"
/// );
///
/// // Schedule for later
/// await MindLoadNotificationService.scheduleAt(
///   DateTime.now().add(Duration(hours: 1)),
///   "Reminder",
///   "Time to study!",
///   payload: "quiz_id_123"
/// );
///
/// // Cancel all
/// await MindLoadNotificationService.cancelAll();
/// ```
class MindLoadNotificationService {
  // --- Singleton Pattern with factory constructor ---
  static final MindLoadNotificationService _instance =
      MindLoadNotificationService._internal();

  factory MindLoadNotificationService() => _instance;
  MindLoadNotificationService._internal();

  // --- State Management ---
  static bool _initialized = false;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final Set<String> _scheduledHashes = {};

  // --- Constants ---
  static const String _channelId = 'mindload_local';
  static const String _channelName = 'MindLoad Local Notifications';
  static const String _channelDesc = 'Study reminders and notifications';
  static const String _firstRunFlag = 'hasFiredFirstStudySetNotification';

  /// Initialize the notification service (idempotent)
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('🔔 MindLoadNotificationService already initialized');
      return;
    }

    try {
      debugPrint('🔔 Initializing MindLoadNotificationService...');

      // Configure timezone first
      await _configureTimezone();

      // Configure platform-specific settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false, // Don't request critical by default
        requestProvisionalPermission: true, // Allow provisional notifications
        notificationCategories: [
          // Study Reminders Category
          DarwinNotificationCategory(
            'mindload_study_reminders',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('start_study', 'Start Studying'),
              DarwinNotificationAction.plain('postpone', 'Postpone 30 min'),
            ],
          ),
          // Pop Quiz Category
          DarwinNotificationCategory(
            'mindload_pop_quiz',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('take_quiz', 'Take Quiz'),
              DarwinNotificationAction.plain('skip', 'Skip'),
            ],
          ),
          // Deadlines Category
          DarwinNotificationCategory(
            'mindload_deadlines',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('view_deadline', 'View Details'),
              DarwinNotificationAction.plain('set_reminder', 'Set Reminder'),
            ],
          ),
          // Achievements Category
          DarwinNotificationCategory(
            'mindload_achievements',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('view_achievement', 'View Achievement'),
              DarwinNotificationAction.plain('share', 'Share'),
            ],
          ),
          // Promotions Category
          DarwinNotificationCategory(
            'mindload_promotions',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('view_offer', 'View Offer'),
              DarwinNotificationAction.plain('dismiss', 'Dismiss'),
            ],
          ),
          // General Category
          DarwinNotificationCategory(
            'mindload_notifications',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('open_app', 'Open App'),
            ],
          ),
        ],
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _handleBackgroundResponse,
      );

      // Create Android notification channel
      if (Platform.isAndroid) {
        await _createAndroidChannel();
      }

      // Request permissions after initialization
      await _requestPermissions();

      _initialized = true;
      debugPrint('✅ MindLoadNotificationService initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize notification service: $e');
      debugPrint('Stack trace: $stackTrace');
      // Mark as initialized to prevent repeated failures
      _initialized = true;
    }
  }

  /// Schedule an instant notification
  static Future<void> scheduleInstant(String title, String body) async {
    debugPrint('📱 Attempting to send instant notification: "$title"');

    if (!_initialized) {
      debugPrint(
          '⚠️ Notification service not initialized, initializing now...');
      await initialize();
    }

    try {
      // Check permissions first
      debugPrint('🔐 Checking notification permissions...');
      final hasPermission = await _hasPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ No notification permissions - attempting to request...');
        final granted = await _requestPermissions();
        if (!granted) {
          debugPrint('❌ Notification permissions denied');
          return;
        }
      }

      // Generate unique ID
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      debugPrint('🆔 Generated notification ID: $id');

      // Create notification details
      final details = _createNotificationDetails();
      debugPrint('⚙️ Notification details created');

      // Show notification
      debugPrint('📤 Sending notification...');
      await _plugin.show(
        id,
        title,
        body,
        details,
      );

      debugPrint('✅ Instant notification sent successfully: "$title"');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send instant notification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Schedule a notification at a specific time
  static Future<void> scheduleAt(
    DateTime when,
    String title,
    String body, {
    String? payload,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️ Notification service not initialized');
      await initialize();
    }

    if (when.isBefore(DateTime.now())) {
      debugPrint('⚠️ Cannot schedule notification in the past');
      return;
    }

    try {
      // Check permissions first
      final hasPermission = await _hasPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ No notification permissions');
        return;
      }

      // Generate hash for deduplication
      final hash = _generateHash(title, body, when.toIso8601String());
      if (_scheduledHashes.contains(hash)) {
        debugPrint('⚠️ Duplicate notification prevented');
        return;
      }

      // Convert to TZDateTime
      final scheduledDate = tz.TZDateTime.from(when, tz.local);
      final id = hash.hashCode.abs() % 2147483647; // Ensure positive 32-bit int

      // Create notification details
      final details = _createNotificationDetails();

      // Schedule notification
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _scheduledHashes.add(hash);
      debugPrint('✅ Notification scheduled for: ${when.toString()}');
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();
      _scheduledHashes.clear();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel notifications: $e');
    }
  }

  /// Fire first-run notification for first study set creation
  static Future<void> fireFirstStudySetNotificationIfNeeded() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasFired = prefs.getBool(_firstRunFlag) ?? false;

      if (!hasFired) {
        // Schedule the notification
        await scheduleInstant(
          "You're set! 🎉",
          "Your study set is ready. Time to start learning!",
        );

        // Mark as fired
        await prefs.setBool(_firstRunFlag, true);
        debugPrint('✅ First study set notification fired');
      } else {
        debugPrint('ℹ️ First study set notification already fired');
      }
    } catch (e) {
      debugPrint('❌ Failed to fire first study set notification: $e');
    }
  }

  // --- Private Helper Methods ---

  /// Configure timezone for accurate scheduling
  static Future<void> _configureTimezone() async {
    try {
      tz.initializeTimeZones();

      // Try to get local timezone
      try {
        final String timeZoneName =
            await ftz.FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('🌍 Timezone configured: $timeZoneName');
      } catch (e) {
        // Fallback to UTC if local timezone fails
        tz.setLocalLocation(tz.UTC);
        debugPrint('🌍 Using UTC timezone (fallback)');
      }
    } catch (e) {
      debugPrint('⚠️ Timezone configuration failed: $e');
      // Continue without timezone - notifications will still work
    }
  }

  /// Create Android notification channel
  static Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
        debugPrint('✅ Android notification channel created');
      }
    } catch (e) {
      debugPrint('❌ Failed to create Android channel: $e');
    }
  }

  /// Request notification permissions
  static Future<bool> _requestPermissions() async {
    debugPrint('🔐 Requesting notification permissions...');

    try {
      if (Platform.isIOS) {
        debugPrint('🍎 Requesting iOS notification permissions...');

        // iOS permissions through plugin
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          final result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: false, // Don't request critical by default
            provisional: true, // Allow provisional notifications
          );

          debugPrint('🍎 iOS permissions result: $result');
          debugPrint(
              '🍎 iOS permissions: ${result == true ? "✅ granted" : "❌ denied"}');
          return result ?? false;
        } else {
          debugPrint('❌ iOS plugin not available');
          return false;
        }
      } else if (Platform.isAndroid) {
        debugPrint('🤖 Requesting Android notification permissions...');

        // Android permissions through permission_handler
        final status = await Permission.notification.request();
        debugPrint('🤖 Notification permission status: $status');

        // Also request exact alarm permission for Android 12+
        try {
          final alarmStatus = await Permission.scheduleExactAlarm.request();
          debugPrint('⏰ Exact alarm permission: $alarmStatus');
        } catch (e) {
          // Exact alarm permission not available on older Android versions
          debugPrint('ℹ️ Exact alarm permission not available: $e');
        }

        final granted = status == PermissionStatus.granted;
        debugPrint(
            '🤖 Android permissions: ${granted ? "✅ granted" : "❌ denied"}');
        return granted;
      }

      debugPrint(
          'ℹ️ Platform not iOS or Android, assuming permissions granted');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Permission request failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /// Check if we have notification permissions
  static Future<bool> _hasPermissions() async {
    try {
      if (Platform.isIOS) {
        // Check iOS permissions - use checkPermissions instead of requestPermissions
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          try {
            // For iOS, we'll use a simple approach - just try to request permissions
            // with all false to check current status
            final result = await iosPlugin.requestPermissions(
              alert: false,
              badge: false,
              sound: false,
            );
            debugPrint('🍎 iOS permission check result: $result');
            return result ?? true; // Default to true if null
          } catch (e) {
            debugPrint('🍎 iOS permission check failed, assuming granted: $e');
            return true; // Assume granted if check fails
          }
        }
      } else if (Platform.isAndroid) {
        // Check Android permissions
        final status = await Permission.notification.status;
        debugPrint('🤖 Android notification permission: $status');
        return status == PermissionStatus.granted;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Permission check failed: $e');
      return false;
    }
  }

  /// Create platform-specific notification details
  static NotificationDetails _createNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'mindload_notifications', // Use general category by default
      ),
    );
  }

  /// Handle notification tap response
  static Future<void> _handleNotificationResponse(
      NotificationResponse response) async {
    debugPrint('📱 Notification tapped: ${response.payload}');

    // Handle navigation based on payload if needed
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        debugPrint('📱 Payload data: $data');
        // Add navigation logic here if needed
      } catch (e) {
        debugPrint('📱 Simple payload: ${response.payload}');
      }
    }
  }

  /// Handle background notification response
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundResponse(
      NotificationResponse response) async {
    debugPrint('📱 Background notification: ${response.payload}');
  }

  /// Generate unique hash for deduplication
  static String _generateHash(String title, String body, String date) {
    final bytes = utf8.encode('$title|$body|$date');
    return sha256.convert(bytes).toString();
  }

  /// Schedule a study reminder notification with iOS-specific category
  static Future<void> scheduleStudyReminder(
    DateTime when,
    String title,
    String body, {
    String? payload,
  }) async {
    await _scheduleWithCategory(
      when,
      title,
      body,
      'mindload_study_reminders',
      payload: payload,
    );
  }

  /// Schedule a quiz notification with iOS-specific category
  static Future<void> scheduleQuizNotification(
    DateTime when,
    String title,
    String body, {
    String? payload,
  }) async {
    await _scheduleWithCategory(
      when,
      title,
      body,
      'mindload_pop_quiz',
      payload: payload,
    );
  }

  /// Schedule an achievement notification with iOS-specific category
  static Future<void> scheduleAchievementNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    await _scheduleInstantWithCategory(
      title,
      body,
      'mindload_achievements',
      payload: payload,
    );
  }

  /// Schedule with specific category for iOS
  static Future<void> _scheduleWithCategory(
    DateTime when,
    String title,
    String body,
    String categoryId, {
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (when.isBefore(DateTime.now())) {
      debugPrint('⚠️ Cannot schedule notification in the past');
      return;
    }

    try {
      final hasPermission = await _hasPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ No notification permissions');
        return;
      }

      final hash = _generateHash(title, body, when.toIso8601String());
      if (_scheduledHashes.contains(hash)) {
        debugPrint('⚠️ Duplicate notification prevented');
        return;
      }

      final scheduledDate = tz.TZDateTime.from(when, tz.local);
      final id = hash.hashCode.abs() % 2147483647;

      final details = NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: categoryId, // Use specific category
        ),
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _scheduledHashes.add(hash);
      debugPrint('✅ $categoryId notification scheduled for: ${when.toString()}');
    } catch (e) {
      debugPrint('❌ Failed to schedule $categoryId notification: $e');
    }
  }

  /// Schedule instant notification with specific category for iOS
  static Future<void> _scheduleInstantWithCategory(
    String title,
    String body,
    String categoryId, {
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final hasPermission = await _hasPermissions();
      if (!hasPermission) {
        final granted = await _requestPermissions();
        if (!granted) {
          debugPrint('❌ Notification permissions denied');
          return;
        }
      }

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final details = NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: categoryId, // Use specific category
        ),
      );

      await _plugin.show(id, title, body, details, payload: payload);

      debugPrint('✅ $categoryId instant notification sent: "$title"');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send $categoryId notification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
}
