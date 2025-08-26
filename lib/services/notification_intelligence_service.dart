import 'package:flutter/foundation.dart';
import 'package:mindload/models/notification_models.dart';
import 'package:mindload/services/notification_event_bus.dart';

/// **NOTIFICATION INTELLIGENCE SERVICE**
/// 
/// Analyzes user behavior patterns to optimize:
/// - Notification timing
/// - Frequency and intensity
/// - User engagement patterns
/// - Optimal study reminder schedules
class NotificationIntelligenceService {
  static final NotificationIntelligenceService _instance = NotificationIntelligenceService._();
  static NotificationIntelligenceService get instance => _instance;
  NotificationIntelligenceService._();

  /// Analyze user behavior and return optimal notification strategy
  Future<NotificationStrategy> analyzeUserBehavior(String userId) async {
    try {
      // Analyze study patterns
      final studyTimes = await _getStudyTimePreferences(userId);
      final responseRates = await _getNotificationResponseRates(userId);
      final quietHours = await _getQuietHours(userId);
      final engagementLevel = await _getUserEngagementLevel(userId);
      
      return NotificationStrategy(
        optimalTimes: studyTimes,
        frequency: _calculateOptimalFrequency(responseRates, engagementLevel),
        quietHours: quietHours,
        urgencyLevels: _determineUrgencyLevels(userId, engagementLevel),
        preferredChannels: _getPreferredChannels(userId),
        timezone: await _getUserTimezone(userId),
      );
    } catch (e) {
      debugPrint('❌ Failed to analyze user behavior: $e');
      // Return default strategy
      return NotificationStrategy.defaultStrategy();
    }
  }

  /// Get user's preferred study times based on historical data
  Future<List<DateTime>> _getStudyTimePreferences(String userId) async {
    try {
      // In a real implementation, this would analyze:
      // - When user opens the app most frequently
      // - When study sessions are completed
      // - User's timezone and local time preferences
      
      // For now, return common optimal study times
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      return [
        today.add(const Duration(hours: 7)),   // Morning study
        today.add(const Duration(hours: 10)),  // Mid-morning
        today.add(const Duration(hours: 14)),  // Afternoon
        today.add(const Duration(hours: 19)),  // Evening
        today.add(const Duration(hours: 21)),  // Night study
      ];
    } catch (e) {
      debugPrint('❌ Failed to get study time preferences: $e');
      return [];
    }
  }

  /// Get notification response rates for different types
  Future<Map<String, double>> _getNotificationResponseRates(String userId) async {
    try {
      // In a real implementation, this would analyze:
      // - How often user taps on notifications
      // - Which notification types get the best response
      // - Time-based response patterns
      
      // Return default response rates
      return {
        'achievement': 0.85,      // High engagement for achievements
        'deadline': 0.75,         // Good response to deadlines
        'study_reminder': 0.60,   // Moderate response to reminders
        'streak': 0.70,           // Good response to streak updates
        'pop_quiz': 0.45,         // Lower response to pop quizzes
      };
    } catch (e) {
      debugPrint('❌ Failed to get notification response rates: $e');
      return {};
    }
  }

  /// Get user's quiet hours preferences
  Future<QuietHours?> _getQuietHours(String userId) async {
    try {
      // In a real implementation, this would load from user preferences
      // For now, return default quiet hours (11 PM - 7 AM)
      return const QuietHours(
        start: '23:00',
        end: '07:00',
      );
    } catch (e) {
      debugPrint('❌ Failed to get quiet hours: $e');
      return null;
    }
  }

  /// Get user engagement level
  Future<UserEngagementLevel> _getUserEngagementLevel(String userId) async {
    try {
      // In a real implementation, this would analyze:
      // - App usage frequency
      // - Study session completion rates
      // - Feature adoption
      // - Retention metrics
      
      // For now, return medium engagement
      return UserEngagementLevel.medium;
    } catch (e) {
      debugPrint('❌ Failed to get user engagement level: $e');
      return UserEngagementLevel.low;
    }
  }

  /// Calculate optimal notification frequency based on user behavior
  int _calculateOptimalFrequency(Map<String, double> responseRates, UserEngagementLevel engagementLevel) {
    try {
      // Base frequency on engagement level
      int baseFrequency;
      switch (engagementLevel) {
        case UserEngagementLevel.high:
          baseFrequency = 4; // 4 notifications per day
          break;
        case UserEngagementLevel.medium:
          baseFrequency = 3; // 3 notifications per day
          break;
        case UserEngagementLevel.low:
          baseFrequency = 2; // 2 notifications per day
          break;
      }
      
      // Adjust based on response rates
      final avgResponseRate = responseRates.values.reduce((a, b) => a + b) / responseRates.length;
      if (avgResponseRate > 0.7) {
        baseFrequency = (baseFrequency * 1.2).round(); // Increase if good response
      } else if (avgResponseRate < 0.4) {
        baseFrequency = (baseFrequency * 0.8).round(); // Decrease if poor response
      }
      
      return baseFrequency.clamp(1, 6); // Between 1-6 notifications per day
    } catch (e) {
      debugPrint('❌ Failed to calculate optimal frequency: $e');
      return 3; // Default to 3 per day
    }
  }

  /// Determine urgency levels for different notification types
  Map<String, String> _determineUrgencyLevels(String userId, UserEngagementLevel engagementLevel) {
    try {
      // Base urgency levels
      final baseUrgency = {
        'achievement': 'medium',
        'deadline': 'high',
        'study_reminder': 'low',
        'streak': 'medium',
        'pop_quiz': 'low',
      };
      
      // Adjust based on engagement level
      if (engagementLevel == UserEngagementLevel.low) {
        // Increase urgency for low-engagement users
        baseUrgency['study_reminder'] = 'medium';
        baseUrgency['pop_quiz'] = 'medium';
      } else if (engagementLevel == UserEngagementLevel.high) {
        // Decrease urgency for high-engagement users (they're already engaged)
        baseUrgency['study_reminder'] = 'low';
        baseUrgency['deadline'] = 'medium';
      }
      
      return baseUrgency;
    } catch (e) {
      debugPrint('❌ Failed to determine urgency levels: $e');
      return {};
    }
  }

  /// Get user's preferred notification channels
  List<String> _getPreferredChannels(String userId) {
    try {
      // In a real implementation, this would analyze:
      // - Which channels get better response rates
      // - User's device preferences
      // - Historical engagement data
      
      // Return default channel preferences
      return ['reminders', 'deadlines', 'achievements'];
    } catch (e) {
      debugPrint('❌ Failed to get preferred channels: $e');
      return ['reminders'];
    }
  }

  /// Get user's timezone
  Future<String?> _getUserTimezone(String userId) async {
    try {
      // In a real implementation, this would load from user preferences
      // For now, return null (will use device timezone)
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get user timezone: $e');
      return null;
    }
  }

  /// Get optimal notification time for a specific type
  Future<DateTime?> getOptimalNotificationTime({
    required String notificationType,
    required String userId,
    DateTime? preferredTime,
  }) async {
    try {
      final strategy = await analyzeUserBehavior(userId);
      final optimalTimes = strategy.optimalTimes;
      
      if (optimalTimes.isEmpty) {
        return preferredTime ?? DateTime.now().add(const Duration(hours: 1));
      }
      
      // Find the best time based on notification type and user preferences
      DateTime? bestTime;
      
      switch (notificationType) {
        case 'achievement':
          // Show achievements during peak engagement times
          bestTime = _findBestTime(optimalTimes, preferredTime, 'achievement');
          break;
        case 'deadline':
          // Show deadlines early to give users time to act
          bestTime = _findBestTime(optimalTimes, preferredTime, 'deadline');
          break;
        case 'study_reminder':
          // Show study reminders during optimal study times
          bestTime = _findBestTime(optimalTimes, preferredTime, 'study_reminder');
          break;
        default:
          bestTime = _findBestTime(optimalTimes, preferredTime, 'general');
      }
      
      return bestTime;
    } catch (e) {
      debugPrint('❌ Failed to get optimal notification time: $e');
      return preferredTime ?? DateTime.now().add(const Duration(hours: 1));
    }
  }

  /// Find the best time from available options
  DateTime _findBestTime(List<DateTime> optimalTimes, DateTime? preferredTime, String type) {
    if (optimalTimes.isEmpty) {
      return preferredTime ?? DateTime.now().add(const Duration(hours: 1));
    }
    
          // If preferred time is provided, find closest optimal time
      if (preferredTime != null) {
        DateTime? closest;
        int minDifference = 9223372036854775807; // int.maxValue equivalent
      
      for (final time in optimalTimes) {
        final difference = (time.difference(preferredTime).inMinutes).abs();
        if (difference < minDifference) {
          minDifference = difference;
          closest = time;
        }
      }
      
      if (closest != null) {
        return closest;
      }
    }
    
    // Otherwise, return the next optimal time
    final now = DateTime.now();
    final futureTimes = optimalTimes.where((time) => time.isAfter(now)).toList();
    
    if (futureTimes.isNotEmpty) {
      return futureTimes.first;
    }
    
    // If no future times, return the first optimal time tomorrow
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return optimalTimes.first;
  }

  /// Emit study session completed event for analysis
  void emitStudySessionCompleted({
    required String studySetId,
    required Duration duration,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
  }) {
    NotificationEventBus.instance.emitStudySessionCompleted(
      studySetId: studySetId,
      duration: duration,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      xpEarned: xpEarned,
    );
  }

  /// Emit streak milestone event for analysis
  void emitStreakMilestone({
    required int streakDays,
    required String milestone,
  }) {
    NotificationEventBus.instance.emitStreakMilestone(
      streakDays: streakDays,
      milestone: milestone,
    );
  }
}

/// **NOTIFICATION STRATEGY MODEL**
class NotificationStrategy {
  final List<DateTime> optimalTimes;
  final int frequency;
  final QuietHours? quietHours;
  final Map<String, String> urgencyLevels;
  final List<String> preferredChannels;
  final String? timezone;

  const NotificationStrategy({
    required this.optimalTimes,
    required this.frequency,
    this.quietHours,
    required this.urgencyLevels,
    required this.preferredChannels,
    this.timezone,
  });

  /// Default notification strategy
  factory NotificationStrategy.defaultStrategy() {
    return const NotificationStrategy(
      optimalTimes: [],
      frequency: 3,
      quietHours: QuietHours(start: '23:00', end: '07:00'),
      urgencyLevels: {
        'achievement': 'medium',
        'deadline': 'high',
        'study_reminder': 'low',
        'streak': 'medium',
        'pop_quiz': 'low',
      },
      preferredChannels: ['reminders', 'deadlines'],
      timezone: null,
    );
  }
}

/// **USER ENGAGEMENT LEVEL ENUM**
enum UserEngagementLevel {
  low,      // Infrequent app usage, low feature adoption
  medium,   // Regular usage, moderate feature adoption
  high,     // Frequent usage, high feature adoption
}
