import 'dart:math';
import '../constants/strings_neurograph_offline.dart';

// ============================================================================
// NEUROGRAPH PHRASE ENGINE
// ============================================================================
// Handles placeholder replacement and deterministic phrase selection
// for stable, offline text generation.

class NeuroGraphPhraseEngine {
  // ============================================================================
  // PLACEHOLDER REPLACEMENT
  // ============================================================================

  /// Replaces placeholders in a phrase with actual values
  static String formatPhrase(String phrase, Map<String, dynamic> placeholders) {
    String result = phrase;

    placeholders.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });

    return result;
  }

  // ============================================================================
  // DETERMINISTIC PHRASE SELECTION
  // ============================================================================

  /// Selects a phrase from a category using deterministic RNG
  static String selectPhrase(List<String> phrases, [String? seed]) {
    if (phrases.isEmpty) return '';

    // Use seed if provided, otherwise use current phrases hash
    int seedValue = seed?.hashCode ?? phrases.hashCode;
    final random = Random(seedValue);

    return phrases[random.nextInt(phrases.length)];
  }

  // ============================================================================
  // ANALYSIS TEXT GENERATION
  // ============================================================================

  /// Generates analysis text based on metrics and rules
  static List<String> generateAnalysis(Map<String, dynamic> metrics) {
    final List<String> analysis = [];
    final Map<String, dynamic> placeholders = _buildPlaceholders(metrics);

    // Always include one overview line
    analysis.add(formatPhrase(
        selectPhrase(NeuroGraphPhrases.overview, 'overview'), placeholders));

    // Apply conditional rules for additional lines
    final int consistency = metrics['consistency_idx'] ?? 0;
    final int adherence = metrics['spaced_rep_adherence'] ?? 0;
    final int dueCount = metrics['due_count'] ?? 0;
    final int latency = metrics['latency_ms_p50'] ?? 0;

    // Low consistency rule
    if (consistency < 60) {
      analysis.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.consistency, 'consistency'),
          placeholders));
      analysis
          .add(selectPhrase(NeuroGraphPhrases.risk_alerts, 'risk_consistency'));
    }

    // Poor spaced-rep health rule
    else if (adherence < 70 || dueCount > 20) {
      analysis.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.spaced_rep, 'spaced_rep'),
          placeholders));
    }

    // Slow responses rule
    else if (latency > 2500) {
      analysis.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.efficiency_pacing, 'efficiency'),
          placeholders));
    }

    // Default: time of day insight
    else {
      analysis.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.time_of_day, 'time_of_day'),
          placeholders));
    }

    // Add one more insight based on best performing metric
    final int recallRate = metrics['recall_rate'] ?? 0;
    final int coverageRatio = metrics['coverage_ratio'] ?? 0;

    if (recallRate > 80) {
      analysis.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.recall_accuracy, 'recall'),
          placeholders));
    } else if (coverageRatio > 70) {
      analysis.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.coverage_interleaving, 'coverage'),
          placeholders));
    }

    return analysis;
  }

  // ============================================================================
  // QUICK TIPS GENERATION
  // ============================================================================

  /// Generates exactly 3 quick tips based on metrics
  static List<String> generateQuickTips(Map<String, dynamic> metrics) {
    final List<String> tips = [];
    final Map<String, dynamic> placeholders = _buildPlaceholders(metrics);

    // Tip 1: Micro-habit tip (always include)
    tips.add(selectPhrase(NeuroGraphPhrases.quick_tips, 'micro_habit'));

    // Tip 2: Due cards tip (if applicable)
    final int dueCount = metrics['due_count'] ?? 0;
    if (dueCount > 0) {
      tips.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.quick_tips, 'due_cards'),
          placeholders));
    } else {
      // Alternative: time-based tip
      tips.add(formatPhrase(
          selectPhrase(NeuroGraphPhrases.quick_tips, 'time_based'),
          placeholders));
    }

    // Tip 3: Pacing/interleaving tip
    tips.add(selectPhrase(NeuroGraphPhrases.quick_tips, 'pacing'));

    return tips.take(3).toList(); // Ensure exactly 3 tips
  }

  // ============================================================================
  // PLACEHOLDER BUILDING
  // ============================================================================

  /// Converts metrics into placeholder map for phrase formatting
  static Map<String, dynamic> _buildPlaceholders(Map<String, dynamic> metrics) {
    final Map<String, dynamic> placeholders = {};

    // Basic metrics
    placeholders['total_minutes'] = metrics['total_minutes'] ?? 0;
    placeholders['study_days'] = metrics['study_days'] ?? 0;
    placeholders['streak_days'] = metrics['streak_days'] ?? 0;
    placeholders['due_count'] = metrics['due_count'] ?? 0;
    placeholders['recall_rate'] = metrics['recall_rate'] ?? 0;
    placeholders['latency_ms_p50'] = metrics['latency_ms_p50'] ?? 0;
    placeholders['consistency_idx'] = metrics['consistency_idx'] ?? 0;
    placeholders['best_hour_band'] = metrics['best_hour_band'] ?? '9-11 AM';
    placeholders['mastery_velocity'] = metrics['mastery_velocity'] ?? 0;
    placeholders['coverage_ratio'] = metrics['coverage_ratio'] ?? 0;
    placeholders['interruptions'] = metrics['interruptions'] ?? 0;
    placeholders['notification_frequency'] =
        metrics['notification_frequency'] ?? 0;
    placeholders['best_subject'] = metrics['best_subject'] ?? 'General';

    // Quality descriptors
    placeholders['consistency_quality'] =
        NeuroGraphPhrases.getConsistencyQuality(
            placeholders['consistency_idx']);
    placeholders['recall_quality'] =
        NeuroGraphPhrases.getRecallQuality(placeholders['recall_rate']);
    placeholders['pacing_quality'] =
        NeuroGraphPhrases.getPacingQuality(placeholders['latency_ms_p50']);
    placeholders['notification_quality'] =
        NeuroGraphPhrases.getNotificationQuality(
            placeholders['notification_frequency']);

    return placeholders;
  }

  // ============================================================================
  // CACHING UTILITIES
  // ============================================================================

  /// Generates a hash for metrics to detect changes
  static String generateMetricsHash(Map<String, dynamic> metrics) {
    final sortedKeys = metrics.keys.toList()..sort();
    final hashString =
        sortedKeys.map((key) => '$key:${metrics[key]}').join('|');
    return hashString.hashCode.toString();
  }
}
