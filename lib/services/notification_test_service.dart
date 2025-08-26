import 'package:flutter/foundation.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/services/user_profile_service.dart';

/// Enhanced service to test and demonstrate all notification features
/// Now includes comprehensive testing of all notification styles
/// Shows how personalized notifications work throughout the application
class NotificationTestService {
  static final NotificationTestService _instance = NotificationTestService._();
  static NotificationTestService get instance => _instance;
  NotificationTestService._();

  /// Test all notification types with current style
  Future<void> testAllNotificationTypes() async {
    try {
      if (kDebugMode) {
        debugPrint('🧪 Testing all notification types...');
      }

      // Test study session reminder
      await WorkingNotificationService.instance.showStudySessionReminder(
        subject: 'Mathematics',
        durationMinutes: 30,
        customMessage: 'Time to practice calculus',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test pop quiz
      await WorkingNotificationService.instance.showPopQuiz('Algebra Quiz');

      await Future.delayed(const Duration(seconds: 1));

      // Test streak reminder
      await WorkingNotificationService.instance.showStreakReminder(7);

      await Future.delayed(const Duration(seconds: 1));

      // Test achievement
      await WorkingNotificationService.instance
          .showAchievementUnlocked('Math Master');

      await Future.delayed(const Duration(seconds: 1));

      // Test deadline reminder
      await WorkingNotificationService.instance.showDeadlineReminder(
        title: 'Final Exam',
        deadline: DateTime.now().add(const Duration(days: 3)),
        subject: 'Advanced Calculus',
      );

      if (kDebugMode) {
        debugPrint('✅ All notification types tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to test notification types: $e');
      }
    }
  }

  /// Test all notification styles
  Future<void> testAllNotificationStyles() async {
    try {
      if (kDebugMode) {
        debugPrint('🎨 Testing all notification styles...');
      }

      final userProfile = UserProfileService.instance;
      final originalStyle = userProfile.notificationStyle;
      final availableStyles = userProfile.availableStyles;

      // Test each style
      for (final style in availableStyles) {
        if (kDebugMode) {
          debugPrint('🎨 Testing style: $style');
        }

        // Update to this style
        await userProfile.updateNotificationStyle(style);

        // Test a notification with this style
        await WorkingNotificationService.instance.showNotificationNow(
          title: 'Style Test',
          body: 'This is a test notification to demonstrate the $style style',
          payload: 'style_test:$style',
          channelType: 'general',
          subject: 'Style Testing',
          timeContext: 'test',
        );

        await Future.delayed(const Duration(seconds: 2));
      }

      // Restore original style
      await userProfile.updateNotificationStyle(originalStyle);

      if (kDebugMode) {
        debugPrint('✅ All notification styles tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to test notification styles: $e');
      }
    }
  }

  /// Test quiet hours functionality
  Future<void> testQuietHours() async {
    try {
      if (kDebugMode) {
        debugPrint('🔇 Testing quiet hours...');
      }

      final userProfile = UserProfileService.instance;
      final originalQuietHours = userProfile.quietHoursEnabled;

      // Enable quiet hours
      await userProfile.updateQuietHours(
        enabled: true,
        start: '22:00',
        end: '07:00',
      );

      // Try to send a notification (should be suppressed)
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Quiet Hours Test',
        body: 'This notification should be suppressed during quiet hours',
        payload: 'quiet_hours_test',
        channelType: 'general',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Disable quiet hours
      await userProfile.updateQuietHours(
        enabled: false,
        start: '22:00',
        end: '07:00',
      );

      // Send notification again (should work now)
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Quiet Hours Disabled',
        body: 'This notification should work now that quiet hours are disabled',
        payload: 'quiet_hours_disabled_test',
        channelType: 'general',
      );

      // Restore original setting
      await userProfile.updateQuietHours(
        enabled: originalQuietHours,
        start: userProfile.quietHoursStart,
        end: userProfile.quietHoursEnd,
      );

      if (kDebugMode) {
        debugPrint('✅ Quiet hours tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to test quiet hours: $e');
      }
    }
  }

  /// Test timezone-aware notifications
  Future<void> testTimezoneNotifications() async {
    try {
      if (kDebugMode) {
        debugPrint('🌍 Testing timezone notifications...');
      }

      // Test scheduling a notification for 1 minute from now
      final scheduledTime = DateTime.now().add(const Duration(minutes: 1));

      await WorkingNotificationService.instance.scheduleNotification(
        title: 'Scheduled Test',
        body: 'This notification was scheduled and should appear in 1 minute',
        scheduledTime: scheduledTime,
        payload: 'scheduled_test',
        channelType: 'general',
        timezoneName: 'UTC',
        subject: 'Timezone Testing',
        timeContext: 'scheduled',
      );

      if (kDebugMode) {
        debugPrint('✅ Timezone notifications tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to test timezone notifications: $e');
      }
    }
  }

  /// Test notification channels
  Future<void> testNotificationChannels() async {
    try {
      if (kDebugMode) {
        debugPrint('📡 Testing notification channels...');
      }

      // Test study reminders channel
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Study Channel Test',
        body: 'This notification uses the study reminders channel',
        payload: 'channel_test:study',
        channelType: 'study_reminders',
        subject: 'Channel Testing',
        timeContext: 'test',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test pop quiz channel
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Pop Quiz Channel Test',
        body: 'This notification uses the pop quiz channel',
        payload: 'channel_test:pop_quiz',
        channelType: 'pop_quiz',
        subject: 'Channel Testing',
        timeContext: 'test',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test deadlines channel
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Deadlines Channel Test',
        body: 'This notification uses the deadlines channel',
        payload: 'channel_test:deadlines',
        channelType: 'deadlines',
        subject: 'Channel Testing',
        timeContext: 'test',
      );

      if (kDebugMode) {
        debugPrint('✅ Notification channels tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to test notification channels: $e');
      }
    }
  }

  /// Test notification priorities
  Future<void> testNotificationPriorities() async {
    try {
      if (kDebugMode) {
        debugPrint('⚡ Testing notification priorities...');
      }

      // Test low priority notification
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Low Priority Test',
        body: 'This is a low priority notification',
        payload: 'priority_test:low',
        isHighPriority: false,
        channelType: 'general',
        subject: 'Priority Testing',
        timeContext: 'test',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test high priority notification
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'High Priority Test',
        body: 'This is a high priority notification',
        payload: 'priority_test:high',
        isHighPriority: true,
        channelType: 'general',
        subject: 'Priority Testing',
        timeContext: 'test',
      );

      if (kDebugMode) {
        debugPrint('✅ Notification priorities tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to test notification priorities: $e');
      }
    }
  }

  /// Test personalized notifications with different contexts
  Future<void> testPersonalizedContexts() async {
    try {
      if (kDebugMode) {
        debugPrint('👤 Testing personalized contexts...');
      }

      // Test with subject context
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Subject Context Test',
        body: 'Testing notifications with subject context',
        payload: 'context_test:subject',
        channelType: 'general',
        subject: 'Advanced Physics',
        timeContext: 'test',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test with deadline context
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Deadline Context Test',
        body: 'Testing notifications with deadline context',
        payload: 'context_test:deadline',
        channelType: 'general',
        deadline: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        timeContext: 'test',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test with streak context
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Streak Context Test',
        body: 'Testing notifications with streak context',
        payload: 'context_test:streak',
        channelType: 'general',
        streakDays: 15,
        timeContext: 'test',
      );

      await Future.delayed(const Duration(seconds: 1));

      // Test with achievement context
      await WorkingNotificationService.instance.showNotificationNow(
        title: 'Achievement Context Test',
        body: 'Testing notifications with achievement context',
        payload: 'context_test:achievement',
        channelType: 'general',
        achievement: 'Perfect Score',
        timeContext: 'test',
      );

      if (kDebugMode) {
        debugPrint('✅ Personalized contexts tested successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to test personalized contexts: $e');
      }
    }
  }

  /// Run comprehensive notification system test
  Future<void> runComprehensiveTest() async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 Starting comprehensive notification system test...');
      }

      // Test 1: All notification types
      await testAllNotificationTypes();
      await Future.delayed(const Duration(seconds: 2));

      // Test 2: All notification styles
      await testAllNotificationStyles();
      await Future.delayed(const Duration(seconds: 2));

      // Test 3: Quiet hours
      await testQuietHours();
      await Future.delayed(const Duration(seconds: 2));

      // Test 4: Timezone awareness
      await testTimezoneNotifications();
      await Future.delayed(const Duration(seconds: 2));

      // Test 5: Notification channels
      await testNotificationChannels();
      await Future.delayed(const Duration(seconds: 2));

      // Test 6: Priority levels
      await testNotificationPriorities();
      await Future.delayed(const Duration(seconds: 2));

      // Test 7: Personalized contexts
      await testPersonalizedContexts();

      if (kDebugMode) {
        debugPrint('🎉 Comprehensive notification system test completed!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Comprehensive test failed: $e');
      }
    }
  }

  /// Get comprehensive system status
  Map<String, dynamic> getSystemStatus() {
    final userProfile = UserProfileService.instance;
    final notificationService = WorkingNotificationService.instance;

    return {
      'user_profile': {
        'nickname': userProfile.nickname,
        'display_name': userProfile.displayName,
        'timezone': userProfile.timezone,
        'quiet_hours_enabled': userProfile.quietHoursEnabled,
        'quiet_hours_start': userProfile.quietHoursStart,
        'quiet_hours_end': userProfile.quietHoursEnd,
        'notification_style': userProfile.notificationStyle,
        'available_styles': userProfile.availableStyles,
        'is_in_quiet_hours': userProfile.isInQuietHours,
        'personalized_greeting': userProfile.personalizedGreeting,
      },
      'notification_service': notificationService.getSystemStatus(),
      'style_system': {
        'current_style': userProfile.notificationStyle,
        'style_info': userProfile.getStyleInfo(userProfile.notificationStyle),
        'all_styles': userProfile.availableStyles
            .map((style) => {
                  'style': style,
                  'info': userProfile.getStyleInfo(style),
                })
            .toList(),
      },
      'features': {
        'personalized_notifications': true,
        'style_based_notifications': true,
        'quiet_hours': true,
        'timezone_awareness': true,
        'multiple_channels': true,
        'priority_levels': true,
        'context_awareness': true,
        'nickname_integration': true,
      },
      'test_capabilities': {
        'all_notification_types': true,
        'all_notification_styles': true,
        'quiet_hours_testing': true,
        'timezone_testing': true,
        'channel_testing': true,
        'priority_testing': true,
        'context_testing': true,
        'comprehensive_testing': true,
      },
    };
  }
}
