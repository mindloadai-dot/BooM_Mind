import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/notification_test_service.dart';
import 'package:mindload/services/mindload_notification_service.dart';
import 'package:mindload/services/deadline_service.dart';
import 'package:mindload/models/study_data.dart';

/// Notification Debug Screen for testing automatic scheduling
class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String _statusMessage = 'Ready to test notifications';
  bool _isLoading = false;
  List<String> _logMessages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTestButton(
                      '🧪 Run All Tests',
                      () => _runAllTests(),
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '📅 Test Deadline Service',
                      () => _testDeadlineService(),
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '📱 Test Instant Notification',
                      () => _testInstantNotification(),
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '⏰ Test Scheduled Notification',
                      () => _testScheduledNotification(),
                      Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '🔍 Get Debug Info',
                      () => _getDebugInfo(),
                      Colors.teal,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '🧹 Clear All Notifications',
                      () => _clearAllNotifications(),
                      Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '📚 Create Test Study Set with Deadline',
                      () => _createTestStudySetWithDeadline(),
                      Colors.indigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Daily Notification System',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '📅 Setup 3x Daily Notifications',
                      () => _setupDailyNotifications(),
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '🔄 Test Daily System',
                      () => _testDailySystem(),
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildTestButton(
                      '❌ Clear Daily Notifications',
                      () => _clearDailyNotifications(),
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Log Messages
            if (_logMessages.isNotEmpty) ...[
              Text(
                'Debug Log',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logMessages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(
                        _logMessages[index],
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(title),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running comprehensive notification tests...';
      _logMessages.clear();
    });

    try {
      await NotificationTestService.runComprehensiveTests();
      setState(() {
        _statusMessage = 'All tests completed successfully!';
        _logMessages.add('✅ Comprehensive tests completed');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Tests failed: $e';
        _logMessages.add('❌ Tests failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDeadlineService() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing deadline service...';
      _logMessages.clear();
    });

    try {
      await NotificationTestService.testDeadlineService();
      setState(() {
        _statusMessage = 'Deadline service test completed!';
        _logMessages.add('✅ Deadline service test completed');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Deadline service test failed: $e';
        _logMessages.add('❌ Deadline service test failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testInstantNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing instant notification...';
      _logMessages.clear();
    });

    try {
      await MindLoadNotificationService.scheduleInstant(
        '🧪 Debug Test',
        'This is a test instant notification from debug screen',
      );
      setState(() {
        _statusMessage = 'Instant notification sent!';
        _logMessages.add('✅ Instant notification sent');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Instant notification failed: $e';
        _logMessages.add('❌ Instant notification failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testScheduledNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing scheduled notification...';
      _logMessages.clear();
    });

    try {
      final futureTime = DateTime.now().add(const Duration(seconds: 5));
      await MindLoadNotificationService.scheduleAt(
        futureTime,
        '🧪 Scheduled Debug Test',
        'This notification was scheduled 5 seconds from now',
        payload: 'debug_scheduled',
      );
      setState(() {
        _statusMessage = 'Scheduled notification set for 5 seconds from now!';
        _logMessages.add('✅ Scheduled notification set for ${futureTime.toString()}');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Scheduled notification failed: $e';
        _logMessages.add('❌ Scheduled notification failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getDebugInfo() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Getting debug information...';
      _logMessages.clear();
    });

    try {
      await NotificationTestService.getDebugInfo();
      setState(() {
        _statusMessage = 'Debug information retrieved!';
        _logMessages.add('✅ Debug information retrieved');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Debug info failed: $e';
        _logMessages.add('❌ Debug info failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing all notifications...';
      _logMessages.clear();
    });

    try {
      await NotificationTestService.clearTestNotifications();
      setState(() {
        _statusMessage = 'All notifications cleared!';
        _logMessages.add('✅ All notifications cleared');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Clear notifications failed: $e';
        _logMessages.add('❌ Clear notifications failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestStudySetWithDeadline() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating test study set with deadline...';
      _logMessages.clear();
    });

    try {
      // Create a test study set with deadline in 2 days
      final testStudySet = StudySet(
        id: 'test_deadline_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Study Set - Deadline Notifications',
        content: 'This is a test study set to verify automatic notification scheduling.',
        flashcards: [],
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        deadlineDate: DateTime.now().add(const Duration(days: 2)), // Deadline in 2 days
        notificationsEnabled: true,
      );
      
      _logMessages.add('📚 Created test study set: ${testStudySet.title}');
      _logMessages.add('📅 Deadline: ${testStudySet.deadlineDate}');
      
      // Schedule notifications for this study set
      final deadlineService = DeadlineService.instance;
      await deadlineService.scheduleDeadlineNotifications(testStudySet);
      
      _logMessages.add('✅ Notifications scheduled for test study set');
      
      // Get pending notifications to verify
      final pendingNotifications = await MindLoadNotificationService.getPendingNotifications();
      _logMessages.add('📋 Pending notifications: ${pendingNotifications.length}');
      
      for (final notification in pendingNotifications) {
        _logMessages.add('  - ID: ${notification.id}, Title: ${notification.title}');
      }
      
      setState(() {
        _statusMessage = 'Test study set created with deadline! Check notifications in 2 days.';
        _logMessages.add('🎉 Test study set created successfully!');
        _logMessages.add('📱 You will receive notifications at:');
        _logMessages.add('   - 3 days before deadline');
        _logMessages.add('   - 1 day before deadline');
        _logMessages.add('   - On the deadline day');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to create test study set: $e';
        _logMessages.add('❌ Failed to create test study set: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupDailyNotifications() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up daily notifications...';
      _logMessages.clear();
    });

    try {
      // Set up 3x daily notifications
      await MindLoadNotificationService.updateDailyPlan(
        ['09:00', '13:00', '19:00'],
        title: 'MindLoad Study Reminder',
        body: '15 min today keeps your streak alive! 🧠',
      );

      // Get pending notifications to verify
      final pendingNotifications = await MindLoadNotificationService.getPendingNotifications();
      final dailyNotifications = pendingNotifications.where((n) => n.id >= 20000).toList();

      setState(() {
        _statusMessage = 'Daily notifications set up successfully!';
        _logMessages.add('✅ Set up 3x daily notifications:');
        _logMessages.add('   - 09:00 AM');
        _logMessages.add('   - 01:00 PM');
        _logMessages.add('   - 07:00 PM');
        _logMessages.add('📋 Found ${dailyNotifications.length} daily notifications scheduled');
        
        for (final notification in dailyNotifications) {
          _logMessages.add('  - ID: ${notification.id}, Title: ${notification.title}');
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to setup daily notifications: $e';
        _logMessages.add('❌ Failed to setup daily notifications: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDailySystem() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing daily notification system...';
      _logMessages.clear();
    });

    try {
      // Run the comprehensive daily system test
      await MindLoadNotificationService.testDailyNotificationSystem();
      
      // Also test rescheduling
      await MindLoadNotificationService.rescheduleDailyPlan();

      setState(() {
        _statusMessage = 'Daily notification system test completed!';
        _logMessages.add('✅ Daily notification system test passed');
        _logMessages.add('🔄 Rescheduling test completed');
        _logMessages.add('📱 Check console for detailed test results');
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Daily system test failed: $e';
        _logMessages.add('❌ Daily system test failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearDailyNotifications() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing daily notifications...';
      _logMessages.clear();
    });

    try {
      // Clear all daily notifications
      await MindLoadNotificationService.clearDailyPlan();

      // Verify they're cleared
      final pendingNotifications = await MindLoadNotificationService.getPendingNotifications();
      final dailyNotifications = pendingNotifications.where((n) => n.id >= 20000).toList();

      setState(() {
        _statusMessage = 'Daily notifications cleared!';
        _logMessages.add('✅ Daily notifications cleared');
        _logMessages.add('📋 Remaining daily notifications: ${dailyNotifications.length}');
        
        if (dailyNotifications.isEmpty) {
          _logMessages.add('🎉 All daily notifications successfully removed');
        } else {
          _logMessages.add('⚠️ Some daily notifications may still be pending');
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to clear daily notifications: $e';
        _logMessages.add('❌ Failed to clear daily notifications: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
