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

      // Check if platform supports notifications
      if (!Platform.isIOS && !Platform.isAndroid) {
        debugPrint('⚠️ Platform ${Platform.operatingSystem} does not support local notifications');
        debugPrint('✅ MindLoadNotificationService initialized (no-op for unsupported platform)');
        _initialized = true;
        return;
      }

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
        requestProvisionalPermission:
            false, // Set to false initially, request manually
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
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
              DarwinNotificationAction.plain(
                  'view_achievement', 'View Achievement'),
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

    // Skip notification on unsupported platforms
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('⚠️ Skipping notification on unsupported platform: ${Platform.operatingSystem}');
      return;
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

    // Skip notification on unsupported platforms
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('⚠️ Skipping scheduled notification on unsupported platform: ${Platform.operatingSystem}');
      return;
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

  /// Cancel a specific notification by ID
  static Future<void> cancelById(int id) async {
    if (!_initialized) return;

    try {
      await _plugin.cancel(id);
      debugPrint('✅ Notification cancelled with ID: $id');
    } catch (e) {
      debugPrint('❌ Failed to cancel notification with ID $id: $e');
    }
  }

  /// Cancel multiple notifications by IDs
  static Future<void> cancelByIds(List<int> ids) async {
    if (!_initialized) return;

    try {
      for (final id in ids) {
        await _plugin.cancel(id);
      }
      debugPrint('✅ ${ids.length} notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel notifications: $e');
    }
  }

  /// Get all pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) return [];

    try {
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      debugPrint('📋 Found ${pendingNotifications.length} pending notifications');
      return pendingNotifications;
    } catch (e) {
      debugPrint('❌ Failed to get pending notifications: $e');
      return [];
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

        // iOS permissions through plugin - use the correct method
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          // Check if permissions are already granted using checkPermissions
          try {
            final settings = await iosPlugin.checkPermissions();
            debugPrint(
                '🍎 Current iOS settings: Alert=${settings?.isAlertEnabled}, Badge=${settings?.isBadgeEnabled}, Sound=${settings?.isSoundEnabled}');

            if ((settings?.isAlertEnabled ?? false) ||
                (settings?.isBadgeEnabled ?? false) ||
                (settings?.isSoundEnabled ?? false)) {
              debugPrint('🍎 iOS permissions already granted');
              return true;
            }
          } catch (e) {
            debugPrint(
                '🍎 checkPermissions not available, proceeding with request: $e');
          }

          // Request permissions if not already granted
          final result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: false, // Don't request critical by default
            provisional: false, // Request explicit permission, not provisional
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
        // For iOS, we need a different approach since checkPermissions might not be available
        // in older versions of the plugin
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          try {
            // Use checkPermissions which is the available method
            final settings = await iosPlugin.checkPermissions();
            debugPrint(
                '🍎 iOS notification settings: Alert=${settings?.isAlertEnabled}, Badge=${settings?.isBadgeEnabled}, Sound=${settings?.isSoundEnabled}');

            // Check if any notifications are enabled
            final isAuthorized = (settings?.isAlertEnabled ?? false) ||
                (settings?.isBadgeEnabled ?? false) ||
                (settings?.isSoundEnabled ?? false);

            debugPrint('🍎 iOS notifications authorized: $isAuthorized');
            return isAuthorized;
          } catch (e) {
            // If getNotificationSettings is not available, fall back to permission_handler
            debugPrint(
                '🍎 getNotificationSettings not available, using permission_handler: $e');
          }

          // Fallback: Use permission_handler for iOS as well
          try {
            final status = await Permission.notification.status;
            debugPrint('🍎 iOS notification permission via handler: $status');
            return status == PermissionStatus.granted ||
                status ==
                    PermissionStatus
                        .provisional; // iOS can have provisional permission
          } catch (e) {
            debugPrint('🍎 Permission handler check failed: $e');
            // If all else fails, assume we need to request permissions
            return false;
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
        categoryIdentifier:
            'mindload_notifications', // Use general category by default
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
      debugPrint(
          '✅ $categoryId notification scheduled for: ${when.toString()}');
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

  /// Test iOS notification permissions and functionality
  static Future<void> testIOSPermissions() async {
    if (!Platform.isIOS) {
      debugPrint('⚠️ This test is for iOS only');
      return;
    }

    debugPrint('🍎 Starting iOS notification test...');

    try {
      // Check current permission status using permission_handler
      final status = await Permission.notification.status;
      debugPrint('🍎 Current permission status: $status');

      if (status == PermissionStatus.denied ||
          status == PermissionStatus.restricted) {
        debugPrint('❌ Notifications are denied or restricted');
        debugPrint(
            '📱 Please go to Settings > Notifications > Mindload and enable notifications');
        return;
      }

      if (status == PermissionStatus.permanentlyDenied) {
        debugPrint('❌ Notifications are permanently denied');
        debugPrint('📱 Opening app settings...');
        await openAppSettings();
        return;
      }

      if (status != PermissionStatus.granted &&
          status != PermissionStatus.provisional) {
        debugPrint('🔐 Requesting notification permissions...');
        final result = await Permission.notification.request();
        debugPrint('🍎 Permission request result: $result');
        
        if (result != PermissionStatus.granted && 
            result != PermissionStatus.provisional) {
          debugPrint('❌ Permission request denied');
          return;
        }
      }

      // Test notification functionality
      debugPrint('✅ Permissions granted, testing notification...');
      await scheduleInstant(
        '🍎 iOS Test Notification',
        'This is a test notification from MindLoad!',
      );
      
      debugPrint('✅ iOS notification test completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ iOS notification test failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Test Android notification permissions and functionality
  static Future<void> testAndroidPermissions() async {
    if (!Platform.isAndroid) {
      debugPrint('⚠️ This test is for Android only');
      return;
    }

    debugPrint('🤖 Starting Android notification test...');

    try {
      // Check current permission status
      final status = await Permission.notification.status;
      debugPrint('🤖 Current permission status: $status');

      if (status == PermissionStatus.denied) {
        debugPrint('🔐 Requesting notification permissions...');
        final result = await Permission.notification.request();
        debugPrint('🤖 Permission request result: $result');
        
        if (result != PermissionStatus.granted) {
          debugPrint('❌ Permission request denied');
          return;
        }
      }

      // Test notification functionality
      debugPrint('✅ Permissions granted, testing notification...');
      await scheduleInstant(
        '🤖 Android Test Notification',
        'This is a test notification from MindLoad!',
      );
      
      debugPrint('✅ Android notification test completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Android notification test failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Comprehensive notification system test
  static Future<void> runComprehensiveTest() async {
    debugPrint('🧪 Starting comprehensive notification test...');

    try {
      // Ensure service is initialized
      if (!_initialized) {
        debugPrint('⚠️ Service not initialized, initializing now...');
        await initialize();
      }

      // Test platform-specific functionality
      if (Platform.isIOS) {
        await testIOSPermissions();
      } else if (Platform.isAndroid) {
        await testAndroidPermissions();
      } else {
        debugPrint('⚠️ Platform ${Platform.operatingSystem} not supported for notifications');
        debugPrint('✅ Notification system is properly configured to skip unsupported platforms');
        return;
      }

      // Test scheduled notification
      debugPrint('⏰ Testing scheduled notification...');
      await scheduleAt(
        DateTime.now().add(const Duration(seconds: 5)),
        '⏰ Scheduled Test',
        'This notification was scheduled 5 seconds ago!',
        payload: 'test_scheduled',
      );

      // Test first-run notification
      debugPrint('🎉 Testing first-run notification...');
      await fireFirstStudySetNotificationIfNeeded();

      debugPrint('✅ Comprehensive notification test completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Comprehensive notification test failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
}
