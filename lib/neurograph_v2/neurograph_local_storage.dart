import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'neurograph_models.dart';
import 'neurograph_config.dart';

/// Local storage service for NeuroGraph V2 - completely offline
/// Uses SQLite for structured data and SharedPreferences for configuration
class NeuroGraphLocalStorage {
  static final NeuroGraphLocalStorage _instance =
      NeuroGraphLocalStorage._internal();
  factory NeuroGraphLocalStorage() => _instance;
  static NeuroGraphLocalStorage get instance => _instance;
  NeuroGraphLocalStorage._internal();

  Database? _database;
  bool _isInitialized = false;

  /// Initialize the local storage system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeDatabase();
      _isInitialized = true;
      debugPrint('✅ NeuroGraph V2 local storage initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize NeuroGraph V2 local storage: $e');
      rethrow;
    }
  }

  /// Initialize SQLite database
  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'neurograph_v2.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => _createTables(db, version),
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, [int? version]) async {
    // Attempts table - stores individual question attempts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        test_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        bloom TEXT,
        is_correct INTEGER NOT NULL,
        score REAL NOT NULL,
        response_ms INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        confidence_pct REAL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Sessions table - stores study sessions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL,
        items_seen INTEGER NOT NULL,
        items_correct INTEGER NOT NULL,
        test_id TEXT,
        session_type TEXT,
        subject TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Questions table - stores question metadata
    await db.execute('''
      CREATE TABLE IF NOT EXISTS questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT UNIQUE NOT NULL,
        topic_id TEXT NOT NULL,
        bloom TEXT,
        difficulty INTEGER,
        text TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attempts_user_timestamp ON attempts(user_id, timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attempts_question ON attempts(question_id, timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attempts_topic ON attempts(topic_id, timestamp)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id, started_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic_id)');
  }

  /// Upgrade database schema if needed
  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here if needed in the future
    debugPrint(
        'Upgrading NeuroGraph V2 database from $oldVersion to $newVersion');
  }

  /// Save attempt to local storage
  Future<int> saveAttempt(Attempt attempt) async {
    await _ensureInitialized();

    final id = await _database!.insert('attempts', {
      'user_id': attempt.userId,
      'test_id': attempt.testId,
      'question_id': attempt.questionId,
      'topic_id': attempt.topicId,
      'bloom': attempt.bloom,
      'is_correct': attempt.isCorrect ? 1 : 0,
      'score': attempt.score,
      'response_ms': attempt.responseMs,
      'timestamp': attempt.timestamp.millisecondsSinceEpoch,
      'confidence_pct': attempt.confidencePct,
      'synced': 0,
    });

    debugPrint('💾 Saved attempt locally: ${attempt.questionId}');
    return id;
  }

  /// Save session to local storage
  Future<int> saveSession(Session session) async {
    await _ensureInitialized();

    final id = await _database!.insert('sessions', {
      'user_id': session.userId,
      'started_at': session.startedAt.millisecondsSinceEpoch,
      'ended_at': session.endedAt.millisecondsSinceEpoch,
      'items_seen': session.itemsSeen,
      'items_correct': session.itemsCorrect,
      'test_id': session.testId,
      'session_type': session.sessionType,
      'subject': session.subject,
      'synced': 0,
    });

    debugPrint('💾 Saved session locally: ${session.testId}');
    return id;
  }

  /// Save question metadata to local storage
  Future<int> saveQuestion(Question question) async {
    await _ensureInitialized();

    final id = await _database!.insert(
      'questions',
      {
        'question_id': question.questionId,
        'topic_id': question.topicId,
        'bloom': question.bloom,
        'difficulty': question.difficulty,
        'text': question.text,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  /// Get attempts for user with optional filters
  Future<List<Attempt>> getAttemptsForUser(
    String userId, {
    DateTime? from,
    DateTime? to,
    NeuroGraphFilters? filters,
    int? limit,
  }) async {
    await _ensureInitialized();

    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (from != null) {
      whereClause += ' AND timestamp >= ?';
      whereArgs.add(from.millisecondsSinceEpoch);
    }

    if (to != null) {
      whereClause += ' AND timestamp <= ?';
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    if (filters != null) {
      if (filters.topics.isNotEmpty) {
        whereClause +=
            ' AND topic_id IN (${filters.topics.map((_) => '?').join(',')})';
        whereArgs.addAll(filters.topics);
      }
      if (filters.tests.isNotEmpty) {
        whereClause +=
            ' AND test_id IN (${filters.tests.map((_) => '?').join(',')})';
        whereArgs.addAll(filters.tests);
      }
    }

    final results = await _database!.query(
      'attempts',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit ?? NeuroGraphConfig.maxAttemptsPerQuery,
    );

    return results.map((row) => _attemptFromRow(row)).toList();
  }

  /// Get sessions for user with optional filters
  Future<List<Session>> getSessionsForUser(
    String userId, {
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    await _ensureInitialized();

    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (from != null) {
      whereClause += ' AND started_at >= ?';
      whereArgs.add(from.millisecondsSinceEpoch);
    }

    if (to != null) {
      whereClause += ' AND ended_at <= ?';
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final results = await _database!.query(
      'sessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'started_at DESC',
      limit: limit ?? 100,
    );

    return results.map((row) => _sessionFromRow(row)).toList();
  }

  /// Get questions with optional filters
  Future<List<Question>> getQuestions({
    List<String>? topicIds,
    int? limit,
  }) async {
    await _ensureInitialized();

    String? whereClause;
    List<dynamic>? whereArgs;

    if (topicIds != null && topicIds.isNotEmpty) {
      whereClause = 'topic_id IN (${topicIds.map((_) => '?').join(',')})';
      whereArgs = topicIds;
    }

    final results = await _database!.query(
      'questions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit ?? 1000,
    );

    return results.map((row) => _questionFromRow(row)).toList();
  }

  /// Get data summary for analytics
  Future<Map<String, dynamic>> getDataSummary(String userId) async {
    await _ensureInitialized();

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get attempt counts
    final attemptCount = await _database!.rawQuery('''
      SELECT COUNT(*) as total,
             SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM attempts 
      WHERE user_id = ? AND timestamp >= ?
    ''', [userId, thirtyDaysAgo.millisecondsSinceEpoch]);

    // Get session counts
    final sessionCount = await _database!.rawQuery('''
      SELECT COUNT(*) as total,
             AVG(items_correct * 1.0 / items_seen) as avg_accuracy
      FROM sessions 
      WHERE user_id = ? AND started_at >= ?
    ''', [userId, thirtyDaysAgo.millisecondsSinceEpoch]);

    // Get topic breakdown
    final topicBreakdown = await _database!.rawQuery('''
      SELECT topic_id, 
             COUNT(*) as attempts,
             SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM attempts 
      WHERE user_id = ? AND timestamp >= ?
      GROUP BY topic_id
      ORDER BY attempts DESC
      LIMIT 10
    ''', [userId, thirtyDaysAgo.millisecondsSinceEpoch]);

    return {
      'totalAttempts': attemptCount.first['total'] ?? 0,
      'correctAttempts': attemptCount.first['correct'] ?? 0,
      'totalSessions': sessionCount.first['total'] ?? 0,
      'averageAccuracy': sessionCount.first['avg_accuracy'] ?? 0.0,
      'topicBreakdown': topicBreakdown,
      'dataAvailable': (attemptCount.first['total'] as int? ?? 0) > 0,
      'lastUpdated': now.toIso8601String(),
    };
  }

  /// Clear all local data (for testing or reset)
  Future<void> clearAllData() async {
    await _ensureInitialized();

    await _database!.delete('attempts');
    await _database!.delete('sessions');
    await _database!.delete('questions');

    debugPrint('🗑️ Cleared all NeuroGraph V2 local data');
  }

  /// Get unsynced data for background sync
  Future<Map<String, List<Map<String, dynamic>>>> getUnsyncedData() async {
    await _ensureInitialized();

    final unsyncedAttempts = await _database!.query(
      'attempts',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );

    final unsyncedSessions = await _database!.query(
      'sessions',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );

    final unsyncedQuestions = await _database!.query(
      'questions',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );

    return {
      'attempts': unsyncedAttempts,
      'sessions': unsyncedSessions,
      'questions': unsyncedQuestions,
    };
  }

  /// Mark data as synced
  Future<void> markAsSynced(String table, List<int> ids) async {
    await _ensureInitialized();

    if (ids.isEmpty) return;

    await _database!.update(
      table,
      {'synced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// Create sample data for testing
  Future<void> createSampleData(String userId) async {
    await _ensureInitialized();

    final now = DateTime.now();
    final topics = [
      'mathematics',
      'science',
      'history',
      'literature',
      'geography'
    ];
    final tests = ['quiz_math_1', 'quiz_science_1', 'quiz_history_1'];

    // Generate 50 sample attempts over the last 30 days
    for (int i = 0; i < 50; i++) {
      final daysAgo = i % 30;
      final timestamp = now.subtract(Duration(days: daysAgo));
      final topicId = topics[i % topics.length];
      final testId = tests[i % tests.length];
      final questionId = 'sample_q_${i}_$topicId';

      // Simulate learning curve - better performance over time
      final progressFactor = (30 - daysAgo) / 30.0;
      final baseAccuracy = 0.5 + (progressFactor * 0.4); // 50% to 90%
      final isCorrect = (i / 50.0) < baseAccuracy;

      final attempt = Attempt(
        userId: userId,
        testId: testId,
        questionId: questionId,
        topicId: topicId,
        bloom: ['remember', 'understand', 'apply', 'analyze'][i % 4],
        isCorrect: isCorrect,
        score:
            isCorrect ? (0.7 + (0.3 * (i / 50.0))) : (0.1 + (0.4 * (i / 50.0))),
        responseMs: 1500 + (i * 100),
        timestamp: timestamp,
        confidencePct:
            isCorrect ? (60 + (40 * (i / 50.0))) : (20 + (30 * (i / 50.0))),
      );

      await saveAttempt(attempt);

      // Create question if it doesn't exist
      final question = Question(
        questionId: questionId,
        topicId: topicId,
        bloom: attempt.bloom,
        difficulty: (i % 5) + 1,
        text: 'Sample question ${i + 1} for $topicId',
      );

      await saveQuestion(question);
    }

    // Create sample sessions
    for (int i = 0; i < 10; i++) {
      final daysAgo = i * 3;
      final startTime = now.subtract(Duration(days: daysAgo, hours: 1));
      final endTime = startTime.add(const Duration(minutes: 30));
      final correctAnswers = 3 + (i % 3);
      final totalQuestions = 5;

      final session = Session(
        userId: userId,
        startedAt: startTime,
        endedAt: endTime,
        itemsSeen: totalQuestions,
        itemsCorrect: correctAnswers,
        testId: tests[i % tests.length],
        sessionType: 'quiz',
        subject: topics[i % topics.length],
      );

      await saveSession(session);
    }

    debugPrint('✅ Created sample NeuroGraph V2 data locally');
  }

  /// Convert database row to Attempt object
  Attempt _attemptFromRow(Map<String, dynamic> row) {
    return Attempt(
      userId: row['user_id'],
      testId: row['test_id'],
      questionId: row['question_id'],
      topicId: row['topic_id'],
      bloom: row['bloom'],
      isCorrect: row['is_correct'] == 1,
      score: row['score'].toDouble(),
      responseMs: row['response_ms'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp']),
      confidencePct: row['confidence_pct']?.toDouble(),
    );
  }

  /// Convert database row to Session object
  Session _sessionFromRow(Map<String, dynamic> row) {
    return Session(
      userId: row['user_id'],
      startedAt: DateTime.fromMillisecondsSinceEpoch(row['started_at']),
      endedAt: DateTime.fromMillisecondsSinceEpoch(row['ended_at']),
      itemsSeen: row['items_seen'],
      itemsCorrect: row['items_correct'],
      testId: row['test_id'],
      sessionType: row['session_type'],
      subject: row['subject'],
    );
  }

  /// Convert database row to Question object
  Question _questionFromRow(Map<String, dynamic> row) {
    return Question(
      questionId: row['question_id'],
      topicId: row['topic_id'],
      bloom: row['bloom'],
      difficulty: row['difficulty'],
      text: row['text'],
    );
  }

  /// Ensure database is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }
}
