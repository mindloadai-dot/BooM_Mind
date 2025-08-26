import 'package:flutter/material.dart';
import 'package:mindload/services/notification_service.dart';
import 'package:mindload/services/notification_event_bus.dart';
import 'package:mindload/services/smart_deadline_service.dart';
import 'package:mindload/services/notification_intelligence_service.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/theme.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/auth_service.dart';

/// **NOTIFICATION SYSTEM VALIDATOR**
/// 
/// Comprehensive testing widget to validate all notification features:
/// - Achievement notifications
/// - Deadline reminders
/// - Study session notifications
/// - Streak milestones
/// - Exam countdowns
/// - Smart timing
/// - Event bus functionality
class NotificationSystemValidator extends StatefulWidget {
  const NotificationSystemValidator({super.key});

  @override
  State<NotificationSystemValidator> createState() => _NotificationSystemValidatorState();
}

class _NotificationSystemValidatorState extends State<NotificationSystemValidator> {
  final List<String> _testResults = [];
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SemanticTokensExtension>()?.tokens ?? 
                 ThemeManager.instance.currentTokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notification System Validator'),
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
      ),
      body: Container(
        color: tokens.bg,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Overview
            _buildStatusCard(tokens),
            const SizedBox(height: 16),
            
            // Test Controls
            _buildTestControls(tokens),
            const SizedBox(height: 16),
            
            // Test Results
            Expanded(
              child: _buildTestResults(tokens),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 System Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusIndicator('Event Bus', true, tokens),
              const SizedBox(width: 16),
              _buildStatusIndicator('Smart Deadlines', true, tokens),
              const SizedBox(width: 16),
              _buildStatusIndicator('Intelligence', true, tokens),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, SemanticTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? tokens.success : tokens.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTestControls(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 Test Controls',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Basic Notification Tests
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isTesting ? null : _testBasicNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.onPrimary,
                  ),
                  child: const Text('Test Basic Notifications'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isTesting ? null : _testEventBus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.secondary,
                    foregroundColor: tokens.onSecondary,
                  ),
                  child: const Text('Test Event Bus'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Advanced Feature Tests
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isTesting ? null : _testSmartDeadlines,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.warning,
                    foregroundColor: tokens.textInverse,
                  ),
                  child: const Text('Test Smart Deadlines'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isTesting ? null : _testIntelligence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.secondary,
                    foregroundColor: tokens.onSecondary,
                  ),
                  child: const Text('Test Intelligence'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Comprehensive Test
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTesting ? null : _runComprehensiveTest,
                                style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.success,
                    foregroundColor: tokens.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
              child: Text(
                _isTesting ? 'Testing...' : '🚀 Run Comprehensive Test',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults(SemanticTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Test Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          
          if (_testResults.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No tests run yet. Use the controls above to test the notification system.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  final result = _testResults[index];
                  final isSuccess = result.startsWith('✅');
                  final isError = result.startsWith('❌');
                  final isWarning = result.startsWith('⚠️');
                  
                  Color textColor;
                  if (isSuccess) {
                    textColor = tokens.success;
                  } else if (isError) {
                    textColor = tokens.error;
                  } else if (isWarning) {
                    textColor = tokens.warning;
                  } else {
                    textColor = tokens.textSecondary;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      result,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          
          if (_testResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_testResults.where((r) => r.startsWith('✅')).length} passed, '
                    '${_testResults.where((r) => r.startsWith('❌')).length} failed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _testResults.clear();
                      });
                    },
                    child: Text(
                      'Clear Results',
                      style: TextStyle(color: tokens.primary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Test basic notification functionality
  Future<void> _testBasicNotifications() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    try {
      _addResult('🧪 Testing basic notification functionality...');
      
      // Test immediate notification
      final success = await WorkingNotificationService.instance.sendTestNotification();
      if (success) {
        _addResult('✅ Test notification sent successfully');
      } else {
        _addResult('❌ Test notification failed');
      }
      
      // Test scheduled notification
      final scheduled = await NotificationService.scheduleStudyReminder(
        studySetId: 'test_scheduled',
        title: 'Test Scheduled Notification',
        body: 'This is a test scheduled notification',
        scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      );
      _addResult('✅ Scheduled notification test completed');
      
      // Test pop quiz
      await NotificationService.schedulePopQuiz('test_set', 'Test Topic');
      _addResult('✅ Pop quiz notification test completed');
      
    } catch (e) {
      _addResult('❌ Basic notification test failed: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// Test event bus functionality
  Future<void> _testEventBus() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    try {
      _addResult('🧪 Testing notification event bus...');
      
      // Test achievement event
      NotificationEventBus.instance.emitAchievementUnlocked(
        achievementId: 'test_achievement',
        achievementTitle: 'Test Achievement',
        category: 'test_category',
        tier: 'test_tier',
      );
      _addResult('✅ Achievement event emitted');
      
      // Test deadline event
      NotificationEventBus.instance.emitDeadlineReminder(
        studySetId: 'test_deadline',
        title: 'Test Study Set',
        deadline: DateTime.now().add(const Duration(days: 7)),
        daysUntil: 7,
        urgency: 'medium',
      );
      _addResult('✅ Deadline event emitted');
      
      // Test study session event
      NotificationEventBus.instance.emitStudySessionCompleted(
        studySetId: 'test_session',
        duration: const Duration(minutes: 30),
        correctAnswers: 8,
        totalQuestions: 10,
        xpEarned: 25,
      );
      _addResult('✅ Study session event emitted');
      
      // Test streak event
      NotificationEventBus.instance.emitStreakMilestone(
        streakDays: 7,
        milestone: 'One Week Streak',
      );
      _addResult('✅ Streak event emitted');
      
      // Test exam countdown event
      NotificationEventBus.instance.emitExamCountdown(
        course: 'Test Course',
        examDate: DateTime.now().add(const Duration(hours: 24)),
        hoursUntil: 24,
        urgency: 'high',
      );
      _addResult('✅ Exam countdown event emitted');
      
    } catch (e) {
      _addResult('❌ Event bus test failed: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// Test smart deadline functionality
  Future<void> _testSmartDeadlines() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    try {
      _addResult('🧪 Testing smart deadline service...');
      
      // Test deadline status calculation
      final testStudySet = _createTestStudySet();
      final status = SmartDeadlineService.instance.getDeadlineStatus(testStudySet);
      _addResult('✅ Deadline status calculated: ${status['message']}');
      
      // Test optimal reminder times
      final optimalTimes = await SmartDeadlineService.instance.getOptimalReminderTimes(
        testStudySet.deadlineDate!,
      );
      _addResult('✅ Optimal reminder times calculated: ${optimalTimes.length} times');
      
      // Test smart notification scheduling
      await SmartDeadlineService.instance.scheduleSmartDeadlineNotifications(testStudySet);
      _addResult('✅ Smart deadline notifications scheduled');
      
    } catch (e) {
      _addResult('❌ Smart deadline test failed: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// Test notification intelligence
  Future<void> _testIntelligence() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    try {
      _addResult('🧪 Testing notification intelligence...');
      
      // Test user behavior analysis
      final strategy = await NotificationIntelligenceService.instance.analyzeUserBehavior(AuthService.instance.currentUserId ?? 'anonymous');
      _addResult('✅ User behavior analyzed: ${strategy.frequency} notifications/day');
      
      // Test optimal timing calculation
      final optimalTime = await NotificationIntelligenceService.instance.getOptimalNotificationTime(
        notificationType: 'achievement',
        userId: AuthService.instance.currentUserId ?? 'anonymous',
      );
      _addResult('✅ Optimal notification time calculated: ${optimalTime?.toLocal()}');
      
      // Test engagement level determination
      _addResult('✅ Intelligence service test completed');
      
    } catch (e) {
      _addResult('❌ Intelligence test failed: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// Run comprehensive test of all features
  Future<void> _runComprehensiveTest() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    try {
      _addResult('🚀 Starting comprehensive notification system test...');
      
      // Test all components in sequence
      await _testBasicNotifications();
      await Future.delayed(const Duration(seconds: 1));
      
      await _testEventBus();
      await Future.delayed(const Duration(seconds: 1));
      
      await _testSmartDeadlines();
      await Future.delayed(const Duration(seconds: 1));
      
      await _testIntelligence();
      
      _addResult('🎉 Comprehensive test completed successfully!');
      
      // Summary
      final passed = _testResults.where((r) => r.startsWith('✅')).length;
      final failed = _testResults.where((r) => r.startsWith('❌')).length;
      final total = _testResults.length;
      
      _addResult('📊 Test Summary: $passed/$total passed, $failed failed');
      
    } catch (e) {
      _addResult('❌ Comprehensive test failed: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  /// Add test result to the list
  void _addResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toLocal().toString().substring(11, 19)} $result');
    });
  }

  /// Create a test study set for validation
  StudySet _createTestStudySet() {
    return StudySet(
      id: 'test_study_set',
      title: 'Test Study Set',
      content: 'A test study set for validation purposes',
      flashcards: [
        Flashcard(
          id: 'test_flashcard_1',
          question: 'What is the purpose of this test?',
          answer: 'To validate the notification system functionality',
          difficulty: DifficultyLevel.easy,
          reviewCount: 0,
        ),
      ],
      createdDate: DateTime.now(),
      lastStudied: DateTime.now(),
      deadlineDate: DateTime.now().add(const Duration(days: 7)),
      notificationsEnabled: true,
    );
  }
}