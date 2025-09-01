import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/mindload_notification_service.dart';

class DeadlineService {
  static final DeadlineService _instance = DeadlineService._();
  static DeadlineService get instance => _instance;
  DeadlineService._();

  // Track scheduled notifications by study set ID
  static final Map<String, List<int>> _scheduledNotificationIds = {};

  /// Schedule all deadline notifications for a study set
  Future<void> scheduleDeadlineNotifications(StudySet studySet) async {
    if (!studySet.hasDeadline) return;

    final deadline = studySet.deadlineDate!;
    final now = DateTime.now();
    final studySetId = studySet.id;
    final title = studySet.title;

    debugPrint('📅 Scheduling deadline notifications for study set: $studySetId');
    debugPrint('📅 Deadline: $deadline');
    debugPrint('📅 Current time: $now');

    // Cancel any existing notifications for this study set
    await cancelDeadlineNotifications(studySetId);

    // Schedule notifications at different intervals before the deadline
    final notificationSchedule = <Duration, String>{
      const Duration(days: 7):
          '📅 Deadline Alert: One week left to study "$title"',
      const Duration(days: 3):
          '⏰ Deadline Reminder: 3 days left for "$title" - Time to review!',
      const Duration(days: 1):
          '🚨 Final Notice: "$title" deadline is tomorrow!',
      const Duration(hours: 2):
          '⚡ Last Call: "$title" deadline in 2 hours - Final review time!',
    };

    final List<int> scheduledIds = [];

    for (final entry in notificationSchedule.entries) {
      final notificationTime = deadline.subtract(entry.key);

      // Only schedule if the notification time is in the future
      if (notificationTime.isAfter(now)) {
        debugPrint('📅 Scheduling notification for: ${notificationTime.toString()}');
        
        try {
          // Generate a unique ID for this notification
          final notificationId = _generateNotificationId(studySetId, entry.key);
          
          await MindLoadNotificationService.scheduleAt(
            notificationTime,
            'Study Deadline Approaching',
            entry.value,
            payload: 'deadline_${studySetId}_${entry.key.inDays}',
          );
          
          scheduledIds.add(notificationId);
          debugPrint('✅ Deadline notification scheduled: ${entry.value}');
        } catch (e) {
          debugPrint('❌ Failed to schedule deadline notification: $e');
        }
      } else {
        debugPrint('⚠️ Skipping notification in the past: ${notificationTime.toString()}');
      }
    }

    // Store the scheduled notification IDs for this study set
    if (scheduledIds.isNotEmpty) {
      _scheduledNotificationIds[studySetId] = scheduledIds;
      debugPrint('📅 Stored ${scheduledIds.length} notification IDs for study set: $studySetId');
    }

    // Schedule motivational message right after creation/update
    await _scheduleMotivationalMessage(studySet);
  }

  /// Schedule a motivational message based on time until deadline
  Future<void> _scheduleMotivationalMessage(StudySet studySet) async {
    final deadline = studySet.deadlineDate!;
    final now = DateTime.now();
    final daysUntilDeadline = deadline.difference(now).inDays;
    final title = studySet.title;

    String motivationMessage;

    if (daysUntilDeadline > 7) {
      motivationMessage =
          'Great! You have $daysUntilDeadline days to master "$title". Start strong! 💪';
    } else if (daysUntilDeadline > 1) {
      motivationMessage =
          'Perfect timing! $daysUntilDeadline days to excel at "$title". Let\'s do this! 🚀';
    } else if (daysUntilDeadline == 1) {
      motivationMessage =
          'One day to shine with "$title"! Intensive study mode activated! ⚡';
    } else if (daysUntilDeadline == 0) {
      motivationMessage =
          'Deadline today for "$title"! Every minute counts - you\'ve got this! 🎯';
    } else {
      // Overdue
      final daysPast = -daysUntilDeadline;
      motivationMessage =
          '"$title" deadline passed $daysPast days ago. Time for focused catch-up! 🔥';
    }

    try {
      await MindLoadNotificationService.scheduleAt(
        DateTime.now().add(const Duration(seconds: 3)),
        '🎯 Study Plan Update',
        motivationMessage,
        payload: 'motivation_${studySet.id}',
      );
      debugPrint('✅ Motivational message scheduled for study set: ${studySet.id}');
    } catch (e) {
      debugPrint('❌ Failed to schedule motivational message: $e');
    }
  }

  /// Cancel all deadline notifications for a specific study set
  Future<void> cancelDeadlineNotifications(String studySetId) async {
    debugPrint('📅 Canceling deadline notifications for study set: $studySetId');
    
    try {
      // Get the scheduled notification IDs for this study set
      final notificationIds = _scheduledNotificationIds[studySetId];
      
      if (notificationIds != null && notificationIds.isNotEmpty) {
        debugPrint('📅 Found ${notificationIds.length} notifications to cancel for study set: $studySetId');
        
        // Cancel each specific notification
        for (final id in notificationIds) {
          try {
            await MindLoadNotificationService.cancelById(id);
            debugPrint('📅 Cancelled notification ID: $id');
          } catch (e) {
            debugPrint('❌ Failed to cancel notification ID $id: $e');
          }
        }
        
        // Remove the tracking for this study set
        _scheduledNotificationIds.remove(studySetId);
        debugPrint('📅 Removed notification tracking for study set: $studySetId');
      } else {
        debugPrint('📅 No scheduled notifications found for study set: $studySetId');
      }
    } catch (e) {
      debugPrint('❌ Error canceling deadline notifications: $e');
    }
  }

  /// Generate a unique notification ID for a study set and duration
  int _generateNotificationId(String studySetId, Duration duration) {
    final hash = '$studySetId${duration.inDays}${duration.inHours}'.hashCode;
    return hash.abs() % 2147483647; // Ensure positive 32-bit int
  }

  /// Get study sets that have deadlines today
  List<StudySet> getTodayDeadlines(List<StudySet> studySets) {
    return studySets.where((set) => set.isDeadlineToday).toList();
  }

  /// Get study sets that have deadlines tomorrow
  List<StudySet> getTomorrowDeadlines(List<StudySet> studySets) {
    return studySets.where((set) => set.isDeadlineTomorrow).toList();
  }

  /// Get overdue study sets
  List<StudySet> getOverdueStudySets(List<StudySet> studySets) {
    return studySets.where((set) => set.isOverdue).toList();
  }

  /// Get upcoming deadlines (within next 7 days)
  List<StudySet> getUpcomingDeadlines(List<StudySet> studySets) {
    return studySets.where((set) {
      if (!set.hasDeadline) return false;
      final daysUntil = set.daysUntilDeadline!;
      return daysUntil >= 0 && daysUntil <= 7;
    }).toList()
      ..sort((a, b) => a.deadlineDate!.compareTo(b.deadlineDate!));
  }

  /// Sort study sets by deadline priority (overdue first, then by date)
  List<StudySet> sortByDeadlinePriority(List<StudySet> studySets) {
    return studySets.toList()
      ..sort((a, b) {
        // Sets without deadlines go to the end
        if (!a.hasDeadline && !b.hasDeadline) return 0;
        if (!a.hasDeadline) return 1;
        if (!b.hasDeadline) return -1;

        // Overdue sets first
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;

        // Then sort by deadline date
        return a.deadlineDate!.compareTo(b.deadlineDate!);
      });
  }

  /// Update deadline for an existing study set
  Future<void> updateDeadline(StudySet studySet, DateTime? newDeadline) async {
    debugPrint('📅 Updating deadline for study set: ${studySet.id}');
    debugPrint('📅 New deadline: $newDeadline');
    
    // Cancel existing notifications
    await cancelDeadlineNotifications(studySet.id);

    // Create updated study set
    final updatedSet = studySet.copyWith(deadlineDate: newDeadline);

    // Schedule new notifications if deadline is set
    if (newDeadline != null) {
      await scheduleDeadlineNotifications(updatedSet);
      debugPrint('✅ Deadline updated and notifications scheduled for study set: ${studySet.id}');
    } else {
      debugPrint('✅ Deadline removed for study set: ${studySet.id}');
    }
  }

  /// Get deadline status message for a study set
  String getDeadlineStatusMessage(StudySet studySet) {
    if (!studySet.hasDeadline) return 'No deadline set';

    final now = DateTime.now();
    final deadline = studySet.deadlineDate!;
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final daysPast = difference.inDays.abs();
      return 'Overdue by $daysPast day${daysPast == 1 ? '' : 's'}';
    } else if (difference.inDays == 0) {
      final hoursLeft = difference.inHours;
      if (hoursLeft == 0) {
        final minutesLeft = difference.inMinutes;
        return 'Due in $minutesLeft minute${minutesLeft == 1 ? '' : 's'}';
      }
      return 'Due in $hoursLeft hour${hoursLeft == 1 ? '' : 's'}';
    } else {
      return 'Due in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    }
  }

  /// Check if any deadlines are approaching and send summary notification
  Future<void> checkDeadlineReminders(List<StudySet> studySets) async {
    final todayDeadlines = getTodayDeadlines(studySets);
    final tomorrowDeadlines = getTomorrowDeadlines(studySets);
    final overdueStudySets = getOverdueStudySets(studySets);

    // Send daily summary if there are important deadlines
    if (todayDeadlines.isNotEmpty ||
        tomorrowDeadlines.isNotEmpty ||
        overdueStudySets.isNotEmpty) {
      String message = '';

      if (overdueStudySets.isNotEmpty) {
        final count = overdueStudySets.length;
        message += '🚨 $count overdue study set${count > 1 ? 's' : ''}. ';
      }

      if (todayDeadlines.isNotEmpty) {
        final count = todayDeadlines.length;
        message += '📅 $count deadline${count > 1 ? 's' : ''} today. ';
      }

      if (tomorrowDeadlines.isNotEmpty) {
        final count = tomorrowDeadlines.length;
        message += '⏰ $count deadline${count > 1 ? 's' : ''} tomorrow. ';
      }

      message += 'Open Mindload to stay on track!';

      try {
        await MindLoadNotificationService.scheduleAt(
          DateTime.now().add(const Duration(seconds: 1)),
          'Deadline Summary',
          message.trim(),
          payload: 'deadline_summary',
        );
        debugPrint('✅ Deadline summary notification scheduled');
      } catch (e) {
        debugPrint('❌ Failed to schedule deadline summary notification: $e');
      }
    }
  }

  /// Get the number of scheduled notifications for a study set
  int getScheduledNotificationCount(String studySetId) {
    return _scheduledNotificationIds[studySetId]?.length ?? 0;
  }

  /// Get all scheduled notification IDs for debugging
  Map<String, List<int>> getAllScheduledNotifications() {
    return Map.from(_scheduledNotificationIds);
  }
}
