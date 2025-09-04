import 'dart:math';
import 'package:timezone/timezone.dart' as tz;
import 'neurograph_config.dart';
import 'neurograph_models.dart';

/// Pure compute functions for NeuroGraph V2 analytics
/// All functions are stateless, deterministic, and unit-testable

class NeuroGraphCompute {
  /// Calculate daily accuracy points for learning curve
  /// Groups attempts by day and calculates accuracy per day
  static List<DailyPoint> dailyAccuracy(List<Attempt> attempts,
      {String? timezone}) {
    if (attempts.isEmpty) return [];

    // Use provided timezone or fallback to default
    final tzName = timezone ?? NeuroGraphConfig.defaultTimezone;

    // Group attempts by date (user's timezone)
    final Map<String, List<Attempt>> dailyGroups = {};

    for (final attempt in attempts) {
      // Use user's timezone if available, otherwise fallback to local time
      DateTime userTime;
      try {
        userTime =
            tz.TZDateTime.from(attempt.timestamp, tz.getLocation(tzName));
      } catch (e) {
        userTime = attempt.timestamp;
      }
      final dateKey =
          '${userTime.year}-${userTime.month.toString().padLeft(2, '0')}-${userTime.day.toString().padLeft(2, '0')}';

      dailyGroups.putIfAbsent(dateKey, () => []).add(attempt);
    }

    // Calculate accuracy for each day
    final List<DailyPoint> points = [];
    for (final entry in dailyGroups.entries) {
      final attempts = entry.value;
      final correctAttempts = attempts.where((a) => a.isCorrect).length;
      final totalAttempts = attempts.length;
      final accuracy =
          totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;

      // Parse date from key
      final parts = entry.key.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      points.add(DailyPoint(
        date: date,
        accuracy: accuracy,
        totalAttempts: totalAttempts,
        correctAttempts: correctAttempts,
      ));
    }

    // Sort by date
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Calculate Exponential Moving Average
  /// Formula: EMA = alpha * current + (1 - alpha) * previous
  /// where alpha = 2 / (n + 1)
  static List<double> ema(List<double> xs, {int n = 7}) {
    if (xs.isEmpty) return [];
    if (n <= 0) return xs;

    final alpha = 2.0 / (n + 1);
    final List<double> emaValues = [];

    // First value is the same as input
    emaValues.add(xs.first);

    // Calculate EMA for remaining values
    for (int i = 1; i < xs.length; i++) {
      final emaValue = alpha * xs[i] + (1 - alpha) * emaValues[i - 1];
      emaValues.add(emaValue);
    }

    return emaValues;
  }

  /// Calculate forgetting curve model for spaced review
  /// Uses exponential decay: p_recall = exp(-lambda * days)
  /// where lambda = base / max(1, repetitions)
  static Map<String, RecallModel> forgettingModel(List<Attempt> attempts,
      {DateTime? now, String? timezone}) {
    final currentTime = now ?? DateTime.now();
    final tzName = timezone ?? NeuroGraphConfig.defaultTimezone;

    DateTime userNow;
    try {
      userNow = tz.TZDateTime.from(currentTime, tz.getLocation(tzName));
    } catch (e) {
      userNow = currentTime;
    }

    // Group attempts by questionId
    final Map<String, List<Attempt>> questionGroups = {};
    for (final attempt in attempts) {
      questionGroups.putIfAbsent(attempt.questionId, () => []).add(attempt);
    }

    final Map<String, RecallModel> recallModels = {};

    for (final entry in questionGroups.entries) {
      final questionId = entry.key;
      final questionAttempts = entry.value;

      // Sort by timestamp (newest first)
      questionAttempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Find last successful attempt
      final lastSuccess = questionAttempts.firstWhere(
        (a) => a.isCorrect,
        orElse: () => questionAttempts.first,
      );

      // Count repetitions (successful attempts)
      final repetitions = questionAttempts.where((a) => a.isCorrect).length;

      // Calculate lambda based on repetitions
      final lambda = NeuroGraphConfig.baseLambda / max(1, repetitions);
      final clampedLambda = lambda.clamp(0.05, 0.95);

      // Calculate days since last success
      DateTime userLastSuccess;
      try {
        userLastSuccess =
            tz.TZDateTime.from(lastSuccess.timestamp, tz.getLocation(tzName));
      } catch (e) {
        userLastSuccess = lastSuccess.timestamp;
      }
      final daysSinceLastSuccess = userNow.difference(userLastSuccess).inDays;

      // Calculate recall probability
      final pRecall = exp(-clampedLambda * daysSinceLastSuccess);

      // Determine if item is due for review
      final isDue = pRecall < NeuroGraphConfig.recallThreshold;

      // Calculate next review date (when p_recall would hit threshold)
      final daysUntilDue = isDue
          ? 0
          : (log(NeuroGraphConfig.recallThreshold) / -clampedLambda).ceil();
      final nextReviewDate = userLastSuccess.add(Duration(days: daysUntilDue));

      recallModels[questionId] = RecallModel(
        questionId: questionId,
        lastSuccess: lastSuccess.timestamp,
        repetitions: repetitions,
        lambda: clampedLambda,
        pRecall: pRecall,
        nextReviewDate: nextReviewDate,
        isDue: isDue,
        daysSinceLastSuccess: daysSinceLastSuccess,
      );
    }

    return recallModels;
  }

  /// Calculate retrieval practice vs exam performance
  /// Groups attempts into sessions and correlates with subsequent performance
  static List<WeekPoint> retrievalVsExam(List<Attempt> attempts,
      {String? timezone}) {
    if (attempts.isEmpty) return [];

    final tzName = timezone ?? NeuroGraphConfig.defaultTimezone;

    // Sort attempts by timestamp
    attempts.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Group into sessions (gap > 30 minutes or different testId)
    final List<List<Attempt>> sessions = [];
    List<Attempt> currentSession = [];

    for (int i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];

      if (currentSession.isEmpty) {
        currentSession.add(attempt);
      } else {
        final lastAttempt = currentSession.last;
        final gap =
            attempt.timestamp.difference(lastAttempt.timestamp).inMinutes;
        final differentTest = attempt.testId != lastAttempt.testId;

        if (gap > NeuroGraphConfig.sessionGapMinutes || differentTest) {
          // End current session and start new one
          if (currentSession.isNotEmpty) {
            sessions.add(List.from(currentSession));
          }
          currentSession = [attempt];
        } else {
          currentSession.add(attempt);
        }
      }
    }

    // Add final session
    if (currentSession.isNotEmpty) {
      sessions.add(currentSession);
    }

    // Group sessions by week
    final Map<String, List<List<Attempt>>> weeklySessions = {};
    for (final session in sessions) {
      if (session.isEmpty) continue;

      final sessionStart = session.first.timestamp;
      DateTime userTime;
      try {
        userTime = tz.TZDateTime.from(sessionStart, tz.getLocation(tzName));
      } catch (e) {
        userTime = sessionStart;
      }
      final weekStart = userTime.subtract(Duration(days: userTime.weekday - 1));
      final weekKey =
          '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      weeklySessions.putIfAbsent(weekKey, () => []).add(session);
    }

    // Calculate weekly metrics
    final List<WeekPoint> weekPoints = [];
    for (final entry in weeklySessions.entries) {
      final weekKey = entry.key;
      final weekSessions = entry.value;

      // Parse week start date
      final parts = weekKey.split('-');
      final weekStart = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      // Count retrieval sessions (sessions with multiple attempts)
      final retrievalSessions =
          weekSessions.where((session) => session.length > 1).length;

      // Calculate subsequent exam scores (attempts in next 7-14 days)
      final nextWeekStart = weekStart.add(const Duration(days: 7));
      final nextWeekEnd = weekStart.add(const Duration(days: 14));

      final subsequentAttempts = attempts.where((a) {
        DateTime attemptDate;
        try {
          attemptDate = tz.TZDateTime.from(a.timestamp, tz.getLocation(tzName));
        } catch (e) {
          attemptDate = a.timestamp;
        }
        return attemptDate.isAfter(nextWeekStart) &&
            attemptDate.isBefore(nextWeekEnd);
      }).toList();

      double? nextExamScore;
      if (subsequentAttempts.isNotEmpty) {
        final totalScore =
            subsequentAttempts.fold<double>(0.0, (sum, a) => sum + a.score);
        nextExamScore = totalScore / subsequentAttempts.length;
      }

      weekPoints.add(WeekPoint(
        weekStart: weekStart,
        retrievalSessions: retrievalSessions,
        nextExamScore: nextExamScore,
      ));
    }

    // Sort by week start
    weekPoints.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return weekPoints;
  }

  /// Calculate calibration metrics
  /// Bins confidence into deciles and compares with actual accuracy
  static CalibrationSummary calibration(List<Attempt> attempts,
      {String? timezone}) {
    // Filter attempts with confidence data
    final attemptsWithConfidence =
        attempts.where((a) => a.confidencePct != null).toList();

    if (attemptsWithConfidence.isEmpty) {
      // Return empty calibration if no confidence data
      return const CalibrationSummary(
        bins: [],
        brierScore: 0.0,
        expectedCalibrationError: 0.0,
      );
    }

    // Sort by confidence
    attemptsWithConfidence
        .sort((a, b) => a.confidencePct!.compareTo(b.confidencePct!));

    // Create bins
    final int binSize =
        attemptsWithConfidence.length ~/ NeuroGraphConfig.confidenceBins;
    final List<CalibrationBin> bins = [];

    for (int i = 0; i < NeuroGraphConfig.confidenceBins; i++) {
      final startIndex = i * binSize;
      final endIndex = (i == NeuroGraphConfig.confidenceBins - 1)
          ? attemptsWithConfidence.length
          : (i + 1) * binSize;

      final binAttempts = attemptsWithConfidence.sublist(startIndex, endIndex);

      if (binAttempts.isEmpty) continue;

      final confidenceMin = binAttempts.first.confidencePct! / 100.0;
      final confidenceMax = binAttempts.last.confidencePct! / 100.0;
      final actualAccuracy =
          binAttempts.where((a) => a.isCorrect).length / binAttempts.length;
      final count = binAttempts.length;
      final weight = count / attemptsWithConfidence.length;

      bins.add(CalibrationBin(
        confidenceMin: confidenceMin,
        confidenceMax: confidenceMax,
        actualAccuracy: actualAccuracy,
        count: count,
        weight: weight,
      ));
    }

    // Calculate Brier score
    double brierScore = 0.0;
    for (final attempt in attemptsWithConfidence) {
      final predicted = attempt.confidencePct! / 100.0;
      final actual = attempt.isCorrect ? 1.0 : 0.0;
      brierScore += pow(predicted - actual, 2);
    }
    brierScore /= attemptsWithConfidence.length;

    // Calculate Expected Calibration Error (ECE)
    double ece = 0.0;
    for (final bin in bins) {
      final binConfidence = (bin.confidenceMin + bin.confidenceMax) / 2.0;
      final calibrationError = (bin.actualAccuracy - binConfidence).abs();
      ece += calibrationError * bin.weight;
    }

    return CalibrationSummary(
      bins: bins,
      brierScore: brierScore,
      expectedCalibrationError: ece,
    );
  }

  /// Calculate mastery progress over time
  /// Tracks items through NEW -> PRACTICING -> MASTERED states
  static List<WeekStack> masteryStacks(List<Attempt> attempts,
      {String? timezone}) {
    if (attempts.isEmpty) return [];

    final tzName = timezone ?? NeuroGraphConfig.defaultTimezone;

    // Group attempts by questionId
    final Map<String, List<Attempt>> questionGroups = {};
    for (final attempt in attempts) {
      questionGroups.putIfAbsent(attempt.questionId, () => []).add(attempt);
    }

    // Calculate mastery state for each question
    final Map<String, Map<DateTime, MasteryState>> questionMasteryOverTime = {};

    for (final entry in questionGroups.entries) {
      final questionId = entry.key;
      final questionAttempts = entry.value;

      // Sort by timestamp
      questionAttempts.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final Map<DateTime, MasteryState> masteryOverTime = {};

      for (int i = 0; i < questionAttempts.length; i++) {
        final currentAttempts = questionAttempts.sublist(0, i + 1);
        DateTime userTime;
        try {
          userTime = tz.TZDateTime.from(
              questionAttempts[i].timestamp, tz.getLocation(tzName));
        } catch (e) {
          userTime = questionAttempts[i].timestamp;
        }
        final weekStart =
            userTime.subtract(Duration(days: userTime.weekday - 1));

        final state = _calculateMasteryState(currentAttempts);
        masteryOverTime[weekStart] = state;
      }

      questionMasteryOverTime[questionId] = masteryOverTime;
    }

    // Aggregate by week
    final Map<DateTime, Map<MasteryState, int>> weeklyCounts = {};

    for (final questionMastery in questionMasteryOverTime.values) {
      for (final entry in questionMastery.entries) {
        final weekStart = entry.key;
        final state = entry.value;

        weeklyCounts.putIfAbsent(
            weekStart,
            () => {
                  MasteryState.new_: 0,
                  MasteryState.practicing: 0,
                  MasteryState.mastered: 0,
                });

        weeklyCounts[weekStart]![state] = weeklyCounts[weekStart]![state]! + 1;
      }
    }

    // Convert to WeekStack format
    final List<WeekStack> weekStacks = [];
    for (final entry in weeklyCounts.entries) {
      final weekStart = entry.key;
      final counts = entry.value;

      final totalItems =
          counts.values.fold<int>(0, (sum, count) => sum + count);
      if (totalItems == 0) continue;

      weekStacks.add(WeekStack(
        weekStart: weekStart,
        newPercentage: counts[MasteryState.new_]! / totalItems,
        practicingPercentage: counts[MasteryState.practicing]! / totalItems,
        masteredPercentage: counts[MasteryState.mastered]! / totalItems,
        totalItems: totalItems,
      ));
    }

    // Sort by week start
    weekStacks.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return weekStacks;
  }

  /// Calculate consistency heatmap data
  /// Shows daily study activity and streaks
  static Map<DateTime, ConsistencyHeat> consistencyHeat(List<Attempt> attempts,
      {String? timezone}) {
    final tzName = timezone ?? NeuroGraphConfig.defaultTimezone;
    final Map<DateTime, ConsistencyHeat> heatData = {};

    // Group attempts by date
    final Map<String, List<Attempt>> dailyGroups = {};
    for (final attempt in attempts) {
      DateTime userTime;
      try {
        userTime =
            tz.TZDateTime.from(attempt.timestamp, tz.getLocation(tzName));
      } catch (e) {
        userTime = attempt.timestamp;
      }
      final dateKey =
          '${userTime.year}-${userTime.month.toString().padLeft(2, '0')}-${userTime.day.toString().padLeft(2, '0')}';

      dailyGroups.putIfAbsent(dateKey, () => []).add(attempt);
    }

    // Calculate daily metrics
    final List<int> dailyAttempts = [];
    for (final entry in dailyGroups.entries) {
      final parts = entry.key.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final attempts = entry.value;

      dailyAttempts.add(attempts.length);

      heatData[date] = ConsistencyHeat(
        date: date,
        intensity: 0.0, // Will be calculated below
        attempts: attempts.length,
        studied: true,
      );
    }

    // Calculate intensity based on percentile
    if (dailyAttempts.isNotEmpty) {
      dailyAttempts.sort();
      final maxAttempts = dailyAttempts.last;

      for (final heat in heatData.values) {
        final percentile =
            dailyAttempts.indexOf(heat.attempts) / (dailyAttempts.length - 1);
        final intensity = maxAttempts > 0 ? heat.attempts / maxAttempts : 0.0;

        heatData[heat.date] = heat.copyWith(intensity: intensity);
      }
    }

    return heatData;
  }

  /// Helper function to calculate mastery state for a list of attempts
  static MasteryState _calculateMasteryState(List<Attempt> attempts) {
    if (attempts.length < NeuroGraphConfig.masteryMinAttempts) {
      return MasteryState.new_;
    }

    // Check if mastered (last 3 attempts >= 80% or 3 consecutive correct)
    if (attempts.length >= NeuroGraphConfig.masteryWindowAttempts) {
      final recentAttempts = attempts
          .sublist(attempts.length - NeuroGraphConfig.masteryWindowAttempts);
      final recentAccuracy = recentAttempts.where((a) => a.isCorrect).length /
          recentAttempts.length;

      if (recentAccuracy >= NeuroGraphConfig.practicingAccuracyThreshold) {
        return MasteryState.mastered;
      }
    }

    // Check for 3 consecutive correct
    if (attempts.length >= NeuroGraphConfig.masteryConsecutiveCorrect) {
      final recentAttempts = attempts.sublist(
          attempts.length - NeuroGraphConfig.masteryConsecutiveCorrect);
      final allCorrect = recentAttempts.every((a) => a.isCorrect);

      if (allCorrect) {
        return MasteryState.mastered;
      }
    }

    // Check if practicing (rolling accuracy < 80%)
    final rollingAccuracy =
        attempts.where((a) => a.isCorrect).length / attempts.length;
    if (rollingAccuracy < NeuroGraphConfig.practicingAccuracyThreshold) {
      return MasteryState.practicing;
    }

    return MasteryState.practicing;
  }
}
