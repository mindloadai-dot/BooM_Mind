import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart' as ftz;
import 'neurograph_config.dart';
import 'neurograph_models.dart';

/// Repository layer for NeuroGraph V2 analytics
/// Handles Firestore queries with offline-first approach and dynamic timezone support
class NeuroGraphRepository {
  static final NeuroGraphRepository _instance =
      NeuroGraphRepository._internal();
  factory NeuroGraphRepository() => _instance;
  static NeuroGraphRepository get instance => _instance;
  NeuroGraphRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _cachedTimezone;

  /// Initialize repository and timezone data
  static Future<void> initialize() async {
    // Initialize timezone data for dynamic timezone support
    // Note: timezone data is typically initialized in main.dart
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
      return timezoneName;
    } catch (e) {
      // Fallback to default timezone
      _cachedTimezone = NeuroGraphConfig.defaultTimezone;
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

  /// Get attempts for a specific user with optional date filter
  /// Uses offline-first approach: tries cache first, then server
  Future<List<Attempt>> attemptsForUser(
    String uid, {
    DateTime? from,
    NeuroGraphFilters? filters,
  }) async {
    // Build query
    Query query =
        _firestore.collection('attempts').where('userId', isEqualTo: uid);

    if (from != null) {
      query =
          query.where('ts', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    // Apply filters
    if (filters != null) {
      if (filters.topics.isNotEmpty) {
        query = query.where('topicId', whereIn: filters.topics);
      }
      if (filters.tests.isNotEmpty) {
        query = query.where('testId', whereIn: filters.tests);
      }
    }

    // Order by timestamp descending for efficient pagination
    query = query.orderBy('ts', descending: true);

    // Limit results for performance
    query = query.limit(NeuroGraphConfig.maxAttemptsPerQuery);

    try {
      // Try cache first, then server
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        return _processAttempts(cacheSnapshot.docs);
      }

      // Fallback to server
      final serverSnapshot =
          await query.get(const GetOptions(source: Source.server));
      return _processAttempts(serverSnapshot.docs);
    } catch (e) {
      // If server fails, try cache again
      try {
        final cacheSnapshot =
            await query.get(const GetOptions(source: Source.cache));
        return _processAttempts(cacheSnapshot.docs);
      } catch (cacheError) {
        // Return empty list if both cache and server fail
        return [];
      }
    }
  }

  /// Get attempts for a specific test
  Future<List<Attempt>> attemptsForTest(
    String testId, {
    DateTime? from,
    NeuroGraphFilters? filters,
  }) async {
    Query query =
        _firestore.collection('attempts').where('testId', isEqualTo: testId);

    if (from != null) {
      query =
          query.where('ts', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    // Apply filters
    if (filters != null) {
      if (filters.topics.isNotEmpty) {
        query = query.where('topicId', whereIn: filters.topics);
      }
    }

    query = query.orderBy('ts', descending: true);
    query = query.limit(NeuroGraphConfig.maxAttemptsPerQuery);

    try {
      // Try cache first, then server
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        return _processAttempts(cacheSnapshot.docs);
      }

      final serverSnapshot =
          await query.get(const GetOptions(source: Source.server));
      return _processAttempts(serverSnapshot.docs);
    } catch (e) {
      try {
        final cacheSnapshot =
            await query.get(const GetOptions(source: Source.cache));
        return _processAttempts(cacheSnapshot.docs);
      } catch (cacheError) {
        return [];
      }
    }
  }

  /// Get attempts for a specific question
  Future<List<Attempt>> attemptsForQuestion(
    String questionId, {
    DateTime? from,
  }) async {
    Query query = _firestore
        .collection('attempts')
        .where('questionId', isEqualTo: questionId);

    if (from != null) {
      query =
          query.where('ts', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    query = query.orderBy('ts', descending: true);
    query = query.limit(NeuroGraphConfig.maxAttemptsPerQuery);

    try {
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        return _processAttempts(cacheSnapshot.docs);
      }

      final serverSnapshot =
          await query.get(const GetOptions(source: Source.server));
      return _processAttempts(serverSnapshot.docs);
    } catch (e) {
      try {
        final cacheSnapshot =
            await query.get(const GetOptions(source: Source.cache));
        return _processAttempts(cacheSnapshot.docs);
      } catch (cacheError) {
        return [];
      }
    }
  }

  /// Get attempts for user and topic combination
  Future<List<Attempt>> attemptsForUserAndTopic(
    String uid,
    String topicId, {
    DateTime? from,
  }) async {
    Query query = _firestore
        .collection('attempts')
        .where('userId', isEqualTo: uid)
        .where('topicId', isEqualTo: topicId);

    if (from != null) {
      query =
          query.where('ts', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    query = query.orderBy('ts', descending: true);
    query = query.limit(NeuroGraphConfig.maxAttemptsPerQuery);

    try {
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        return _processAttempts(cacheSnapshot.docs);
      }

      final serverSnapshot =
          await query.get(const GetOptions(source: Source.server));
      return _processAttempts(serverSnapshot.docs);
    } catch (e) {
      try {
        final cacheSnapshot =
            await query.get(const GetOptions(source: Source.cache));
        return _processAttempts(cacheSnapshot.docs);
      } catch (cacheError) {
        return [];
      }
    }
  }

  /// Get sessions for a user (if sessions collection exists)
  Future<List<Session>> sessionsForUser(
    String uid, {
    DateTime? from,
  }) async {
    Query query =
        _firestore.collection('sessions').where('userId', isEqualTo: uid);

    if (from != null) {
      query = query.where('startedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }

    query = query.orderBy('startedAt', descending: true);

    try {
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        return _processSessions(cacheSnapshot.docs);
      }

      final serverSnapshot =
          await query.get(const GetOptions(source: Source.server));
      return _processSessions(serverSnapshot.docs);
    } catch (e) {
      try {
        final cacheSnapshot =
            await query.get(const GetOptions(source: Source.cache));
        return _processSessions(cacheSnapshot.docs);
      } catch (cacheError) {
        return [];
      }
    }
  }

  /// Get questions metadata (if questions collection exists)
  Future<List<Question>> questionsForTopic(String topicId) async {
    final query =
        _firestore.collection('questions').where('topicId', isEqualTo: topicId);

    try {
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        return _processQuestions(cacheSnapshot.docs);
      }

      final serverSnapshot =
          await query.get(const GetOptions(source: Source.server));
      return _processQuestions(serverSnapshot.docs);
    } catch (e) {
      try {
        final cacheSnapshot =
            await query.get(const GetOptions(source: Source.cache));
        return _processQuestions(cacheSnapshot.docs);
      } catch (cacheError) {
        return [];
      }
    }
  }

  /// Get unique topics for a user
  Future<List<String>> topicsForUser(String uid) async {
    try {
      final query = _firestore
          .collection('attempts')
          .where('userId', isEqualTo: uid)
          .orderBy('topicId');

      final snapshot = await query.get(const GetOptions(source: Source.cache));

      if (snapshot.docs.isEmpty) {
        final serverSnapshot =
            await query.get(const GetOptions(source: Source.server));
        return _extractUniqueTopics(serverSnapshot.docs);
      }

      return _extractUniqueTopics(snapshot.docs);
    } catch (e) {
      return [];
    }
  }

  /// Get unique tests for a user
  Future<List<String>> testsForUser(String uid) async {
    try {
      final query = _firestore
          .collection('attempts')
          .where('userId', isEqualTo: uid)
          .orderBy('testId');

      final snapshot = await query.get(const GetOptions(source: Source.cache));

      if (snapshot.docs.isEmpty) {
        final serverSnapshot =
            await query.get(const GetOptions(source: Source.server));
        return _extractUniqueTests(serverSnapshot.docs);
      }

      return _extractUniqueTests(snapshot.docs);
    } catch (e) {
      return [];
    }
  }

  /// Process Firestore documents into Attempt objects
  List<Attempt> _processAttempts(List<DocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Attempt(
        userId: data['userId'] ?? '',
        testId: data['testId'] ?? '',
        questionId: data['questionId'] ?? '',
        topicId: data['topicId'] ?? '',
        bloom: data['bloom'],
        isCorrect: data['isCorrect'] ?? false,
        score: (data['score'] ?? 0.0).toDouble(),
        responseMs: data['responseMs'] ?? 0,
        timestamp: (data['ts'] as Timestamp).toDate(),
        confidencePct: data['confidencePct']?.toDouble(),
      );
    }).toList();
  }

  List<Session> _processSessions(List<DocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Session(
        userId: data['userId'] ?? '',
        startedAt: (data['startedAt'] as Timestamp).toDate(),
        endedAt: data['endedAt'] != null
            ? (data['endedAt'] as Timestamp).toDate()
            : null,
        itemsSeen: data['itemsSeen'] ?? 0,
        itemsCorrect: data['itemsCorrect'] ?? 0,
      );
    }).toList();
  }

  List<Question> _processQuestions(List<DocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Question(
        questionId: data['questionId'] ?? '',
        topicId: data['topicId'] ?? '',
        bloom: data['bloom'],
      );
    }).toList();
  }

  /// Extract unique topics from documents
  List<String> _extractUniqueTopics(List<DocumentSnapshot> docs) {
    final topics = <String>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['topicId'] != null) {
        topics.add(data['topicId']);
      }
    }
    return topics.toList()..sort();
  }

  /// Extract unique tests from documents
  List<String> _extractUniqueTests(List<DocumentSnapshot> docs) {
    final tests = <String>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['testId'] != null) {
        tests.add(data['testId']);
      }
    }
    return tests.toList()..sort();
  }

  /// Get data summary for a user
  Future<Map<String, dynamic>> getUserDataSummary(String uid) async {
    try {
      final attempts = await attemptsForUser(uid);

      if (attempts.isEmpty) {
        return {
          'hasData': false,
          'totalAttempts': 0,
          'totalCorrect': 0,
          'averageAccuracy': 0.0,
          'dateRange': null,
          'topics': [],
          'tests': [],
          'userTimezone': await getUserTimezone(),
        };
      }

      final totalAttempts = attempts.length;
      final totalCorrect = attempts.where((a) => a.isCorrect).length;
      final averageAccuracy =
          totalAttempts > 0 ? totalCorrect / totalAttempts : 0.0;

      final timestamps = attempts.map((a) => a.timestamp).toList();
      timestamps.sort();

      final dateRange = {
        'start': timestamps.first,
        'end': timestamps.last,
      };

      final topics = attempts.map((a) => a.topicId).toSet().toList()..sort();
      final tests = attempts.map((a) => a.testId).toSet().toList()..sort();

      return {
        'hasData': true,
        'totalAttempts': totalAttempts,
        'totalCorrect': totalCorrect,
        'averageAccuracy': averageAccuracy,
        'dateRange': dateRange,
        'topics': topics,
        'tests': tests,
        'userTimezone': await getUserTimezone(),
      };
    } catch (e) {
      debugPrint('Failed to get user data summary for $uid: $e');
      return {
        'hasData': false,
        'totalAttempts': 0,
        'totalCorrect': 0,
        'averageAccuracy': 0.0,
        'dateRange': null,
        'topics': [],
        'tests': [],
        'userTimezone': await getUserTimezone(),
      };
    }
  }
}
