import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mindload/config/storage_config.dart';
import 'package:mindload/models/storage_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

class EnhancedStorageService extends ChangeNotifier {
  static final EnhancedStorageService _instance =
      EnhancedStorageService._internal();
  factory EnhancedStorageService() => _instance;
  static EnhancedStorageService get instance => _instance;
  EnhancedStorageService._internal();

  // Storage state
  final Map<String, StudySetMetadata> _metadata = {};
  final Map<String, StudySet> _fullStudySets = {};
  StorageTotals _totals = StorageTotals(
    totalBytes: 0,
    totalSets: 0,
    totalItems: 0,
    lastUpdated: DateTime.now(),
  );

  // File names
  final String _metadataFileName = 'study_sets_metadata.json';
  final String _totalsFileName = 'storage_totals.json';
  final String _offlineCacheFileName = 'offline_cache.json';
  final String _syncQueueFileName = 'sync_queue.json';

  // Connectivity and sync state
  bool _isOnline = true;
  bool _isSyncing = false;
  final List<Map<String, dynamic>> _syncQueue = [];

  // Check if running on web
  bool get _isWeb => kIsWeb;

  // Getters
  StorageTotals get totals => _totals;
  Map<String, StudySetMetadata> get metadata => Map.unmodifiable(_metadata);
  Map<String, StudySet> get fullStudySets => Map.unmodifiable(_fullStudySets);
  bool get isStorageWarning => StorageConfig.isStorageWarning(
      _totals.getUsagePercentage(StorageConfig.storageBudgetMB));
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _syncQueue.length;

  // Initialize enhanced storage service
  Future<void> initialize() async {
    try {
      // Initialize connectivity monitoring
      await _initializeConnectivity();

      // Load data
      if (_isWeb) {
        await _loadMetadataWeb();
        await _loadTotalsWeb();
        await _loadOfflineCacheWeb();
        await _loadSyncQueueWeb();
      } else {
        await _loadMetadata();
        await _loadTotals();
        await _loadOfflineCache();
        await _loadSyncQueue();
      }

      // Load full study sets into memory for better performance
      await _loadFullStudySetsIntoMemory();

      // Clean up any duplicate study sets
      await cleanupDuplicates();

      // Check if we need to evict
      await _checkAndEvictIfNeeded();

      // Start sync if online
      if (_isOnline && _syncQueue.isNotEmpty) {
        _startBackgroundSync();
      }

      debugPrint('✅ Enhanced storage service initialized');
    } catch (e) {
      debugPrint('⚠️ Enhanced storage service initialization failed: $e');
      // Continue with empty state
    }
  }

  // Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      // For now, assume we're always online
      // TODO: Implement proper connectivity monitoring when connectivity_plus is available
      _isOnline = true;
      debugPrint('🌐 Connectivity monitoring initialized (assumed online)');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize connectivity monitoring: $e');
      _isOnline = true; // Assume online if we can't check
    }
  }

  // Load full study sets into memory for better performance
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

  // Enhanced add study set with offline support
  Future<bool> addStudySet(StudySet studySet) async {
    try {
      // Check for ID collision and generate unique ID if needed
      String uniqueId = studySet.id;
      if (_metadata.containsKey(uniqueId) || _fullStudySets.containsKey(uniqueId)) {
        // Generate a unique ID by appending a counter
        int counter = 1;
        do {
          uniqueId = '${studySet.id}_$counter';
          counter++;
        } while (_metadata.containsKey(uniqueId) || _fullStudySets.containsKey(uniqueId));
        
        debugPrint('⚠️ ID collision detected for ${studySet.id}, using unique ID: $uniqueId');
        
        // Create a new study set with the unique ID
        studySet = studySet.copyWith(id: uniqueId);
      }

      final metadata = studySet.toMetadata();

      // Add to local storage immediately
      _metadata[metadata.setId] = metadata;
      _fullStudySets[studySet.id] = studySet;
      _updateTotals();

      // Save to local storage
      await _saveStudySetToStorage(studySet);
      await _saveMetadata();
      await _saveTotals();

      // Add to sync queue if offline
      if (!_isOnline) {
        _addToSyncQueue('add', studySet.toJson());
        await _saveSyncQueue();
      }

      notifyListeners();
      debugPrint('✅ Study set added with ID: ${studySet.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to add study set: $e');
      return false;
    }
  }

  // Enhanced update study set with offline support
  Future<bool> updateStudySet(StudySet studySet) async {
    try {
      final metadata = studySet.toMetadata();

      // Update local storage immediately
      _metadata[metadata.setId] = metadata;
      _fullStudySets[studySet.id] = studySet;
      _updateTotals();

      // Save to local storage
      await _saveStudySetToStorage(studySet);
      await _saveMetadata();
      await _saveTotals();

      // Add to sync queue if offline
      if (!_isOnline) {
        _addToSyncQueue('update', studySet.toJson());
        await _saveSyncQueue();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to update study set: $e');
      return false;
    }
  }

  // Enhanced delete study set with offline support
  Future<bool> deleteStudySet(String setId) async {
    try {
      // Remove from local storage immediately
      _metadata.remove(setId);
      _fullStudySets.remove(setId);
      _updateTotals();

      // Delete from local storage
      await _deleteStudySetFromStorage(setId);
      await _saveMetadata();
      await _saveTotals();

      // Add to sync queue if offline
      if (!_isOnline) {
        _addToSyncQueue('delete', {'id': setId});
        await _saveSyncQueue();
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete study set: $e');
      return false;
    }
  }

  // Get study set with offline fallback
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

  // Get all study sets with offline support
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

  // Force sync when connection is restored
  Future<void> forceSync() async {
    if (_isOnline && _syncQueue.isNotEmpty) {
      await _startBackgroundSync();
    }
  }

  // Clean up duplicate study sets (for fixing existing data)
  Future<void> cleanupDuplicates() async {
    try {
      final seenTitles = <String, String>{}; // title -> first ID
      final duplicatesToRemove = <String>[];

      // Find duplicates based on title and creation time (within 1 second)
      for (final entry in _metadata.entries) {
        final metadata = entry.value;
        final key = '${metadata.title}_${metadata.createdAt.millisecondsSinceEpoch ~/ 1000}';
        
        if (seenTitles.containsKey(key)) {
          // This is a duplicate, mark for removal
          duplicatesToRemove.add(entry.key);
          debugPrint('🗑️ Found duplicate study set: ${metadata.title} (ID: ${entry.key})');
        } else {
          seenTitles[key] = entry.key;
        }
      }

      // Remove duplicates
      for (final duplicateId in duplicatesToRemove) {
        await deleteStudySet(duplicateId);
        debugPrint('✅ Removed duplicate study set: $duplicateId');
      }

      if (duplicatesToRemove.isNotEmpty) {
        debugPrint('🧹 Cleaned up ${duplicatesToRemove.length} duplicate study sets');
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup duplicates: $e');
    }
  }

  // Background sync process
  Future<void> _startBackgroundSync() async {
    if (_isSyncing || _syncQueue.isEmpty) return;

    setState(() => _isSyncing = true);
    notifyListeners();

    try {
      debugPrint(
          '🔄 Starting background sync of ${_syncQueue.length} items...');

      final itemsToSync = List<Map<String, dynamic>>.from(_syncQueue);
      final successfulSyncs = <int>[];

      for (int i = 0; i < itemsToSync.length; i++) {
        final item = itemsToSync[i];
        try {
          await _syncItem(item);
          successfulSyncs.add(i);
        } catch (e) {
          debugPrint('❌ Failed to sync item $i: $e');
        }
      }

      // Remove successfully synced items
      for (int i = successfulSyncs.length - 1; i >= 0; i--) {
        _syncQueue.removeAt(successfulSyncs[i]);
      }

      await _saveSyncQueue();
      debugPrint(
          '✅ Background sync completed. ${successfulSyncs.length} items synced, ${_syncQueue.length} remaining');
    } catch (e) {
      debugPrint('❌ Background sync failed: $e');
    } finally {
      setState(() => _isSyncing = false);
      notifyListeners();
    }
  }

  // Sync individual item
  Future<void> _syncItem(Map<String, dynamic> item) async {
    final action = item['action'] as String;
    final data = item['data'] as Map<String, dynamic>;

    switch (action) {
      case 'add':
      case 'update':
        // Here you would sync with your backend service
        // For now, we'll just simulate success
        await Future.delayed(const Duration(milliseconds: 100));
        break;
      case 'delete':
        // Here you would delete from your backend service
        await Future.delayed(const Duration(milliseconds: 100));
        break;
    }
  }

  // Add item to sync queue
  void _addToSyncQueue(String action, Map<String, dynamic> data) {
    _syncQueue.add({
      'action': action,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Public method to save study set
  Future<void> saveStudySet(StudySet studySet) async {
    try {
      // Update metadata
      final metadata = StudySetMetadata.fromStudySet(studySet);
      _metadata[studySet.id] = metadata;
      
      // Store full study set in memory
      _fullStudySets[studySet.id] = studySet;
      
      // Save to storage
      await _saveStudySetToStorage(studySet);
      
      // Update totals
      _updateTotals();
      
      // Notify listeners
      notifyListeners();
      
      debugPrint('✅ Study set saved: ${studySet.id}');
    } catch (e) {
      debugPrint('❌ Failed to save study set: $e');
      rethrow;
    }
  }

  // Save study set to storage
  Future<void> _saveStudySetToStorage(StudySet studySet) async {
    try {
      final studySetData = studySet.toJson();

      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'study_set_${studySet.id}', jsonEncode(studySetData));
      } else {
        // For native platforms, use a more robust approach
        try {
          final directory = await getApplicationDocumentsDirectory();
          final studySetsDir = Directory('${directory.path}/study_sets');

          // Ensure directory exists with proper permissions
          if (!await studySetsDir.exists()) {
            await studySetsDir.create(recursive: true);
            debugPrint('📁 Created study_sets directory: ${studySetsDir.path}');
          }

          // Check if directory is writable
          if (!await _isDirectoryWritable(studySetsDir)) {
            debugPrint(
                '⚠️ Study sets directory is not writable, falling back to web storage');
            // Fallback to web storage even on native platforms
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'study_set_${studySet.id}', jsonEncode(studySetData));
            return;
          }

          final file = File('${studySetsDir.path}/${studySet.id}.json');
          await file.writeAsString(jsonEncode(studySetData));
          debugPrint('💾 Saved study set to file: ${file.path}');
        } catch (fileSystemError) {
          debugPrint(
              '⚠️ File system error, falling back to web storage: $fileSystemError');
          // Fallback to web storage if file system fails
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'study_set_${studySet.id}', jsonEncode(studySetData));
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to save study set to storage: $e');
      rethrow;
    }
  }

  // Load study set from storage
  Future<StudySet?> _loadFullStudySetFromStorage(String setId) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        final studySetData = prefs.getString('study_set_$setId');
        if (studySetData != null) {
          final jsonData = jsonDecode(studySetData) as Map<String, dynamic>;
          return StudySet.fromJson(jsonData);
        }
      } else {
        // For native platforms, try file system first, then fallback to web storage
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/study_sets/$setId.json');
          if (await file.exists()) {
            final studySetData = await file.readAsString();
            final jsonData = jsonDecode(studySetData) as Map<String, dynamic>;
            return StudySet.fromJson(jsonData);
          }
        } catch (fileSystemError) {
          debugPrint(
              '⚠️ File system read error, trying web storage fallback: $fileSystemError');
        }

        // Fallback to web storage if file system fails
        try {
          final prefs = await SharedPreferences.getInstance();
          final studySetData = prefs.getString('study_set_$setId');
          if (studySetData != null) {
            final jsonData = jsonDecode(studySetData) as Map<String, dynamic>;
            return StudySet.fromJson(jsonData);
          }
        } catch (webStorageError) {
          debugPrint('⚠️ Web storage fallback also failed: $webStorageError');
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to load study set from storage: $e');
      return null;
    }
  }

  // Delete study set from storage
  Future<void> _deleteStudySetFromStorage(String setId) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('study_set_$setId');
      } else {
        // For native platforms, try file system first, then fallback to web storage
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/study_sets/$setId.json');
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Deleted study set file: ${file.path}');
          }
        } catch (fileSystemError) {
          debugPrint(
              '⚠️ File system delete error, trying web storage fallback: $fileSystemError');
        }

        // Always try to delete from web storage as well (in case of fallback scenarios)
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('study_set_$setId');
        } catch (webStorageError) {
          debugPrint('⚠️ Web storage delete also failed: $webStorageError');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to delete study set from storage: $e');
      rethrow;
    }
  }

  // Save metadata
  Future<void> _saveMetadata() async {
    try {
      if (_isWeb) {
        await _saveMetadataWeb();
      } else {
        await _saveMetadataNative();
      }
    } catch (e) {
      debugPrint('❌ Failed to save metadata: $e');
    }
  }

  // Save totals
  Future<void> _saveTotals() async {
    try {
      if (_isWeb) {
        await _saveTotalsWeb();
      } else {
        await _saveTotalsNative();
      }
    } catch (e) {
      debugPrint('❌ Failed to save totals: $e');
    }
  }

  // Load metadata
  Future<void> _loadMetadata() async {
    try {
      if (_isWeb) {
        await _loadMetadataWeb();
      } else {
        await _loadMetadataNative();
      }
    } catch (e) {
      debugPrint('❌ Failed to load metadata: $e');
    }
  }

  // Load totals
  Future<void> _loadTotals() async {
    try {
      if (_isWeb) {
        await _loadTotalsWeb();
      } else {
        await _loadTotalsNative();
      }
    } catch (e) {
      debugPrint('❌ Failed to load totals: $e');
    }
  }

  // Web storage methods
  Future<void> _saveMetadataWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final json = <String, dynamic>{};
    for (final entry in _metadata.entries) {
      json[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_metadataFileName, jsonEncode(json));
  }

  Future<void> _loadMetadataWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_metadataFileName);
    if (data != null) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      _metadata.clear();
      for (final entry in json.entries) {
        final metadata =
            StudySetMetadata.fromJson(entry.value as Map<String, dynamic>);
        _metadata[entry.key] = metadata;
      }
    }
  }

  Future<void> _saveTotalsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_totalsFileName, jsonEncode(_totals.toJson()));
  }

  Future<void> _loadTotalsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_totalsFileName);
    if (data != null) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      _totals = StorageTotals.fromJson(json);
    }
  }

  // Native storage methods
  Future<void> _saveMetadataNative() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_metadataFileName');
      final json = <String, dynamic>{};
      for (final entry in _metadata.entries) {
        json[entry.key] = entry.value.toJson();
      }
      await file.writeAsString(jsonEncode(json));
      debugPrint('💾 Saved metadata to native storage');
    } catch (e) {
      debugPrint(
          '⚠️ Failed to save metadata to native storage, falling back to web: $e');
      // Fallback to web storage
      await _saveMetadataWeb();
    }
  }

  Future<void> _loadMetadataNative() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_metadataFileName');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _metadata.clear();
        for (final entry in json.entries) {
          final metadata =
              StudySetMetadata.fromJson(entry.value as Map<String, dynamic>);
          _metadata[entry.key] = metadata;
        }
        debugPrint('📁 Loaded metadata from native storage');
      } else {
        // Try web storage fallback if native file doesn't exist
        await _loadMetadataWeb();
      }
    } catch (e) {
      debugPrint(
          '⚠️ Failed to load metadata from native storage, trying web fallback: $e');
      await _loadMetadataWeb();
    }
  }

  Future<void> _saveTotalsNative() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_totalsFileName');
      await file.writeAsString(jsonEncode(_totals.toJson()));
      debugPrint('💾 Saved totals to native storage');
    } catch (e) {
      debugPrint(
          '⚠️ Failed to save totals to native storage, falling back to web: $e');
      // Fallback to web storage
      await _saveTotalsWeb();
    }
  }

  Future<void> _loadTotalsNative() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_totalsFileName');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _totals = StorageTotals.fromJson(json);
        debugPrint('📁 Loaded totals from native storage');
      } else {
        // Try web storage fallback if native file doesn't exist
        await _loadTotalsWeb();
      }
    } catch (e) {
      debugPrint(
          '⚠️ Failed to load totals from native storage, trying web fallback: $e');
      await _loadTotalsWeb();
    }
  }

  // Offline cache methods
  Future<void> _loadOfflineCache() async {
    // Implementation for loading offline cache
  }

  Future<void> _loadOfflineCacheWeb() async {
    // Implementation for loading offline cache on web
  }

  // Sync queue methods
  Future<void> _loadSyncQueue() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_syncQueueFileName');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as List<dynamic>;
        _syncQueue.clear();
        _syncQueue.addAll(json.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('❌ Failed to load sync queue: $e');
    }
  }

  Future<void> _loadSyncQueueWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_syncQueueFileName);
      if (data != null) {
        final json = jsonDecode(data) as List<dynamic>;
        _syncQueue.clear();
        _syncQueue.addAll(json.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('❌ Failed to load sync queue: $e');
    }
  }

  Future<void> _saveSyncQueue() async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_syncQueueFileName, jsonEncode(_syncQueue));
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_syncQueueFileName');
        await file.writeAsString(jsonEncode(_syncQueue));
      }
    } catch (e) {
      debugPrint('❌ Failed to save sync queue: $e');
    }
  }

  // Update totals
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

  // Check and evict if needed
  Future<void> _checkAndEvictIfNeeded() async {
    // Implementation for storage eviction
  }

  // Helper method for setState
  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  // Add quiz result (placeholder for compatibility)
  void addQuizResult(dynamic result) {
    // Implementation for adding quiz results
    notifyListeners();
  }

  // Update study time (placeholder for compatibility)
  void updateStudyTime(int durationMinutes) {
    // Implementation for updating study time
    notifyListeners();
  }

  // Save last custom study set (placeholder for compatibility)
  Future<void> saveLastCustomStudySet(StudySetMetadata metadata) async {
    // For now, just save it as a regular study set
    await addStudySet(StudySet.fromJson(metadata.toStudySetData()));
  }

  // Check if directory is writable
  Future<bool> _isDirectoryWritable(Directory directory) async {
    try {
      // Try to create a temporary file to test write permissions
      final testFile = File(
          '${directory.path}/.write_test_${DateTime.now().millisecondsSinceEpoch}');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      debugPrint('⚠️ Directory write test failed: $e');
      return false;
    }
  }
}
