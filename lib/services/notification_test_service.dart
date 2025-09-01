import 'package:flutter/foundation.dart';
import 'package:mindload/services/mindload_notification_service.dart';
import 'package:mindload/services/deadline_service.dart';
import 'package:mindload/models/study_data.dart';

/// Notification Test Service for debugging automatic scheduling
class NotificationTestService {
  static final NotificationTestService _instance = NotificationTestService._();
  static NotificationTestService get instance => _instance;
  NotificationTestService._();

  /// Run comprehensive notification tests
  static Future<void> runComprehensiveTests() async {
    debugPrint('🧪 Starting comprehensive notification tests...');

    try {
      // Test 1: Basic instant notification
      await _testInstantNotification();

      // Test 2: Scheduled notification
      await _testScheduledNotification();

      // Test 3: Deadline notifications
      await _testDeadlineNotifications();

      // Test 4: Notification cancellation
      await _testNotificationCancellation();

      // Test 5: Get pending notifications
      await _testPendingNotifications();

      debugPrint('✅ All notification tests completed successfully');
    } catch (e) {
      debugPrint('❌ Notification tests failed: $e');
    }
  }

  /// Test instant notification
  static Future<void> _testInstantNotification() async {
    debugPrint('🧪 Test 1: Instant notification');
    
    try {
      await MindLoadNotificationService.scheduleInstant(
        '🧪 Test Notification',
        'This is a test instant notification',
      );
      debugPrint('✅ Instant notification test passed');
    } catch (e) {
      debugPrint('❌ Instant notification test failed: $e');
    }
  }

  /// Test scheduled notification
  static Future<void> _testScheduledNotification() async {
    debugPrint('🧪 Test 2: Scheduled notification');
    
    try {
      final futureTime = DateTime.now().add(const Duration(seconds: 10));
      await MindLoadNotificationService.scheduleAt(
        futureTime,
        '🧪 Scheduled Test',
        'This notification was scheduled for testing',
        payload: 'test_scheduled',
      );
      debugPrint('✅ Scheduled notification test passed');
    } catch (e) {
      debugPrint('❌ Scheduled notification test failed: $e');
    }
  }

  /// Test deadline notifications
  static Future<void> _testDeadlineNotifications() async {
    debugPrint('🧪 Test 3: Deadline notifications');
    
    try {
      // Create a test study set with a deadline in the future
      final testStudySet = StudySet(
        id: 'test_deadline_set',
        title: 'Test Study Set',
        content: 'Test content',
        flashcards: [],
        quizQuestions: [],
        quizzes: [],
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        deadlineDate: DateTime.now().add(const Duration(days: 1)), // Tomorrow
      );

      // Schedule deadline notifications
      await DeadlineService.instance.scheduleDeadlineNotifications(testStudySet);
      
      // Check how many notifications were scheduled
      final scheduledCount = DeadlineService.instance.getScheduledNotificationCount('test_deadline_set');
      debugPrint('📅 Scheduled $scheduledCount deadline notifications for test study set');
      
      debugPrint('✅ Deadline notifications test passed');
    } catch (e) {
      debugPrint('❌ Deadline notifications test failed: $e');
    }
  }

  /// Test notification cancellation
  static Future<void> _testNotificationCancellation() async {
    debugPrint('🧪 Test 4: Notification cancellation');
    
    try {
      // Schedule a notification to cancel
      final futureTime = DateTime.now().add(const Duration(seconds: 30));
      final testId = 999999; // Use a specific ID for testing
      
      await MindLoadNotificationService.scheduleAt(
        futureTime,
        '🧪 Cancel Test',
        'This notification will be cancelled',
        payload: 'test_cancel',
      );

      // Wait a moment then cancel it
      await Future.delayed(const Duration(seconds: 2));
      await MindLoadNotificationService.cancelById(testId);
      
      debugPrint('✅ Notification cancellation test passed');
    } catch (e) {
      debugPrint('❌ Notification cancellation test failed: $e');
    }
  }

  /// Test getting pending notifications
  static Future<void> _testPendingNotifications() async {
    debugPrint('🧪 Test 5: Get pending notifications');
    
    try {
      final pendingNotifications = await MindLoadNotificationService.getPendingNotifications();
      debugPrint('📋 Found ${pendingNotifications.length} pending notifications');
      
      for (final notification in pendingNotifications) {
        debugPrint('📋 Pending: ID=${notification.id}, Title="${notification.title}", Payload="${notification.payload}"');
      }
      
      debugPrint('✅ Pending notifications test passed');
    } catch (e) {
      debugPrint('❌ Pending notifications test failed: $e');
    }
  }

  /// Test deadline service functionality
  static Future<void> testDeadlineService() async {
    debugPrint('🧪 Testing DeadlineService functionality...');
    
    try {
      // Create a test study set
      final testStudySet = StudySet(
        id: 'deadline_test_set',
        title: 'Deadline Test Set',
        content: 'Test content for deadline notifications',
        flashcards: [],
        quizQuestions: [],
        quizzes: [],
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        deadlineDate: DateTime.now().add(const Duration(days: 2)), // 2 days from now
      );

      debugPrint('📅 Test study set created with deadline: ${testStudySet.deadlineDate}');

      // Test scheduling deadline notifications
      await DeadlineService.instance.scheduleDeadlineNotifications(testStudySet);
      
      // Check scheduled notifications
      final scheduledCount = DeadlineService.instance.getScheduledNotificationCount('deadline_test_set');
      debugPrint('📅 Scheduled $scheduledCount notifications for deadline test set');

      // Test updating deadline
      final newDeadline = DateTime.now().add(const Duration(days: 5));
      await DeadlineService.instance.updateDeadline(testStudySet, newDeadline);
      
      // Check updated notifications
      final updatedCount = DeadlineService.instance.getScheduledNotificationCount('deadline_test_set');
      debugPrint('📅 After update: $updatedCount notifications scheduled');

      // Test removing deadline
      await DeadlineService.instance.updateDeadline(testStudySet, null);
      
      // Check final count
      final finalCount = DeadlineService.instance.getScheduledNotificationCount('deadline_test_set');
      debugPrint('📅 After removal: $finalCount notifications scheduled');

      debugPrint('✅ DeadlineService test completed successfully');
    } catch (e) {
      debugPrint('❌ DeadlineService test failed: $e');
    }
  }

  /// Get debug information about notification state
  static Future<void> getDebugInfo() async {
    debugPrint('🔍 Getting notification debug information...');
    
    try {
      // Get pending notifications
      final pendingNotifications = await MindLoadNotificationService.getPendingNotifications();
      debugPrint('📋 Total pending notifications: ${pendingNotifications.length}');
      
      // Get deadline service info
      final allScheduled = DeadlineService.instance.getAllScheduledNotifications();
      debugPrint('📅 Deadline service tracking ${allScheduled.length} study sets');
      
      for (final entry in allScheduled.entries) {
        debugPrint('📅 Study set ${entry.key}: ${entry.value.length} notifications scheduled');
      }
      
      // Show pending notification details
      for (final notification in pendingNotifications) {
        debugPrint('📋 Pending: ID=${notification.id}, Title="${notification.title}", Payload="${notification.payload}"');
      }
      
    } catch (e) {
      debugPrint('❌ Failed to get debug info: $e');
    }
  }

  /// Clear all test notifications
  static Future<void> clearTestNotifications() async {
    debugPrint('🧹 Clearing all test notifications...');
    
    try {
      await MindLoadNotificationService.cancelAll();
      debugPrint('✅ All notifications cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }
}
