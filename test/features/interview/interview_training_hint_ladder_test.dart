import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-005 continuous failures climb the hint ladder', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();

    InterviewTrainingSessionState session = p01TrainingSession();
    final List<InterviewTrainingHintLevel> observed =
        <InterviewTrainingHintLevel>[];

    for (int index = 0; index < 4; index += 1) {
      final InterviewTrainingPlannerDecision decision = agent.decideNext(
        session: session,
        attempt: InterviewTrainingAttemptResult.failure(),
      );
      observed.add(decision.nextHintLevel);
      session = agent.applyDecision(session: session, decision: decision);
    }

    expect(observed, <InterviewTrainingHintLevel>[
      InterviewTrainingHintLevel.sentenceFrame,
      InterviewTrainingHintLevel.options,
      InterviewTrainingHintLevel.chunkShadowing,
      InterviewTrainingHintLevel.modelThenRetry,
    ]);
    expect(session.status, InterviewTrainingSessionStatus.retry);
  });

  test('TC-P01-005 high support success lowers scaffold on next task', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession(
      hintLevel: InterviewTrainingHintLevel.chunkShadowing,
    );

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: InterviewTrainingAttemptResult.success(),
    );

    expect(decision.type, InterviewTrainingDecisionType.lowerHint);
    expect(decision.nextHintLevel, InterviewTrainingHintLevel.options);
    expect(decision.nextStatus, InterviewTrainingSessionStatus.ready);
  });

  test('TC-P01-005 max support failure uses model then retry', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession(
      hintLevel: InterviewTrainingHintLevel.chunkShadowing,
    );

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: InterviewTrainingAttemptResult.failure(),
    );

    expect(decision.type, InterviewTrainingDecisionType.modelThenRetry);
    expect(decision.nextHintLevel, InterviewTrainingHintLevel.modelThenRetry);
  });
}
