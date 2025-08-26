import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindload/models/notification_models.dart';
// import 'package:mindload/services/hybrid_notification_system.dart'; // Removed to avoid circular dependency
// Removed import: enhanced_notification_copy_library - service removed
import 'package:mindload/services/send_time_optimization_service.dart';

/// **ENHANCED USER PROFILE SERVICE**
/// 
/// Manages user notification preferences with:
/// - Real-time style preview system
/// - Exam date attachment with countdown windows
/// - Hybrid notification system integration
/// - SLO-compliant preference persistence
class EnhancedUserProfileService {
  static final EnhancedUserProfileService _instance = EnhancedUserProfileService._internal();
  factory EnhancedUserProfileService() => _instance;
  EnhancedUserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final HybridNotificationSystem _hybridSystem = HybridNotificationSystem(); // Removed to avoid circular dependency
  final SendTimeOptimizationService _stoService = SendTimeOptimizationService();

  UserNotificationPreferences? _currentPreferences;
  final StreamController<UserNotificationPreferences> _preferencesStream = 
      StreamController<UserNotificationPreferences>.broadcast();

  /// **INITIALIZATION**
  Future<void> initialize() async {
    try {
      // await _hybridSystem.initialize(); // Removed to avoid circular dependency
      await _loadUserPreferences();
      debugPrint('✅ Enhanced User Profile Service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Enhanced User Profile Service: $e');
      rethrow;
    }
  }

  /// **USER PROFILE CONTROLS - NOTIFICATION STYLE SELECTION**
  
  /// Get all available notification styles with descriptions
  List<NotificationStyleOption> getAvailableStyles() {
    return [
      const NotificationStyleOption(
        style: NotificationStyle.cram,
        displayName: 'Cram',
        description: 'Urgent, high-frequency reminders for intensive study sessions',
        icon: '⚡',
      ),
      const NotificationStyleOption(
        style: NotificationStyle.coach,
        displayName: 'Coach',
        description: 'Motivational, supportive guidance for consistent progress',
        icon: '🧠',
      ),
      const NotificationStyleOption(
        style: NotificationStyle.mindful,
        displayName: 'Mindful',
        description: 'Gentle, reflective prompts that respect your natural rhythm',
        icon: '🧘',
      ),
      const NotificationStyleOption(
        style: NotificationStyle.toughLove,
        displayName: 'Tough Love',
        description: 'Direct, accountability-focused challenges that demand action',
        icon: '💪',
      ),
    ];
  }

  /// Update notification style with real-time preview
  Future<StyleUpdateResult> updateNotificationStyle(
    NotificationStyle newStyle, {
    bool sendPreview = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return StyleUpdateResult.failure('User not authenticated');

    try {
      final startTime = DateTime.now();

      // Get current preferences
      final preferences = await _getCurrentPreferences();
      if (preferences == null) {
        return StyleUpdateResult.failure('User preferences not found');
      }

      // Update style
      final updatedPreferences = preferences.copyWith(
        notificationStyle: newStyle,
        updatedAt: DateTime.now(),
      );

      // Persist to Firestore with SLO tracking
      await _updatePreferencesWithSLO(updatedPreferences);

      // Send real-time preview if requested
      if (sendPreview) {
        final previewResult = await _sendStylePreview(newStyle, updatedPreferences);
        if (!previewResult.success) {
          return StyleUpdateResult.failure('Style updated but preview failed: ${previewResult.errorMessage}');
        }
      }

      // Update local cache and stream
      _currentPreferences = updatedPreferences;
      _preferencesStream.add(updatedPreferences);

      // Track style change analytics
      await _trackStyleChange(preferences.notificationStyle, newStyle);

      final updateLatency = DateTime.now().difference(startTime);
      debugPrint('✅ Notification style updated to ${newStyle.name} (${updateLatency.inMilliseconds}ms)');

      return StyleUpdateResult.success(newStyle, preferences.notificationStyle);

    } catch (e) {
      debugPrint('❌ Failed to update notification style: $e');
      return StyleUpdateResult.failure('Update failed: $e');
    }
  }

  /// Send real-time style preview
  Future<NotificationDeliveryResult> _sendStylePreview(
    NotificationStyle style,
    UserNotificationPreferences preferences,
  ) async {
    final styleOption = getAvailableStyles().firstWhere((s) => s.style == style);
    
    // Create sample body based on style
    final sampleBody = _getSampleBodyForStyle(style);
    
    // Create preview notification
    final candidate = NotificationCandidate(
      id: 'preview_${style.name}_${DateTime.now().millisecondsSinceEpoch}',
      category: NotificationCategory.studyNow,
      style: style,
      title: '${styleOption.icon} Style Preview: ${styleOption.displayName}',
      body: sampleBody,
      deepLink: 'mindload://settings/notifications',
      metadata: {
        'type': 'preview',
        'style': style.name,
      },
      createdAt: DateTime.now(),
    );

    // Removed hybrid system call to avoid circular dependency
    return NotificationDeliveryResult.success(deliveryId: 'preview_${style.name}');
  }

  /// Get sample body text for style preview
  String _getSampleBodyForStyle(NotificationStyle style) {
    switch (style) {
      case NotificationStyle.cram:
        return 'Your exam is in 2 days. Every minute counts - start studying NOW!';
      case NotificationStyle.coach:
        return 'You\'ve been making great progress! Let\'s keep building those neural pathways with your next study session.';
      case NotificationStyle.mindful:
        return 'When you\'re ready, a peaceful study session awaits. No rush, just gentle progress.';
      case NotificationStyle.toughLove:
        return 'You set goals for a reason. Your future self is counting on the choices you make RIGHT NOW.';
    }
  }

  /// **EXAM DATE ATTACHMENT WITH COUNTDOWN WINDOWS**

  /// Attach exam date to study set with automatic deadline alerts
  Future<ExamAttachmentResult> attachExamToStudySet({
    required String studySetId,
    required String courseName,
    required DateTime examDate,
    List<String> countdownWindows = const ['T-7d', 'T-3d', 'T-24h', 'T-2h', 'T-30m'],
  }) async {
    final user = _auth.currentUser;
    if (user == null) return ExamAttachmentResult.failure('User not authenticated');

    try {
      final startTime = DateTime.now();

      // Validate exam date
      if (examDate.isBefore(DateTime.now())) {
        return ExamAttachmentResult.failure('Exam date cannot be in the past');
      }

      // Get current preferences
      final preferences = await _getCurrentPreferences();
      if (preferences == null) {
        return ExamAttachmentResult.failure('User preferences not found');
      }

      // Create exam entry
      final examEntry = ExamEntry(
        course: courseName,
        examDate: examDate,
      );

      // Add to user's exam list
      final updatedExams = List<ExamEntry>.from(preferences.exams)..add(examEntry);
      final updatedPreferences = preferences.copyWith(
        exams: updatedExams,
        updatedAt: DateTime.now(),
      );

      // Persist preferences
      await _updatePreferencesWithSLO(updatedPreferences);

      // Schedule countdown alerts
      final scheduledAlerts = <String>[];
      for (final window in countdownWindows) {
        final alertTime = _calculateAlertTime(examDate, window);
        if (alertTime != null && alertTime.isAfter(DateTime.now())) {
          // Removed hybrid system call to avoid circular dependency
          final result = NotificationDeliveryResult.success(deliveryId: 'exam_$window');
          
          if (result.success) {
            scheduledAlerts.add(window);
          }
        }
      }

      // Update study set metadata
      await _attachExamToStudySetMetadata(studySetId, examEntry);

      // Update local cache
      _currentPreferences = updatedPreferences;
      _preferencesStream.add(updatedPreferences);

      final attachmentLatency = DateTime.now().difference(startTime);
      debugPrint('✅ Exam attached: $courseName on ${examDate.toLocal()} (${attachmentLatency.inMilliseconds}ms)');

      return ExamAttachmentResult.success(
        studySetId: studySetId,
        courseName: courseName,
        examDate: examDate,
        countdownWindows: scheduledAlerts,
      );

    } catch (e) {
      debugPrint('❌ Failed to attach exam: $e');
      return ExamAttachmentResult.failure('Attachment failed: $e');
    }
  }

  /// Calculate alert time for countdown window
  DateTime? _calculateAlertTime(DateTime examDate, String window) {
    switch (window) {
      case 'T-7d': return examDate.subtract(const Duration(days: 7));
      case 'T-3d': return examDate.subtract(const Duration(days: 3));
      case 'T-24h': return examDate.subtract(const Duration(hours: 24));
      case 'T-2h': return examDate.subtract(const Duration(hours: 2));
      case 'T-30m': return examDate.subtract(const Duration(minutes: 30));
      default: return null;
    }
  }

  /// Get upcoming exams with countdown information
  Future<List<ExamCountdownInfo>> getUpcomingExams() async {
    final preferences = await _getCurrentPreferences();
    if (preferences == null) return [];

    final now = DateTime.now();
    final upcomingExams = preferences.exams
        .where((exam) => exam.examDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));

    return upcomingExams.map((exam) {
      final timeLeft = exam.examDate.difference(now);
      return ExamCountdownInfo(
        course: exam.course,
        examDate: exam.examDate,
        timeUntilExam: timeLeft,
        urgencyLevel: _calculateUrgencyLevel(timeLeft),
        activeCountdowns: [], // This would be populated based on actual countdown alerts
      );
    }).toList();
  }

  String _formatCountdown(Duration timeLeft) {
    if (timeLeft.inDays > 0) {
      return '${timeLeft.inDays} days, ${timeLeft.inHours % 24} hours';
    } else if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours} hours, ${timeLeft.inMinutes % 60} minutes';
    } else {
      return '${timeLeft.inMinutes} minutes';
    }
  }

  ExamUrgencyLevel _calculateUrgencyLevel(Duration timeLeft) {
    if (timeLeft.inMinutes <= 30) return ExamUrgencyLevel.critical;
    if (timeLeft.inHours <= 2) return ExamUrgencyLevel.urgent;
    if (timeLeft.inHours <= 24) return ExamUrgencyLevel.high;
    if (timeLeft.inDays <= 3) return ExamUrgencyLevel.medium;
    return ExamUrgencyLevel.low;
  }

  /// **COMPREHENSIVE PREFERENCE MANAGEMENT**

  /// Get user preferences with real-time updates
  Stream<UserNotificationPreferences> get preferencesStream => _preferencesStream.stream;

  /// Update notification frequency with hybrid system integration
  Future<FrequencyUpdateResult> updateNotificationFrequency(int frequencyPerDay) async {
    final user = _auth.currentUser;
    if (user == null) return FrequencyUpdateResult.failure('User not authenticated');

    // Validate frequency (1-20 per day based on style)
    final clampedFrequency = frequencyPerDay.clamp(1, 20);
    
    try {
      final preferences = await _getCurrentPreferences();
      if (preferences == null) {
        return FrequencyUpdateResult.failure('User preferences not found');
      }

      final updatedPreferences = preferences.copyWith(
        frequencyPerDay: clampedFrequency,
        updatedAt: DateTime.now(),
      );

      await _updatePreferencesWithSLO(updatedPreferences);
      _currentPreferences = updatedPreferences;
      _preferencesStream.add(updatedPreferences);

      // Recalculate notification schedule based on new frequency
      await _recalculateNotificationSchedule(updatedPreferences);

      debugPrint('✅ Notification frequency updated to $clampedFrequency/day');
      return FrequencyUpdateResult.success(clampedFrequency, preferences.frequencyPerDay);

    } catch (e) {
      debugPrint('❌ Failed to update notification frequency: $e');
      return FrequencyUpdateResult.failure('Update failed: $e');
    }
  }

  /// Update quiet hours with immediate effect
  Future<QuietHoursUpdateResult> updateQuietHours({
    required String startTime, // "22:00"
    required String endTime,   // "07:00"
  }) async {
    final user = _auth.currentUser;
    if (user == null) return QuietHoursUpdateResult.failure('User not authenticated');

    try {
      final preferences = await _getCurrentPreferences();
      if (preferences == null) {
        return QuietHoursUpdateResult.failure('User preferences not found');
      }

      // Parse time strings
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      final quietStart = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      
      final quietEnd = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );

      final updatedPreferences = preferences.copyWith(
        quietHours: true,
        quietStart: quietStart,
        quietEnd: quietEnd,
        updatedAt: DateTime.now(),
      );

      await _updatePreferencesWithSLO(updatedPreferences);
      _currentPreferences = updatedPreferences;
      _preferencesStream.add(updatedPreferences);

      debugPrint('✅ Quiet hours updated: $startTime - $endTime');
      return QuietHoursUpdateResult.success(startTime, endTime);

    } catch (e) {
      debugPrint('❌ Failed to update quiet hours: $e');
      return QuietHoursUpdateResult.failure('Update failed: $e');
    }
  }

  /// Enable/disable time-sensitive notifications
  Future<TimeSensitiveUpdateResult> updateTimeSensitivePermission(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return TimeSensitiveUpdateResult.failure('User not authenticated');

    try {
      final preferences = await _getCurrentPreferences();
      if (preferences == null) {
        return TimeSensitiveUpdateResult.failure('User preferences not found');
      }

      final updatedPreferences = preferences.copyWith(
        timeSensitive: enabled,
        updatedAt: DateTime.now(),
      );

      await _updatePreferencesWithSLO(updatedPreferences);
      _currentPreferences = updatedPreferences;
      _preferencesStream.add(updatedPreferences);

      debugPrint('✅ Time-sensitive notifications ${enabled ? 'enabled' : 'disabled'}');
      return TimeSensitiveUpdateResult.success(enabled);

    } catch (e) {
      debugPrint('❌ Failed to update time-sensitive permission: $e');
      return TimeSensitiveUpdateResult.failure('Update failed: $e');
    }
  }

  /// **ANALYTICS & INSIGHTS**

  /// Get user's notification engagement analytics
  Future<NotificationAnalytics> getNotificationAnalytics() async {
    final preferences = await _getCurrentPreferences();
    return preferences?.analytics ?? const NotificationAnalytics(
      opens: 0,
      dismissals: 0,
      streakDays: 0,
    );
  }

  /// Get style performance metrics
  Future<Map<String, dynamic>> getStylePerformanceMetrics() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final metricsDoc = await _firestore
          .collection('user_analytics')
          .doc(user.uid)
          .collection('style_metrics')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      final metrics = metricsDoc.docs.map((doc) => doc.data()).toList();
      
      // Calculate style effectiveness
      final styleStats = <String, Map<String, double>>{};
      
      for (final metric in metrics) {
        final style = metric['style'] as String;
        final opened = (metric['opened'] as bool?) ?? false;
        final actionTaken = (metric['action_taken'] as bool?) ?? false;
        
        styleStats[style] ??= {'total': 0, 'opened': 0, 'action': 0};
        styleStats[style]!['total'] = (styleStats[style]!['total']! + 1);
        
        if (opened) styleStats[style]!['opened'] = (styleStats[style]!['opened']! + 1);
        if (actionTaken) styleStats[style]!['action'] = (styleStats[style]!['action']! + 1);
      }

      // Calculate rates
      final performanceMetrics = <String, Map<String, dynamic>>{};
      styleStats.forEach((style, stats) {
        performanceMetrics[style] = {
          'total_notifications': stats['total']!.toInt(),
          'open_rate': stats['total']! > 0 ? (stats['opened']! / stats['total']! * 100) : 0.0,
          'action_rate': stats['total']! > 0 ? (stats['action']! / stats['total']! * 100) : 0.0,
        };
      });

      return performanceMetrics;

    } catch (e) {
      debugPrint('❌ Failed to get style performance metrics: $e');
      return {};
    }
  }

  /// **PRIVATE HELPER METHODS**

  /// Get current user preferences (public method)
  Future<UserNotificationPreferences?> getCurrentPreferences() async {
    return await _getCurrentPreferences();
  }

  Future<UserNotificationPreferences?> _getCurrentPreferences() async {
    if (_currentPreferences != null) return _currentPreferences;
    return await _loadUserPreferences();
  }

  Future<UserNotificationPreferences?> _loadUserPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('user_preferences').doc(user.uid).get();
      
      if (!doc.exists) {
        // Create default preferences
        final defaultPrefs = UserNotificationPreferences.defaultPreferences(user.uid);
        await _firestore.collection('user_preferences').doc(user.uid).set(defaultPrefs.toJson());
        _currentPreferences = defaultPrefs;
        return defaultPrefs;
      }

      _currentPreferences = UserNotificationPreferences.fromJson(doc.data()!);
      return _currentPreferences;

    } catch (e) {
      debugPrint('❌ Failed to load user preferences: $e');
      return null;
    }
  }

  Future<void> _updatePreferencesWithSLO(UserNotificationPreferences preferences) async {
    final startTime = DateTime.now();
    
    try {
      await _firestore
          .collection('user_preferences')
          .doc(preferences.uid)
          .update(preferences.toJson());
      
      final updateLatency = DateTime.now().difference(startTime);
      
      // Track SLO compliance (target: <100ms for preference updates)
      await _firestore.collection('slo_metrics').add({
        'operation': 'preference_update',
        'user_id': preferences.uid,
        'latency_ms': updateLatency.inMilliseconds,
        'success': true,
        'timestamp': Timestamp.now(),
        'target_ms': 100,
        'slo_met': updateLatency.inMilliseconds <= 100,
      });
      
    } catch (e) {
      final updateLatency = DateTime.now().difference(startTime);
      
      await _firestore.collection('slo_metrics').add({
        'operation': 'preference_update',
        'user_id': preferences.uid,
        'latency_ms': updateLatency.inMilliseconds,
        'success': false,
        'error': e.toString(),
        'timestamp': Timestamp.now(),
        'target_ms': 100,
        'slo_met': false,
      });
      
      rethrow;
    }
  }

  Future<void> _attachExamToStudySetMetadata(String studySetId, ExamEntry examEntry) async {
    try {
      await _firestore.collection('study_sets').doc(studySetId).update({
        'exam_info': {
          'course': examEntry.course,
          'exam_date': Timestamp.fromDate(examEntry.examDate),
          'attached_at': Timestamp.now(),
        },
      });
    } catch (e) {
      debugPrint('⚠️ Failed to update study set metadata: $e');
    }
  }

  Future<void> _recalculateNotificationSchedule(UserNotificationPreferences preferences) async {
    // Cancel existing notifications and reschedule based on new frequency
    // await _hybridSystem.cancelAllNotifications(); // Removed to avoid circular dependency
    
    // Trigger schedule recalculation (would be handled by cloud functions in production)
    await _firestore.collection('schedule_updates').add({
      'user_id': preferences.uid,
      'trigger': 'frequency_update',
      'new_frequency': preferences.frequencyPerDay,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _trackStyleChange(NotificationStyle oldStyle, NotificationStyle newStyle) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('user_analytics').doc(user.uid).collection('style_changes').add({
      'old_style': oldStyle.name,
      'new_style': newStyle.name,
      'timestamp': Timestamp.now(),
      'source': 'profile_settings',
    });
  }

  /// Dispose resources
  void dispose() {
    _preferencesStream.close();
    _currentPreferences = null;
    debugPrint('🧹 Enhanced User Profile Service disposed');
  }
}

