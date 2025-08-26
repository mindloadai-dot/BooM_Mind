import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflinePrefs {
  final bool stoEnabled;
  final bool quietEnabled;
  final String quietStart; // HH:mm
  final String quietEnd; // HH:mm
  final bool digestEnabled;
  final String digestTime; // HH:mm
  final int globalMaxPerDay;
  final Map<String, int> perToneMax;
  final int minGapMinutes;
  final int maxPerWeek;
  final bool deadlineAlerts;
  final bool timeSensitiveIOS;
  final List<String> preferredTones;

  OfflinePrefs({
    this.stoEnabled = true,
    this.quietEnabled = true,
    this.quietStart = '22:00',
    this.quietEnd = '07:00',
    this.digestEnabled = true,
    this.digestTime = '20:30',
    this.globalMaxPerDay = 5, // Reduced from 6 to be more reasonable
    Map<String, int>? perToneMax,
    this.minGapMinutes = 120,
    this.maxPerWeek = 25,
    this.deadlineAlerts = true,
    this.timeSensitiveIOS = true,
    List<String>? preferredTones,
  })  : perToneMax = perToneMax ?? const {'cram': 1, 'toughLove': 2, 'coach': 2, 'mindful': 2},
        preferredTones = preferredTones ?? const ['coach', 'mindful'];

  Map<String, dynamic> toJson() => {
        'stoEnabled': stoEnabled,
        'quietHours': {'enabled': quietEnabled, 'start': quietStart, 'end': quietEnd},
        'eveningDigest': {'enabled': digestEnabled, 'time': digestTime},
        'frequency': {'globalMaxPerDay': globalMaxPerDay, ...perToneMax},
        'fatigue': {'minGapMinutes': minGapMinutes, 'maxPerWeek': maxPerWeek},
        'deadlineAlerts': {'enabled': deadlineAlerts, 'timeSensitiveIOS': timeSensitiveIOS},
        'preferredTones': preferredTones,
      };

  static OfflinePrefs fromJson(Map<String, dynamic> json) {
    final fq = (json['frequency'] as Map<String, dynamic>? ?? {});
    final qh = (json['quietHours'] as Map<String, dynamic>? ?? {});
    final eg = (json['eveningDigest'] as Map<String, dynamic>? ?? {});
    final ft = (json['fatigue'] as Map<String, dynamic>? ?? {});
    final da = (json['deadlineAlerts'] as Map<String, dynamic>? ?? {});
    return OfflinePrefs(
      stoEnabled: json['stoEnabled'] as bool? ?? true,
      quietEnabled: qh['enabled'] as bool? ?? true,
      quietStart: qh['start'] as String? ?? '22:00',
      quietEnd: qh['end'] as String? ?? '07:00',
      digestEnabled: eg['enabled'] as bool? ?? true,
      digestTime: eg['time'] as String? ?? '20:30',
      globalMaxPerDay: fq['globalMaxPerDay'] as int? ?? 6,
      perToneMax: {
        'cram': fq['cram'] as int? ?? 1,
        'toughLove': fq['toughLove'] as int? ?? 2,
        'coach': fq['coach'] as int? ?? 2,
        'mindful': fq['mindful'] as int? ?? 2,
      },
      minGapMinutes: ft['minGapMinutes'] as int? ?? 120,
      maxPerWeek: ft['maxPerWeek'] as int? ?? 25,
      deadlineAlerts: da['enabled'] as bool? ?? true,
      timeSensitiveIOS: da['timeSensitiveIOS'] as bool? ?? true,
      preferredTones: (json['preferredTones'] as List<dynamic>? ?? const ['coach', 'mindful']).cast<String>(),
    );
  }
}

class OfflineMetrics {
  String? lastSentAt;
  Map<String, int> sentDay = {'cram': 0, 'toughLove': 0, 'coach': 0, 'mindful': 0, 'total': 0};
  int weekTotal = 0;
  List<String> recentKeys = [];
  int streak = 0;
  String? lastOpenedAt;
  double openRate30d = 0.0;

  Map<String, dynamic> toJson() => {
        'lastSentAt': lastSentAt,
        'sentCounts': {'day': sentDay, 'weekTotal': weekTotal},
        'recentKeys': recentKeys,
        'streak': streak,
        'lastOpenedAt': lastOpenedAt,
        'openRate30d': openRate30d,
      };

  static OfflineMetrics fromJson(Map<String, dynamic> json) {
    final sc = json['sentCounts'] as Map<String, dynamic>? ?? {};
    return OfflineMetrics()
      ..lastSentAt = json['lastSentAt'] as String?
      ..sentDay = (sc['day'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt()))
      ..weekTotal = (sc['weekTotal'] as num?)?.toInt() ?? 0
      ..recentKeys = (json['recentKeys'] as List<dynamic>? ?? []).cast<String>()
      ..streak = (json['streak'] as num?)?.toInt() ?? 0
      ..lastOpenedAt = json['lastOpenedAt'] as String?
      ..openRate30d = (json['openRate30d'] as num?)?.toDouble() ?? 0.0;
  }
}

class LocalStateStore {
  static const _prefsKey = 'offline_prefs';
  static const _metricsKey = 'offline_metrics';
  static Future<SharedPreferences> get _sp async => SharedPreferences.getInstance();

  static Future<OfflinePrefs> loadPrefs() async {
    final sp = await _sp;
    final data = sp.getString(_prefsKey);
    if (data == null) return OfflinePrefs();
    try {
      return OfflinePrefs.fromJson(json.decode(data));
    } catch (_) {
      return OfflinePrefs();
    }
  }

  static Future<void> savePrefs(OfflinePrefs p) async {
    final sp = await _sp;
    await sp.setString(_prefsKey, json.encode(p.toJson()));
  }

  static Future<OfflineMetrics> loadMetrics() async {
    final sp = await _sp;
    final data = sp.getString(_metricsKey);
    if (data == null) return OfflineMetrics();
    try {
      return OfflineMetrics.fromJson(json.decode(data));
    } catch (_) {
      return OfflineMetrics();
    }
  }

  static Future<void> saveMetrics(OfflineMetrics m) async {
    final sp = await _sp;
    await sp.setString(_metricsKey, json.encode(m.toJson()));
  }
}


