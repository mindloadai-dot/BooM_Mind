import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service for handling user-specific local data storage
/// Ensures all data is isolated per user account to prevent data mixing
class UserSpecificStorageService extends ChangeNotifier {
  static final UserSpecificStorageService _instance =
      UserSpecificStorageService._internal();
  static UserSpecificStorageService get instance => _instance;
  UserSpecificStorageService._internal();

  SharedPreferences? _prefs;
  String? _currentUserPrefix;

  /// Initialize the service with current user context
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _updateUserContext();

      if (kDebugMode) {
        debugPrint('✅ UserSpecificStorageService initialized');
        debugPrint('   Current user prefix: $_currentUserPrefix');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize UserSpecificStorageService: $e');
      }
    }
  }

  /// Update user context when user changes
  Future<void> _updateUserContext() async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null) {
      _currentUserPrefix = 'user_${currentUser.uid}_';
      if (kDebugMode) {
        debugPrint('🔄 Updated user context: $_currentUserPrefix');
      }
    } else {
      _currentUserPrefix = null;
      if (kDebugMode) {
        debugPrint('🔄 Cleared user context (no authenticated user)');
      }
    }
    notifyListeners();
  }

  /// Get user-specific key with prefix
  String _getUserSpecificKey(String key) {
    if (_currentUserPrefix == null) {
      throw Exception('No authenticated user for user-specific storage');
    }
    return '$_currentUserPrefix$key';
  }

  /// Check if user is authenticated for storage operations
  bool get _isUserAuthenticated => _currentUserPrefix != null;

  /// Get string value for current user
  Future<String?> getString(String key) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Attempted to get string without authenticated user: $key');
      }
      return null;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final value = _prefs?.getString(userKey);

    if (kDebugMode && value != null) {
      debugPrint('📖 Retrieved user-specific string: $userKey');
    }

    return value;
  }

  /// Set string value for current user
  Future<bool> setString(String key, String value) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Attempted to set string without authenticated user: $key');
      }
      return false;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final success = await _prefs?.setString(userKey, value) ?? false;

    if (kDebugMode && success) {
      debugPrint('💾 Saved user-specific string: $userKey');
    }

    return success;
  }

  /// Get bool value for current user
  Future<bool?> getBool(String key) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint('⚠️ Attempted to get bool without authenticated user: $key');
      }
      return null;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final value = _prefs?.getBool(userKey);

    if (kDebugMode && value != null) {
      debugPrint('📖 Retrieved user-specific bool: $userKey = $value');
    }

    return value;
  }

  /// Set bool value for current user
  Future<bool> setBool(String key, bool value) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint('⚠️ Attempted to set bool without authenticated user: $key');
      }
      return false;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final success = await _prefs?.setBool(userKey, value) ?? false;

    if (kDebugMode && success) {
      debugPrint('💾 Saved user-specific bool: $userKey = $value');
    }

    return success;
  }

  /// Get int value for current user
  Future<int?> getInt(String key) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint('⚠️ Attempted to get int without authenticated user: $key');
      }
      return null;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final value = _prefs?.getInt(userKey);

    if (kDebugMode && value != null) {
      debugPrint('📖 Retrieved user-specific int: $userKey = $value');
    }

    return value;
  }

  /// Set int value for current user
  Future<bool> setInt(String key, int value) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint('⚠️ Attempted to set int without authenticated user: $key');
      }
      return false;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final success = await _prefs?.setInt(userKey, value) ?? false;

    if (kDebugMode && success) {
      debugPrint('💾 Saved user-specific int: $userKey = $value');
    }

    return success;
  }

  /// Get double value for current user
  Future<double?> getDouble(String key) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Attempted to get double without authenticated user: $key');
      }
      return null;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final value = _prefs?.getDouble(userKey);

    if (kDebugMode && value != null) {
      debugPrint('📖 Retrieved user-specific double: $userKey = $value');
    }

    return value;
  }

  /// Set double value for current user
  Future<bool> setDouble(String key, double value) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Attempted to set double without authenticated user: $key');
      }
      return false;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final success = await _prefs?.setDouble(userKey, value) ?? false;

    if (kDebugMode && success) {
      debugPrint('💾 Saved user-specific double: $userKey = $value');
    }

    return success;
  }

  /// Get string list value for current user
  Future<List<String>?> getStringList(String key) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Attempted to get string list without authenticated user: $key');
      }
      return null;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final value = _prefs?.getStringList(userKey);

    if (kDebugMode && value != null) {
      debugPrint(
          '📖 Retrieved user-specific string list: $userKey (${value.length} items)');
    }

    return value;
  }

  /// Set string list value for current user
  Future<bool> setStringList(String key, List<String> value) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Attempted to set string list without authenticated user: $key');
      }
      return false;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final success = await _prefs?.setStringList(userKey, value) ?? false;

    if (kDebugMode && success) {
      debugPrint(
          '💾 Saved user-specific string list: $userKey (${value.length} items)');
    }

    return success;
  }

  /// Remove value for current user
  Future<bool> remove(String key) async {
    if (!_isUserAuthenticated) {
      if (kDebugMode) {
        debugPrint('⚠️ Attempted to remove without authenticated user: $key');
      }
      return false;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    final success = await _prefs?.remove(userKey) ?? false;

    if (kDebugMode && success) {
      debugPrint('🗑️ Removed user-specific key: $userKey');
    }

    return success;
  }

  /// Clear all data for current user (useful for logout)
  Future<void> clearUserData() async {
    if (!_isUserAuthenticated || _prefs == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Cannot clear user data: no authenticated user or prefs');
      }
      return;
    }

    await _updateUserContext(); // Ensure current user context
    final keys = _prefs!.getKeys();
    final userKeys =
        keys.where((key) => key.startsWith(_currentUserPrefix!)).toList();

    for (final key in userKeys) {
      await _prefs!.remove(key);
    }

    if (kDebugMode) {
      debugPrint(
          '🧹 Cleared ${userKeys.length} user-specific keys for $_currentUserPrefix');
    }
  }

  /// Get all keys for current user
  Future<Set<String>> getUserKeys() async {
    if (!_isUserAuthenticated || _prefs == null) {
      return <String>{};
    }

    await _updateUserContext(); // Ensure current user context
    final allKeys = _prefs!.getKeys();
    final userKeys = allKeys
        .where((key) => key.startsWith(_currentUserPrefix!))
        .map((key) => key.substring(_currentUserPrefix!.length))
        .toSet();

    return userKeys;
  }

  /// Check if key exists for current user
  Future<bool> containsKey(String key) async {
    if (!_isUserAuthenticated) {
      return false;
    }

    await _updateUserContext(); // Ensure current user context
    final userKey = _getUserSpecificKey(key);
    return _prefs?.containsKey(userKey) ?? false;
  }

  /// Force reload preferences (useful after user changes)
  Future<void> reload() async {
    await _prefs?.reload();
    await _updateUserContext();
    notifyListeners();
  }

  /// Get current user ID (for debugging)
  String? get currentUserId => AuthService.instance.currentUser?.uid;

  /// Get current user prefix (for debugging)
  String? get currentUserPrefix => _currentUserPrefix;

  /// Migrate data from global keys to user-specific keys
  /// This is useful for existing users who have data stored globally
  Future<void> migrateGlobalDataToUserSpecific(
      List<String> keysToMigrate) async {
    if (!_isUserAuthenticated || _prefs == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Cannot migrate: no authenticated user');
      }
      return;
    }

    await _updateUserContext(); // Ensure current user context
    int migratedCount = 0;

    for (final key in keysToMigrate) {
      final userKey = _getUserSpecificKey(key);

      // Check if user-specific key already exists (don't overwrite)
      if (_prefs!.containsKey(userKey)) {
        continue;
      }

      // Check if global key exists
      if (_prefs!.containsKey(key)) {
        // Migrate based on type
        final value = _prefs!.get(key);
        if (value is String) {
          await _prefs!.setString(userKey, value);
        } else if (value is bool) {
          await _prefs!.setBool(userKey, value);
        } else if (value is int) {
          await _prefs!.setInt(userKey, value);
        } else if (value is double) {
          await _prefs!.setDouble(userKey, value);
        } else if (value is List<String>) {
          await _prefs!.setStringList(userKey, value);
        }

        // Remove global key after migration
        await _prefs!.remove(key);
        migratedCount++;
      }
    }

    if (kDebugMode && migratedCount > 0) {
      debugPrint(
          '📦 Migrated $migratedCount keys to user-specific storage for $_currentUserPrefix');
    }
  }
}
