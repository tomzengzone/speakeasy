import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/expression_daily_queue_coordinator.dart';
import 'package:speakeasy/features/interview/expression_shadow_scoring.dart';

void main() {
  const String target =
      "Thank you for having me. I'm excited to be here today.";

  test(
    'caps high pronunciation when transcript misses the target expression',
    () {
      final ExpressionShadowScoreResult result = scoreExpressionShadowAttempt(
        transcript: 'The weather is nice today.',
        targets: const <String>[target],
        pronunciationScore: 98,
      );

      expect(result.passed, isFalse);
      expect(result.textMatch, lessThan(0.20));
      expect(result.totalScore, lessThanOrEqualTo(35));
    },
  );

  test('does not pass common-word overlap with high pronunciation', () {
    final ExpressionShadowScoreResult result = scoreExpressionShadowAttempt(
      transcript: "I'm to be here today.",
      targets: const <String>[target],
      pronunciationScore: 95,
    );

    expect(result.passed, isFalse);
    expect(result.textMatch, lessThan(0.55));
    expect(result.totalScore, lessThan(65));
  });

  test('passes a complete target expression with pronunciation signal', () {
    final ExpressionShadowScoreResult result = scoreExpressionShadowAttempt(
      transcript: "Thank you for having me I'm excited to be here today",
      targets: const <String>[target],
      pronunciationScore: 70,
    );

    expect(result.passed, isTrue);
    expect(result.textMatch, 1);
    expect(result.totalScore, greaterThanOrEqualTo(85));
  });

  test('can pass from strong text match when pronunciation is unavailable', () {
    final ExpressionShadowScoreResult result = scoreExpressionShadowAttempt(
      transcript: "Thank you for having me I'm excited to be here today",
      targets: const <String>[target],
      pronunciationScore: null,
    );

    expect(result.passed, isTrue);
    expect(result.totalScore, 100);
  });

  test('uses more relaxed thresholds for open response modes', () {
    final ExpressionShadowScoreResult shadow = scoreExpressionShadowAttempt(
      transcript: 'Thank excited today',
      targets: const <String>[target],
      pronunciationScore: 80,
      practiceMode: ExpressionDailyQueueItem.practiceModeShadow,
    );
    final ExpressionShadowScoreResult cueResponse =
        scoreExpressionShadowAttempt(
          transcript: 'Thank excited today',
          targets: const <String>[target],
          pronunciationScore: 80,
          practiceMode: ExpressionDailyQueueItem.practiceModeCueResponse,
        );

    expect(shadow.passed, isFalse);
    expect(cueResponse.passed, isTrue);
    expect(
      expressionPracticeModeTextThreshold(
        ExpressionDailyQueueItem.practiceModeCueResponse,
      ),
      lessThan(
        expressionPracticeModeTextThreshold(
          ExpressionDailyQueueItem.practiceModeShadow,
        ),
      ),
    );
  });

  test('fluency sprint fails complete text when it takes too long', () {
    final ExpressionShadowScoreResult quick = scoreExpressionShadowAttempt(
      transcript: "Thank you for having me I'm excited to be here today",
      targets: const <String>[target],
      pronunciationScore: null,
      practiceMode: ExpressionDailyQueueItem.practiceModeFluencySprint,
      elapsed: const Duration(seconds: 5),
    );
    final ExpressionShadowScoreResult slow = scoreExpressionShadowAttempt(
      transcript: "Thank you for having me I'm excited to be here today",
      targets: const <String>[target],
      pronunciationScore: null,
      practiceMode: ExpressionDailyQueueItem.practiceModeFluencySprint,
      elapsed: const Duration(seconds: 30),
    );

    expect(quick.passed, isTrue);
    expect(slow.passed, isFalse);
    expect(slow.totalScore, lessThan(quick.totalScore));
  });
}
