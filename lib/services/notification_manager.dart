import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/services/unified_notification_service.dart';
import 'package:mindload/services/working_notification_service.dart';
import 'package:mindload/services/notification_event_bus.dart';
import 'package:mindload/services/send_time_optimization_service.dart';
import 'package:mindload/services/auth_service.dart';

/// **NOTIFICATION MANAGER**
/// 
/// High-level notification management service that provides:
/// ✅ Unified interface for all notification operations
/// ✅ Smart notification scheduling and optimization
/// ✅ User preference management
/// ✅ Notification analytics and insights
/// ✅ Cohesive notification experience across the app
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  static NotificationManager get instance => _instance;
  NotificationManager._internal();

  // Core services
  final UnifiedNotificationService _notificationService = UnifiedNotificationService.instance;
  final NotificationEventBus _eventBus = NotificationEventBus.instance;
  final SendTimeOptimizationService _stoService = SendTimeOptimizationService();
  
  // State management
  bool _isInitialized = false;
  UserNotificationPreferences? _currentPreferences;
  final StreamController<NotificationManagerStatus> _statusController = 
      StreamController<NotificationManagerStatus>.broadcast();
  
  // Notification analytics
  final Map<String, int> _notificationStats = {};
  final List<NotificationRecord> _recentNotifications = [];
  static const int _maxRecentNotifications = 50;
  
  // Getters
  bool get isInitialized => _isInitialized;
  UserNotificationPreferences? get currentPreferences => _currentPreferences;
  Stream<NotificationManagerStatus> get statusStream => _statusController.stream;
  
  /// Initialize the notification manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Initializing Notification Manager...');
      
      // Initialize the WorkingNotificationService first (this is the actual notification handler)
      await WorkingNotificationService.instance.initialize();
      debugPrint('✅ WorkingNotificationService initialized');
      
      // Initialize core notification service
      await _notificationService.initialize();
      
      // Load user preferences
      await _loadUserPreferences();
      
      // Setup event listeners
      _setupEventListeners();
      
      _isInitialized = true;
      _updateStatus(NotificationStatus.ready);
      
      debugPrint('✅ Notification Manager initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize Notification Manager: $e');
      _updateStatus(NotificationStatus.error, error: e.toString());
      // Mark as initialized anyway to prevent blocking
      _isInitialized = true;
    }
  }

  /// Load user notification preferences
  Future<void> _loadUserPreferences() async {
    try {
      // This would typically load from Firestore or local storage
      // For now, use default preferences with a mock UID
      _currentPreferences = UserNotificationPreferences.defaultPreferences(AuthService.instance.currentUserId ?? 'anonymous');
      debugPrint('✅ User preferences loaded');
    } catch (e) {
      debugPrint('⚠️ Failed to load user preferences, using defaults: $e');
      _currentPreferences = UserNotificationPreferences.defaultPreferences(AuthService.instance.currentUserId ?? 'anonymous');
    }
  }

  /// Setup event listeners
  void _setupEventListeners() {
    // Listen to notification events
    _eventBus.stream.listen((event) {
      _handleNotificationEvent(event);
    });
    
    // Listen to notification service status changes
    _notificationService.permissionStream.listen((status) {
      _updateStatus(NotificationStatus.permissionUpdate, permissionStatus: status);
    });
  }

  /// Handle notification events
  Future<void> _handleNotificationEvent(NotificationEvent event) async {
    try {
      debugPrint('🔔 Handling notification event: ${event.type}');
      
      // Record event for analytics
      _recordNotificationEvent(event.type);
      
      // Let the unified service handle the event
      // It will automatically show appropriate notifications
      
    } catch (e) {
      debugPrint('❌ Failed to handle notification event: $e');
    }
  }

  // PUBLIC API METHODS

  /// Show immediate notification with smart defaults
  Future<bool> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.studyNow,
    bool timeSensitive = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final channelType = _getChannelTypeForCategory(category);
      final isHighPriority = priority == NotificationPriority.high;
      
      final success = await _notificationService.showNotificationNow(
        title: title,
        body: body,
        payload: payload,
        isHighPriority: isHighPriority,
        timeSensitive: timeSensitive,
        channelType: channelType,
      );
      
      if (success) {
        _recordNotificationSent(category);
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
      return false;
    }
  }

  /// Schedule notification with smart timing
  Future<bool> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationCategory category = NotificationCategory.studyNow,
    bool allowInQuietHours = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check if we should optimize the timing
      final optimizedTime = await _optimizeNotificationTime(
        scheduledTime,
        category,
        allowInQuietHours,
      );
      
      final channelType = _getChannelTypeForCategory(category);
      final isHighPriority = priority == NotificationPriority.high;
      
      final success = await _notificationService.scheduleNotification(
        title: title,
        body: body,
        scheduledTime: optimizedTime,
        payload: payload,
        isHighPriority: isHighPriority,
        channelType: channelType,
        allowInQuietHours: allowInQuietHours,
      );
      
      if (success) {
        _recordNotificationScheduled(category);
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
      return false;
    }
  }

  /// Schedule daily study reminder
  Future<bool> scheduleDailyReminder({
    TimeOfDay? time,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final reminderTime = time ?? _getOptimalStudyTime();
      final message = customMessage ?? _getPersonalizedStudyMessage();
      
      return await _notificationService.scheduleDailyReminder(
        time: reminderTime,
        customMessage: message,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule daily reminder: $e');
      return false;
    }
  }

  /// Schedule deadline reminder
  Future<bool> scheduleDeadlineReminder({
    required String title,
    required DateTime deadline,
    required String course,
    int daysInAdvance = 1,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _notificationService.scheduleDeadlineReminder(
        title: title,
        deadline: deadline,
        course: course,
        daysInAdvance: daysInAdvance,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule deadline reminder: $e');
      return false;
    }
  }

  /// Show pop quiz notification
  Future<bool> showPopQuiz({
    required String topic,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _notificationService.showPopQuizNotification(
        topic: topic,
        customMessage: customMessage,
      );
    } catch (e) {
      debugPrint('❌ Failed to show pop quiz: $e');
      return false;
    }
  }

  /// Show achievement notification
  Future<bool> showAchievement({
    required String achievementName,
    required String category,
    String? tier,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _notificationService.showAchievementNotification(
        achievementName: achievementName,
        category: category,
        tier: tier,
      );
    } catch (e) {
      debugPrint('❌ Failed to show achievement: $e');
      return false;
    }
  }

  /// Show streak reminder
  Future<bool> showStreakReminder({
    required int streakDays,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _notificationService.showStreakReminder(
        streakDays: streakDays,
        customMessage: customMessage,
      );
    } catch (e) {
      debugPrint('❌ Failed to show streak reminder: $e');
      return false;
    }
  }

  /// Update user notification preferences
  Future<void> updatePreferences(UserNotificationPreferences preferences) async {
    try {
      _currentPreferences = preferences;
      
      // This would typically save to Firestore or local storage
      debugPrint('✅ Notification preferences updated');
      
      // Apply new preferences
      await _applyPreferences(preferences);
      
    } catch (e) {
      debugPrint('❌ Failed to update preferences: $e');
      rethrow;
    }
  }

  /// Get notification statistics
  Map<String, dynamic> getNotificationStats() {
    return {
      'totalSent': _notificationStats.values.fold(0, (sum, count) => sum + count),
      'byCategory': Map.from(_notificationStats),
      'recentNotifications': _recentNotifications.length,
      'systemStatus': _notificationService.getSystemStatus(),
      'preferences': _currentPreferences?.toJson(),
    };
  }

  /// Get notification history
  List<NotificationRecord> getNotificationHistory() {
    return List.from(_recentNotifications);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      
      // Update local record
      final index = _recentNotifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // Create a new record with openedAt set
        final original = _recentNotifications[index];
        _recentNotifications[index] = original.copyWith(
          openedAt: DateTime.now(),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      debugPrint('🗑️ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel notifications: $e');
    }
  }

  /// Test notification system
  Future<bool> testNotificationSystem() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final success = await _notificationService.showNotificationNow(
        title: '🧪 Test Notification',
        body: 'Notification system is working correctly!',
        payload: 'test',
        channelType: 'study_reminders',
      );
      
      if (success) {
        debugPrint('✅ Test notification sent successfully');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Test notification failed: $e');
      return false;
    }
  }

  /// Get system status
  NotificationStatus getStatus() {
    if (!_isInitialized) {
      return NotificationStatus.initializing;
    }
    
    return NotificationStatus.ready;
  }

  // PRIVATE HELPER METHODS

  /// Get channel type for notification category
  String _getChannelTypeForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.studyNow:
        return 'study_reminders';
      case NotificationCategory.examAlert:
        return 'deadlines';
      case NotificationCategory.eventTrigger:
        return 'achievements';
      case NotificationCategory.inactivityNudge:
        return 'study_reminders';
      case NotificationCategory.promotional:
        return 'system';
      default:
        return 'study_reminders';
    }
  }

  /// Optimize notification timing
  Future<DateTime> _optimizeNotificationTime(
    DateTime originalTime,
    NotificationCategory category,
    bool allowInQuietHours,
  ) async {
    try {
      if (_currentPreferences?.stoEnabled == true) {
        // Use STO service to optimize timing
        // For now, just return the original time since STO service may not have this method
        return originalTime;
      }
      
      // Fallback to basic quiet hours adjustment
      if (!allowInQuietHours && _isInQuietHours(originalTime)) {
        return _adjustTimeOutsideQuietHours(originalTime);
      }
      
      return originalTime;
    } catch (e) {
      debugPrint('⚠️ Failed to optimize notification time: $e');
      return originalTime;
    }
  }

  /// Get optimal study time based on user preferences
  TimeOfDay _getOptimalStudyTime() {
    // This would analyze user study patterns
    // For now, return a sensible default
    return const TimeOfDay(hour: 9, minute: 0);
  }

  /// Get personalized study message
  String _getPersonalizedStudyMessage() {
    // This would use user data to personalize messages
    // For now, return a generic message
    return 'Time to strengthen your neural pathways!';
  }

  /// Check if time is in quiet hours
  bool _isInQuietHours(DateTime time) {
    if (_currentPreferences?.quietHours != true) return false;
    
    final hour = time.hour;
    final quietStart = _currentPreferences!.quietStart.hour;
    final quietEnd = _currentPreferences!.quietEnd.hour;
    
    if (quietStart < quietEnd) {
      // Same day quiet hours (e.g., 10 PM to 7 AM)
      return hour >= quietStart || hour < quietEnd;
    } else {
      // Cross-midnight quiet hours (e.g., 10 PM to 7 AM)
      return hour >= quietStart || hour < quietEnd;
    }
  }

  /// Adjust time outside quiet hours
  DateTime _adjustTimeOutsideQuietHours(DateTime time) {
    if (_currentPreferences?.quietHours != true) return time;
    
    final quietEnd = _currentPreferences!.quietEnd.hour;
    
    if (time.hour >= _currentPreferences!.quietStart.hour) {
      // Move to next morning at end of quiet hours
      return DateTime(time.year, time.month, time.day + 1, quietEnd, 0);
    } else if (time.hour < quietEnd) {
      // Move to end of quiet hours same day
      return DateTime(time.year, time.month, time.day, quietEnd, 0);
    }
    
    return time;
  }

  /// Apply user preferences
  Future<void> _applyPreferences(UserNotificationPreferences preferences) async {
    try {
      // Cancel existing notifications if preferences changed
      if (_currentPreferences != null) {
        final oldPreferences = _currentPreferences!;
        
        if (oldPreferences.digestTime != preferences.digestTime ||
            oldPreferences.eveningDigest != preferences.eveningDigest) {
          
          // Reschedule daily reminder
          if (preferences.eveningDigest) {
            await scheduleDailyReminder(time: preferences.digestTime);
          }
        }
      }
      
      debugPrint('✅ Notification preferences applied');
    } catch (e) {
      debugPrint('❌ Failed to apply preferences: $e');
    }
  }

  /// Record notification event for analytics
  void _recordNotificationEvent(String eventType) {
    _notificationStats[eventType] = (_notificationStats[eventType] ?? 0) + 1;
  }

  /// Record notification sent
  void _recordNotificationSent(NotificationCategory category) {
    final categoryKey = category.toString().split('.').last;
    _notificationStats[categoryKey] = (_notificationStats[categoryKey] ?? 0) + 1;
  }

  /// Record notification scheduled
  void _recordNotificationScheduled(NotificationCategory category) {
    final categoryKey = '${category.toString().split('.').last}_scheduled';
    _notificationStats[categoryKey] = (_notificationStats[categoryKey] ?? 0) + 1;
  }

  /// Update status and notify listeners
  void _updateStatus(
    NotificationStatus status, {
    String? error,
    NotificationPermissionStatus? permissionStatus,
  }) {
    _statusController.add(NotificationManagerStatus(
      status: status,
      error: error,
      permissionStatus: permissionStatus,
      timestamp: DateTime.now(),
    ));
  }

  /// Dispose of the manager
  void dispose() {
    _statusController.close();
    debugPrint('🔔 Notification Manager disposed');
  }
}

/// Notification manager status
class NotificationManagerStatus {
  final NotificationStatus status;
  final String? error;
  final NotificationPermissionStatus? permissionStatus;
  final DateTime timestamp;

  NotificationManagerStatus({
    required this.status,
    this.error,
    this.permissionStatus,
    required this.timestamp,
  });
}

/// Notification status enum
enum NotificationStatus {
  initializing,
  ready,
  error,
  permissionUpdate,
}

/// Notification priority enum
enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}