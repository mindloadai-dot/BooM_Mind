import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/notification_service.dart';

class DeadlineService {
  static final DeadlineService _instance = DeadlineService._();
  static DeadlineService get instance => _instance;
  DeadlineService._();

  /// Schedule all deadline notifications for a study set
  Future<void> scheduleDeadlineNotifications(StudySet studySet) async {
    if (!studySet.hasDeadline) return;

    final deadline = studySet.deadlineDate!;
    final now = DateTime.now();
    final studySetId = studySet.id;
    final title = studySet.title;

    // Cancel any existing notifications for this study set
    await cancelDeadlineNotifications(studySetId);

    // Schedule notifications at different intervals before the deadline
    final notificationSchedule = <Duration, String>{
      const Duration(days: 7): '📅 Deadline Alert: One week left to study "$title"',
      const Duration(days: 3): '⏰ Deadline Reminder: 3 days left for "$title" - Time to review!',
      const Duration(days: 1): '🚨 Final Notice: "$title" deadline is tomorrow!',
      const Duration(hours: 2): '⚡ Last Call: "$title" deadline in 2 hours - Final review time!',
    };
    
    for (final entry in notificationSchedule.entries) {
      final notificationTime = deadline.subtract(entry.key);
      
      // Only schedule if the notification time is in the future
      if (notificationTime.isAfter(now)) {
        await NotificationService.scheduleStudyReminder(
          studySetId: '${studySetId}_deadline_${entry.key.inHours}h',
          title: 'Study Deadline Approaching',
          body: entry.value,
          scheduledTime: notificationTime,
        );
      }
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
      motivationMessage = 'Great! You have $daysUntilDeadline days to master "$title". Start strong! 💪';
    } else if (daysUntilDeadline > 1) {
      motivationMessage = 'Perfect timing! $daysUntilDeadline days to excel at "$title". Let\'s do this! 🚀';
    } else if (daysUntilDeadline == 1) {
      motivationMessage = 'One day to shine with "$title"! Intensive study mode activated! ⚡';
    } else if (daysUntilDeadline == 0) {
      motivationMessage = 'Deadline today for "$title"! Every minute counts - you\'ve got this! 🎯';
    } else {
      // Overdue
      final daysPast = -daysUntilDeadline;
      motivationMessage = '"$title" deadline passed $daysPast days ago. Time for focused catch-up! 🔥';
    }
    
    await NotificationService.scheduleStudyReminder(
      studySetId: '${studySet.id}_motivation',
      title: '🎯 Study Plan Update',
      body: motivationMessage,
      scheduledTime: DateTime.now().add(const Duration(seconds: 3)),
    );
  }

  /// Cancel all deadline notifications for a specific study set
  Future<void> cancelDeadlineNotifications(String studySetId) async {
    // In a real implementation, this would cancel specific notifications
    // For now, we'll use a simple approach
    debugPrint('📅 Canceling deadline notifications for study set: $studySetId');
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
    }).toList()..sort((a, b) => a.deadlineDate!.compareTo(b.deadlineDate!));
  }

  /// Sort study sets by deadline priority (overdue first, then by date)
  List<StudySet> sortByDeadlinePriority(List<StudySet> studySets) {
    return studySets.toList()..sort((a, b) {
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
    // Cancel existing notifications
    await cancelDeadlineNotifications(studySet.id);
    
    // Create updated study set
    final updatedSet = studySet.copyWith(deadlineDate: newDeadline);
    
    // Schedule new notifications if deadline is set
    if (newDeadline != null) {
      await scheduleDeadlineNotifications(updatedSet);
    }
  }

  /// Get deadline status message for a study set
  String getDeadlineStatusMessage(StudySet studySet) {
    if (!studySet.hasDeadline) return 'No deadline set';
    
    if (studySet.isOverdue) {
      final daysPast = DateTime.now().difference(studySet.deadlineDate!).inDays;
      return daysPast == 0 
        ? 'Deadline was today' 
        : daysPast == 1 
          ? 'Overdue by 1 day' 
          : 'Overdue by $daysPast days';
    }
    
    if (studySet.isDeadlineToday) return 'Due today';
    if (studySet.isDeadlineTomorrow) return 'Due tomorrow';
    
    final daysUntil = studySet.daysUntilDeadline!;
    if (daysUntil <= 7) {
      return daysUntil == 1 ? 'Due in 1 day' : 'Due in $daysUntil days';
    }
    
    if (daysUntil <= 30) {
      final weeks = (daysUntil / 7).ceil();
      return weeks == 1 ? 'Due in 1 week' : 'Due in $weeks weeks';
    }
    
    final months = (daysUntil / 30).ceil();
    return months == 1 ? 'Due in 1 month' : 'Due in $months months';
  }

  /// Check if any deadlines are approaching and send summary notification
  Future<void> checkDeadlineReminders(List<StudySet> studySets) async {
    final todayDeadlines = getTodayDeadlines(studySets);
    final tomorrowDeadlines = getTomorrowDeadlines(studySets);
    final overdueStudySets = getOverdueStudySets(studySets);
    
    // Send daily summary if there are important deadlines
    if (todayDeadlines.isNotEmpty || tomorrowDeadlines.isNotEmpty || overdueStudySets.isNotEmpty) {
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
      
      await NotificationService.scheduleStudyReminder(
        studySetId: 'deadline_summary_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Deadline Summary',
        body: message.trim(),
        scheduledTime: DateTime.now().add(const Duration(seconds: 1)),
      );
    }
  }
}