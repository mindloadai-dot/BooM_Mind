import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/services/mindload_notification_service.dart';
import 'package:mindload/services/ios_notification_test.dart';

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

      // Test 4: iOS-specific notifications
      debugPrint('🧪 Test 4: Testing iOS-specific notifications...');
      await testIOSSpecificNotifications();
      debugPrint('✅ Test 4 passed: iOS-specific notifications tested');

      // Test 5: First-run notification
      debugPrint('🧪 Test 5: Testing first-run notification...');
      await testFirstRunNotification();
      debugPrint('✅ Test 5 passed: First-run notification tested');

      debugPrint('🧪 === ALL NOTIFICATION TESTS COMPLETED SUCCESSFULLY ===');
    } catch (e, stackTrace) {
      debugPrint('❌ Comprehensive test failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  /// Test iOS-specific notification categories and features
  static Future<void> testIOSSpecificNotifications() async {
    debugPrint('🍎 Testing iOS-specific notification categories...');

    // Test study reminder with category
    await MindLoadNotificationService.scheduleStudyReminder(
      DateTime.now().add(const Duration(seconds: 2)),
      "Study Time! 📚",
      "Your scheduled study session is ready. Tap to start!",
      payload: "study_reminder_test",
    );
    debugPrint('✅ Study reminder with iOS category scheduled');

    // Test quiz notification with category
    await MindLoadNotificationService.scheduleQuizNotification(
      DateTime.now().add(const Duration(seconds: 4)),
      "Pop Quiz! 🧠",
      "Test your knowledge with a quick quiz. Ready?",
      payload: "quiz_test",
    );
    debugPrint('✅ Quiz notification with iOS category scheduled');

    // Test achievement notification with category
    await MindLoadNotificationService.scheduleAchievementNotification(
      "Achievement Unlocked! 🏆",
      "You've reached a new milestone in your learning journey!",
      payload: "achievement_test",
    );
    debugPrint('✅ Achievement notification with iOS category sent');

    debugPrint('🍎 iOS-specific notification tests completed');
  }

  /// Cancel all test notifications
  static Future<void> cancelAllTests() async {
    await MindLoadNotificationService.cancelAll();
    debugPrint('✅ All test notifications cancelled');
  }

  /// Test iOS-specific notification functionality
  /// Now uses comprehensive test based on pub.dev best practices
  static Future<void> testIOSNotification() async {
    if (!Platform.isIOS) {
      debugPrint('⚠️ This test is for iOS only');
      return;
    }

    debugPrint('🍎 Starting comprehensive iOS notification test...');

    try {
      // Use the comprehensive test based on pub.dev best practices
      await IOSNotificationTest.runComprehensiveTest();

      // Also run diagnostics
      debugPrint('\n📊 Running diagnostics...');
      final diagnostics = await IOSNotificationTest.getDiagnostics();
      debugPrint('Diagnostics results: $diagnostics');

      // Additionally test with MindLoadNotificationService
      debugPrint('\n🔄 Testing MindLoad service integration...');
      await MindLoadNotificationService.initialize();
      await MindLoadNotificationService.scheduleInstant('✅ MindLoad iOS Test',
          'Offline notifications working! ${DateTime.now().toString().substring(11, 19)}');

      debugPrint('🎉 All iOS notification tests passed!');
    } catch (e, stackTrace) {
      debugPrint('❌ iOS notification test failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      // Provide troubleshooting guide
      debugPrint('\n📚 Troubleshooting:');
      debugPrint('1. Test on physical iOS device (not simulator)');
      debugPrint('2. Check Settings > Notifications > Mindload');
      debugPrint('3. Ensure Runner.entitlements has push notifications');
      debugPrint(
          '4. Reference: https://pub.dev/packages/flutter_local_notifications');
    }
  }
}
