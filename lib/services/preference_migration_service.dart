import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/services/user_specific_storage_service.dart';
import 'package:mindload/services/auth_service.dart';
import 'package:mindload/services/user_profile_service.dart';

/// Service to handle migration of global preferences to user-specific storage
/// This ensures that when users log in, their existing preferences are preserved
class PreferenceMigrationService {
  static final PreferenceMigrationService _instance =
      PreferenceMigrationService._();
  static PreferenceMigrationService get instance => _instance;
  PreferenceMigrationService._();

  // Keys for global preferences that need migration
  static const List<String> _globalPreferenceKeys = [
    // Privacy & Security
    'haptic_feedback',
    'analytics_enabled',
    'crash_reporting',

    // User Profile
    'user_nickname',
    'user_timezone',
    'quiet_hours_enabled',
    'quiet_hours_start',
    'quiet_hours_end',
    'notification_style',

    // Theme
    'selected_theme',

    // Other app preferences
    'onboarding_completed',
    'first_launch_date',
    'last_used_version',
  ];

  /// Check if migration is needed for the current user
  Future<bool> isMigrationNeeded() async {
    if (!AuthService.instance.isAuthenticated) {
      return false;
    }

    try {
      // Check if user has already been migrated
      final migrated = await UserSpecificStorageService.instance
              .getBool('preferences_migrated') ??
          false;
      return !migrated;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking migration status: $e');
      }
      return false;
    }
  }

  /// Perform migration of global preferences to user-specific storage
  Future<void> migratePreferences() async {
    if (!AuthService.instance.isAuthenticated) {
      if (kDebugMode) {
        debugPrint('⚠️ Cannot migrate: user not authenticated');
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting preference migration...');
      }

      final prefs = await SharedPreferences.getInstance();
      int migratedCount = 0;

      // Migrate each preference key
      for (final key in _globalPreferenceKeys) {
        try {
          final value = prefs.get(key);
          if (value != null) {
            await _migratePreference(key, value);
            migratedCount++;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to migrate key $key: $e');
          }
        }
      }

      // Mark migration as complete
      await UserSpecificStorageService.instance
          .setBool('preferences_migrated', true);

      // Reload user profile data to ensure it's up to date
      await UserProfileService.instance.loadProfileData();

      if (kDebugMode) {
        debugPrint(
            '✅ Preference migration completed: $migratedCount preferences migrated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Preference migration failed: $e');
      }
    }
  }

  /// Migrate a single preference based on its type
  Future<void> _migratePreference(String key, dynamic value) async {
    try {
      if (value is String) {
        await UserSpecificStorageService.instance.setString(key, value);
      } else if (value is bool) {
        await UserSpecificStorageService.instance.setBool(key, value);
      } else if (value is int) {
        await UserSpecificStorageService.instance.setInt(key, value);
      } else if (value is double) {
        await UserSpecificStorageService.instance.setDouble(key, value);
      } else {
        // For complex types, convert to string
        await UserSpecificStorageService.instance
            .setString(key, value.toString());
      }

      if (kDebugMode) {
        debugPrint('📦 Migrated $key: $value');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to migrate $key: $e');
      }
    }
  }

  /// Clear global preferences after successful migration
  Future<void> clearGlobalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final key in _globalPreferenceKeys) {
        await prefs.remove(key);
      }

      if (kDebugMode) {
        debugPrint('🗑️ Cleared global preferences after migration');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear global preferences: $e');
      }
    }
  }

  /// Get migration status for debugging
  Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> status = {};

      for (final key in _globalPreferenceKeys) {
        final globalValue = prefs.get(key);
        dynamic userSpecificValue;

        if (AuthService.instance.isAuthenticated) {
          // Try to get the value using the appropriate method based on type
          if (globalValue is String) {
            userSpecificValue =
                await UserSpecificStorageService.instance.getString(key);
          } else if (globalValue is bool) {
            userSpecificValue =
                await UserSpecificStorageService.instance.getBool(key);
          } else if (globalValue is int) {
            userSpecificValue =
                await UserSpecificStorageService.instance.getInt(key);
          } else if (globalValue is double) {
            userSpecificValue =
                await UserSpecificStorageService.instance.getDouble(key);
          }
        }

        status[key] = {
          'global': globalValue,
          'user_specific': userSpecificValue,
          'migrated': globalValue != null && userSpecificValue != null,
        };
      }

      status['migration_completed'] = await UserSpecificStorageService.instance
              .getBool('preferences_migrated') ??
          false;
      status['user_authenticated'] = AuthService.instance.isAuthenticated;

      return status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get migration status: $e');
      }
      return {};
    }
  }

  /// Force re-migration (useful for debugging or fixing corrupted data)
  Future<void> forceRemigration() async {
    try {
      // Clear migration flag
      await UserSpecificStorageService.instance
          .setBool('preferences_migrated', false);

      // Perform migration again
      await migratePreferences();

      if (kDebugMode) {
        debugPrint('🔄 Force re-migration completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Force re-migration failed: $e');
      }
    }
  }
}
