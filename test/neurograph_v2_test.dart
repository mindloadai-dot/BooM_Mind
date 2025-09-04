import 'package:flutter_test/flutter_test.dart';
import 'package:mindload/neurograph_v2/neurograph_models.dart';
import 'package:mindload/neurograph_v2/neurograph_compute.dart';

void main() {
  group('NeuroGraphCompute', () {
    group('dailyAccuracy', () {
      test('should return empty list for empty attempts', () {
        final result = NeuroGraphCompute.dailyAccuracy([]);
        expect(result, isEmpty);
      });

      test('should calculate daily accuracy correctly', () {
        final attempts = [
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1000,
            timestamp: DateTime(2024, 1, 1, 10, 0),
          ),
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q2',
            topicId: 'topic1',
            isCorrect: false,
            score: 0.0,
            responseMs: 2000,
            timestamp: DateTime(2024, 1, 1, 11, 0),
          ),
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q3',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1500,
            timestamp: DateTime(2024, 1, 2, 10, 0),
          ),
        ];

        final result = NeuroGraphCompute.dailyAccuracy(attempts);

        expect(result.length, equals(2));
        expect(result[0].date, equals(DateTime(2024, 1, 1)));
        expect(result[0].accuracy, equals(0.5)); // 1 correct out of 2
        expect(result[0].totalAttempts, equals(2));
        expect(result[0].correctAttempts, equals(1));

        expect(result[1].date, equals(DateTime(2024, 1, 2)));
        expect(result[1].accuracy, equals(1.0)); // 1 correct out of 1
        expect(result[1].totalAttempts, equals(1));
        expect(result[1].correctAttempts, equals(1));
      });
    });

    group('ema', () {
      test('should return empty list for empty input', () {
        final result = NeuroGraphCompute.ema([]);
        expect(result, isEmpty);
      });

      test('should return input for n <= 0', () {
        final input = [1.0, 2.0, 3.0];
        final result = NeuroGraphCompute.ema(input, n: 0);
        expect(result, equals(input));
      });

      test('should calculate EMA correctly', () {
        final input = [1.0, 2.0, 3.0, 4.0, 5.0];
        final result = NeuroGraphCompute.ema(input, n: 3);

        expect(result.length, equals(5));
        expect(result[0], equals(1.0)); // First value is same as input
        // Subsequent values are calculated with alpha = 2/(3+1) = 0.5
        expect(result[1], equals(0.5 * 2.0 + 0.5 * 1.0)); // 1.5
        expect(result[2], equals(0.5 * 3.0 + 0.5 * 1.5)); // 2.25
        expect(result[3], equals(0.5 * 4.0 + 0.5 * 2.25)); // 3.125
        expect(result[4], equals(0.5 * 5.0 + 0.5 * 3.125)); // 4.0625
      });
    });

    group('forgettingModel', () {
      test('should return empty map for empty attempts', () {
        final result = NeuroGraphCompute.forgettingModel([]);
        expect(result, isEmpty);
      });

      test('should calculate recall model correctly', () {
        final now = DateTime(2024, 1, 10);
        final attempts = [
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1000,
            timestamp: now.subtract(const Duration(days: 5)), // 5 days ago
          ),
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1200,
            timestamp: now.subtract(const Duration(days: 3)), // 3 days ago
          ),
        ];

        final result = NeuroGraphCompute.forgettingModel(attempts, now: now);

        expect(result.length, equals(1));
        expect(result.containsKey('q1'), isTrue);

        final model = result['q1']!;
        expect(model.questionId, equals('q1'));
        expect(model.repetitions, equals(2)); // 2 successful attempts
        expect(model.daysSinceLastSuccess,
            equals(3)); // Last success was 3 days ago
        expect(
            model.isDue, isFalse); // Should not be due yet with 2 repetitions
      });
    });

    group('retrievalVsExam', () {
      test('should return empty list for empty attempts', () {
        final result = NeuroGraphCompute.retrievalVsExam([]);
        expect(result, isEmpty);
      });

      test('should group sessions correctly', () {
        final baseTime = DateTime(2024, 1, 1, 10, 0);
        final attempts = [
          // Session 1: 2 attempts within 30 minutes
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1000,
            timestamp: baseTime,
          ),
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q2',
            topicId: 'topic1',
            isCorrect: false,
            score: 0.0,
            responseMs: 2000,
            timestamp: baseTime.add(const Duration(minutes: 15)),
          ),
          // Session 2: 1 attempt after 30+ minute gap
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q3',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1500,
            timestamp: baseTime.add(const Duration(minutes: 45)),
          ),
        ];

        final result = NeuroGraphCompute.retrievalVsExam(attempts);

        expect(result.length, equals(1)); // All in same week
        expect(result[0].retrievalSessions,
            equals(1)); // Only first session has multiple attempts
      });
    });

    group('calibration', () {
      test('should return empty calibration for attempts without confidence',
          () {
        final attempts = [
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1000,
            timestamp: DateTime.now(),
          ),
        ];

        final result = NeuroGraphCompute.calibration(attempts);

        expect(result.bins, isEmpty);
        expect(result.brierScore, equals(0.0));
        expect(result.expectedCalibrationError, equals(0.0));
      });

      test('should calculate calibration correctly', () {
        final attempts = [
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1000,
            timestamp: DateTime.now(),
            confidencePct: 80.0,
          ),
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q2',
            topicId: 'topic1',
            isCorrect: false,
            score: 0.0,
            responseMs: 2000,
            timestamp: DateTime.now(),
            confidencePct: 90.0,
          ),
        ];

        final result = NeuroGraphCompute.calibration(attempts);

        expect(result.bins.length,
            equals(1)); // 1 bin for 2 attempts (minimum bin size)
        expect(result.brierScore, greaterThan(0.0));
        expect(result.expectedCalibrationError, greaterThan(0.0));
      });
    });

    group('masteryStacks', () {
      test('should return empty list for empty attempts', () {
        final result = NeuroGraphCompute.masteryStacks([]);
        expect(result, isEmpty);
      });

      test('should calculate mastery states correctly', () {
        final attempts = [
          // First attempt - should be NEW
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: false,
            score: 0.0,
            responseMs: 1000,
            timestamp: DateTime(2024, 1, 1),
          ),
          // Second attempt - still NEW (less than 2 attempts)
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1200,
            timestamp: DateTime(2024, 1, 2),
          ),
        ];

        final result = NeuroGraphCompute.masteryStacks(attempts);

        expect(
            result.length, equals(1)); // One week (both attempts in same week)
        expect(result[0].newPercentage,
            equals(1.0)); // Items are new (less than 3 attempts)
        expect(result[0].practicingPercentage,
            equals(0.0)); // No items are practicing
        expect(
            result[0].masteredPercentage, equals(0.0)); // No items are mastered
      });
    });

    group('consistencyHeat', () {
      test('should return empty map for empty attempts', () {
        final result = NeuroGraphCompute.consistencyHeat([]);
        expect(result, isEmpty);
      });

      test('should calculate heat data correctly', () {
        final attempts = [
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q1',
            topicId: 'topic1',
            isCorrect: true,
            score: 1.0,
            responseMs: 1000,
            timestamp: DateTime(2024, 1, 1),
          ),
          Attempt(
            userId: 'user1',
            testId: 'test1',
            questionId: 'q2',
            topicId: 'topic1',
            isCorrect: false,
            score: 0.0,
            responseMs: 2000,
            timestamp: DateTime(2024, 1, 1), // Same day
          ),
        ];

        final result = NeuroGraphCompute.consistencyHeat(attempts);

        expect(result.length, equals(1)); // One day
        final heat = result.values.first;
        expect(heat.attempts, equals(2));
        expect(heat.studied, isTrue);
        expect(heat.intensity, greaterThan(0.0));
      });
    });
  });
}
