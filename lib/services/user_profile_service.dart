import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindload/services/user_specific_storage_service.dart';
import 'package:mindload/services/auth_service.dart';

/// Service to manage user profile data including nicknames, timezones, and notification preferences
/// This is the central service for all user personalization features
class UserProfileService extends ChangeNotifier {
  static final UserProfileService _instance = UserProfileService._();
  static UserProfileService get instance => _instance;
  UserProfileService._();

  // SharedPreferences keys
  static const String _nicknameKey = 'user_nickname';
  static const String _timezoneKey = 'user_timezone';
  static const String _quietHoursEnabledKey = 'quiet_hours_enabled';
  static const String _quietHoursStartKey = 'quiet_hours_start';
  static const String _quietHoursEndKey = 'quiet_hours_end';
  static const String _notificationStyleKey = 'notification_style';

  // Default values
  static const String _defaultNotificationStyle = 'mindful';
  static const List<String> _availableStyles = [
    'mindful',
    'coach',
    'toughlove',
    'cram'
  ];

  // Profile data
  String? _nickname;
  String? _timezone;
  bool _quietHoursEnabled = false;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  String _notificationStyle = _defaultNotificationStyle;

  // Getters
  String? get nickname => _nickname;
  String? get timezone => _timezone;
  bool get quietHoursEnabled => _quietHoursEnabled;
  String get quietHoursStart => _quietHoursStart;
  String get quietHoursEnd => _quietHoursEnd;
  String get notificationStyle => _notificationStyle;
  List<String> get availableStyles => List.unmodifiable(_availableStyles);

  /// Check if user has set a nickname
  bool get hasNickname => _nickname != null && _nickname!.isNotEmpty;

  /// Get the display name for the user (nickname priority)
  String get displayName {
    if (_nickname != null && _nickname!.isNotEmpty) {
      return _nickname!;
    }
    // TODO: Add Firebase display name fallback
    // if (_firebaseDisplayName != null && _firebaseDisplayName!.isNotEmpty) {
    //   return _firebaseDisplayName!;
    // }
    // TODO: Add email username fallback
    // if (_emailUsername != null && _emailUsername!.isNotEmpty) {
    //   return _emailUsername!;
    // }
    return 'User';
  }

  /// Get personalized greeting based on time of day
  String get personalizedGreeting {
    final now = DateTime.now();
    final hour = now.hour;

    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    return '$timeGreeting, $displayName';
  }

  /// Check if currently in quiet hours
  bool get isInQuietHours {
    if (!_quietHoursEnabled) return false;

    try {
      final now = DateTime.now();
      final startParts = _quietHoursStart.split(':');
      final endParts = _quietHoursEnd.split(':');

      if (startParts.length == 2 && endParts.length == 2) {
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);

        final startTime =
            DateTime(now.year, now.month, now.day, startHour, startMinute);
        final endTime =
            DateTime(now.year, now.month, now.day, endHour, endMinute);

        // Handle overnight quiet hours
        if (endTime.isBefore(startTime)) {
          if (now.isAfter(startTime) || now.isBefore(endTime)) {
            return true;
          }
        } else {
          if (now.isAfter(startTime) && now.isBefore(endTime)) {
            return true;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking quiet hours: $e');
      }
    }

    return false;
  }

  /// Load all profile data from storage
  Future<void> loadProfileData() async {
    try {
      // Try user-specific storage first (for authenticated users)
      if (AuthService.instance.isAuthenticated) {
        await _loadFromUserSpecificStorage();
      } else {
        // Fallback to global storage for unauthenticated users
        await _loadFromGlobalStorage();
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Profile data loaded');
        debugPrint('   Nickname: $_nickname');
        debugPrint('   Timezone: $_timezone');
        debugPrint(
            '   Quiet hours: $_quietHoursEnabled ($_quietHoursStart - $_quietHoursEnd)');
        debugPrint('   Notification style: $_notificationStyle');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load profile data: $e');
      }
    }
  }

  /// Load from user-specific storage
  Future<void> _loadFromUserSpecificStorage() async {
    try {
      _nickname =
          await UserSpecificStorageService.instance.getString(_nicknameKey);
      _timezone =
          await UserSpecificStorageService.instance.getString(_timezoneKey);
      _quietHoursEnabled = await UserSpecificStorageService.instance
              .getBool(_quietHoursEnabledKey) ??
          false;
      _quietHoursStart = await UserSpecificStorageService.instance
              .getString(_quietHoursStartKey) ??
          '22:00';
      _quietHoursEnd = await UserSpecificStorageService.instance
              .getString(_quietHoursEndKey) ??
          '07:00';
      _notificationStyle = await UserSpecificStorageService.instance
              .getString(_notificationStyleKey) ??
          _defaultNotificationStyle;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load from user-specific storage: $e');
      }
      // Fallback to global storage
      await _loadFromGlobalStorage();
    }
  }

  /// Load from global storage
  Future<void> _loadFromGlobalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _nickname = prefs.getString(_nicknameKey);
      _timezone = prefs.getString(_timezoneKey);
      _quietHoursEnabled = prefs.getBool(_quietHoursEnabledKey) ?? false;
      _quietHoursStart = prefs.getString(_quietHoursStartKey) ?? '22:00';
      _quietHoursEnd = prefs.getString(_quietHoursEndKey) ?? '07:00';
      _notificationStyle =
          prefs.getString(_notificationStyleKey) ?? _defaultNotificationStyle;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load from global storage: $e');
      }
    }
  }

  /// Update user nickname
  Future<void> updateNickname(String newNickname) async {
    try {
      final trimmedNickname = newNickname.trim();
      if (trimmedNickname.isEmpty) {
        _nickname = null;
      } else {
        _nickname = trimmedNickname;
      }

      // Save to user-specific storage if authenticated
      if (AuthService.instance.isAuthenticated) {
        if (_nickname != null) {
          await UserSpecificStorageService.instance
              .setString(_nicknameKey, _nickname!);
        } else {
          // Note: UserSpecificStorageService doesn't have remove method, so we'll set to empty string
          await UserSpecificStorageService.instance.setString(_nicknameKey, '');
        }
      } else {
        // Fallback to global storage for unauthenticated users
        final prefs = await SharedPreferences.getInstance();
        if (_nickname != null) {
          await prefs.setString(_nicknameKey, _nickname!);
        } else {
          await prefs.remove(_nicknameKey);
        }
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Nickname updated: $_nickname');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update nickname: $e');
      }
    }
  }

  /// Update user timezone
  Future<void> updateTimezone(String newTimezone) async {
    try {
      _timezone = newTimezone;

      // Save to user-specific storage if authenticated
      if (AuthService.instance.isAuthenticated) {
        await UserSpecificStorageService.instance
            .setString(_timezoneKey, _timezone!);
      } else {
        // Fallback to global storage for unauthenticated users
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_timezoneKey, _timezone!);
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Timezone updated: $_timezone');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update timezone: $e');
      }
    }
  }

  /// Update quiet hours settings
  Future<void> updateQuietHours({
    required bool enabled,
    required String start,
    required String end,
  }) async {
    try {
      _quietHoursEnabled = enabled;
      _quietHoursStart = start;
      _quietHoursEnd = end;

      // Save to user-specific storage if authenticated
      if (AuthService.instance.isAuthenticated) {
        await UserSpecificStorageService.instance
            .setBool(_quietHoursEnabledKey, _quietHoursEnabled);
        await UserSpecificStorageService.instance
            .setString(_quietHoursStartKey, _quietHoursStart);
        await UserSpecificStorageService.instance
            .setString(_quietHoursEndKey, _quietHoursEnd);
      } else {
        // Fallback to global storage for unauthenticated users
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_quietHoursEnabledKey, _quietHoursEnabled);
        await prefs.setString(_quietHoursStartKey, _quietHoursStart);
        await prefs.setString(_quietHoursEndKey, _quietHoursEnd);
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Quiet hours updated: $enabled ($start - $end)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update quiet hours: $e');
      }
    }
  }

  /// Update notification style
  Future<void> updateNotificationStyle(String newStyle) async {
    try {
      if (!_availableStyles.contains(newStyle)) {
        throw Exception('Invalid notification style: $newStyle');
      }

      _notificationStyle = newStyle;

      // Save to user-specific storage if authenticated
      if (AuthService.instance.isAuthenticated) {
        await UserSpecificStorageService.instance
            .setString(_notificationStyleKey, _notificationStyle);
      } else {
        // Fallback to global storage for unauthenticated users
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_notificationStyleKey, _notificationStyle);
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Notification style updated: $_notificationStyle');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update notification style: $e');
      }
    }
  }

  /// Clear all profile data
  Future<void> clearProfileData() async {
    try {
      _nickname = null;
      _timezone = null;
      _quietHoursEnabled = false;
      _quietHoursStart = '22:00';
      _quietHoursEnd = '07:00';
      _notificationStyle = _defaultNotificationStyle;

      // Clear from user-specific storage if authenticated
      if (AuthService.instance.isAuthenticated) {
        await UserSpecificStorageService.instance.setString(_nicknameKey, '');
        await UserSpecificStorageService.instance.setString(_timezoneKey, '');
        await UserSpecificStorageService.instance
            .setBool(_quietHoursEnabledKey, false);
        await UserSpecificStorageService.instance
            .setString(_quietHoursStartKey, '22:00');
        await UserSpecificStorageService.instance
            .setString(_quietHoursEndKey, '07:00');
        await UserSpecificStorageService.instance
            .setString(_notificationStyleKey, _defaultNotificationStyle);
      } else {
        // Clear from global storage for unauthenticated users
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_nicknameKey);
        await prefs.remove(_timezoneKey);
        await prefs.remove(_quietHoursEnabledKey);
        await prefs.remove(_quietHoursStartKey);
        await prefs.remove(_quietHoursEndKey);
        await prefs.remove(_notificationStyleKey);
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Profile data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear profile data: $e');
      }
    }
  }

  /// Migrate data from global storage to user-specific storage
  Future<void> migrateToUserSpecificStorage() async {
    if (!AuthService.instance.isAuthenticated) {
      if (kDebugMode) {
        debugPrint('⚠️ Cannot migrate: user not authenticated');
      }
      return;
    }

    try {
      // Load from global storage
      final prefs = await SharedPreferences.getInstance();
      final globalNickname = prefs.getString(_nicknameKey);
      final globalTimezone = prefs.getString(_timezoneKey);
      final globalQuietHoursEnabled =
          prefs.getBool(_quietHoursEnabledKey) ?? false;
      final globalQuietHoursStart =
          prefs.getString(_quietHoursStartKey) ?? '22:00';
      final globalQuietHoursEnd = prefs.getString(_quietHoursEndKey) ?? '07:00';
      final globalNotificationStyle =
          prefs.getString(_notificationStyleKey) ?? _defaultNotificationStyle;

      // Save to user-specific storage
      if (globalNickname != null && globalNickname.isNotEmpty) {
        await UserSpecificStorageService.instance
            .setString(_nicknameKey, globalNickname);
      }
      if (globalTimezone != null && globalTimezone.isNotEmpty) {
        await UserSpecificStorageService.instance
            .setString(_timezoneKey, globalTimezone);
      }
      await UserSpecificStorageService.instance
          .setBool(_quietHoursEnabledKey, globalQuietHoursEnabled);
      await UserSpecificStorageService.instance
          .setString(_quietHoursStartKey, globalQuietHoursStart);
      await UserSpecificStorageService.instance
          .setString(_quietHoursEndKey, globalQuietHoursEnd);
      await UserSpecificStorageService.instance
          .setString(_notificationStyleKey, globalNotificationStyle);

      // Update local state
      _nickname = globalNickname;
      _timezone = globalTimezone;
      _quietHoursEnabled = globalQuietHoursEnabled;
      _quietHoursStart = globalQuietHoursStart;
      _quietHoursEnd = globalQuietHoursEnd;
      _notificationStyle = globalNotificationStyle;

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Profile data migrated to user-specific storage');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to migrate profile data: $e');
      }
    }
  }

  /// Get notification style display name
  String getStyleDisplayName(String style) {
    switch (style) {
      case 'mindful':
        return '🧘 Mindful';
      case 'coach':
        return '🏆 Coach';
      case 'toughlove':
        return '💪 Tough Love';
      case 'cram':
        return '🚨 Cram';
      default:
        return 'Unknown';
    }
  }

  /// Get notification style description
  String getStyleDescription(String style) {
    switch (style) {
      case 'mindful':
        return 'Gentle, encouraging reminders with mindfulness approach';
      case 'coach':
        return 'Motivational guidance with positive reinforcement';
      case 'toughlove':
        return 'Direct, challenging messages to push your limits';
      case 'cram':
        return 'High-intensity, urgent notifications for maximum focus';
      default:
        return 'Balanced notification style';
    }
  }

  /// Get comprehensive style information
  Map<String, dynamic> getStyleInfo(String style) {
    switch (style) {
      case 'mindful':
        return {
          'name': 'Mindful',
          'emoji': '🧘',
          'description':
              'Gentle, encouraging reminders with mindfulness approach',
          'urgency': 1,
          'priority': false,
          'tone': 'calm',
          'intensity': 'low',
        };
      case 'coach':
        return {
          'name': 'Coach',
          'emoji': '🏆',
          'description': 'Motivational guidance with positive reinforcement',
          'urgency': 2,
          'priority': false,
          'tone': 'motivational',
          'intensity': 'medium',
        };
      case 'toughlove':
        return {
          'name': 'Tough Love',
          'emoji': '💪',
          'description': 'Direct, challenging messages to push your limits',
          'urgency': 3,
          'priority': true,
          'tone': 'challenging',
          'intensity': 'high',
        };
      case 'cram':
        return {
          'name': 'Cram',
          'emoji': '🚨',
          'description':
              'High-intensity, urgent notifications for maximum focus',
          'urgency': 4,
          'priority': true,
          'tone': 'urgent',
          'intensity': 'maximum',
        };
      default:
        return {
          'name': 'Default',
          'emoji': '📱',
          'description': 'Balanced notification style',
          'urgency': 2,
          'priority': false,
          'tone': 'neutral',
          'intensity': 'medium',
        };
    }
  }

  /// Debug method to check nickname status
  void debugNicknameStatus() {
    if (kDebugMode) {
      debugPrint('🔍 NICKNAME DEBUG INFO:');
      debugPrint('   Raw nickname: $_nickname');
      debugPrint('   Has nickname: $hasNickname');
      debugPrint('   Display name: $displayName');
      debugPrint('   Personalized greeting: $personalizedGreeting');
    }
  }

  /// Force refresh nickname from storage
  Future<void> refreshNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _nickname = prefs.getString(_nicknameKey);

      // Ensure nickname is properly loaded
      if (_nickname != null && _nickname!.trim().isEmpty) {
        _nickname = null;
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('🔄 Nickname refreshed: $_nickname');
        debugPrint('   Display name: $displayName');
        debugPrint('   Has Nickname: $hasNickname');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to refresh nickname: $e');
      }
    }
  }
}
