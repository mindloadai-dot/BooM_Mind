// ============================================================================
// NEUROGRAPH OFFLINE PHRASES BUNDLE
// ============================================================================
// This file contains all text templates and phrases used in the NeuroGraph
// analysis system. All content is offline-only with simple placeholders.

class NeuroGraphPhrases {
  // ============================================================================
  // OVERVIEW PHRASES
  // ============================================================================
  static const List<String> overview = [
    "You've studied for {total_minutes} minutes across {study_days} days.",
    "Your learning journey spans {study_days} days with {total_minutes} minutes of focused study.",
    "Over {study_days} days, you've invested {total_minutes} minutes in your knowledge.",
    "Your study pattern shows {total_minutes} minutes across {study_days} active days.",
  ];

  // ============================================================================
  // CONSISTENCY PHRASES
  // ============================================================================
  static const List<String> consistency = [
    "Your consistency index is {consistency_idx}% - {consistency_quality}.",
    "You're maintaining {consistency_idx}% consistency in your study routine.",
    "Your study consistency stands at {consistency_idx}% this period.",
    "You've achieved {consistency_idx}% consistency in your learning schedule.",
  ];

  // ============================================================================
  // TIME OF DAY PHRASES
  // ============================================================================
  static const List<String> time_of_day = [
    "Your peak study hours are {best_hour_band} - when you're most productive.",
    "You're most active during {best_hour_band} - your natural study window.",
    "Your optimal study time is {best_hour_band} - leverage this pattern.",
    "You tend to study best during {best_hour_band} - your brain's prime time.",
  ];

  // ============================================================================
  // SPACED REPETITION PHRASES
  // ============================================================================
  static const List<String> spaced_rep = [
    "You have {due_count} cards waiting for review - spaced repetition needs attention.",
    "Your spaced repetition system shows {due_count} overdue cards.",
    "There are {due_count} cards due for review - time to catch up.",
    "Your review queue has {due_count} cards waiting - spaced repetition is key.",
  ];

  // ============================================================================
  // RECALL ACCURACY PHRASES
  // ============================================================================
  static const List<String> recall_accuracy = [
    "Your recall rate is {recall_rate}% - {recall_quality} performance.",
    "You're achieving {recall_rate}% accuracy in your reviews.",
    "Your memory retention shows {recall_rate}% success rate.",
    "You're maintaining {recall_rate}% recall accuracy across sessions.",
  ];

  // ============================================================================
  // EFFICIENCY PACING PHRASES
  // ============================================================================
  static const List<String> efficiency_pacing = [
    "Your response time averages {latency_ms_p50}ms - {pacing_quality} pace.",
    "You're responding in {latency_ms_p50}ms on average - {pacing_quality} speed.",
    "Your average response time is {latency_ms_p50}ms - {pacing_quality} rhythm.",
    "You're processing cards at {latency_ms_p50}ms - {pacing_quality} efficiency.",
  ];

  // ============================================================================
  // SUBJECT MASTERY PHRASES
  // ============================================================================
  static const List<String> subject_mastery = [
    "Your strongest subject is {best_subject} with {mastery_velocity}% mastery velocity.",
    "You're excelling in {best_subject} - your mastery velocity is {mastery_velocity}%.",
    "Your top-performing area is {best_subject} at {mastery_velocity}% velocity.",
    "You're mastering {best_subject} fastest with {mastery_velocity}% velocity.",
  ];

  // ============================================================================
  // COVERAGE INTERLEAVING PHRASES
  // ============================================================================
  static const List<String> coverage_interleaving = [
    "You're covering {coverage_ratio}% of your study material - good breadth.",
    "Your material coverage is {coverage_ratio}% - balanced learning approach.",
    "You've covered {coverage_ratio}% of your study content - comprehensive progress.",
    "Your study coverage stands at {coverage_ratio}% - well-rounded learning.",
  ];

  // ============================================================================
  // FOCUS DISTRACTION PHRASES
  // ============================================================================
  static const List<String> focus_distraction = [
    "You experience {interruptions} interruptions per session - focus optimization needed.",
    "Your sessions average {interruptions} interruptions - consider focus strategies.",
    "You're getting {interruptions} interruptions per study session.",
    "Your focus is interrupted {interruptions} times per session on average.",
  ];

  // ============================================================================
  // NOTIFICATIONS DIGEST PHRASES
  // ============================================================================
  static const List<String> notifications_digest = [
    "Your study notifications are {notification_frequency} - {notification_quality} engagement.",
    "You receive {notification_frequency} study reminders - {notification_quality} responsiveness.",
    "Your notification pattern shows {notification_frequency} - {notification_quality} interaction.",
    "You're getting {notification_frequency} study alerts - {notification_quality} participation.",
  ];

  // ============================================================================
  // RISK ALERTS PHRASES
  // ============================================================================
  static const List<String> risk_alerts = [
    "⚠️ Low consistency may impact long-term retention.",
    "⚠️ Falling behind on reviews could hurt spaced repetition benefits.",
    "⚠️ Slow response times might indicate fatigue or distraction.",
    "⚠️ High interruption rate suggests focus optimization needed.",
    "⚠️ Declining recall rate may signal need for review strategy adjustment.",
  ];

  // ============================================================================
  // QUICK TIPS PHRASES
  // ============================================================================
  static const List<String> quick_tips = [
    "Try 20-minute focused sessions for better retention.",
    "Review {due_count} due cards to maintain spaced repetition.",
    "Study during {best_hour_band} for peak performance.",
    "Use interleaving to mix different subjects in one session.",
    "Take 2-minute breaks every 25 minutes to maintain focus.",
    "Review difficult cards first when your mind is freshest.",
    "Set a daily minimum of 10 minutes to build consistency.",
    "Use active recall by covering answers before checking.",
    "Group related concepts together for better understanding.",
    "Practice spaced repetition with increasing intervals.",
  ];

  // ============================================================================
  // ENCOURAGEMENT PHRASES
  // ============================================================================
  static const List<String> encouragement = [
    "Great progress! Your consistency is building strong habits.",
    "Excellent work! Your study patterns show real dedication.",
    "Keep it up! Your learning journey is on the right track.",
    "Well done! Your study habits are creating lasting knowledge.",
    "Fantastic! Your approach to learning is yielding results.",
    "Amazing! Your commitment to study is paying off.",
    "Outstanding! Your learning patterns are impressive.",
    "Brilliant! Your study consistency is remarkable.",
  ];

  // ============================================================================
  // SYSTEM NOTES PHRASES
  // ============================================================================
  static const List<String> system_notes = [
    "Data based on local study sessions only.",
    "Analysis generated from your device's study history.",
    "Insights derived from your personal learning patterns.",
    "Recommendations based on your study behavior.",
  ];

  // ============================================================================
  // QUALITY DESCRIPTORS (for dynamic text)
  // ============================================================================
  static String getConsistencyQuality(int consistency) {
    if (consistency >= 90) return "excellent";
    if (consistency >= 80) return "very good";
    if (consistency >= 70) return "good";
    if (consistency >= 60) return "fair";
    return "needs improvement";
  }

  static String getRecallQuality(int recallRate) {
    if (recallRate >= 90) return "outstanding";
    if (recallRate >= 80) return "excellent";
    if (recallRate >= 70) return "good";
    if (recallRate >= 60) return "fair";
    return "needs work";
  }

  static String getPacingQuality(int latencyMs) {
    if (latencyMs <= 1500) return "excellent";
    if (latencyMs <= 2500) return "good";
    if (latencyMs <= 3500) return "moderate";
    return "slow";
  }

  static String getNotificationQuality(int frequency) {
    if (frequency >= 5) return "high";
    if (frequency >= 3) return "moderate";
    return "low";
  }
}
