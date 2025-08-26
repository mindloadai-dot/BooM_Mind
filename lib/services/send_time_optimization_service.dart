import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/models/notification_models.dart';
// Removed import: enhanced_notification_copy_library - service removed

enum OptimizationStrategy { 
  best_hour,        // Send at user's historically best hour
  daypart,          // Send within appropriate daypart window  
  backup_slot,      // Use backup when best hour isn't available
  quiet_respect,    // Respect quiet hours absolutely
  fatigue_avoid     // Avoid when user is fatigued
}

class SendTimeOptimizationService {
  static final SendTimeOptimizationService _instance = SendTimeOptimizationService._internal();
  factory SendTimeOptimizationService() => _instance;
  SendTimeOptimizationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for user optimization data
  final Map<String, UserOptimizationData> _optimizationCache = {};

  /// Learn user's best engagement hours from app opens and notification interactions
  Future<DateTime?> getOptimalSendTime(
    NotificationCategory category,
    UserNotificationPreferences preferences, {
    DateTime? preferredTime,
    bool respectQuietHours = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final optimization = await _getUserOptimizationData(user.uid);
      final baseTime = preferredTime ?? DateTime.now();
      
      // Get user's best engagement hour
      final bestHour = _getBestEngagementHour(optimization, category);
      
      // Create candidate times
      final candidates = _generateCandidateTimes(
        baseTime, 
        bestHour, 
        preferences,
        respectQuietHours: respectQuietHours,
      );
      
      // Score and rank candidates
      final scoredCandidates = candidates
          .map((time) => ScoredCandidate(
                time: time,
                score: _scoreCandidateTime(time, optimization, preferences, category),
              ))
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      return scoredCandidates.isNotEmpty ? scoredCandidates.first.time : null;
    } catch (e) {
      debugPrint('Error getting optimal send time: $e');
      final baseTime = preferredTime ?? DateTime.now();
      return _getFallbackTime(baseTime, preferences, respectQuietHours);
    }
  }

  /// Generate multiple candidate send times
  List<DateTime> _generateCandidateTimes(
    DateTime baseTime,
    int? bestHour,
    UserNotificationPreferences preferences, {
    bool respectQuietHours = true,
  }) {
    final candidates = <DateTime>[];
    final now = DateTime.now();
    
    // Primary candidate: User's best engagement hour today
    if (bestHour != null) {
      final primaryTime = DateTime(baseTime.year, baseTime.month, baseTime.day, bestHour);
      if (primaryTime.isAfter(now)) {
        candidates.add(primaryTime);
      }
    }
    
    // Backup candidates: within preferred time windows
    for (final window in preferences.timeWindows) {
      final startTime = _parseTimeWindow(window.start, baseTime);
      final endTime = _parseTimeWindow(window.end, baseTime);
      
      if (startTime.isAfter(now) && endTime.isAfter(startTime)) {
        // Add time at start of window
        candidates.add(startTime);
        
        // Add time in middle of window
        final middleMinutes = startTime.difference(endTime).inMinutes ~/ 2;
        candidates.add(startTime.add(Duration(minutes: middleMinutes)));
      }
    }
    
    // Emergency candidates: next available slots respecting quiet hours
    if (respectQuietHours) {
      final nextAvailable = _getNextAvailableSlot(now, preferences);
      if (nextAvailable != null) candidates.add(nextAvailable);
    }
    
    return candidates.toSet().toList(); // Remove duplicates
  }

  /// Score a candidate time based on optimization factors
  double _scoreCandidateTime(
    DateTime candidateTime,
    UserOptimizationData optimization,
    UserNotificationPreferences preferences,
    NotificationCategory category,
  ) {
    double score = 0.0;
    final hour = candidateTime.hour;
    
    // 1. Historical engagement score (40% weight)
    final hourEngagement = optimization.hourlyEngagement[hour] ?? 0.0;
    score += hourEngagement * 0.4;
    
    // 2. Day part alignment score (25% weight)
    final dayPart = _getDayPart(candidateTime);
    final dayPartMultiplier = _getDayPartMultiplier(dayPart, category);
    score += dayPartMultiplier * 0.25;
    
    // 3. Quiet hours respect (20% weight)
    final quietHoursObj = _createQuietHoursFromPreferences(preferences);
    final isInQuietHours = _isInQuietHours(candidateTime, quietHoursObj);
    score += isInQuietHours ? -0.5 : 0.2; // Heavy penalty for quiet hours
    
    // 4. Fatigue avoidance (10% weight)  
    final fatigueScore = _getFatigueScore(candidateTime, optimization);
    score += fatigueScore * 0.1;
    
    // 5. Recency boost (5% weight)
    final recencyScore = _getRecencyScore(candidateTime, DateTime.now());
    score += recencyScore * 0.05;
    
    return score.clamp(0.0, 1.0);
  }

  /// Get user's best engagement hour based on historical data
  int? _getBestEngagementHour(UserOptimizationData optimization, NotificationCategory category) {
    if (optimization.hourlyEngagement.isEmpty) return null;
    
    // Weight by category preferences
    final categoryWeight = _getCategoryWeight(category);
    final weightedEngagement = <int, double>{};
    
    optimization.hourlyEngagement.forEach((hour, engagement) {
      weightedEngagement[hour] = engagement * categoryWeight;
    });
    
    // Find hour with highest weighted engagement
    final bestEntry = weightedEngagement.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return bestEntry.value > 0.1 ? bestEntry.key : null; // Minimum threshold
  }

  DayPart _getDayPart(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 6 && hour < 11) return DayPart.morning;
    if (hour >= 11 && hour < 14) return DayPart.midday;
    if (hour >= 14 && hour < 18) return DayPart.afternoon;
    if (hour >= 18 && hour < 21) return DayPart.evening;
    return DayPart.late;
  }

  double _getDayPartMultiplier(DayPart dayPart, NotificationCategory category) {
    // Optimize notification timing based on category and day part
    switch (category) {
      case NotificationCategory.studyNow:
        switch (dayPart) {
          case DayPart.morning: return 1.0;   // Great for study sessions
          case DayPart.midday: return 0.8;    // Good
          case DayPart.afternoon: return 0.9; // Very good
          case DayPart.evening: return 0.7;   // Okay
          case DayPart.late: return 0.3;      // Not ideal
        }
      
      case NotificationCategory.examAlert:
        switch (dayPart) {
          case DayPart.morning: return 1.0;   // Perfect for deadline pressure
          case DayPart.midday: return 0.9;    
          case DayPart.afternoon: return 0.8; 
          case DayPart.evening: return 0.6;   
          case DayPart.late: return 0.2;      
        }
      
      case NotificationCategory.streakSave:
        switch (dayPart) {
          case DayPart.morning: return 0.7;   
          case DayPart.midday: return 0.8;    
          case DayPart.afternoon: return 0.9; 
          case DayPart.evening: return 1.0;   // Perfect time for streak saves
          case DayPart.late: return 0.8;      // Still good
        }
        
      default:
        return 0.7; // Neutral
    }
  }

  double _getCategoryWeight(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.examAlert: return 1.2;      // High priority
      case NotificationCategory.streakSave: return 1.1;     // Important  
      case NotificationCategory.studyNow: return 1.0;       // Normal
      case NotificationCategory.eventTrigger: return 0.9;   // Medium
      case NotificationCategory.inactivityNudge: return 0.7; // Lower
      case NotificationCategory.promotional: return 0.5;    // Lowest
    }
  }

  bool _isInQuietHours(DateTime time, QuietHours quietHours) {
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    
    // Handle cross-midnight quiet hours
    if (quietHours.start.compareTo(quietHours.end) > 0) {
      return timeStr.compareTo(quietHours.start) >= 0 || timeStr.compareTo(quietHours.end) <= 0;
    } else {
      return timeStr.compareTo(quietHours.start) >= 0 && timeStr.compareTo(quietHours.end) <= 0;
    }
  }

  double _getFatigueScore(DateTime candidateTime, UserOptimizationData optimization) {
    final hour = candidateTime.hour;
    final recentNotifications = optimization.recentNotificationHours
        .where((h) => (hour - h).abs() <= 2) // Within 2 hours
        .length;
    
    // Penalize times with high recent notification density
    return (1.0 - (recentNotifications * 0.2)).clamp(0.0, 1.0);
  }

  double _getRecencyScore(DateTime candidateTime, DateTime now) {
    final hoursDiff = candidateTime.difference(now).inHours.abs();
    if (hoursDiff <= 1) return 1.0;      // Perfect - within next hour
    if (hoursDiff <= 3) return 0.8;      // Good - within 3 hours  
    if (hoursDiff <= 6) return 0.6;      // Okay - within 6 hours
    if (hoursDiff <= 12) return 0.4;     // Lower - within 12 hours
    return 0.2;                          // Low - beyond 12 hours
  }

  DateTime? _getNextAvailableSlot(DateTime from, UserNotificationPreferences preferences) {
    final now = from;
    
    // Check each hour for the next 24 hours
    for (int i = 1; i <= 24; i++) {
      final candidate = now.add(Duration(hours: i));
      final quietHoursObj = _createQuietHoursFromPreferences(preferences);
      if (!_isInQuietHours(candidate, quietHoursObj)) {
        return candidate;
      }
    }
    
    return null; // No available slot found (shouldn't happen)
  }

  DateTime? _getFallbackTime(DateTime baseTime, UserNotificationPreferences preferences, bool respectQuietHours) {
    if (!respectQuietHours) return baseTime.add(const Duration(minutes: 5));
    
    return _getNextAvailableSlot(baseTime, preferences);
  }

  DateTime _parseTimeWindow(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  /// Track user app opens and notification interactions for learning
  Future<void> trackUserEngagement(String action, {
    DateTime? timestamp,
    NotificationCategory? category,
    String? notificationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final engagementTime = timestamp ?? DateTime.now();
      final hour = engagementTime.hour;
      
      await _firestore.collection('user_optimization').doc(user.uid).set({
        'engagement_events': FieldValue.arrayUnion([{
          'action': action,
          'hour': hour,
          'timestamp': Timestamp.fromDate(engagementTime),
          'category': category?.name,
          'notification_id': notificationId,
        }]),
        'last_updated': Timestamp.now(),
      }, SetOptions(merge: true));

      // Update cache
      await _refreshOptimizationData(user.uid);
    } catch (e) {
      debugPrint('Error tracking engagement: $e');
    }
  }

  Future<UserOptimizationData> _getUserOptimizationData(String userId) async {
    // Check cache first
    if (_optimizationCache.containsKey(userId)) {
      final cached = _optimizationCache[userId]!;
      if (DateTime.now().difference(cached.lastUpdated).inHours < 6) {
        return cached;
      }
    }

    return await _refreshOptimizationData(userId);
  }

  Future<UserOptimizationData> _refreshOptimizationData(String userId) async {
    try {
      final doc = await _firestore.collection('user_optimization').doc(userId).get();
      
      UserOptimizationData optimizationData;
      if (doc.exists && doc.data() != null) {
        optimizationData = UserOptimizationData.fromFirestore(doc.data()!);
      } else {
        optimizationData = UserOptimizationData.empty(userId);
      }

      _optimizationCache[userId] = optimizationData;
      return optimizationData;
    } catch (e) {
      debugPrint('Error loading optimization data: $e');
      return UserOptimizationData.empty(userId);
    }
  }

  /// Get A/B test variant for send-time optimization
  OptimizationStrategy getOptimizationStrategy(String userId) {
    // Simple hash-based A/B testing
    final hash = userId.hashCode.abs();
    final variant = hash % 5;
    
    switch (variant) {
      case 0: return OptimizationStrategy.best_hour;
      case 1: return OptimizationStrategy.daypart;
      case 2: return OptimizationStrategy.backup_slot;
      case 3: return OptimizationStrategy.quiet_respect;
      case 4: return OptimizationStrategy.fatigue_avoid;
      default: return OptimizationStrategy.best_hour;
    }
  }

  void clearCache() {
    _optimizationCache.clear();
  }

  /// Helper method to create QuietHours object from UserNotificationPreferences
  QuietHours _createQuietHoursFromPreferences(UserNotificationPreferences preferences) {
    // Convert TimeOfDay to string format "HH:MM"
    final startStr = "${preferences.quietStart.hour.toString().padLeft(2, '0')}:${preferences.quietStart.minute.toString().padLeft(2, '0')}";
    final endStr = "${preferences.quietEnd.hour.toString().padLeft(2, '0')}:${preferences.quietEnd.minute.toString().padLeft(2, '0')}";
    
    return QuietHours(
      start: startStr,
      end: endStr,
    );
  }
}

class UserOptimizationData {
  final String userId;
  final Map<int, double> hourlyEngagement; // hour -> engagement score
  final List<int> recentNotificationHours;
  final DateTime lastUpdated;
  final int totalInteractions;
  final double averageEngagement;

  UserOptimizationData({
    required this.userId,
    required this.hourlyEngagement,
    required this.recentNotificationHours,
    required this.lastUpdated,
    required this.totalInteractions,
    required this.averageEngagement,
  });

  factory UserOptimizationData.empty(String userId) => UserOptimizationData(
    userId: userId,
    hourlyEngagement: {},
    recentNotificationHours: [],
    lastUpdated: DateTime.now(),
    totalInteractions: 0,
    averageEngagement: 0.0,
  );

  factory UserOptimizationData.fromFirestore(Map<String, dynamic> data) {
    final engagementEvents = data['engagement_events'] as List<dynamic>? ?? [];
    final hourlyEngagement = <int, double>{};
    final recentHours = <int>[];
    int totalInteractions = 0;
    
    // Process engagement events to calculate hourly scores
    for (final event in engagementEvents) {
      if (event is Map<String, dynamic>) {
        final hour = event['hour'] as int?;
        final timestamp = event['timestamp'] as Timestamp?;
        final action = event['action'] as String?;
        
        if (hour != null && timestamp != null && action != null) {
          totalInteractions++;
          
          // Track recent notifications (last 24 hours)
          if (DateTime.now().difference(timestamp.toDate()).inHours <= 24) {
            recentHours.add(hour);
          }
          
          // Calculate engagement score for this hour
          final engagementScore = _getActionEngagementScore(action);
          hourlyEngagement[hour] = (hourlyEngagement[hour] ?? 0.0) + engagementScore;
        }
      }
    }

    // Normalize hourly engagement scores
    final maxEngagement = hourlyEngagement.values.isNotEmpty 
        ? hourlyEngagement.values.reduce(max) 
        : 1.0;
    if (maxEngagement > 0) {
      hourlyEngagement.updateAll((hour, score) => score / maxEngagement);
    }

    return UserOptimizationData(
      userId: data['userId'] as String? ?? '',
      hourlyEngagement: hourlyEngagement,
      recentNotificationHours: recentHours,
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalInteractions: totalInteractions,
      averageEngagement: hourlyEngagement.values.isNotEmpty 
          ? hourlyEngagement.values.reduce((a, b) => a + b) / hourlyEngagement.length
          : 0.0,
    );
  }

  static double _getActionEngagementScore(String action) {
    switch (action) {
      case 'notification_opened': return 1.0;
      case 'app_opened': return 0.8;
      case 'study_started': return 1.5;
      case 'quiz_completed': return 2.0;
      case 'notification_dismissed': return -0.2;
      case 'app_backgrounded': return 0.1;
      default: return 0.5;
    }
  }
}

class ScoredCandidate {
  final DateTime time;
  final double score;

  ScoredCandidate({required this.time, required this.score});

  @override
  String toString() => 'ScoredCandidate(time: $time, score: $score)';
}