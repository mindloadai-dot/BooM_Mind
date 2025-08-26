import 'dart:async';
import 'package:flutter/foundation.dart';

/// **NOTIFICATION EVENT BUS**
/// 
/// This service breaks circular dependencies by allowing services to emit
/// notification events without directly depending on the notification service.
/// The notification service listens to these events and handles them appropriately.
class NotificationEventBus {
  static final NotificationEventBus _instance = NotificationEventBus._();
  static NotificationEventBus get instance => _instance;
  NotificationEventBus._();

  final StreamController<NotificationEvent> _controller = 
      StreamController<NotificationEvent>.broadcast();

  Stream<NotificationEvent> get stream => _controller.stream;

  /// Emit a notification event
  void emit(NotificationEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
      debugPrint('🔔 Notification event emitted: ${event.type}');
    }
  }

  /// Emit achievement unlocked event
  void emitAchievementUnlocked({
    required String achievementId,
    required String achievementTitle,
    required String category,
    required String tier,
  }) {
    emit(NotificationEvent(
      type: 'achievement_unlocked',
      data: {
        'achievementId': achievementId,
        'achievementTitle': achievementTitle,
        'category': category,
        'tier': tier,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Emit deadline reminder event
  void emitDeadlineReminder({
    required String studySetId,
    required String title,
    required DateTime deadline,
    required int daysUntil,
    required String urgency,
  }) {
    emit(NotificationEvent(
      type: 'deadline_reminder',
      data: {
        'studySetId': studySetId,
        'title': title,
        'deadline': deadline.toIso8601String(),
        'daysUntil': daysUntil,
        'urgency': urgency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Emit study session completed event
  void emitStudySessionCompleted({
    required String studySetId,
    required Duration duration,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
  }) {
    emit(NotificationEvent(
      type: 'study_session_completed',
      data: {
        'studySetId': studySetId,
        'duration': duration.inMinutes,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'xpEarned': xpEarned,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Emit streak milestone event
  void emitStreakMilestone({
    required int streakDays,
    required String milestone,
  }) {
    emit(NotificationEvent(
      type: 'streak_milestone',
      data: {
        'streakDays': streakDays,
        'milestone': milestone,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Emit exam countdown event
  void emitExamCountdown({
    required String course,
    required DateTime examDate,
    required int hoursUntil,
    required String urgency,
  }) {
    emit(NotificationEvent(
      type: 'exam_countdown',
      data: {
        'course': course,
        'examDate': examDate.toIso8601String(),
        'hoursUntil': hoursUntil,
        'urgency': urgency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Dispose the event bus
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
      debugPrint('🧹 Notification event bus disposed');
    }
  }
}

/// **NOTIFICATION EVENT MODEL**
class NotificationEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NotificationEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'NotificationEvent(type: $type, data: $data, timestamp: $timestamp)';
}
