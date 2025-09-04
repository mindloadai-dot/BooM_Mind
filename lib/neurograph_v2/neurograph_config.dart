/// NeuroGraph V2 Configuration
/// Contains all tunable parameters and feature flags for the analytics system
class NeuroGraphConfig {
  // Feature Flag - NeuroGraph V2 is now the ONLY system
  static const bool neurographV2 = true; // Always true - V1 is deprecated

  // Chart Configuration
  static const int learningCurveDays = 90;
  static const int emaPeriod = 7;
  static const double goalAccuracyMin = 0.8;
  static const double goalAccuracyMax = 0.9;

  // Spaced Review Configuration
  static const double baseLambda = 0.18;
  static const double recallThreshold = 0.7;
  static const int forgettingCurveDays = 120;

  // Retrieval Practice Configuration
  static const int sessionGapMinutes = 30;
  static const int examPredictionDays = 10; // 7-14 days range

  // Calibration Configuration
  static const int confidenceBins = 10;
  static const double brierThreshold = 0.25;
  static const double eceThreshold = 0.1;

  // Mastery Configuration
  static const int masteryMinAttempts = 3;
  static const double masteryAccuracyThreshold = 0.85;
  static const double practicingAccuracyThreshold = 0.6;
  static const int masteryConsecutiveCorrect = 3;
  static const int masteryWindowAttempts = 10;
  static const int masteryAnalysisWeeks = 12;

  // Consistency Configuration
  static const int consistencyWeeks = 8;

  // Performance Configuration
  static const int maxAttemptsPerQuery = 1000;
  static const int isolateTimeoutSeconds = 30;
  static const int maxDataPoints = 500;

  // UI Configuration
  static const double chartHeight = 300.0;
  static const double chartPadding = 16.0;
  static const double legendFontSize = 12.0;
  static const double tooltipFontSize = 14.0;

  // Colors
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFF4CAF50;
  static const int accentColor = 0xFFFF9800;
  static const int errorColor = 0xFFF44336;
  static const int successColor = 0xFF4CAF50;
  static const int warningColor = 0xFFFF9800;
  static const int goalColor = 0xFF9C27B0;

  // Timezone Configuration - Dynamic with fallback
  static const String defaultTimezone = 'America/Chicago';

  /// Get the user's timezone dynamically, falling back to default
  static Future<String> getUserTimezone() async {
    try {
      // Import flutter_timezone for dynamic timezone detection
      // This will be handled by the repository layer
      return defaultTimezone;
    } catch (e) {
      return defaultTimezone;
    }
  }

  /// Validate configuration parameters
  static void validateConfiguration() {
    assert(learningCurveDays > 0, 'learningCurveDays must be positive');
    assert(emaPeriod > 0, 'emaPeriod must be positive');
    assert(goalAccuracyMin >= 0 && goalAccuracyMin <= 1,
        'goalAccuracyMin must be between 0 and 1');
    assert(goalAccuracyMax >= 0 && goalAccuracyMax <= 1,
        'goalAccuracyMax must be between 0 and 1');
    assert(goalAccuracyMin < goalAccuracyMax,
        'goalAccuracyMin must be less than goalAccuracyMax');
    assert(baseLambda > 0, 'baseLambda must be positive');
    assert(recallThreshold >= 0 && recallThreshold <= 1,
        'recallThreshold must be between 0 and 1');
    assert(forgettingCurveDays > 0, 'forgettingCurveDays must be positive');
    assert(sessionGapMinutes > 0, 'sessionGapMinutes must be positive');
    assert(examPredictionDays > 0, 'examPredictionDays must be positive');
    assert(confidenceBins > 0, 'confidenceBins must be positive');
    assert(masteryMinAttempts > 0, 'masteryMinAttempts must be positive');
    assert(masteryAccuracyThreshold >= 0 && masteryAccuracyThreshold <= 1,
        'masteryAccuracyThreshold must be between 0 and 1');
    assert(practicingAccuracyThreshold >= 0 && practicingAccuracyThreshold <= 1,
        'practicingAccuracyThreshold must be between 0 and 1');
    assert(masteryConsecutiveCorrect > 0,
        'masteryConsecutiveCorrect must be positive');
    assert(masteryWindowAttempts > 0, 'masteryWindowAttempts must be positive');
    assert(masteryAnalysisWeeks > 0, 'masteryAnalysisWeeks must be positive');
    assert(consistencyWeeks > 0, 'consistencyWeeks must be positive');
    assert(maxAttemptsPerQuery > 0, 'maxAttemptsPerQuery must be positive');
    assert(isolateTimeoutSeconds > 0, 'isolateTimeoutSeconds must be positive');
    assert(maxDataPoints > 0, 'maxDataPoints must be positive');
    assert(chartHeight > 0, 'chartHeight must be positive');
    assert(chartPadding >= 0, 'chartPadding must be non-negative');
    assert(legendFontSize > 0, 'legendFontSize must be positive');
    assert(tooltipFontSize > 0, 'tooltipFontSize must be positive');
  }
}
