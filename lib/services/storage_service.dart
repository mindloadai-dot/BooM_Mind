import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mindload/config/storage_config.dart';
import 'package:mindload/models/storage_models.dart';
import 'package:mindload/models/study_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  static StorageService get instance => _instance;
  StorageService._internal();

  // Storage state
  final Map<String, StudySetMetadata> _metadata = {};
  StorageTotals _totals = StorageTotals(
    totalBytes: 0,
    totalSets: 0,
    totalItems: 0,
    lastUpdated: DateTime.now(),
  );

  // File names
  final String _metadataFileName = 'study_sets_metadata.json';
  final String _totalsFileName = 'storage_totals.json';

  // Check if running on web
  bool get _isWeb => kIsWeb;

  // Getters
  StorageTotals get totals => _totals;
  Map<String, StudySetMetadata> get metadata => Map.unmodifiable(_metadata);
  bool get isStorageWarning => StorageConfig.isStorageWarning(
      _totals.getUsagePercentage(StorageConfig.storageBudgetMB));

  // Initialize storage service
  Future<void> initialize() async {
    try {
      if (_isWeb) {
        await _loadMetadataWeb();
        await _loadTotalsWeb();
      } else {
        await _loadMetadata();
        await _loadTotals();
      }
      await _checkAndEvictIfNeeded();
      debugPrint('✅ Storage service initialized');
    } catch (e) {
      debugPrint('⚠️ Storage service initialization failed: $e');
      // Continue with empty state
    }
  }

  // Add a new study set
  Future<void> addSet(StudySetMetadata metadata) async {
    _metadata[metadata.setId] = metadata;
    _updateTotals();

    // Save to storage
    if (_isWeb) {
      await _saveMetadataWeb();
      await _saveTotalsWeb();
    } else {
      await _saveMetadata();
      await _saveTotals();
    }

    // Check if we need to evict
    await _checkAndEvictIfNeeded();

    notifyListeners();
  }

  // Add or update a study set (alias for compatibility)
  Future<bool> addOrUpdateSet(StudySetMetadata metadata) async {
    try {
      final oldMetadata = _metadata[metadata.setId];
      if (oldMetadata != null) {
        await updateSet(metadata);
      } else {
        await addSet(metadata);
      }
      return true;
    } catch (e) {
      debugPrint('❌ Failed to add/update set: $e');
      return false;
    }
  }

  // Remove a study set
  Future<void> removeSet(String setId) async {
    final metadata = _metadata.remove(setId);
    if (metadata != null) {
      _updateTotals();

      // Save to storage
      if (_isWeb) {
        await _saveMetadataWeb();
        await _saveTotalsWeb();
      } else {
        await _saveMetadata();
        await _saveTotals();
      }

      notifyListeners();
    }
  }

  // Update a study set
  Future<void> updateSet(StudySetMetadata metadata) async {
    final oldMetadata = _metadata[metadata.setId];
    if (oldMetadata != null) {
      _metadata[metadata.setId] = metadata;
      _updateTotals();

      // Save to storage
      if (_isWeb) {
        await _saveMetadataWeb();
        await _saveTotalsWeb();
      } else {
        await _saveMetadata();
        await _saveTotals();
      }

      notifyListeners();
    }
  }

  // Mark set as opened (update LRU)
  Future<bool> markSetOpened(String setId) async {
    try {
      final metadata = _metadata[setId];
      if (metadata != null) {
        final updatedMetadata = metadata.markOpened();
        _metadata[setId] = updatedMetadata;

        if (_isWeb) {
          await _saveMetadataWeb();
        } else {
          await _saveMetadata();
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to mark set opened: $e');
      return false;
    }
  }

  // Toggle pin status
  Future<bool> togglePin(String setId) async {
    try {
      final metadata = _metadata[setId];
      if (metadata != null) {
        final updatedMetadata = metadata.copyWith(isPinned: !metadata.isPinned);
        _metadata[setId] = updatedMetadata;

        if (_isWeb) {
          await _saveMetadataWeb();
        } else {
          await _saveMetadata();
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to toggle pin: $e');
      return false;
    }
  }

  // Archive set to cloud (keep metadata)
  Future<bool> archiveSet(String setId) async {
    try {
      final metadata = _metadata[setId];
      if (metadata != null) {
        final updatedMetadata = metadata.copyWith(isArchived: true);
        _metadata[setId] = updatedMetadata;

        if (_isWeb) {
          await _saveMetadataWeb();
          await _saveTotalsWeb();
        } else {
          await _saveMetadata();
          await _saveTotals();
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to archive set: $e');
      return false;
    }
  }

  // Create working study set
  Future<bool> createWorkingStudySet(String title, String content) async {
    try {
      final metadata = StudySetMetadata(
        setId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        isPinned: false,
        bytes: content.length,
        items: 1,
        lastOpenedAt: DateTime.now(),
        lastStudied: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await addSet(metadata);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to create working study set: $e');
      return false;
    }
  }

  // Get last custom study set
  Future<StudySetMetadata?> getLastCustomStudySet() async {
    final sets = _metadata.values.toList();
    if (sets.isEmpty) return null;
    sets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sets.first;
  }

  // Save last custom study set
  Future<bool> saveLastCustomStudySet(StudySetMetadata studySet) async {
    return addOrUpdateSet(studySet);
  }

  // Save study set (alias for compatibility)
  Future<bool> saveStudySet(StudySetMetadata studySet) async {
    return addOrUpdateSet(studySet);
  }

  // Save full study set with flashcards and quiz questions
  Future<bool> saveFullStudySet(StudySet studySet) async {
    try {
      // Save the metadata
      final metadata = studySet.toMetadata();
      await addOrUpdateSet(metadata);

      // Save the full study set data separately
      final studySetData = studySet.toJson();
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'study_set_${studySet.id}', jsonEncode(studySetData));
      } else {
        // For native platforms, save to file system
        final file = File(
            '${await getApplicationDocumentsDirectory()}/study_sets/${studySet.id}.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(studySetData));
      }

      return true;
    } catch (e) {
      debugPrint('Failed to save full study set: $e');
      return false;
    }
  }

  // Update study set (alias for compatibility)
  Future<bool> updateStudySet(StudySetMetadata studySet) async {
    try {
      await updateSet(studySet);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update full study set with all data
  Future<bool> updateFullStudySet(StudySet studySet) async {
    try {
      // Update the metadata
      final metadata = studySet.toMetadata();
      await updateSet(metadata);

      // Update the full study set data
      final studySetData = studySet.toJson();
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'study_set_${studySet.id}', jsonEncode(studySetData));
      } else {
        // For native platforms, save to file system
        final file = File(
            '${await getApplicationDocumentsDirectory()}/study_sets/${studySet.id}.json');
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode(studySetData));
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to update full study set: $e');
      return false;
    }
  }

  // Delete study set (alias for compatibility)
  Future<bool> deleteStudySet(String setId) async {
    try {
      await removeSet(setId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get study sets (alias for compatibility)
  Future<List<StudySetMetadata>> getStudySets() async {
    return _metadata.values.toList();
  }

  // Get full study set with flashcards and quiz questions
  Future<StudySet?> getFullStudySet(String setId) async {
    try {
      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        final studySetData = prefs.getString('study_set_$setId');
        if (studySetData != null) {
          final jsonData = jsonDecode(studySetData) as Map<String, dynamic>;
          return StudySet.fromJson(jsonData);
        }
      } else {
        // For native platforms, load from file system
        final file = File(
            '${await getApplicationDocumentsDirectory()}/study_sets/$setId.json');
        if (await file.exists()) {
          final studySetData = await file.readAsString();
          final jsonData = jsonDecode(studySetData) as Map<String, dynamic>;
          return StudySet.fromJson(jsonData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to load full study set: $e');
      return null;
    }
  }

  // Add quiz result
  void addQuizResult(dynamic result) {
    // Implementation for adding quiz results
    notifyListeners();
  }

  // Update study time
  void updateStudyTime(int durationMinutes) {
    // Implementation for updating study time
    notifyListeners();
  }

  // Get user progress
  Future<Map<String, dynamic>> getUserProgress() async {
    return {
      'totalSets': _totals.totalSets,
      'totalItems': _totals.totalItems,
      'lastUpdated': _totals.lastUpdated.millisecondsSinceEpoch,
    };
  }

  // Get selected theme
  Future<String?> getSelectedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_theme');
    } catch (e) {
      return null;
    }
  }

  // Save selected theme
  Future<void> saveSelectedTheme(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_theme', theme);
    } catch (e) {
      debugPrint('❌ Failed to save theme: $e');
    }
  }

  // Get remote config
  Future<Map<String, dynamic>?> getRemoteConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('remote_config');
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save remote config
  Future<void> saveRemoteConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('remote_config', jsonEncode(config));
    } catch (e) {
      debugPrint('❌ Failed to save remote config: $e');
    }
  }

  // Get JSON data
  Future<Map<String, dynamic>?> getJsonData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('json_data_$key');
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save JSON data
  Future<void> saveJsonData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('json_data_$key', jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Failed to save JSON data: $e');
    }
  }

  // Get user economy data
  Future<Map<String, dynamic>?> getUserEconomyData(String userId) async {
    return await getJsonData('user_economy_$userId');
  }

  // Save user economy data
  Future<void> saveUserEconomyData(
      String userId, Map<String, dynamic> data) async {
    await saveJsonData('user_economy_$userId', data);
  }

  // Get budget controller data
  Future<Map<String, dynamic>?> getBudgetControllerData() async {
    return await getJsonData('budget_controller');
  }

  // Save budget controller data
  Future<void> saveBudgetControllerData(Map<String, dynamic> data) async {
    await saveJsonData('budget_controller', data);
  }

  // Get user subscription new
  Future<Map<String, dynamic>?> getUserSubscriptionNew() async {
    return await getJsonData('user_subscription_new');
  }

  // Save user subscription new
  Future<void> saveUserSubscriptionNew(Map<String, dynamic> data) async {
    await saveJsonData('user_subscription_new', data);
  }

  // Save credit data
  Future<void> saveCreditData(Map<String, dynamic> data) async {
    await saveJsonData('credit_data', data);
  }

  // Get credit data
  Future<Map<String, dynamic>?> getCreditData() async {
    return await getJsonData('credit_data');
  }

  // Save user entitlements
  Future<void> saveUserEntitlements(
      String userId, Map<String, dynamic> data) async {
    await saveJsonData('user_entitlements_$userId', data);
  }

  // Get user entitlements
  Future<Map<String, dynamic>?> getUserEntitlements(String userId) async {
    return await getJsonData('user_entitlements_$userId');
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> data) async {
    await saveJsonData('user_data', data);
  }

  // Set authenticated
  Future<void> setAuthenticated(bool isAuthenticated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', isAuthenticated);
    } catch (e) {
      debugPrint('❌ Failed to set authenticated: $e');
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    return await getJsonData('user_data');
  }

  // Clear user data
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('is_authenticated');
    } catch (e) {
      debugPrint('❌ Failed to clear user data: $e');
    }
  }

  // Set subscription plan
  Future<void> setSubscriptionPlan(String plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_plan', plan);
    } catch (e) {
      debugPrint('❌ Failed to set subscription plan: $e');
    }
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_authenticated') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Set string value (for international compliance service)
  Future<void> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      debugPrint('✅ String value saved for key: $key');
    } catch (e) {
      debugPrint('❌ Failed to save string value for key $key: $e');
    }
  }

  // Get storage stats (alias for compatibility)
  Map<String, dynamic> getStorageStats() {
    // Use default values for free space to avoid async issues
    final freeSpaceGB = 10; // Default fallback
    final currentBudgetMB = StorageConfig.getCurrentBudgetMB(freeSpaceGB);
    final usagePercentage = _totals.getUsagePercentage(currentBudgetMB);

    return {
      'totalBytes': _totals.totalBytes,
      'totalSets': _totals.totalSets,
      'totalItems': _totals.totalItems,
      'budgetMB': currentBudgetMB,
      'usagePercentage': usagePercentage,
      'isWarning': isStorageWarning,
      'freeSpaceGB': freeSpaceGB,
    };
  }

  // Get storage stats with async free space (for when async is needed)
  Future<Map<String, dynamic>> getStorageStatsAsync() async {
    final freeSpaceGB = await _getFreeSpaceGB();
    final currentBudgetMB = StorageConfig.getCurrentBudgetMB(freeSpaceGB);
    final usagePercentage = _totals.getUsagePercentage(currentBudgetMB);

    return {
      'totalBytes': _totals.totalBytes,
      'totalSets': _totals.totalSets,
      'totalItems': _totals.totalItems,
      'budgetMB': currentBudgetMB,
      'usagePercentage': usagePercentage,
      'isWarning': isStorageWarning,
      'freeSpaceGB': freeSpaceGB,
    };
  }

  // Clear all data (alias for compatibility)
  Future<void> clearAllData() async {
    return clearAll();
  }

  // Initialize (alias for initialize method)
  Future<void> init() async {
    return initialize();
  }

  // Force refresh study sets (useful for debugging)
  Future<void> forceRefresh() async {
    try {
      debugPrint('🔄 Force refreshing study sets...');
      await _loadMetadata();
      await _loadTotals();
      notifyListeners();
      debugPrint('✅ Force refresh completed');
    } catch (e) {
      debugPrint('❌ Force refresh failed: $e');
    }
  }

  // Debug method to check storage status

  // Update totals based on current metadata
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

  // Check storage limits and evict if needed
  Future<void> _checkAndEvictIfNeeded() async {
    try {
      // Auto cleanup disabled - users can manually manage their storage
      debugPrint('📱 Auto cleanup disabled - users manage their own storage');
    } catch (e) {
      debugPrint('⚠️ Failed to check eviction: $e');
    }
  }

  // Evict sets to free up space
  Future<EvictionResult> evict(int budgetMB) async {
    try {
      // Get unpinned sets ordered by LRU (oldest first)
      final unpinnedSets = _metadata.values
          .where((m) => !m.isPinned && !m.isArchived)
          .toList()
        ..sort((a, b) => a.lastOpenedAt.compareTo(b.lastOpenedAt));

      int freedBytes = 0;
      int evictedSets = 0;
      final List<String> evictedSetIds = [];

      for (final set in unpinnedSets) {
        // Check if we've freed enough space (using hardcoded batch size since evictBatch is disabled)
        if (freedBytes / (1024 * 1024) >= 50 || // 50MB batch size
            !_totals.isOverAnyLimit(budgetMB)) {
          break;
        }

        // Evict this set
        await removeSet(set.setId);
        freedBytes += set.bytes;
        evictedSets++;
        evictedSetIds.add(set.setId);

        debugPrint('🗑️ Evicted set: ${set.title} (${set.bytes} bytes)');
      }

      final result = EvictionResult(
        freedBytes: freedBytes,
        evictedSets: evictedSets,
        evictedSetIds: evictedSetIds,
      );

      debugPrint('✅ Eviction completed: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Eviction failed: $e');
      return const EvictionResult(
        freedBytes: 0,
        evictedSets: 0,
        evictedSetIds: [],
      );
    }
  }

  // Evict old sets to free up space (legacy method)
  Future<void> _evictOldSets(int budgetMB) async {
    try {
      final sets = _metadata.values.toList()
        ..sort((a, b) => a.lastOpenedAt.compareTo(b.lastOpenedAt));

      final targetBytes =
          (budgetMB * 1024 * 1024 * 0.8).round(); // 80% of budget

      while (_totals.totalBytes > targetBytes && sets.isNotEmpty) {
        final oldestSet = sets.removeAt(0);
        await removeSet(oldestSet.setId);
        debugPrint('🗑️ Evicted old set: ${oldestSet.title}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to evict old sets: $e');
    }
  }

  // Get free space (native platforms only)
  Future<int> _getFreeSpaceGB() async {
    try {
      if (_isWeb) {
        // On web, return a reasonable estimate
        return 10; // Assume 10GB for web
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final stat = await directory.stat();
        final freeSpaceBytes = stat.size;
        return (freeSpaceBytes / (1024 * 1024 * 1024)).round();
      }
    } catch (e) {
      debugPrint('⚠️ Could not determine free space: $e');
      return 10; // Default fallback
    }
  }

  // Load metadata from disk (native platforms)
  Future<void> _loadMetadata() async {
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

        debugPrint(
            '📁 Loaded ${_metadata.length} study set metadata entries from disk');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load metadata from disk: $e');
    }
  }

  // Load metadata from web storage
  Future<void> _loadMetadataWeb() async {
    try {
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
        debugPrint(
            '📁 Loaded ${_metadata.length} study set metadata entries from web storage');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load metadata from web storage: $e');
    }
  }

  // Save metadata to disk (native platforms)
  Future<void> _saveMetadata() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_metadataFileName');

      final json = <String, dynamic>{};
      for (final entry in _metadata.entries) {
        json[entry.key] = entry.value.toJson();
      }

      await file.writeAsString(jsonEncode(json));
      debugPrint('💾 Saved metadata to disk');
    } catch (e) {
      debugPrint('❌ Failed to save metadata: $e');
    }
  }

  // Save metadata to web storage
  Future<void> _saveMetadataWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = <String, dynamic>{};
      for (final entry in _metadata.entries) {
        json[entry.key] = entry.value.toJson();
      }

      await prefs.setString(_metadataFileName, jsonEncode(json));
      debugPrint('💾 Saved metadata to web storage');
    } catch (e) {
      debugPrint('❌ Failed to save metadata to web storage: $e');
    }
  }

  // Load totals from disk (native platforms)
  Future<void> _loadTotals() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_totalsFileName');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _totals = StorageTotals.fromJson(json);
        debugPrint('📁 Loaded totals from disk');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load totals from disk: $e');
    }
  }

  // Load totals from web storage
  Future<void> _loadTotalsWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_totalsFileName);

      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        _totals = StorageTotals.fromJson(json);
        debugPrint('📁 Loaded totals from web storage');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load totals from web storage: $e');
    }
  }

  // Save totals to disk (native platforms)
  Future<void> _saveTotals() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_totalsFileName');

      await file.writeAsString(jsonEncode(_totals.toJson()));
      debugPrint('💾 Saved totals to disk');
    } catch (e) {
      debugPrint('❌ Failed to save totals: $e');
    }
  }

  // Save totals to web storage
  Future<void> _saveTotalsWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_totalsFileName, jsonEncode(_totals.toJson()));
      debugPrint('💾 Saved totals to web storage');
    } catch (e) {
      debugPrint('❌ Failed to save totals to web storage: $e');
    }
  }

  // Get storage usage statistics
  String getStorageInfo() {
    return '''
Storage Service Info:
- Platform: ${_isWeb ? 'Web' : 'Native'}
- Total Sets: ${_totals.totalSets}
- Total Items: ${_totals.totalItems}
- Total Bytes: ${_totals.totalBytes}
- Last Updated: ${_totals.lastUpdated}
- Is Warning: $isStorageWarning
''';
  }

  // Get all study sets
  List<StudySetMetadata> getAllSets() {
    return _metadata.values.toList();
  }

  // Get a specific study set
  StudySetMetadata? getSet(String setId) {
    return _metadata[setId];
  }

  // Check if a set exists
  bool hasSet(String setId) {
    return _metadata.containsKey(setId);
  }

  // Get sets by title (since category doesn't exist)
  List<StudySetMetadata> getSetsByTitle(String titleQuery) {
    return _metadata.values
        .where((metadata) =>
            metadata.title.toLowerCase().contains(titleQuery.toLowerCase()))
        .toList();
  }

  // Search sets by title or content
  List<StudySetMetadata> searchSets(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _metadata.values
        .where((metadata) =>
            metadata.title.toLowerCase().contains(lowercaseQuery) ||
            (metadata.content?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList();
  }

  // Get recent sets
  List<StudySetMetadata> getRecentSets({int limit = 10}) {
    final sortedSets = _metadata.values.toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return sortedSets.take(limit).toList();
  }

  // Get popular sets (by access count - using lastOpenedAt as proxy)
  List<StudySetMetadata> getPopularSets({int limit = 10}) {
    final sortedSets = _metadata.values.toList()
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return sortedSets.take(limit).toList();
  }

  // Clear all data (for testing/reset)
  Future<void> clearAll() async {
    try {
      _metadata.clear();
      _totals = StorageTotals(
        totalBytes: 0,
        totalSets: 0,
        totalItems: 0,
        lastUpdated: DateTime.now(),
      );

      if (_isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_metadataFileName);
        await prefs.remove(_totalsFileName);
      } else {
        // Clear native storage
        final directory = await getApplicationDocumentsDirectory();
        final metadataFile = File('${directory.path}/$_metadataFileName');
        final totalsFile = File('${directory.path}/$_totalsFileName');

        if (await metadataFile.exists()) await metadataFile.delete();
        if (await totalsFile.exists()) await totalsFile.delete();
      }

      notifyListeners();
      debugPrint('🗑️ All storage data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear storage: $e');
    }
  }
}
