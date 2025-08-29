import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/services/mindload_notification_service.dart';

/// Simple test service for verifying notification functionality
///
/// This is a helper service for development and testing only.
/// All notifications go through the single MindLoadNotificationService.
class NotificationTestService {
  /// Test basic instant notification
  static Future<void> testBasicNotification() async {
    await MindLoadNotificationService.scheduleInstant(
      "Test Notification 🧪",
      "This is a test to verify notifications are working correctly!",
    );
    debugPrint('✅ Basic notification test sent');
  }

  /// Test study reminder notification
  static Future<void> testStudyReminder() async {
    await MindLoadNotificationService.scheduleInstant(
      "Study Time! 📚",
      "Time for your daily review session. Keep up the great work!",
    );
    debugPrint('✅ Study reminder test sent');
  }

  /// Test scheduled notification (5 seconds)
  static Future<void> testScheduledNotification() async {
    final when = DateTime.now().add(const Duration(seconds: 5));
    await MindLoadNotificationService.scheduleAt(
      when,
      "Scheduled Test ⏰",
      "This notification was scheduled 5 seconds ago!",
      payload: "test_scheduled",
    );
    debugPrint('✅ Scheduled notification test sent (5 seconds)');
  }

  /// Test first-run notification manually
  static Future<void> testFirstRunNotification() async {
    // Clear the flag first to test
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasFiredFirstStudySetNotification');

    // Now trigger it
    await MindLoadNotificationService.fireFirstStudySetNotificationIfNeeded();
    debugPrint('✅ First-run notification test triggered');
  }

  /// Test permission request
  static Future<void> testPermissionRequest() async {
    await MindLoadNotificationService.initialize();
    debugPrint('✅ Permission request test completed');
  }

  /// Cancel all test notifications
  static Future<void> cancelAllTests() async {
    await MindLoadNotificationService.cancelAll();
    debugPrint('✅ All test notifications cancelled');
  }
}
