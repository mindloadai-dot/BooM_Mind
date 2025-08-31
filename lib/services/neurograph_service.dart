import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/neurograph_models.dart';
import 'neurograph_phrase_engine.dart';

class NeuroGraphService extends ChangeNotifier {
  static final NeuroGraphService _instance = NeuroGraphService._internal();
  factory NeuroGraphService() => _instance;
  static NeuroGraphService get instance => _instance;
  NeuroGraphService._internal();

  // Data storage keys
  static const String _lastUpdatedKey = 'neurograph_last_updated';
  static const String _studyDataKey = 'neurograph_study_data';
  static const String _streakDataKey = 'neurograph_streak_data';
  static const String _recallDataKey = 'neurograph_recall_data';
  static const String _efficiencyDataKey = 'neurograph_efficiency_data';
  static const String _forgettingDataKey = 'neurograph_forgetting_data';

  // Cached data
  DateTime? _lastUpdated;
  List<StudySession> _studyData = [];
  List<StreakData> _streakData = [];
  List<RecallData> _recallData = [];
  List<EfficiencyData> _efficiencyData = [];
  List<ForgettingData> _forgettingData = [];

  // Getters
  DateTime? get lastUpdated => _lastUpdated;
  List<StudySession> get studyData => List.unmodifiable(_studyData);
  List<StreakData> get streakData => List.unmodifiable(_streakData);
  List<RecallData> get recallData => List.unmodifiable(_recallData);
  List<EfficiencyData> get efficiencyData => List.unmodifiable(_efficiencyData);
  List<ForgettingData> get forgettingData => List.unmodifiable(_forgettingData);

  bool get hasData =>
      _studyData.isNotEmpty ||
      _streakData.isNotEmpty ||
      _recallData.isNotEmpty ||
      _efficiencyData.isNotEmpty ||
      _forgettingData.isNotEmpty;

  /// Initialize the service and load cached data
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load last updated timestamp
      final lastUpdatedMillis = prefs.getInt(_lastUpdatedKey);
      if (lastUpdatedMillis != null) {
        _lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
      }

      // Load all data from local storage
      await _loadStudyData(prefs);
      await _loadStreakData(prefs);
      await _loadRecallData(prefs);
      await _loadEfficiencyData(prefs);
      await _loadForgettingData(prefs);

      debugPrint('✅ NeuroGraph service initialized');
    } catch (e) {
      debugPrint('⚠️ NeuroGraph service initialization failed: $e');
    }
  }

  /// Load study data from SharedPreferences
  Future<void> _loadStudyData(SharedPreferences prefs) async {
    try {
      final studyDataJson = prefs.getString(_studyDataKey);
      if (studyDataJson != null) {
        final List<dynamic> data = jsonDecode(studyDataJson);
        _studyData = data.map((json) => StudySession.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading study data: $e');
      _studyData = [];
    }
  }

  /// Load streak data from SharedPreferences
  Future<void> _loadStreakData(SharedPreferences prefs) async {
    try {
      final streakDataJson = prefs.getString(_streakDataKey);
      if (streakDataJson != null) {
        final List<dynamic> data = jsonDecode(streakDataJson);
        _streakData = data.map((json) => StreakData.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading streak data: $e');
      _streakData = [];
    }
  }

  /// Load recall data from SharedPreferences
  Future<void> _loadRecallData(SharedPreferences prefs) async {
    try {
      final recallDataJson = prefs.getString(_recallDataKey);
      if (recallDataJson != null) {
        final List<dynamic> data = jsonDecode(recallDataJson);
        _recallData = data.map((json) => RecallData.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading recall data: $e');
      _recallData = [];
    }
  }

  /// Load efficiency data from SharedPreferences
  Future<void> _loadEfficiencyData(SharedPreferences prefs) async {
    try {
      final efficiencyDataJson = prefs.getString(_efficiencyDataKey);
      if (efficiencyDataJson != null) {
        final List<dynamic> data = jsonDecode(efficiencyDataJson);
        _efficiencyData =
            data.map((json) => EfficiencyData.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading efficiency data: $e');
      _efficiencyData = [];
    }
  }

  /// Load forgetting curve data from SharedPreferences
  Future<void> _loadForgettingData(SharedPreferences prefs) async {
    try {
      final forgettingDataJson = prefs.getString(_forgettingDataKey);
      if (forgettingDataJson != null) {
        final List<dynamic> data = jsonDecode(forgettingDataJson);
        _forgettingData =
            data.map((json) => ForgettingData.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading forgetting data: $e');
      _forgettingData = [];
    }
  }

  /// Add study session data
  Future<void> addStudySession({
    required DateTime timestamp,
    required int durationMinutes,
    required String subject,
    required int correctAnswers,
    required int totalQuestions,
    required double averageResponseTime,
  }) async {
    try {
      final accuracy =
          totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100.0 : 0.0;
      final sessionData = StudySession(
        timestamp: timestamp,
        durationMinutes: durationMinutes,
        subject: subject,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        averageResponseTime: averageResponseTime,
        accuracy: accuracy,
      );

      _studyData.add(sessionData);
      await _saveStudyData();
      await _updateLastUpdated();
      _updateRelatedData(sessionData);

      notifyListeners();
      debugPrint('✅ Study session data added to NeuroGraph');
    } catch (e) {
      debugPrint('❌ Failed to add study session data: $e');
    }
  }

  /// Update related data based on new study session
  void _updateRelatedData(StudySession sessionData) {
    // Update streak data
    _updateStreakData(sessionData);

    // Update recall data by subject
    _updateRecallData(sessionData);

    // Update efficiency data
    _updateEfficiencyData(sessionData);

    // Update forgetting curve data
    _updateForgettingData(sessionData);
  }

  /// Update streak data
  void _updateStreakData(StudySession sessionData) {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Find existing streak entry for today
    final existingIndex =
        _streakData.indexWhere((entry) => entry.date == todayKey);

    if (existingIndex >= 0) {
      // Update existing entry
      final existing = _streakData[existingIndex];
      _streakData[existingIndex] = existing.copyWith(
        durationMinutes: existing.durationMinutes + sessionData.durationMinutes,
        sessions: existing.sessions + 1,
      );
    } else {
      // Add new entry
      _streakData.add(StreakData(
        date: todayKey,
        durationMinutes: sessionData.durationMinutes,
        sessions: 1,
        timestamp: sessionData.timestamp,
      ));
    }
  }

  /// Update recall data by subject
  void _updateRecallData(StudySession sessionData) {
    final subject = sessionData.subject;
    final accuracy = sessionData.accuracy;

    // Find existing recall entry for subject
    final existingIndex =
        _recallData.indexWhere((entry) => entry.subject == subject);

    if (existingIndex >= 0) {
      // Update existing entry with weighted average
      final existing = _recallData[existingIndex];
      final totalSessions = existing.sessions + 1;
      final newAverage =
          ((existing.averageAccuracy * existing.sessions) + accuracy) /
              totalSessions;

      _recallData[existingIndex] = existing.copyWith(
        averageAccuracy: newAverage,
        sessions: totalSessions,
        lastUpdated: sessionData.timestamp,
      );
    } else {
      // Add new entry
      _recallData.add(RecallData(
        subject: subject,
        averageAccuracy: accuracy,
        sessions: 1,
        lastUpdated: sessionData.timestamp,
      ));
    }
  }

  /// Update efficiency data
  void _updateEfficiencyData(StudySession sessionData) {
    final correctPerMinute = sessionData.durationMinutes > 0
        ? sessionData.correctAnswers / sessionData.durationMinutes
        : 0.0;

    _efficiencyData.add(EfficiencyData(
      timestamp: sessionData.timestamp,
      correctPerMinute: correctPerMinute,
      averageResponseTime: sessionData.averageResponseTime,
      sessionDuration: sessionData.durationMinutes,
    ));

    // Keep only last 30 efficiency entries
    if (_efficiencyData.length > 30) {
      _efficiencyData.removeRange(0, _efficiencyData.length - 30);
    }
  }

  /// Update forgetting curve data
  void _updateForgettingData(StudySession sessionData) {
    final accuracy = sessionData.accuracy;
    final timestamp = sessionData.timestamp;

    _forgettingData.add(ForgettingData(
      timestamp: timestamp,
      accuracy: accuracy,
      daysSinceCreation:
          0, // This would be calculated based on card creation date
      reviewed: true,
    ));

    // Keep only last 100 forgetting curve entries
    if (_forgettingData.length > 100) {
      _forgettingData.removeRange(0, _forgettingData.length - 100);
    }
  }

  /// Save study data to SharedPreferences
  Future<void> _saveStudyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studyDataJson =
          _studyData.map((session) => session.toJson()).toList();
      await prefs.setString(_studyDataKey, jsonEncode(studyDataJson));
    } catch (e) {
      debugPrint('Error saving study data: $e');
    }
  }

  /// Save streak data to SharedPreferences
  Future<void> _saveStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakDataJson =
          _streakData.map((entry) => entry.toJson()).toList();
      await prefs.setString(_streakDataKey, jsonEncode(streakDataJson));
    } catch (e) {
      debugPrint('Error saving streak data: $e');
    }
  }

  /// Save recall data to SharedPreferences
  Future<void> _saveRecallData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recallDataJson =
          _recallData.map((entry) => entry.toJson()).toList();
      await prefs.setString(_recallDataKey, jsonEncode(recallDataJson));
    } catch (e) {
      debugPrint('Error saving recall data: $e');
    }
  }

  /// Save efficiency data to SharedPreferences
  Future<void> _saveEfficiencyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final efficiencyDataJson =
          _efficiencyData.map((entry) => entry.toJson()).toList();
      await prefs.setString(_efficiencyDataKey, jsonEncode(efficiencyDataJson));
    } catch (e) {
      debugPrint('Error saving efficiency data: $e');
    }
  }

  /// Save forgetting curve data to SharedPreferences
  Future<void> _saveForgettingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final forgettingDataJson =
          _forgettingData.map((entry) => entry.toJson()).toList();
      await prefs.setString(_forgettingDataKey, jsonEncode(forgettingDataJson));
    } catch (e) {
      debugPrint('Error saving forgetting data: $e');
    }
  }

  /// Update last updated timestamp
  Future<void> _updateLastUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastUpdated = DateTime.now();
      await prefs.setInt(_lastUpdatedKey, _lastUpdated!.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error updating last updated timestamp: $e');
    }
  }

  /// Save all data to SharedPreferences
  Future<void> saveAllData() async {
    await _saveStudyData();
    await _saveStreakData();
    await _saveRecallData();
    await _saveEfficiencyData();
    await _saveForgettingData();
    await _updateLastUpdated();
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_lastUpdatedKey);
      await prefs.remove(_studyDataKey);
      await prefs.remove(_streakDataKey);
      await prefs.remove(_recallDataKey);
      await prefs.remove(_efficiencyDataKey);
      await prefs.remove(_forgettingDataKey);

      _lastUpdated = null;
      _studyData.clear();
      _streakData.clear();
      _recallData.clear();
      _efficiencyData.clear();
      _forgettingData.clear();

      notifyListeners();
      debugPrint('✅ NeuroGraph data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear NeuroGraph data: $e');
    }
  }

  /// Get quick tips based on current data
  List<Map<String, String>> getQuickTips() {
    final tips = <Map<String, String>>[];

    // Tip based on study time patterns
    if (_studyData.isNotEmpty) {
      final eveningSessions = _studyData.where((session) {
        final hour = session.timestamp.hour;
        return hour >= 19 && hour <= 21;
      }).length;

      if (eveningSessions > _studyData.length * 0.3) {
        tips.add({
          'icon': '🕐',
          'tip': 'Study 20 minutes between 7–9 pm for best retention',
        });
      }
    }

    // Tip based on recall data
    if (_recallData.isNotEmpty) {
      final weakestSubject = _recallData
          .reduce((a, b) => a.averageAccuracy < b.averageAccuracy ? a : b);

      if (weakestSubject.averageAccuracy < 70) {
        tips.add({
          'icon': '🧠',
          'tip': 'Review ${weakestSubject.subject} - your weakest subject',
        });
      }
    }

    // Tip based on efficiency data
    if (_efficiencyData.isNotEmpty) {
      final avgCorrectPerMin = _efficiencyData
              .map((e) => e.correctPerMinute)
              .reduce((a, b) => a + b) /
          _efficiencyData.length;

      if (avgCorrectPerMin < 2.0) {
        tips.add({
          'icon': '🎯',
          'tip': 'Use Focus Mode for 25-minute blocks to improve efficiency',
        });
      }
    }

    // Add default tips if not enough data
    while (tips.length < 3) {
      tips.add({
        'icon': '📚',
        'tip': 'Review your weakest subjects first',
      });
    }

    return tips.take(3).toList();
  }

  /// Generate sample data for testing
  Future<void> generateSampleData() async {
    try {
      final now = DateTime.now();
      final random = Random();

      // Generate sample study sessions for the last 30 days
      for (int i = 0; i < 30; i++) {
        final sessionDate = now.subtract(Duration(days: i));
        final sessionsPerDay = random.nextInt(3) + 1;

        for (int j = 0; j < sessionsPerDay; j++) {
          final hour = random.nextInt(14) + 8; // 8 AM to 10 PM
          final sessionTime = DateTime(
              sessionDate.year, sessionDate.month, sessionDate.day, hour);

          await addStudySession(
            timestamp: sessionTime,
            durationMinutes: random.nextInt(45) + 15, // 15-60 minutes
            subject: [
              'Math',
              'Science',
              'History',
              'Language',
              'Literature'
            ][random.nextInt(5)],
            correctAnswers: random.nextInt(20) + 5,
            totalQuestions: random.nextInt(10) + 15,
            averageResponseTime: random.nextDouble() * 5 + 1, // 1-6 seconds
          );
        }
      }

      await saveAllData();
      debugPrint('✅ Sample NeuroGraph data generated');
    } catch (e) {
      debugPrint('❌ Failed to generate sample data: $e');
    }
  }

  // ============================================================================
  // COMPACT METRICS OBJECT
  // ============================================================================

  /// Get compact metrics object for analysis and tips
  Map<String, dynamic> getCompactMetrics() {
    final metrics = <String, dynamic>{};

    // Basic study metrics
    final totalMinutes = _studyData.fold<int>(
        0, (sum, session) => sum + session.durationMinutes);
    final studyDays = _streakData.length;
    final streakDays = _calculateCurrentStreak();

    metrics['total_minutes'] = totalMinutes;
    metrics['study_days'] = studyDays;
    metrics['streak_days'] = streakDays;

    // Consistency index (percentage of days studied in last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final recentStudyDays = _streakData.where((entry) {
      final entryDate = DateTime.parse(entry.date);
      return entryDate.isAfter(thirtyDaysAgo);
    }).length;
    metrics['consistency_idx'] = ((recentStudyDays / 30) * 100).round();

    // Due count (simulated - in real app this would come from spaced repetition system)
    metrics['due_count'] = _calculateDueCount();

    // Recall rate (average accuracy across all sessions)
    if (_studyData.isNotEmpty) {
      final avgAccuracy = _studyData
              .map((session) => session.accuracy)
              .reduce((a, b) => a + b) /
          _studyData.length;
      metrics['recall_rate'] = avgAccuracy.round();
    } else {
      metrics['recall_rate'] = 0;
    }

    // Response time (P50 latency)
    if (_efficiencyData.isNotEmpty) {
      final responseTimes = _efficiencyData
          .map((entry) => entry.averageResponseTime)
          .toList()
        ..sort();
      final p50Index = (responseTimes.length * 0.5).round();
      metrics['latency_ms_p50'] = (responseTimes[p50Index] * 1000).round();
    } else {
      metrics['latency_ms_p50'] = 2000;
    }

    // Best hour band
    metrics['best_hour_band'] = _calculateBestHourBand();

    // Spaced repetition adherence (simulated)
    metrics['spaced_rep_adherence'] = _calculateSpacedRepAdherence();

    // Mastery velocity (improvement rate)
    metrics['mastery_velocity'] = _calculateMasteryVelocity();

    // Coverage ratio (percentage of subjects studied)
    metrics['coverage_ratio'] = _calculateCoverageRatio();

    // Interruptions (simulated)
    metrics['interruptions'] = _calculateInterruptions();

    // Notification frequency (simulated)
    metrics['notification_frequency'] = _calculateNotificationFrequency();

    // Best subject
    metrics['best_subject'] = _calculateBestSubject();

    return metrics;
  }

  // ============================================================================
  // ANALYSIS & TIPS GENERATION
  // ============================================================================

  /// Get analysis text based on current metrics
  List<String> getAnalysis() {
    final metrics = getCompactMetrics();
    return NeuroGraphPhraseEngine.generateAnalysis(metrics);
  }

  /// Get quick tips based on current metrics
  List<String> getAnalysisQuickTips() {
    final metrics = getCompactMetrics();
    return NeuroGraphPhraseEngine.generateQuickTips(metrics);
  }

  /// Get cached analysis (for performance)
  List<String>? _cachedAnalysis;
  String? _cachedAnalysisHash;

  List<String> getCachedAnalysis() {
    final metrics = getCompactMetrics();
    final currentHash = NeuroGraphPhraseEngine.generateMetricsHash(metrics);

    if (_cachedAnalysis == null || _cachedAnalysisHash != currentHash) {
      _cachedAnalysis = getAnalysis();
      _cachedAnalysisHash = currentHash;
    }

    return _cachedAnalysis!;
  }

  /// Get cached quick tips (for performance)
  List<String>? _cachedQuickTips;
  String? _cachedQuickTipsHash;

  List<String> getCachedQuickTips() {
    final metrics = getCompactMetrics();
    final currentHash = NeuroGraphPhraseEngine.generateMetricsHash(metrics);

    if (_cachedQuickTips == null || _cachedQuickTipsHash != currentHash) {
      _cachedQuickTips = getAnalysisQuickTips();
      _cachedQuickTipsHash = currentHash;
    }

    return _cachedQuickTips!;
  }

  // ============================================================================
  // HELPER METHODS FOR METRICS CALCULATION
  // ============================================================================

  int _calculateCurrentStreak() {
    if (_streakData.isEmpty) return 0;

    final sortedDates = _streakData
        .map((entry) => DateTime.parse(entry.date))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime? currentDate = DateTime.now();

    for (final date in sortedDates) {
      final daysDiff = currentDate!.difference(date).inDays;
      if (daysDiff <= 1) {
        streak++;
        currentDate = date;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateDueCount() {
    // Simulated due count - in real app this would come from spaced repetition system
    if (_studyData.isEmpty) return 0;

    final random = Random(42); // Deterministic for consistent results
    return random.nextInt(50) + 5; // 5-55 cards
  }

  String _calculateBestHourBand() {
    if (_studyData.isEmpty) return '9-11 AM';

    final hourCounts = <int, int>{};
    for (final session in _studyData) {
      final hour = session.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    final mostFrequentHour =
        hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    if (mostFrequentHour < 12) return '9-11 AM';
    if (mostFrequentHour < 17) return '2-4 PM';
    return '7-9 PM';
  }

  int _calculateSpacedRepAdherence() {
    // Simulated adherence - in real app this would be calculated from actual spaced repetition data
    if (_studyData.isEmpty) return 85;

    final random = Random(42);
    return random.nextInt(30) + 70; // 70-100%
  }

  int _calculateMasteryVelocity() {
    if (_studyData.length < 2) return 75;

    // Calculate improvement over time
    final sortedSessions = _studyData
        .map((session) => MapEntry(session.timestamp, session.accuracy))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedSessions.length < 2) return 75;

    final firstHalf = sortedSessions.take(sortedSessions.length ~/ 2);
    final secondHalf = sortedSessions.skip(sortedSessions.length ~/ 2);

    final firstAvg = firstHalf.map((e) => e.value).reduce((a, b) => a + b) /
        firstHalf.length;
    final secondAvg = secondHalf.map((e) => e.value).reduce((a, b) => a + b) /
        secondHalf.length;

    final improvement = ((secondAvg - firstAvg) / firstAvg * 100).round();
    return (75 + improvement).clamp(0, 100).toInt();
  }

  int _calculateCoverageRatio() {
    if (_studyData.isEmpty) return 0;

    final uniqueSubjects =
        _studyData.map((session) => session.subject).toSet().length;

    // Assume 5 main subjects for coverage calculation
    return (uniqueSubjects / 5 * 100).round().clamp(0, 100);
  }

  int _calculateInterruptions() {
    // Simulated interruptions per session
    if (_studyData.isEmpty) return 0;

    final random = Random(42);
    return random.nextInt(3) + 1; // 1-4 interruptions
  }

  int _calculateNotificationFrequency() {
    // Simulated notification frequency
    if (_studyData.isEmpty) return 2;

    final random = Random(42);
    return random.nextInt(4) + 1; // 1-5 notifications
  }

  String _calculateBestSubject() {
    if (_recallData.isEmpty) return 'General';

    final bestSubject = _recallData
        .reduce((a, b) => a.averageAccuracy > b.averageAccuracy ? a : b);

    return bestSubject.subject;
  }
}
