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
    debugPrint('🔍 Querying attempts for user: $uid');
    
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
      debugPrint('📱 Trying cache first for user $uid');
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isNotEmpty) {
        debugPrint('✅ Found ${cacheSnapshot.docs.length} cached attempts');
        return _processAttempts(cacheSnapshot.docs);
      }

      // Fallback to server
      debugPrint('🌐 Cache empty, trying server for user $uid');
      final serverSnapshot =
          await query.get(const GetOptions(source: Source.server));
      debugPrint('✅ Found ${serverSnapshot.docs.length} server attempts');
      return _processAttempts(serverSnapshot.docs);
    } catch (e) {
      debugPrint('❌ Server query failed for user $uid: $e');
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
      debugPrint('🔍 Getting user data summary for uid: $uid');
      final attempts = await attemptsForUser(uid);
      debugPrint('📊 Found ${attempts.length} attempts for user $uid');

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
      debugPrint('❌ Failed to get user data summary for $uid: $e');
      return {
        'hasData': false,
        'totalAttempts': 0,
        'totalCorrect': 0,
        'averageAccuracy': 0.0,
        'dateRange': null,
        'topics': [],
        'tests': [],
        'userTimezone': await getUserTimezone(),
        'error': e.toString(),
      };
    }
  }

  /// Create sample data for testing purposes
  Future<void> createSampleData(String uid) async {
    debugPrint('🧪 Creating sample data for user: $uid');
    
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    // Create sample topics and tests
    final topics = ['math', 'science', 'history', 'literature'];
    final tests = ['quiz_1', 'quiz_2', 'midterm', 'final'];
    
    // Generate 50 sample attempts over the last 30 days
    for (int i = 0; i < 50; i++) {
      final daysAgo = i % 30;
      final timestamp = now.subtract(Duration(days: daysAgo));
      final topicId = topics[i % topics.length];
      final testId = tests[i % tests.length];
      final questionId = 'q_${i}_$topicId';
      
      // Simulate learning curve - better performance over time
      final progressFactor = (30 - daysAgo) / 30.0;
      final baseAccuracy = 0.6 + (progressFactor * 0.3); // 60% to 90%
      final isCorrect = (i / 50.0) < baseAccuracy;
      
      final attemptRef = _firestore.collection('attempts').doc();
      batch.set(attemptRef, {
        'userId': uid,
        'testId': testId,
        'questionId': questionId,
        'topicId': topicId,
        'bloom': ['remember', 'understand', 'apply', 'analyze'][i % 4],
        'isCorrect': isCorrect,
        'score': isCorrect ? (0.8 + (0.2 * (i / 50.0))) : (0.2 + (0.3 * (i / 50.0))),
        'responseMs': 2000 + (i * 100), // Response time varies
        'ts': Timestamp.fromDate(timestamp),
        'confidence': isCorrect ? (0.7 + (0.3 * (i / 50.0))) : (0.3 + (0.4 * (i / 50.0))),
      });
    }
    
    // Create sample questions
    for (int i = 0; i < 20; i++) {
      final topicId = topics[i % topics.length];
      final questionId = 'q_${i}_$topicId';
      
      final questionRef = _firestore.collection('questions').doc(questionId);
      batch.set(questionRef, {
        'questionId': questionId,
        'topicId': topicId,
        'bloom': ['remember', 'understand', 'apply', 'analyze'][i % 4],
        'difficulty': (i % 5) + 1, // 1-5 difficulty
        'text': 'Sample question ${i + 1} for $topicId',
      });
    }
    
    // Create sample sessions
    for (int i = 0; i < 10; i++) {
      final daysAgo = i * 3;
      final startTime = now.subtract(Duration(days: daysAgo, hours: 1));
      final endTime = startTime.add(const Duration(minutes: 30));
      
      final sessionRef = _firestore.collection('sessions').doc();
      batch.set(sessionRef, {
        'userId': uid,
        'startedAt': Timestamp.fromDate(startTime),
        'endedAt': Timestamp.fromDate(endTime),
        'itemsSeen': 5 + (i % 10),
        'itemsCorrect': 3 + (i % 7),
        'sessionType': ['study', 'quiz', 'review'][i % 3],
      });
    }
    
    await batch.commit();
    debugPrint('✅ Sample data created successfully for user: $uid');
  }
}
