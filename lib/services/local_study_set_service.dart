import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Local Study Set Service
/// Handles storage of study sets and items generated from URLs
/// Ensures offline functionality for generated content
class LocalStudySetService {
  static final LocalStudySetService _instance = LocalStudySetService._internal();
  factory LocalStudySetService() => _instance;
  static LocalStudySetService get instance => _instance;
  LocalStudySetService._internal();

  Database? _database;
  bool _isInitialized = false;

  /// Initialize the local database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'local_study_sets.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
      );

      _isInitialized = true;
      debugPrint('✅ LocalStudySetService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize LocalStudySetService: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Study sets table
    await db.execute('''
      CREATE TABLE study_sets (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        sourceUrl TEXT,
        preview TEXT,
        itemCount INTEGER NOT NULL,
        userId TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isGenerated INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Study items table
    await db.execute('''
      CREATE TABLE study_items (
        id TEXT PRIMARY KEY,
        studySetId TEXT NOT NULL,
        type TEXT NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        options TEXT,
        explanation TEXT,
        difficulty TEXT DEFAULT 'medium',
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (studySetId) REFERENCES study_sets (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_study_sets_user_id ON study_sets (userId)');
    await db.execute('CREATE INDEX idx_study_items_set_id ON study_items (studySetId)');
  }

  /// Save a study set and its items locally
  Future<void> saveStudySetLocally({
    required String studySetId,
    required String title,
    required String sourceUrl,
    required String preview,
    required int itemCount,
    required String userId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _database!.transaction((txn) async {
        // Save study set
        await txn.insert(
          'study_sets',
          {
            'id': studySetId,
            'title': title,
            'sourceUrl': sourceUrl,
            'preview': preview,
            'itemCount': itemCount,
            'userId': userId,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
            'isGenerated': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Save study items
        for (final item in items) {
          await txn.insert(
            'study_items',
            {
              'id': '${studySetId}_${item['question'].hashCode}',
              'studySetId': studySetId,
              'type': item['type'],
              'question': item['question'],
              'answer': item['answer'],
              'options': item['options'] != null 
                  ? (item['options'] as List).join('|')
                  : null,
              'explanation': item['explanation'],
              'difficulty': item['difficulty'] ?? 'medium',
              'createdAt': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      debugPrint('✅ Saved study set locally: $studySetId with ${items.length} items');
    } catch (e) {
      debugPrint('❌ Failed to save study set locally: $e');
      rethrow;
    }
  }

  /// Get all study sets for a user
  Future<List<Map<String, dynamic>>> getStudySets(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      final results = await _database!.query(
        'study_sets',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );

      return results.map((row) => {
        ...row,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
        'updatedAt': DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int),
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get study sets: $e');
      return [];
    }
  }

  /// Get all items for a study set
  Future<List<Map<String, dynamic>>> getStudyItems(String studySetId) async {
    if (!_isInitialized) await initialize();

    try {
      final results = await _database!.query(
        'study_items',
        where: 'studySetId = ?',
        whereArgs: [studySetId],
        orderBy: 'createdAt ASC',
      );

      return results.map((row) {
        final options = row['options'] as String?;
        return {
          ...row,
          'options': options != null ? options.split('|') : [],
          'createdAt': DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get study items: $e');
      return [];
    }
  }

  /// Delete a study set and all its items
  Future<void> deleteStudySet(String studySetId) async {
    if (!_isInitialized) await initialize();

    try {
      await _database!.transaction((txn) async {
        // Delete items first (due to foreign key constraint)
        await txn.delete(
          'study_items',
          where: 'studySetId = ?',
          whereArgs: [studySetId],
        );

        // Delete study set
        await txn.delete(
          'study_sets',
          where: 'id = ?',
          whereArgs: [studySetId],
        );
      });

      debugPrint('✅ Deleted study set: $studySetId');
    } catch (e) {
      debugPrint('❌ Failed to delete study set: $e');
      rethrow;
    }
  }

  /// Clear all data for a user
  Future<void> clearUserData(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      await _database!.transaction((txn) async {
        // Get all study set IDs for the user
        final studySets = await txn.query(
          'study_sets',
          columns: ['id'],
          where: 'userId = ?',
          whereArgs: [userId],
        );

        final studySetIds = studySets.map((row) => row['id'] as String).toList();

        // Delete all items for these study sets
        for (final studySetId in studySetIds) {
          await txn.delete(
            'study_items',
            where: 'studySetId = ?',
            whereArgs: [studySetId],
          );
        }

        // Delete all study sets for the user
        await txn.delete(
          'study_sets',
          where: 'userId = ?',
          whereArgs: [userId],
        );
      });

      debugPrint('✅ Cleared all study set data for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to clear user data: $e');
      rethrow;
    }
  }

  /// Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }
}
