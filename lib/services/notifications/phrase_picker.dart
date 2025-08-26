import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:crypto/crypto.dart' as crypto;

class PhrasePicker {
  static Map<String, List<String>> _tones = {};
  static bool _initialized = false;

  // Precomputed checksum for integrity (update if file changes)
  // SHA-256 of assets/phrases/notification_phrases.json
  static const String phrasesSha256 = '6b22d3e30f62db955a5ca117236c14ca15a319d5606be64540027850453c6a80';

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final data = await rootBundle.loadString('assets/phrases/notification_phrases.json');
      final bytes = utf8.encode(data);
      final hash = crypto.sha256.convert(bytes).toString();
      if (hash.toLowerCase() != phrasesSha256) {
        throw Exception('Phrase library checksum mismatch');
      }
      final jsonData = json.decode(data) as Map<String, dynamic>;
      final tones = jsonData['tones'] as Map<String, dynamic>;
      _tones = tones.map((k, v) => MapEntry(k, List<String>.from(v as List)));
      _initialized = true;
    } catch (_) {
      // Fallback minimal constants (deterministic)
      _tones = {
        'coach': ['You’re building momentum — keep going.'],
        'mindful': ['Take a breath. Study gently.'],
        'cram': ['Clock’s ticking — dive in now.'],
        'toughLove': ['Stop making excuses. Start reviewing.'],
      };
      _initialized = true;
    }
  }

  // Simple no-repeat window with LRU cache per tone
  static final Map<String, List<int>> _recentIdx = {
    'coach': <int>[], 'mindful': <int>[], 'cram': <int>[], 'toughLove': <int>[]
  };
  static const int noRepeatWindow = 5;

  static ({String text, String key}) pick(String tone) {
    final list = _tones[tone] ?? const <String>[];
    if (list.isEmpty) return (text: '', key: '');
    // Deterministic selection: rotate through phrases without repeat window collisions
    final recent = _recentIdx[tone]!..removeWhere((_) => false);
    int idx = 0;
    for (var i = 0; i < list.length; i++) {
      if (!recent.contains(i)) { idx = i; break; }
    }
    // Update LRU
    recent.insert(0, idx);
    while (recent.length > noRepeatWindow) { recent.removeLast(); }
    final phrase = list[idx];
    final key = crypto.sha256.convert(utf8.encode('$tone|$phrase|${DateTime.now().toLocal().toIso8601String().split("T").first}')).toString();
    return (text: phrase, key: key);
  }
}


