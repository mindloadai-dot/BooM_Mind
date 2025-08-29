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
        requestProvisionalPermission: true, // Allow provisional as fallback
        notificationCategories: [
          DarwinNotificationCategory(
            'mindload_local',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('open', 'Open App'),
              DarwinNotificationAction.plain('dismiss', 'Dismiss'),
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
    if (!_initialized) {
      debugPrint('⚠️ Notification service not initialized');
      await initialize();
    }

    try {
      // Check permissions first
      final hasPermission = await _hasPermissions();
      if (!hasPermission) {
        debugPrint('⚠️ No notification permissions');
        return;
      }

      // Generate unique ID
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create notification details
      final details = _createNotificationDetails();

      // Show notification
      await _plugin.show(
        id,
        title,
        body,
        details,
      );

      debugPrint('✅ Instant notification sent: $title');
    } catch (e) {
      debugPrint('❌ Failed to send instant notification: $e');
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
    try {
      if (Platform.isIOS) {
        // iOS permissions through plugin
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          final result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

          debugPrint(
              '🍎 iOS permissions: ${result == true ? "granted" : "denied"}');
          return result ?? false;
        }
      } else if (Platform.isAndroid) {
        // Android permissions through permission_handler
        final status = await Permission.notification.request();

        // Also request exact alarm permission for Android 12+
        if (Platform.isAndroid) {
          try {
            final alarmStatus = await Permission.scheduleExactAlarm.request();
            debugPrint('⏰ Exact alarm permission: $alarmStatus');
          } catch (e) {
            // Exact alarm permission not available on older Android versions
            debugPrint('ℹ️ Exact alarm permission not available');
          }
        }

        final granted = status == PermissionStatus.granted;
        debugPrint('🤖 Android permissions: ${granted ? "granted" : "denied"}');
        return granted;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Permission request failed: $e');
      return false;
    }
  }

  /// Check if we have notification permissions
  static Future<bool> _hasPermissions() async {
    try {
      if (Platform.isIOS) {
        // Check iOS permissions
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          // Request with all false just checks current status
          final result = await iosPlugin.requestPermissions(
            alert: false,
            badge: false,
            sound: false,
          );
          return result ?? false;
        }
      } else if (Platform.isAndroid) {
        // Check Android permissions
        final status = await Permission.notification.status;
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
        categoryIdentifier: 'mindload_local',
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
}
