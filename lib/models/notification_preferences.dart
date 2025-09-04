import 'package:flutter/foundation.dart';

/// Model for notification category preferences
class NotificationPreferences {
  bool studyReminders;
  bool streakAlerts;
  bool examDeadlines;
  bool inactivityNudges;
  bool eventTriggers;
  bool promotional;

  NotificationPreferences({
    this.studyReminders = true,
    this.streakAlerts = true,
    this.examDeadlines = true,
    this.inactivityNudges = false,
    this.eventTriggers = true,
    this.promotional = false,
  });

  /// Create from JSON
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      studyReminders: json['studyReminders'] ?? true,
      streakAlerts: json['streakAlerts'] ?? true,
      examDeadlines: json['examDeadlines'] ?? true,
      inactivityNudges: json['inactivityNudges'] ?? false,
      eventTriggers: json['eventTriggers'] ?? true,
      promotional: json['promotional'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'studyReminders': studyReminders,
      'streakAlerts': streakAlerts,
      'examDeadlines': examDeadlines,
      'inactivityNudges': inactivityNudges,
      'eventTriggers': eventTriggers,
      'promotional': promotional,
    };
  }

  /// Create a copy with updated values
  NotificationPreferences copyWith({
    bool? studyReminders,
    bool? streakAlerts,
    bool? examDeadlines,
    bool? inactivityNudges,
    bool? eventTriggers,
    bool? promotional,
  }) {
    return NotificationPreferences(
      studyReminders: studyReminders ?? this.studyReminders,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      examDeadlines: examDeadlines ?? this.examDeadlines,
      inactivityNudges: inactivityNudges ?? this.inactivityNudges,
      eventTriggers: eventTriggers ?? this.eventTriggers,
      promotional: promotional ?? this.promotional,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPreferences &&
        other.studyReminders == studyReminders &&
        other.streakAlerts == streakAlerts &&
        other.examDeadlines == examDeadlines &&
        other.inactivityNudges == inactivityNudges &&
        other.eventTriggers == eventTriggers &&
        other.promotional == promotional;
  }

  @override
  int get hashCode {
    return Object.hash(
      studyReminders,
      streakAlerts,
      examDeadlines,
      inactivityNudges,
      eventTriggers,
      promotional,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferences('
        'studyReminders: $studyReminders, '
        'streakAlerts: $streakAlerts, '
        'examDeadlines: $examDeadlines, '
        'inactivityNudges: $inactivityNudges, '
        'eventTriggers: $eventTriggers, '
        'promotional: $promotional)';
  }
}

/// Service to manage notification preferences
class NotificationPreferencesService extends ChangeNotifier {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  static NotificationPreferencesService get instance => _instance;
  NotificationPreferencesService._internal();

  NotificationPreferences _preferences = NotificationPreferences();
  bool _isLoaded = false;

  /// Get current preferences
  NotificationPreferences get preferences => _preferences;
  bool get isLoaded => _isLoaded;

  /// Initialize and load preferences
  Future<void> initialize() async {
    try {
      // TODO: Load from SharedPreferences or user profile
      // For now, use defaults
      _preferences = NotificationPreferences();
      _isLoaded = true;
      notifyListeners();
      debugPrint('✅ Notification preferences initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification preferences: $e');
      _preferences = NotificationPreferences();
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Update a specific preference
  Future<void> updatePreference(String category, bool value) async {
    try {
      switch (category) {
        case 'studyReminders':
          _preferences = _preferences.copyWith(studyReminders: value);
          break;
        case 'streakAlerts':
          _preferences = _preferences.copyWith(streakAlerts: value);
          break;
        case 'examDeadlines':
          _preferences = _preferences.copyWith(examDeadlines: value);
          break;
        case 'inactivityNudges':
          _preferences = _preferences.copyWith(inactivityNudges: value);
          break;
        case 'eventTriggers':
          _preferences = _preferences.copyWith(eventTriggers: value);
          break;
        case 'promotional':
          _preferences = _preferences.copyWith(promotional: value);
          break;
        default:
          debugPrint('❌ Unknown notification category: $category');
          return;
      }

      // TODO: Save to SharedPreferences or user profile
      notifyListeners();
      debugPrint('✅ Updated $category to $value');
    } catch (e) {
      debugPrint('❌ Failed to update preference $category: $e');
    }
  }

  /// Get preference value by category
  bool getPreference(String category) {
    switch (category) {
      case 'studyReminders':
        return _preferences.studyReminders;
      case 'streakAlerts':
        return _preferences.streakAlerts;
      case 'examDeadlines':
        return _preferences.examDeadlines;
      case 'inactivityNudges':
        return _preferences.inactivityNudges;
      case 'eventTriggers':
        return _preferences.eventTriggers;
      case 'promotional':
        return _preferences.promotional;
      default:
        return false;
    }
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      _preferences = NotificationPreferences();
      // TODO: Save to SharedPreferences or user profile
      notifyListeners();
      debugPrint('✅ Reset notification preferences to defaults');
    } catch (e) {
      debugPrint('❌ Failed to reset preferences: $e');
    }
  }
}
