import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:mindload/services/firebase_client_service.dart';
import 'package:mindload/firestore/firestore_repository.dart';
import 'package:mindload/firestore/firestore_data_schema.dart';
import 'package:mindload/models/study_data.dart';

/// MindLoad-specific Firebase service
/// Handles advanced MindLoad features with Firebase integration
class FirebaseMindLoadService {
  static FirebaseMindLoadService? _instance;
  static FirebaseMindLoadService get instance => _instance ??= FirebaseMindLoadService._internal();

  FirebaseMindLoadService._internal();

  final FirebaseClientService _firebaseClient = FirebaseClientService.instance;
  FirestoreRepository? get _repository => _firebaseClient.repository;

  bool get isInitialized => _firebaseClient.isInitialized;
  String? get currentUserId => _firebaseClient.currentUserId;
  bool get isAuthenticated => _firebaseClient.isAuthenticated;

  // MARK: - Study Set Analytics & Intelligence

  /// Get intelligent study recommendations based on user behavior
  Future<List<StudyRecommendation>> getStudyRecommendations() async {
    if (!isAuthenticated || _repository == null) return [];

    try {
      // Get user's study history and performance
      final userProgress = await _repository!.getUserProgress(currentUserId!);
      final recentResults = await _getRecentQuizResults(limit: 20);
      
      // Analyze weak areas
      final weakAreas = _analyzeWeakAreas(recentResults);
      
      // Get study sets that need review
      final studySetsNeedingReview = await _getStudySetsNeedingReview();
      
      // Generate recommendations
      final recommendations = <StudyRecommendation>[];
      
      // Add weak area recommendations
      for (final area in weakAreas) {
        recommendations.add(StudyRecommendation(
          type: RecommendationType.weakArea,
          title: 'Focus on ${area.subject}',
          description: 'You scored ${area.averageScore.toStringAsFixed(1)}% in this area',
          studySetId: area.studySetId,
          priority: _calculatePriority(area.averageScore),
          estimatedTime: Duration(minutes: 15),
        ));
      }
      
      // Add review recommendations
      for (final studySet in studySetsNeedingReview) {
        final daysSinceStudy = DateTime.now().difference(studySet.lastStudied).inDays;
        recommendations.add(StudyRecommendation(
          type: RecommendationType.review,
          title: 'Review: ${studySet.title}',
          description: 'Last studied $daysSinceStudy days ago',
          studySetId: studySet.id,
          priority: _calculateReviewPriority(daysSinceStudy),
          estimatedTime: Duration(minutes: 10),
        ));
      }
      
      // Sort by priority and return top recommendations
      recommendations.sort((a, b) => b.priority.compareTo(a.priority));
      
      // Log analytics
      await _firebaseClient.logAnalyticsEvent('study_recommendations_generated', {
        'recommendation_count': recommendations.length,
        'user_id': currentUserId,
      });
      
      return recommendations.take(10).toList();
    } catch (e) {
      debugPrint('Failed to get study recommendations: $e');
      return [];
    }
  }

  /// Get personalized study schedule
  Future<List<StudyScheduleItem>> generatePersonalizedSchedule({
    int daysAhead = 7,
  }) async {
    if (!isAuthenticated || _repository == null) return [];

    try {
      final schedule = <StudyScheduleItem>[];
      final now = DateTime.now();
      
      // Get user preferences and patterns
      final notificationPrefs = await _repository!.getNotificationPreferences(currentUserId!);
      final studySets = await _repository!.getUserStudySets(currentUserId!).first;
      
      // Generate schedule for each day
      for (int day = 0; day < daysAhead; day++) {
        final scheduleDate = now.add(Duration(days: day));
        
        // Skip weekends if user prefers
        if (_shouldSkipWeekend(scheduleDate, notificationPrefs)) continue;
        
        // Get optimal study time for this day
        final optimalTimes = _getOptimalStudyTimes(scheduleDate, notificationPrefs);
        
        for (final time in optimalTimes) {
          final studySet = _selectStudySetForSchedule(studySets, scheduleDate);
          if (studySet != null) {
            schedule.add(StudyScheduleItem(
              id: '${scheduleDate.toIso8601String()}_${time.hour}${time.minute}',
              studySetId: studySet.id,
              studySetTitle: studySet.title,
              scheduledTime: DateTime(
                scheduleDate.year,
                scheduleDate.month,
                scheduleDate.day,
                time.hour,
                time.minute,
              ),
              duration: Duration(minutes: 20),
              type: _getScheduleType(day),
              priority: _calculateSchedulePriority(studySet, scheduleDate),
            ));
          }
        }
      }
      
      // Log analytics
      await _firebaseClient.logAnalyticsEvent('study_schedule_generated', {
        'schedule_items': schedule.length,
        'days_ahead': daysAhead,
        'user_id': currentUserId,
      });
      
      return schedule;
    } catch (e) {
      debugPrint('Failed to generate personalized schedule: $e');
      return [];
    }
  }

  /// Track study session with detailed analytics
  Future<void> trackStudySession({
    required String studySetId,
    required String sessionType, // 'flashcards', 'quiz', 'review', 'ultra_mode'
    required Duration duration,
    int? questionsAnswered,
    int? correctAnswers,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!isAuthenticated || _repository == null) return;

    try {
      final sessionId = '${DateTime.now().millisecondsSinceEpoch}';
      
      // Create session record
      final sessionData = {
        'id': sessionId,
        'userId': currentUserId,
        'studySetId': studySetId,
        'sessionType': sessionType,
        'duration': duration.inSeconds,
        'questionsAnswered': questionsAnswered ?? 0,
        'correctAnswers': correctAnswers ?? 0,
        'accuracy': questionsAnswered != null && questionsAnswered > 0 
            ? (correctAnswers ?? 0) / questionsAnswered * 100 
            : null,
        'startTime': FieldValue.serverTimestamp(),
        'additionalData': additionalData,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('study_sessions')
          .doc(sessionId)
          .set(sessionData);
      
      // Update study set last studied time
      await _repository!.markStudySetAsStudied(studySetId);
      
      // Update user progress
      final xpEarned = _calculateXPForSession(duration, correctAnswers, questionsAnswered);
      await _repository!.addXP(currentUserId!, xpEarned);
      
      // Check for achievements
      await _checkAchievements(sessionType, duration, correctAnswers, questionsAnswered);
      
      // Log analytics
      await _firebaseClient.logAnalyticsEvent('study_session_completed', {
        'study_set_id': studySetId,
        'session_type': sessionType,
        'duration_minutes': duration.inMinutes,
        'questions_answered': questionsAnswered,
        'correct_answers': correctAnswers,
        'xp_earned': xpEarned,
        'user_id': currentUserId,
      });
    } catch (e) {
      debugPrint('Failed to track study session: $e');
    }
  }

  /// Get study analytics for user
  Future<StudyAnalytics> getStudyAnalytics({
    int daysBack = 30,
  }) async {
    if (!isAuthenticated) return StudyAnalytics.empty();

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));
      
      // Get study sessions
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('study_sessions')
          .where('userId', isEqualTo: currentUserId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('startTime', descending: true)
          .get();
      
      final sessions = sessionsSnapshot.docs.map((doc) => doc.data()).toList();
      
      // Calculate analytics
      final totalSessions = sessions.length;
      final totalStudyTime = sessions.fold<int>(0, (sum, session) => sum + (session['duration'] as int? ?? 0));
      final totalQuestions = sessions.fold<int>(0, (sum, session) => sum + (session['questionsAnswered'] as int? ?? 0));
      final totalCorrect = sessions.fold<int>(0, (sum, session) => sum + (session['correctAnswers'] as int? ?? 0));
      
      final averageAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0.0;
      final averageSessionDuration = totalSessions > 0 ? Duration(seconds: totalStudyTime ~/ totalSessions) : Duration.zero;
      
      // Get study streak
      final currentStreak = await _calculateCurrentStreak();
      
      // Get favorite study times
      final favoriteStudyTimes = _analyzeFavoriteStudyTimes(sessions);
      
      // Get subject breakdown
      final subjectBreakdown = await _getSubjectBreakdown(sessions);
      
      // Get progress trend
      final progressTrend = _calculateProgressTrend(sessions);
      
      return StudyAnalytics(
        totalSessions: totalSessions,
        totalStudyTime: Duration(seconds: totalStudyTime),
        averageAccuracy: averageAccuracy,
        averageSessionDuration: averageSessionDuration,
        currentStreak: currentStreak,
        favoriteStudyTimes: favoriteStudyTimes,
        subjectBreakdown: subjectBreakdown,
        progressTrend: progressTrend,
        periodStart: startDate,
        periodEnd: endDate,
      );
    } catch (e) {
      debugPrint('Failed to get study analytics: $e');
      return StudyAnalytics.empty();
    }
  }

  /// Advanced PDF processing with AI-powered content extraction
  Future<StudyContentResult> processAdvancedPDF({
    required Uint8List pdfBytes,
    required String fileName,
    bool generateQuestions = true,
    bool generateFlashcards = true,
    bool generateSummary = true,
    String? customInstructions,
  }) async {
    if (!isAuthenticated) {
      return StudyContentResult.error('User not authenticated');
    }

    try {
      // Upload PDF to Firebase Storage
      final downloadUrl = await _firebaseClient.uploadFile(
        pdfBytes,
        fileName,
        currentUserId!,
      );
      
      if (downloadUrl == null) {
        return StudyContentResult.error('Failed to upload PDF');
      }
      
      // Check credits
      final creditsNeeded = _calculateCreditsForPDFProcessing(
        pdfBytes.length,
        generateQuestions,
        generateFlashcards,
        generateSummary,
      );
      
      final hasCredits = await _repository!.useCredits(
        currentUserId!,
        creditsNeeded,
        'advanced_pdf_processing',
      );
      
      if (!hasCredits) {
        return StudyContentResult.error('Insufficient credits');
      }
      
      // Process PDF with AI (this would integrate with your OpenAI service)
      final processingResult = await _processWithAI(
        downloadUrl,
        generateQuestions: generateQuestions,
        generateFlashcards: generateFlashcards,
        generateSummary: generateSummary,
        customInstructions: customInstructions,
      );
      
      // Log usage analytics
      await _firebaseClient.logAIFeatureUsage('advanced_pdf_processing', creditsNeeded);
      
      return processingResult;
    } catch (e) {
      debugPrint('Failed to process advanced PDF: $e');
      return StudyContentResult.error('Processing failed: $e');
    }
  }

  // MARK: - Private Helper Methods

  Future<List<QuizResultFirestore>> _getRecentQuizResults({int limit = 50}) async {
    try {
      return await _repository!.getUserQuizResults(currentUserId!).first;
    } catch (e) {
      return [];
    }
  }

  List<WeakArea> _analyzeWeakAreas(List<QuizResultFirestore> results) {
    final Map<String, List<double>> subjectScores = {};
    
    for (final result in results) {
      final subject = result.studySetId; // Simplified - you might want to get actual subject
      subjectScores.putIfAbsent(subject, () => []).add(result.percentage);
    }
    
    return subjectScores.entries
        .map((entry) {
          final averageScore = entry.value.reduce((a, b) => a + b) / entry.value.length;
          return WeakArea(
            subject: entry.key,
            studySetId: entry.key,
            averageScore: averageScore,
            attempts: entry.value.length,
          );
        })
        .where((area) => area.averageScore < 75) // Consider below 75% as weak
        .toList();
  }

  Future<List<StudySetFirestore>> _getStudySetsNeedingReview() async {
    try {
      final studySets = await _repository!.getUserStudySets(currentUserId!).first;
      final now = DateTime.now();
      
      return studySets.where((studySet) {
        final daysSinceStudy = now.difference(studySet.lastStudied).inDays;
        return daysSinceStudy >= 7; // Need review after 7 days
      }).toList();
    } catch (e) {
      return [];
    }
  }

  int _calculatePriority(double averageScore) {
    if (averageScore < 50) return 10;
    if (averageScore < 60) return 8;
    if (averageScore < 70) return 6;
    return 4;
  }

  int _calculateReviewPriority(int daysSinceStudy) {
    if (daysSinceStudy >= 30) return 9;
    if (daysSinceStudy >= 14) return 7;
    if (daysSinceStudy >= 7) return 5;
    return 3;
  }

  bool _shouldSkipWeekend(DateTime date, NotificationFirestore? prefs) {
    // Check if it's weekend and user prefers weekdays only
    return (date.weekday == 6 || date.weekday == 7) && 
           (prefs?.preferences['weekendsOnly'] == false);
  }

  List<DateTime> _getOptimalStudyTimes(DateTime date, NotificationFirestore? prefs) {
    // Return optimal study times based on user preferences
    final baseTime = prefs?.reminderTime ?? '19:00';
    final parts = baseTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 19;
    final minute = int.tryParse(parts[1]) ?? 0;
    
    return [
      DateTime(date.year, date.month, date.day, hour, minute),
    ];
  }

  StudySetFirestore? _selectStudySetForSchedule(List<StudySetFirestore> studySets, DateTime date) {
    if (studySets.isEmpty) return null;
    
    // Simple selection logic - you can make this more sophisticated
    final index = date.day % studySets.length;
    return studySets[index];
  }

  String _getScheduleType(int dayOffset) {
    if (dayOffset == 0) return 'today';
    if (dayOffset == 1) return 'tomorrow';
    return 'upcoming';
  }

  int _calculateSchedulePriority(StudySetFirestore studySet, DateTime scheduleDate) {
    final daysSinceStudy = scheduleDate.difference(studySet.lastStudied).inDays;
    return daysSinceStudy.clamp(1, 10);
  }

  int _calculateXPForSession(Duration duration, int? correct, int? total) {
    int baseXP = (duration.inMinutes * 2).clamp(5, 50);
    
    if (correct != null && total != null && total > 0) {
      final accuracy = correct / total;
      baseXP = (baseXP * (0.5 + accuracy * 0.5)).round();
    }
    
    return baseXP;
  }

  Future<void> _checkAchievements(String sessionType, Duration duration, int? correct, int? total) async {
    // Implementation would check various achievement conditions
    // and award achievements accordingly
  }

  Future<int> _calculateCurrentStreak() async {
    try {
      final progress = await _repository!.getUserProgress(currentUserId!);
      return progress.currentStreak;
    } catch (e) {
      return 0;
    }
  }

  List<int> _analyzeFavoriteStudyTimes(List<Map<String, dynamic>> sessions) {
    final hourCounts = <int, int>{};
    
    for (final session in sessions) {
      final timestamp = session['startTime'] as Timestamp?;
      if (timestamp != null) {
        final hour = timestamp.toDate().hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }
    
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHours.take(3).map((e) => e.key).toList();
  }

  Future<Map<String, double>> _getSubjectBreakdown(List<Map<String, dynamic>> sessions) async {
    final subjectTime = <String, int>{};
    
    for (final session in sessions) {
      final studySetId = session['studySetId'] as String?;
      final duration = session['duration'] as int? ?? 0;
      
      if (studySetId != null) {
        // Get subject from study set (simplified)
        subjectTime[studySetId] = (subjectTime[studySetId] ?? 0) + duration;
      }
    }
    
    final totalTime = subjectTime.values.fold(0, (sum, time) => sum + time);
    
    return subjectTime.map((key, value) => 
      MapEntry(key, totalTime > 0 ? value / totalTime * 100 : 0.0));
  }

  List<double> _calculateProgressTrend(List<Map<String, dynamic>> sessions) {
    // Calculate weekly progress trend
    final weeklyAccuracy = <double>[];
    
    // Group sessions by week and calculate average accuracy
    // This is a simplified implementation
    final now = DateTime.now();
    for (int week = 3; week >= 0; week--) {
      final weekStart = now.subtract(Duration(days: (week + 1) * 7));
      final weekEnd = now.subtract(Duration(days: week * 7));
      
      final weekSessions = sessions.where((session) {
        final timestamp = session['startTime'] as Timestamp?;
        if (timestamp == null) return false;
        final date = timestamp.toDate();
        return date.isAfter(weekStart) && date.isBefore(weekEnd);
      }).toList();
      
      if (weekSessions.isNotEmpty) {
        final totalQuestions = weekSessions.fold<int>(0, (sum, s) => sum + (s['questionsAnswered'] as int? ?? 0));
        final totalCorrect = weekSessions.fold<int>(0, (sum, s) => sum + (s['correctAnswers'] as int? ?? 0));
        final accuracy = totalQuestions > 0 ? totalCorrect / totalQuestions * 100 : 0.0;
        weeklyAccuracy.add(accuracy);
      } else {
        weeklyAccuracy.add(0.0);
      }
    }
    
    return weeklyAccuracy;
  }

  int _calculateCreditsForPDFProcessing(int fileSize, bool questions, bool flashcards, bool summary) {
    int credits = 5; // Base cost
    
    // File size factor
    credits += (fileSize / (1024 * 1024)).ceil(); // 1 credit per MB
    
    // Feature costs
    if (questions) credits += 3;
    if (flashcards) credits += 3;
    if (summary) credits += 2;
    
    return credits.clamp(5, 50);
  }

  Future<StudyContentResult> _processWithAI(
    String pdfUrl, {
    bool generateQuestions = true,
    bool generateFlashcards = true,
    bool generateSummary = true,
    String? customInstructions,
  }) async {
    try {
      // Call Firebase Cloud Function for AI processing
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('processWithAI').call({
        'pdfUrl': pdfUrl,
        'generateQuestions': generateQuestions,
        'generateFlashcards': generateFlashcards,
        'generateSummary': generateSummary,
        'customInstructions': customInstructions,
      });

      final data = result.data as Map<String, dynamic>;
      
      return StudyContentResult(
        success: true,
        message: data['message'] ?? 'Content processed successfully',
        flashcards: null, // Will be processed separately
        questions: null, // Will be processed separately
        summary: generateSummary ? data['summary'] as String? : null,
      );
    } catch (e) {
      debugPrint('Error processing with AI: $e');
      return StudyContentResult(
        success: false,
        message: 'Failed to process content with AI: ${e.toString()}',
      );
    }
  }
}

// MARK: - Data Models

class StudyRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final String studySetId;
  final int priority;
  final Duration estimatedTime;

  StudyRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.studySetId,
    required this.priority,
    required this.estimatedTime,
  });
}

enum RecommendationType {
  weakArea,
  review,
  newContent,
  streak,
}

class StudyScheduleItem {
  final String id;
  final String studySetId;
  final String studySetTitle;
  final DateTime scheduledTime;
  final Duration duration;
  final String type;
  final int priority;

  StudyScheduleItem({
    required this.id,
    required this.studySetId,
    required this.studySetTitle,
    required this.scheduledTime,
    required this.duration,
    required this.type,
    required this.priority,
  });
}

class WeakArea {
  final String subject;
  final String studySetId;
  final double averageScore;
  final int attempts;

  WeakArea({
    required this.subject,
    required this.studySetId,
    required this.averageScore,
    required this.attempts,
  });
}

class StudyAnalytics {
  final int totalSessions;
  final Duration totalStudyTime;
  final double averageAccuracy;
  final Duration averageSessionDuration;
  final int currentStreak;
  final List<int> favoriteStudyTimes;
  final Map<String, double> subjectBreakdown;
  final List<double> progressTrend;
  final DateTime periodStart;
  final DateTime periodEnd;

  StudyAnalytics({
    required this.totalSessions,
    required this.totalStudyTime,
    required this.averageAccuracy,
    required this.averageSessionDuration,
    required this.currentStreak,
    required this.favoriteStudyTimes,
    required this.subjectBreakdown,
    required this.progressTrend,
    required this.periodStart,
    required this.periodEnd,
  });

  static StudyAnalytics empty() {
    return StudyAnalytics(
      totalSessions: 0,
      totalStudyTime: Duration.zero,
      averageAccuracy: 0.0,
      averageSessionDuration: Duration.zero,
      currentStreak: 0,
      favoriteStudyTimes: [],
      subjectBreakdown: {},
      progressTrend: [],
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
    );
  }
}

class StudyContentResult {
  final bool success;
  final String message;
  final List<Flashcard>? flashcards;
  final List<Quiz>? questions;
  final String? summary;

  StudyContentResult({
    required this.success,
    required this.message,
    this.flashcards,
    this.questions,
    this.summary,
  });

  static StudyContentResult _success(
    String message, {
    List<Flashcard>? flashcards,
    List<Quiz>? questions,
    String? summary,
  }) {
    return StudyContentResult(
      success: true,
      message: message,
      flashcards: flashcards,
      questions: questions,
      summary: summary,
    );
  }

  static StudyContentResult error(String message) {
    return StudyContentResult(
      success: false,
      message: message,
    );
  }
}