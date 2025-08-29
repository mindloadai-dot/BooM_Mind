import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// iOS Local Notification Test Service
///
/// Based on pub.dev best practices and flutter_local_notifications v19.4.1
/// Reference: https://pub.dev/packages/flutter_local_notifications
class IOSNotificationTest {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Test iOS local notifications with comprehensive checks
  static Future<void> runComprehensiveTest() async {
    if (!Platform.isIOS) {
      debugPrint('⚠️ This test is for iOS only');
      return;
    }

    debugPrint('🍎 Starting comprehensive iOS notification test...');
    debugPrint('📦 Using flutter_local_notifications v19.4.1 from pub.dev');

    try {
      // Step 1: Check iOS version
      debugPrint('📱 Step 1: Checking iOS compatibility...');
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin == null) {
        throw Exception('iOS plugin not available');
      }

      // Step 2: Check current permission status
      debugPrint('🔐 Step 2: Checking notification permissions...');
      final settings = await iosPlugin.checkPermissions();
      debugPrint('   Alert: ${settings?.isAlertEnabled}');
      debugPrint('   Badge: ${settings?.isBadgeEnabled}');
      debugPrint('   Sound: ${settings?.isSoundEnabled}');

      // Step 3: Request permissions if needed
      if (!(settings?.isAlertEnabled ?? false)) {
        debugPrint('🔔 Step 3: Requesting notification permissions...');
        final result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: false,
          provisional: false,
        );
        debugPrint('   Permission result: $result');

        if (result != true) {
          throw Exception('Notification permissions denied');
        }
      } else {
        debugPrint('✅ Step 3: Permissions already granted');
      }

      // Step 4: Initialize the plugin with iOS-specific settings
      debugPrint('🚀 Step 4: Initializing notification plugin...');
      final DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false, // Already requested above
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'test_category',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('action_1', 'Action 1'),
              DarwinNotificationAction.plain('action_2', 'Action 2'),
            ],
          ),
        ],
      );

      final InitializationSettings initSettings = InitializationSettings(
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 Notification tapped: ${response.payload}');
        },
      );

      debugPrint('✅ Plugin initialized successfully');

      // Step 5: Send immediate test notification
      debugPrint('📤 Step 5: Sending immediate test notification...');
      await _sendImmediateNotification();

      // Step 6: Schedule future notification (5 seconds)
      debugPrint('⏰ Step 6: Scheduling notification for 5 seconds...');
      await _scheduleNotification();

      // Step 7: Test notification with attachment (optional)
      debugPrint('📎 Step 7: Testing rich notification...');
      await _sendRichNotification();

      // Step 8: Verify pending notifications
      debugPrint('📋 Step 8: Checking pending notifications...');
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('   Pending notifications: ${pending.length}');
      for (final notification in pending) {
        debugPrint('   - ID: ${notification.id}, Title: ${notification.title}');
      }

      debugPrint('✅ iOS notification test completed successfully!');
      debugPrint('🎉 All offline local notifications are working on iOS');
    } catch (e, stackTrace) {
      debugPrint('❌ iOS notification test failed: $e');
      debugPrint('Stack trace: $stackTrace');

      // Provide helpful troubleshooting
      debugPrint('\n📚 Troubleshooting Guide:');
      debugPrint('1. Ensure you\'re testing on a physical iOS device');
      debugPrint('2. Check Settings > Notifications > Your App');
      debugPrint('3. Verify Info.plist has proper usage descriptions');
      debugPrint(
          '4. Check Runner.entitlements for push notification capability');
      debugPrint(
          '5. Reference: https://pub.dev/packages/flutter_local_notifications');
    }
  }

  /// Send an immediate notification
  static Future<void> _sendImmediateNotification() async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      subtitle: 'Offline Local Notification',
      threadIdentifier: 'mindload_test',
      categoryIdentifier: 'test_category',
    );

    const NotificationDetails details = NotificationDetails(iOS: iosDetails);

    await _plugin.show(
      1,
      '🍎 iOS Test Success!',
      'Local notifications are working offline on iOS',
      details,
      payload: 'test_payload_immediate',
    );

    debugPrint('✅ Immediate notification sent');
  }

  /// Schedule a notification for 5 seconds from now
  static Future<void> _scheduleNotification() async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      const Duration(seconds: 5),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 2,
      subtitle: 'Scheduled Offline Notification',
      threadIdentifier: 'mindload_scheduled',
    );

    const NotificationDetails details = NotificationDetails(iOS: iosDetails);

    await _plugin.zonedSchedule(
      2,
      '⏰ Scheduled Test',
      'This notification was scheduled 5 seconds ago',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'test_payload_scheduled',
    );

    debugPrint('✅ Scheduled notification for 5 seconds from now');
  }

  /// Send a rich notification with additional features
  static Future<void> _sendRichNotification() async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 3,
      subtitle: 'Rich Notification Test',
      threadIdentifier: 'mindload_rich',
      categoryIdentifier: 'test_category',
      interruptionLevel: InterruptionLevel.active,
    );

    const NotificationDetails details = NotificationDetails(iOS: iosDetails);

    await _plugin.show(
      3,
      '🎨 Rich Notification',
      'This notification has actions and enhanced features',
      details,
      payload: 'test_payload_rich',
    );

    debugPrint('✅ Rich notification sent');
  }

  /// Clear all test notifications
  static Future<void> clearTestNotifications() async {
    await _plugin.cancelAll();
    debugPrint('🧹 All test notifications cleared');
  }

  /// Get diagnostic information
  static Future<Map<String, dynamic>> getDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    try {
      // Check platform
      diagnostics['platform'] = Platform.operatingSystem;
      diagnostics['isIOS'] = Platform.isIOS;

      // Check permissions
      final status = await Permission.notification.status;
      diagnostics['permissionStatus'] = status.toString();

      // Check plugin
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      diagnostics['iosPluginAvailable'] = iosPlugin != null;

      if (iosPlugin != null) {
        final settings = await iosPlugin.checkPermissions();
        diagnostics['alertEnabled'] = settings?.isAlertEnabled;
        diagnostics['badgeEnabled'] = settings?.isBadgeEnabled;
        diagnostics['soundEnabled'] = settings?.isSoundEnabled;
      }

      // Check pending notifications
      final pending = await _plugin.pendingNotificationRequests();
      diagnostics['pendingCount'] = pending.length;

      debugPrint('📊 Diagnostics: $diagnostics');
    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }
}
