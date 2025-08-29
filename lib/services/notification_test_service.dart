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
    debugPrint('🧪 Starting permission test...');
    await MindLoadNotificationService.initialize();
    debugPrint('✅ Permission request test completed');
  }

  /// Run comprehensive notification test
  static Future<void> runComprehensiveTest() async {
    debugPrint('🧪 === COMPREHENSIVE NOTIFICATION TEST STARTED ===');

    try {
      // Test 1: Initialize
      debugPrint('🧪 Test 1: Initializing notification service...');
      await MindLoadNotificationService.initialize();
      debugPrint('✅ Test 1 passed: Service initialized');

      // Test 2: Basic notification
      debugPrint('🧪 Test 2: Sending basic notification...');
      await testBasicNotification();
      debugPrint('✅ Test 2 passed: Basic notification sent');

      // Test 3: Study reminder
      debugPrint('🧪 Test 3: Sending study reminder...');
      await testStudyReminder();
      debugPrint('✅ Test 3 passed: Study reminder sent');

      // Test 4: First-run notification
      debugPrint('🧪 Test 4: Testing first-run notification...');
      await testFirstRunNotification();
      debugPrint('✅ Test 4 passed: First-run notification tested');

      debugPrint('🧪 === ALL NOTIFICATION TESTS COMPLETED SUCCESSFULLY ===');
    } catch (e, stackTrace) {
      debugPrint('❌ Comprehensive test failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Cancel all test notifications
  static Future<void> cancelAllTests() async {
    await MindLoadNotificationService.cancelAll();
    debugPrint('✅ All test notifications cancelled');
  }
}
