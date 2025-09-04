import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/config/storage_config.dart';
import 'package:mindload/models/storage_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:mindload/services/mindload_notification_service.dart';

/// Unified Storage Service
/// Consolidates all study set storage into one system
/// Ensures all study sets (URL-generated, manually created, YouTube, etc.) are stored in the same location
class UnifiedStorageService extends ChangeNotifier {
  static final UnifiedStorageService _instance =
      UnifiedStorageService._internal();
  factory UnifiedStorageService() => _instance;
  static UnifiedStorageService get instance => _instance;
  UnifiedStorageService._internal();

  // Storage state
  final Map<String, StudySetMetadata> _metadata = {};
  final Map<String, StudySet> _fullStudySets = {};
  StorageTotals _totals = StorageTotals(
    totalBytes: 0,
    totalSets: 0,
    totalItems: 0,
    lastUpdated: DateTime.now(),
  );

  // Database
  Database? _database;
  bool _isInitialized = false;

  // File names
  final String _metadataFileName = 'unified_study_sets_metadata.json';
  final String _totalsFileName = 'unified_storage_totals.json';

  // Check if running on web
  bool get _isWeb => kIsWeb;

  // Getters
  StorageTotals get totals => _totals;
  Map<String, StudySetMetadata> get metadata => Map.unmodifiable(_metadata);
  Map<String, StudySet> get fullStudySets => Map.unmodifiable(_fullStudySets);
  bool get isStorageWarning => StorageConfig.isStorageWarning(
      _totals.getUsagePercentage(StorageConfig.storageBudgetMB));
  bool get isInitialized => _isInitialized;

  /// Initialize the unified storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize database
      await _initializeDatabase();

      // Load data
      if (_isWeb) {
        await _loadMetadataWeb();
        await _loadTotalsWeb();
      } else {
        await _loadMetadata();
        await _loadTotals();
      }

      // Load full study sets into memory for better performance
      await _loadFullStudySetsIntoMemory();

      // Clean up any duplicate study sets
      await cleanupDuplicates();

      // Check if we need to evict
      await _checkAndEvictIfNeeded();

      _isInitialized = true;
      debugPrint('✅ Unified storage service initialized');
    } catch (e) {
      debugPrint('⚠️ Unified storage service initialization failed: $e');
      // Continue with empty state
    }
  }

  /// Initialize SQLite database
  Future<void> _initializeDatabase() async {
    if (_isWeb) return; // Web doesn't use SQLite

    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'unified_study_sets.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );

      debugPrint('✅ Unified storage database initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize database: $e');
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
        content TEXT,
        sourceUrl TEXT,
        preview TEXT,
        itemCount INTEGER NOT NULL,
        userId TEXT NOT NULL,
        isPinned INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        bytes INTEGER NOT NULL DEFAULT 0,
        lastOpenedAt INTEGER NOT NULL,
        lastStudied INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isGenerated INTEGER NOT NULL DEFAULT 0
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

    // Quizzes table
    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        studySetId TEXT NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        createdDate INTEGER NOT NULL,
        data TEXT NOT NULL,
        FOREIGN KEY (studySetId) REFERENCES study_sets (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db
        .execute('CREATE INDEX idx_study_sets_user_id ON study_sets (userId)');
    await db.execute(
        'CREATE INDEX idx_study_sets_last_opened ON study_sets (lastOpenedAt)');
    await db.execute(
        'CREATE INDEX idx_study_items_set_id ON study_items (studySetId)');
    await db.execute(
        'CREATE INDEX idx_quizzes_set_id ON quizzes (studySetId)');
  }

  /// Upgrade database
  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Handle future database upgrades here
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');
  }

  /// Load full study sets into memory for better performance
  Future<void> _loadFullStudySetsIntoMemory() async {
    try {
      _fullStudySets.clear();

      for (final metadata in _metadata.values) {
        final studySet = await _loadFullStudySetFromStorage(metadata.setId);
        if (studySet != null) {
          _fullStudySets[metadata.setId] = studySet;
        }
      }

      debugPrint('📚 Loaded ${_fullStudySets.length} study sets into memory');
    } catch (e) {
      debugPrint('❌ Failed to load study sets into memory: $e');
    }
  }

  /// Add study set (unified method for all types)
  Future<bool> addStudySet(StudySet studySet) async {
    try {
      // Check for ID collision and generate unique ID if needed
      String uniqueId = studySet.id;
      if (_metadata.containsKey(uniqueId) ||
          _fullStudySets.containsKey(uniqueId)) {
        int counter = 1;
        do {
          uniqueId = '${studySet.id}_$counter';
          counter++;
        } while (_metadata.containsKey(uniqueId) ||
            _fullStudySets.containsKey(uniqueId));

        debugPrint(
            '⚠️ ID collision detected for ${studySet.id}, using unique ID: $uniqueId');
        studySet = studySet.copyWith(id: uniqueId);
      }

      final metadata = studySet.toMetadata();

      // Add to local storage immediately
      _metadata[metadata.setId] = metadata;
      _fullStudySets[studySet.id] = studySet;
      _updateTotals();

      // Save to storage
      await _saveStudySetToStorage(studySet);
      await _saveMetadata();
      await _saveTotals();

      notifyListeners();
      debugPrint('✅ Study set added with ID: ${studySet.id}');

      // Fire first-run notification if this is the first study set
      if (studySet.flashcards.isNotEmpty || studySet.quizQuestions.isNotEmpty) {
        try {
          await MindLoadNotificationService
              .fireFirstStudySetNotificationIfNeeded();
        } catch (e) {
          debugPrint('Failed to fire first study set notification: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Failed to add study set: $e');
      return false;
    }
  }

  /// Save study set from URL generation (compatibility method)
  Future<void> saveStudySetFromUrl({
    required String studySetId,
    required String title,
    required String sourceUrl,
    required String preview,
    required int itemCount,
    required String userId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Convert items to StudySet format
      final flashcards = <Flashcard>[];
      final quizQuestions = <QuizQuestion>[];

      for (final itemData in items) {
        // itemData is already Map<String, dynamic> from the method signature
        final item = itemData;

        // Validate required fields
        final question = item['question']?.toString();
        final answer = item['answer']?.toString();
        final type = item['type']?.toString();

        if (question == null || answer == null || type == null) {
          debugPrint('⚠️ Skipping invalid item: missing required fields');
          continue;
        }

        switch (type) {
          case 'flashcard':
            flashcards.add(Flashcard(
              id: '${studySetId}_${question.hashCode}',
              question: question,
              answer: answer,
              difficulty:
                  _mapDifficulty(item['difficulty']?.toString() ?? 'medium'),
            ));
            break;
          case 'multiple_choice':
          case 'short_answer':
            final options = item['options'];
            final optionsList = <String>[];

            if (options is List) {
              optionsList.addAll(options.map((e) => e.toString()));
            } else if (options is String && options.isNotEmpty) {
              optionsList.addAll(options.split('|'));
            }

            quizQuestions.add(QuizQuestion(
              id: '${studySetId}_${question.hashCode}',
              question: question,
              correctAnswer: answer,
              options: optionsList,
              difficulty:
                  _mapDifficulty(item['difficulty']?.toString() ?? 'medium'),
              explanation: item['explanation']?.toString(),
              type: type == 'multiple_choice'
                  ? QuestionType.multipleChoice
                  : QuestionType.shortAnswer,
            ));
            break;
          default:
            debugPrint('⚠️ Unknown item type: $type');
        }
      }

      // Create StudySet
      final studySet = StudySet(
        id: studySetId,
        title: title,
        content: preview,
        flashcards: flashcards,
        quizQuestions: quizQuestions,
        createdDate: DateTime.now(),
        lastStudied: DateTime.now(),
        sourceUrl: sourceUrl,
      );

      // Add to unified storage
      await addStudySet(studySet);
    } catch (e) {
      debugPrint('❌ Failed to save study set from URL: $e');
      rethrow;
    }
  }

  /// Map difficulty string to DifficultyLevel enum
  DifficultyLevel _mapDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.beginner;
      case 'medium':
        return DifficultyLevel.intermediate;
      case 'hard':
        return DifficultyLevel.advanced;
      case 'expert':
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.intermediate;
    }
  }

  /// Update study set
  Future<bool> updateStudySet(StudySet studySet) async {
    try {
      final metadata = studySet.toMetadata();

      // Update local storage immediately
      _metadata[metadata.setId] = metadata;
      _fullStudySets[studySet.id] = studySet;
      _updateTotals();

      // Save to storage
      await _saveStudySetToStorage(studySet);
      await _saveMetadata();
      await _saveTotals();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update study set: $e');
      return false;
    }
  }

  /// Delete study set
  Future<bool> deleteStudySet(String setId) async {
    try {
      // Remove from local storage immediately
      _metadata.remove(setId);
      _fullStudySets.remove(setId);
      _updateTotals();

      // Delete from storage
      await _deleteStudySetFromStorage(setId);
      await _saveMetadata();
      await _saveTotals();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete study set: $e');
      return false;
    }
  }

  /// Get study set
  Future<StudySet?> getStudySet(String setId) async {
    try {
      // First try to get from memory
      if (_fullStudySets.containsKey(setId)) {
        return _fullStudySets[setId];
      }

      // Then try to load from storage
      final studySet = await _loadFullStudySetFromStorage(setId);
      if (studySet != null) {
        _fullStudySets[setId] = studySet;
        return studySet;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Failed to get study set: $e');
      return null;
    }
  }

  /// Get all study sets for a user
  Future<List<StudySet>> getStudySets(String userId) async {
    try {
      final studySets = <StudySet>[];

      for (final metadata in _metadata.values) {
        if (metadata.setId.contains(userId) ||
            metadata.setId.startsWith(userId)) {
          final studySet = await getStudySet(metadata.setId);
          if (studySet != null) {
            studySets.add(studySet);
          }
        }
      }

      return studySets;
    } catch (e) {
      debugPrint('❌ Failed to get study sets: $e');
      return [];
    }
  }

  /// Get all study sets
  Future<List<StudySet>> getAllStudySets() async {
    try {
      final studySets = <StudySet>[];

      for (final metadata in _metadata.values) {
        final studySet = await getStudySet(metadata.setId);
        if (studySet != null) {
          studySets.add(studySet);
        }
      }

      return studySets;
    } catch (e) {
      debugPrint('❌ Failed to get all study sets: $e');
      return [];
    }
  }

  /// Pin/unpin study set
  /// Toggle pin status of a study set
  Future<bool> togglePin(String setId) async {
    try {
      if (_metadata.containsKey(setId)) {
        final currentMetadata = _metadata[setId]!;
        final newPinStatus = !currentMetadata.isPinned;
        return await pinStudySet(setId, newPinStatus);
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to toggle pin for set $setId: $e');
      return false;
    }
  }

  Future<bool> pinStudySet(String setId, bool isPinned) async {
    try {
      final studySet = await getStudySet(setId);
      if (studySet == null) return false;

      // Note: StudySet doesn't have isPinned property, so we'll store it in metadata
      final metadata = studySet.toMetadata();
      final updatedMetadata = StudySetMetadata(
        setId: metadata.setId,
        title: metadata.title,
        content: metadata.content,
        isPinned: isPinned,
        bytes: metadata.bytes,
        items: metadata.items,
        lastOpenedAt: metadata.lastOpenedAt,
        lastStudied: metadata.lastStudied,
        createdAt: metadata.createdAt,
        updatedAt: metadata.updatedAt,
        isArchived: metadata.isArchived,
      );

      _metadata[setId] = updatedMetadata;
      await _saveMetadata();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to pin/unpin study set: $e');
      return false;
    }
  }

  /// Clean up duplicate study sets
  Future<void> cleanupDuplicates() async {
    try {
      final seenTitles = <String, String>{}; // title -> first ID
      final duplicatesToRemove = <String>[];

      // Find duplicates based on title and creation time (within 1 second)
      for (final metadata in _metadata.values) {
        final key =
            '${metadata.title}_${metadata.createdAt.millisecondsSinceEpoch ~/ 1000}';
        if (seenTitles.containsKey(key)) {
          duplicatesToRemove.add(metadata.setId);
        } else {
          seenTitles[key] = metadata.setId;
        }
      }

      // Remove duplicates
      for (final setId in duplicatesToRemove) {
        await deleteStudySet(setId);
      }

      if (duplicatesToRemove.isNotEmpty) {
        debugPrint(
            '🧹 Cleaned up ${duplicatesToRemove.length} duplicate study sets');
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup duplicates: $e');
    }
  }

  /// Check and evict if needed
  Future<void> _checkAndEvictIfNeeded() async {
    try {
      if (_totals.getUsagePercentage(StorageConfig.storageBudgetMB) > 0.9) {
        await _evictOldestStudySets();
      }
    } catch (e) {
      debugPrint('❌ Failed to check and evict: $e');
    }
  }

  /// Evict oldest study sets
  Future<void> _evictOldestStudySets() async {
    try {
      final unpinnedSets = _metadata.values
          .where((metadata) => !metadata.isPinned)
          .toList()
        ..sort((a, b) => a.lastOpenedAt.compareTo(b.lastOpenedAt));

      // Use a fixed batch size since evictBatch is not available
      const evictBatchSize = 50;
      final setsToEvict = unpinnedSets.take(evictBatchSize).toList();

      for (final metadata in setsToEvict) {
        await deleteStudySet(metadata.setId);
      }

      if (setsToEvict.isNotEmpty) {
        debugPrint('🗑️ Evicted ${setsToEvict.length} oldest study sets');
      }
    } catch (e) {
      debugPrint('❌ Failed to evict oldest study sets: $e');
    }
  }

  /// Update totals
  void _updateTotals() {
    int totalBytes = 0;
    int totalItems = 0;

    for (final metadata in _metadata.values) {
      totalBytes += metadata.bytes;
      totalItems += metadata.items;
    }

    _totals = StorageTotals(
      totalBytes: totalBytes,
      totalSets: _metadata.length,
      totalItems: totalItems,
      lastUpdated: DateTime.now(),
    );
  }

  /// Save study set to storage
  Future<void> _saveStudySetToStorage(StudySet studySet) async {
    try {
      final studySetData = studySet.toJson();

      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'unified_study_set_${studySet.id}', jsonEncode(studySetData));
      } else {
        // Use SQLite for native platforms
        if (_database != null) {
          await _database!.transaction((txn) async {
            // Save study set
            await txn.insert(
              'study_sets',
              {
                'id': studySet.id,
                'title': studySet.title,
                'content': studySet.content,
                'sourceUrl': studySet.sourceUrl,
                'preview': studySet.content.substring(0, 200),
                'itemCount':
                    studySet.flashcards.length + studySet.quizQuestions.length,
                'userId': studySet.id
                    .split('_')
                    .first, // Extract user ID from study set ID
                'isPinned': 0, // Default to unpinned
                'isArchived': 0,
                'bytes': jsonEncode(studySetData).length,
                'lastOpenedAt': studySet.lastStudied.millisecondsSinceEpoch,
                'lastStudied': studySet.lastStudied.millisecondsSinceEpoch,
                'createdAt': studySet.createdDate.millisecondsSinceEpoch,
                'updatedAt': studySet.lastStudied.millisecondsSinceEpoch,
                'isGenerated': 1,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Save flashcards
            for (final flashcard in studySet.flashcards) {
              await txn.insert(
                'study_items',
                {
                  'id': flashcard.id,
                  'studySetId': studySet.id,
                  'type': 'flashcard',
                  'question': flashcard.question,
                  'answer': flashcard.answer,
                  'options': null,
                  'explanation': null, // Flashcard doesn't have explanation
                  'difficulty': flashcard.difficulty.name,
                  'createdAt': studySet.createdDate.millisecondsSinceEpoch,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }

            // Save quiz questions
            for (final question in studySet.quizQuestions) {
              await txn.insert(
                'study_items',
                {
                  'id': question.id,
                  'studySetId': studySet.id,
                  'type': question.type.name,
                  'question': question.question,
                  'answer': question.correctAnswer,
                  'options': question.options.join('|'),
                  'explanation': question.explanation,
                  'difficulty': question.difficulty.name,
                  'createdAt': studySet.createdDate.millisecondsSinceEpoch,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }

            // Save full quiz objects
            for (final quiz in studySet.quizzes) {
              await txn.insert(
                'quizzes',
                {
                  'id': quiz.id,
                  'studySetId': studySet.id,
                  'title': quiz.title,
                  'type': quiz.type.name,
                  'createdDate': quiz.createdDate.millisecondsSinceEpoch,
                  'data': jsonEncode(quiz.toJson()),
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to save study set to storage: $e');
      rethrow;
    }
  }

  /// Load study set from storage
  Future<StudySet?> _loadFullStudySetFromStorage(String setId) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        final studySetData = prefs.getString('unified_study_set_$setId');
        if (studySetData != null) {
          final jsonData = jsonDecode(studySetData) as Map<String, dynamic>;
          return StudySet.fromJson(jsonData);
        }
      } else {
        // Use SQLite for native platforms
        if (_database != null) {
          final studySetRows = await _database!.query(
            'study_sets',
            where: 'id = ?',
            whereArgs: [setId],
          );

          if (studySetRows.isNotEmpty) {
            final studySetRow = studySetRows.first;
            final itemRows = await _database!.query(
              'study_items',
              where: 'studySetId = ?',
              whereArgs: [setId],
            );

            final flashcards = <Flashcard>[];
            final quizQuestions = <QuizQuestion>[];
            final quizzes = <Quiz>[];

            for (final itemRow in itemRows) {
              switch (itemRow['type']) {
                case 'flashcard':
                  flashcards.add(Flashcard(
                    id: itemRow['id'] as String,
                    question: itemRow['question'] as String,
                    answer: itemRow['answer'] as String,
                    difficulty: DifficultyLevel.values.firstWhere(
                      (e) =>
                          e.name ==
                          (itemRow['difficulty'] as String? ?? 'intermediate'),
                    ),
                  ));
                  break;
                case 'multipleChoice':
                case 'shortAnswer':
                  final options =
                      (itemRow['options'] as String?)?.split('|') ?? [];
                  quizQuestions.add(QuizQuestion(
                    id: itemRow['id'] as String,
                    question: itemRow['question'] as String,
                    correctAnswer: itemRow['answer'] as String,
                    options: options,
                    difficulty: DifficultyLevel.values.firstWhere(
                      (e) =>
                          e.name ==
                          (itemRow['difficulty'] as String? ?? 'intermediate'),
                    ),
                    explanation: itemRow['explanation'] as String?,
                    type: itemRow['type'] == 'multipleChoice'
                        ? QuestionType.multipleChoice
                        : QuestionType.shortAnswer,
                  ));
                  break;
              }
            }

            // Load full quiz objects
            final quizRows = await _database!.query(
              'quizzes',
              where: 'studySetId = ?',
              whereArgs: [setId],
            );

            for (final quizRow in quizRows) {
              final quizData = jsonDecode(quizRow['data'] as String);
              quizzes.add(Quiz.fromJson(quizData));
            }

            return StudySet(
              id: studySetRow['id'] as String,
              title: studySetRow['title'] as String,
              content: studySetRow['content'] as String? ?? '',
              flashcards: flashcards,
              quizQuestions: quizQuestions,
              quizzes: quizzes,
              createdDate: DateTime.fromMillisecondsSinceEpoch(
                  studySetRow['createdAt'] as int),
              lastStudied: DateTime.fromMillisecondsSinceEpoch(
                  studySetRow['lastStudied'] as int),
              sourceUrl: studySetRow['sourceUrl'] as String?,
            );
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to load study set from storage: $e');
      return null;
    }
  }

  /// Delete study set from storage
  Future<void> _deleteStudySetFromStorage(String setId) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('unified_study_set_$setId');
      } else {
        if (_database != null) {
          await _database!.transaction((txn) async {
                      await txn.delete('study_items',
              where: 'studySetId = ?', whereArgs: [setId]);
          await txn.delete('quizzes',
              where: 'studySetId = ?', whereArgs: [setId]);
          await txn.delete('study_sets', where: 'id = ?', whereArgs: [setId]);
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to delete study set from storage: $e');
    }
  }

  /// Save metadata
  Future<void> _saveMetadata() async {
    try {
      final metadataJson =
          _metadata.map((key, value) => MapEntry(key, value.toJson()));
      final data = jsonEncode(metadataJson);

      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_metadataFileName, data);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_metadataFileName');
        await file.writeAsString(data);
      }
    } catch (e) {
      debugPrint('❌ Failed to save metadata: $e');
    }
  }

  /// Load metadata
  Future<void> _loadMetadata() async {
    try {
      String? data;
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        data = prefs.getString(_metadataFileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_metadataFileName');
        if (await file.exists()) {
          data = await file.readAsString();
        }
      }

      if (data != null) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        _metadata.clear();
        for (final entry in jsonData.entries) {
          _metadata[entry.key] =
              StudySetMetadata.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load metadata: $e');
    }
  }

  /// Load metadata (web)
  Future<void> _loadMetadataWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_metadataFileName);
      if (data != null) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        _metadata.clear();
        for (final entry in jsonData.entries) {
          _metadata[entry.key] =
              StudySetMetadata.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load metadata (web): $e');
    }
  }

  /// Save totals
  Future<void> _saveTotals() async {
    try {
      final data = jsonEncode(_totals.toJson());

      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_totalsFileName, data);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_totalsFileName');
        await file.writeAsString(data);
      }
    } catch (e) {
      debugPrint('❌ Failed to save totals: $e');
    }
  }

  /// Load totals
  Future<void> _loadTotals() async {
    try {
      String? data;
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        data = prefs.getString(_totalsFileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_totalsFileName');
        if (await file.exists()) {
          data = await file.readAsString();
        }
      }

      if (data != null) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        _totals = StorageTotals.fromJson(jsonData);
      }
    } catch (e) {
      debugPrint('❌ Failed to load totals: $e');
    }
  }

  /// Load totals (web)
  Future<void> _loadTotalsWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_totalsFileName);
      if (data != null) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        _totals = StorageTotals.fromJson(jsonData);
      }
    } catch (e) {
      debugPrint('❌ Failed to load totals (web): $e');
    }
  }

  /// Auth-related methods for compatibility with AuthService
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_data', jsonEncode(userData));
      debugPrint('✅ User data saved');
    } catch (e) {
      debugPrint('❌ Failed to save user data: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('auth_user_data');
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get user data: $e');
      return null;
    }
  }

  Future<void> setAuthenticated(bool isAuthenticated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_authenticated', isAuthenticated);
      debugPrint('✅ Authentication status set: $isAuthenticated');
    } catch (e) {
      debugPrint('❌ Failed to set authentication status: $e');
    }
  }

  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_data');
      await prefs.remove('auth_is_authenticated');
      debugPrint('✅ User data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear user data: $e');
    }
  }

  /// Generic JSON data storage methods for compatibility with other services
  Future<Map<String, dynamic>?> getJsonData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get JSON data for key $key: $e');
      return null;
    }
  }

  Future<void> saveJsonData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      debugPrint('✅ JSON data saved for key: $key');
    } catch (e) {
      debugPrint('❌ Failed to save JSON data for key $key: $e');
    }
  }

  /// Credit service compatibility methods
  Future<void> saveCreditData(Map<String, dynamic> creditData) async {
    await saveJsonData('credit_data', creditData);
  }

  Future<Map<String, dynamic>?> getCreditData() async {
    return await getJsonData('credit_data');
  }

  /// Entitlement service compatibility methods
  Future<Map<String, dynamic>?> getUserEntitlements([String? userId]) async {
    final key =
        userId != null ? 'user_entitlements_$userId' : 'user_entitlements';
    return await getJsonData(key);
  }

  Future<void> saveUserEntitlements(dynamic userIdOrEntitlements,
      [Map<String, dynamic>? entitlements]) async {
    if (entitlements != null) {
      // Called with userId and entitlements
      final userId = userIdOrEntitlements as String;
      await saveJsonData('user_entitlements_$userId', entitlements);
    } else {
      // Called with just entitlements
      final data = userIdOrEntitlements as Map<String, dynamic>;
      await saveJsonData('user_entitlements', data);
    }
  }

  /// YouTube service compatibility - use addStudySet instead
  Future<void> saveStudySet(StudySet studySet) async {
    await addStudySet(studySet);
  }

  /// Theme management methods for compatibility
  Future<String?> getSelectedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_theme');
    } catch (e) {
      debugPrint('❌ Failed to get selected theme: $e');
      return null;
    }
  }

  Future<void> saveSelectedTheme(String themeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_theme', themeId);
      debugPrint('✅ Selected theme saved: $themeId');
    } catch (e) {
      debugPrint('❌ Failed to save selected theme: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      // Clear all study sets
      final setIds = _metadata.keys.toList();
      for (final setId in setIds) {
        await deleteStudySet(setId);
      }

      // Clear user data
      await clearUserData();

      // Clear metadata and totals
      _metadata.clear();
      _fullStudySets.clear();
      _totals = StorageTotals(
        totalBytes: 0,
        totalSets: 0,
        totalItems: 0,
        lastUpdated: DateTime.now(),
      );

      // Save cleared state
      await _saveMetadata();
      await _saveTotals();

      debugPrint('✅ All data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear all data: $e');
    }
  }

  /// Get storage statistics for management screen
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final studySets = await getAllStudySets();
      final totalSets = studySets.length;
      final totalFlashcards =
          studySets.fold<int>(0, (sum, set) => sum + set.flashcards.length);
      final totalQuizzes =
          studySets.fold<int>(0, (sum, set) => sum + set.quizzes.length);

      return {
        'totalSets': totalSets,
        'totalFlashcards': totalFlashcards,
        'totalQuizzes': totalQuizzes,
        'storageUsed': _totals.totalBytes,
        'storageLimit': StorageConfig.storageBudgetMB * 1024 * 1024,
        'usagePercentage':
            _totals.getUsagePercentage(StorageConfig.storageBudgetMB),
      };
    } catch (e) {
      debugPrint('❌ Failed to get storage stats: $e');
      return {
        'totalSets': 0,
        'totalFlashcards': 0,
        'totalQuizzes': 0,
        'storageUsed': 0,
        'storageLimit': StorageConfig.storageBudgetMB * 1024 * 1024,
        'usagePercentage': 0.0,
      };
    }
  }

  /// Close database
  Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      _isInitialized = false;
      debugPrint('✅ Unified storage service closed');
    } catch (e) {
      debugPrint('❌ Failed to close unified storage service: $e');
    }
  }
}
