import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart' as ftz;
import 'neurograph_config.dart';
import 'neurograph_models.dart';
import 'neurograph_local_storage.dart';

/// Completely offline NeuroGraph V2 repository
/// Uses only local SQLite storage for all operations
/// Phone resources handle all calculations and data processing
class NeuroGraphOfflineRepository {
  static final NeuroGraphOfflineRepository _instance =
      NeuroGraphOfflineRepository._internal();
  factory NeuroGraphOfflineRepository() => _instance;
  static NeuroGraphOfflineRepository get instance => _instance;
  NeuroGraphOfflineRepository._internal();

  final NeuroGraphLocalStorage _localStorage = NeuroGraphLocalStorage.instance;
  String? _cachedTimezone;
  bool _isInitialized = false;

  /// Initialize repository
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _localStorage.initialize();
      _isInitialized = true;
      debugPrint('✅ NeuroGraph offline repository initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize NeuroGraph offline repository: $e');
      rethrow;
    }
  }

  /// Get user's timezone dynamically, with caching
  Future<String> getUserTimezone() async {
    if (_cachedTimezone != null) {
      return _cachedTimezone!;
    }

    try {
      // Try to get the user's actual timezone from their device
      final timezoneName = await ftz.FlutterTimezone.getLocalTimezone();
      _cachedTimezone = timezoneName;
      debugPrint('📍 User timezone: $timezoneName');
      return timezoneName;
    } catch (e) {
      // Fallback to default timezone
      _cachedTimezone = NeuroGraphConfig.defaultTimezone;
      debugPrint(
          '⚠️ Using default timezone: ${NeuroGraphConfig.defaultTimezone}');
      return NeuroGraphConfig.defaultTimezone;
    }
  }

  /// Get timezone location for date conversions
  Future<tz.Location> _getTimezoneLocation() async {
    final timezoneName = await getUserTimezone();
    try {
      return tz.getLocation(timezoneName);
    } catch (e) {
      // Fallback to default timezone
      return tz.getLocation(NeuroGraphConfig.defaultTimezone);
    }
  }

  /// Convert timestamp to user's timezone
  Future<tz.TZDateTime> _toUserTimezone(DateTime timestamp) async {
    final location = await _getTimezoneLocation();
    return tz.TZDateTime.from(timestamp, location);
  }

  /// Save attempt to local storage
  Future<bool> saveAttempt(Attempt attempt) async {
    try {
      await _ensureInitialized();
      await _localStorage.saveAttempt(attempt);
      debugPrint('💾 Saved attempt: ${attempt.questionId}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to save attempt: $e');
      return false;
    }
  }

  /// Save session to local storage
  Future<bool> saveSession(Session session) async {
    try {
      await _ensureInitialized();
      await _localStorage.saveSession(session);
      debugPrint('💾 Saved session: ${session.testId}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to save session: $e');
      return false;
    }
  }

  /// Save question metadata to local storage
  Future<bool> saveQuestion(Question question) async {
    try {
      await _ensureInitialized();
      await _localStorage.saveQuestion(question);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to save question: $e');
      return false;
    }
  }

  /// Get attempts for a specific user with optional filters
  /// Completely offline using local SQLite storage
  Future<List<Attempt>> attemptsForUser(
    String uid, {
    DateTime? from,
    NeuroGraphFilters? filters,
  }) async {
    debugPrint('🔍 Querying local attempts for user: $uid');

    try {
      await _ensureInitialized();

      final attempts = await _localStorage.getAttemptsForUser(
        uid,
        from: from,
        filters: filters,
        limit: NeuroGraphConfig.maxAttemptsPerQuery,
      );

      debugPrint('✅ Found ${attempts.length} local attempts for user $uid');
      return attempts;
    } catch (e) {
      debugPrint('❌ Error querying local attempts for user $uid: $e');
      return [];
    }
  }

  /// Get attempts for a specific test
  Future<List<Attempt>> attemptsForTest(
    String testId, {
    DateTime? from,
  }) async {
    debugPrint('🔍 Querying local attempts for test: $testId');

    try {
      await _ensureInitialized();

      // Get all attempts and filter by testId
      final allAttempts = await _localStorage.getAttemptsForUser(
        '', // Empty userId to get all attempts, then filter
        from: from,
        limit: NeuroGraphConfig.maxAttemptsPerQuery,
      );

      final testAttempts =
          allAttempts.where((a) => a.testId == testId).toList();

      debugPrint(
          '✅ Found ${testAttempts.length} local attempts for test $testId');
      return testAttempts;
    } catch (e) {
      debugPrint('❌ Error querying local attempts for test $testId: $e');
      return [];
    }
  }

  /// Get attempts for a specific question
  Future<List<Attempt>> attemptsForQuestion(
    String questionId, {
    DateTime? from,
  }) async {
    debugPrint('🔍 Querying local attempts for question: $questionId');

    try {
      await _ensureInitialized();

      // Get all attempts and filter by questionId
      final allAttempts = await _localStorage.getAttemptsForUser(
        '', // Empty userId to get all attempts, then filter
        from: from,
        limit: NeuroGraphConfig.maxAttemptsPerQuery,
      );

      final questionAttempts =
          allAttempts.where((a) => a.questionId == questionId).toList();

      debugPrint(
          '✅ Found ${questionAttempts.length} local attempts for question $questionId');
      return questionAttempts;
    } catch (e) {
      debugPrint(
          '❌ Error querying local attempts for question $questionId: $e');
      return [];
    }
  }

  /// Get attempts for user and topic combination
  Future<List<Attempt>> attemptsForUserAndTopic(
    String uid,
    String topicId, {
    DateTime? from,
  }) async {
    debugPrint('🔍 Querying local attempts for user $uid and topic $topicId');

    try {
      await _ensureInitialized();

      final filters = NeuroGraphFilters(
        topics: [topicId],
        tests: [],
      );

      final attempts = await _localStorage.getAttemptsForUser(
        uid,
        from: from,
        filters: filters,
        limit: NeuroGraphConfig.maxAttemptsPerQuery,
      );

      debugPrint(
          '✅ Found ${attempts.length} local attempts for user $uid and topic $topicId');
      return attempts;
    } catch (e) {
      debugPrint(
          '❌ Error querying local attempts for user $uid and topic $topicId: $e');
      return [];
    }
  }

  /// Get sessions for a specific user
  Future<List<Session>> sessionsForUser(
    String uid, {
    DateTime? from,
  }) async {
    debugPrint('🔍 Querying local sessions for user: $uid');

    try {
      await _ensureInitialized();

      final sessions = await _localStorage.getSessionsForUser(
        uid,
        from: from,
        limit: 100,
      );

      debugPrint('✅ Found ${sessions.length} local sessions for user $uid');
      return sessions;
    } catch (e) {
      debugPrint('❌ Error querying local sessions for user $uid: $e');
      return [];
    }
  }

  /// Get questions with optional filters
  Future<List<Question>> questionsForTopics(List<String> topicIds) async {
    debugPrint('🔍 Querying local questions for topics: $topicIds');

    try {
      await _ensureInitialized();

      final questions = await _localStorage.getQuestions(
        topicIds: topicIds,
        limit: 1000,
      );

      debugPrint('✅ Found ${questions.length} local questions for topics');
      return questions;
    } catch (e) {
      debugPrint('❌ Error querying local questions: $e');
      return [];
    }
  }

  /// Get comprehensive user data summary for analytics
  Future<Map<String, dynamic>> getUserDataSummary(
    String uid, {
    NeuroGraphFilters? filters,
    String? timezone,
  }) async {
    debugPrint('📊 Computing user data summary locally for: $uid');

    try {
      await _ensureInitialized();

      final userTimezone = timezone ?? await getUserTimezone();

      // Get basic data summary from local storage
      final summary = await _localStorage.getDataSummary(uid);

      // Add timezone information
      summary['timezone'] = userTimezone;
      summary['userTimezone'] = userTimezone;

      // Add computed analytics
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final attempts = await attemptsForUser(uid, from: thirtyDaysAgo);
      final sessions = await sessionsForUser(uid, from: thirtyDaysAgo);

      // Compute additional metrics using phone resources
      summary['learningTrend'] = _computeLearningTrend(attempts);
      summary['studyStreak'] = await _computeStudyStreak(uid);
      summary['averageSessionDuration'] =
          _computeAverageSessionDuration(sessions);
      summary['topicMastery'] = _computeTopicMastery(attempts);
      summary['responseTimeImprovement'] =
          _computeResponseTimeImprovement(attempts);

      debugPrint('✅ Computed comprehensive data summary locally');
      return summary;
    } catch (e) {
      debugPrint('❌ Error computing user data summary: $e');
      return {
        'error': e.toString(),
        'dataAvailable': false,
        'totalAttempts': 0,
        'correctAttempts': 0,
        'totalSessions': 0,
        'averageAccuracy': 0.0,
        'timezone': await getUserTimezone(),
      };
    }
  }

  /// Compute learning trend from attempts
  Map<String, dynamic> _computeLearningTrend(List<Attempt> attempts) {
    if (attempts.isEmpty) {
      return {'trend': 'stable', 'improvement': 0.0, 'confidence': 0.0};
    }

    // Sort by timestamp
    attempts.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate accuracy over time windows
    const windowSize = 10;
    final accuracyWindows = <double>[];

    for (int i = 0; i <= attempts.length - windowSize; i += windowSize ~/ 2) {
      final window = attempts.skip(i).take(windowSize);
      final correct = window.where((a) => a.isCorrect).length;
      final accuracy = correct / windowSize;
      accuracyWindows.add(accuracy);
    }

    if (accuracyWindows.length < 2) {
      return {'trend': 'stable', 'improvement': 0.0, 'confidence': 0.5};
    }

    // Calculate trend
    final first = accuracyWindows.first;
    final last = accuracyWindows.last;
    final improvement = last - first;

    String trend;
    if (improvement > 0.1) {
      trend = 'improving';
    } else if (improvement < -0.1) {
      trend = 'declining';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'improvement': improvement,
      'confidence': accuracyWindows.length / 10.0,
    };
  }

  /// Compute study streak
  Future<Map<String, dynamic>> _computeStudyStreak(String uid) async {
    try {
      final now = DateTime.now();
      final sessions = await sessionsForUser(uid);

      if (sessions.isEmpty) {
        return {'currentStreak': 0, 'longestStreak': 0, 'lastStudyDate': null};
      }

      // Sort sessions by date
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      // Calculate current streak
      int currentStreak = 0;
      DateTime? lastDate;
      final studyDates = <String>{};

      for (final session in sessions) {
        final dateKey =
            '${session.startedAt.year}-${session.startedAt.month}-${session.startedAt.day}';
        studyDates.add(dateKey);
      }

      final sortedDates = studyDates.toList()..sort();
      sortedDates.reversed.toList();

      // Calculate streaks
      int longestStreak = 0;
      currentStreak = 0;
      int tempStreak = 0;
      DateTime? previousDate;

      for (final dateStr in sortedDates.reversed) {
        final parts = dateStr.split('-');
        final date = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

        if (previousDate == null) {
          tempStreak = 1;
          if (date.difference(now).inDays.abs() <= 1) {
            currentStreak = 1;
          }
        } else {
          final daysDiff = previousDate.difference(date).inDays;
          if (daysDiff == 1) {
            tempStreak++;
            if (currentStreak > 0) currentStreak++;
          } else {
            longestStreak =
                longestStreak > tempStreak ? longestStreak : tempStreak;
            tempStreak = 1;
            if (currentStreak > 0 && daysDiff > 1) currentStreak = 0;
          }
        }

        previousDate = date;
      }

      longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;

      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastStudyDate': sessions.first.startedAt.toIso8601String(),
      };
    } catch (e) {
      return {'currentStreak': 0, 'longestStreak': 0, 'lastStudyDate': null};
    }
  }

  /// Compute average session duration
  double _computeAverageSessionDuration(List<Session> sessions) {
    if (sessions.isEmpty) return 0.0;

    final totalMinutes = sessions.fold<int>(0, (sum, session) {
      return sum + session.endedAt.difference(session.startedAt).inMinutes;
    });

    return totalMinutes / sessions.length;
  }

  /// Compute topic mastery
  Map<String, double> _computeTopicMastery(List<Attempt> attempts) {
    final topicStats = <String, List<bool>>{};

    for (final attempt in attempts) {
      topicStats.putIfAbsent(attempt.topicId, () => []);
      topicStats[attempt.topicId]!.add(attempt.isCorrect);
    }

    final mastery = <String, double>{};
    topicStats.forEach((topic, results) {
      final correct = results.where((r) => r).length;
      mastery[topic] = correct / results.length;
    });

    return mastery;
  }

  /// Compute response time improvement
  Map<String, dynamic> _computeResponseTimeImprovement(List<Attempt> attempts) {
    if (attempts.length < 10) {
      return {'improvement': 0.0, 'averageTime': 0.0, 'trend': 'stable'};
    }

    attempts.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstHalf = attempts.take(attempts.length ~/ 2);
    final secondHalf = attempts.skip(attempts.length ~/ 2);

    final firstAvg = firstHalf.fold<int>(0, (sum, a) => sum + a.responseMs) /
        firstHalf.length;
    final secondAvg = secondHalf.fold<int>(0, (sum, a) => sum + a.responseMs) /
        secondHalf.length;

    final improvement = (firstAvg - secondAvg) / firstAvg;

    return {
      'improvement': improvement,
      'averageTime': secondAvg,
      'trend': improvement > 0.1
          ? 'improving'
          : (improvement < -0.1 ? 'declining' : 'stable'),
    };
  }

  /// Create sample data for testing
  Future<void> createSampleData(String uid) async {
    try {
      await _ensureInitialized();
      await _localStorage.createSampleData(uid);
      debugPrint('✅ Created sample data locally for user $uid');
    } catch (e) {
      debugPrint('❌ Failed to create sample data: $e');
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await _ensureInitialized();
      await _localStorage.clearAllData();
      debugPrint('🗑️ Cleared all local NeuroGraph data');
    } catch (e) {
      debugPrint('❌ Failed to clear data: $e');
    }
  }

  /// Ensure repository is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
