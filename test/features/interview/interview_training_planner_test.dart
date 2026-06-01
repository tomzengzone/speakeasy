import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-002 maps both official scenes to the local action chain', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();

    for (final String sceneId in p01InterviewTrainingSceneIds) {
      final List<InterviewTrainingActionChainStep> chain = agent.actionChainFor(
        sceneId,
      );

      expect(
        chain.map((InterviewTrainingActionChainStep item) => item.step),
        <InterviewTrainingActionStep>[
          InterviewTrainingActionStep.opening,
          InterviewTrainingActionStep.explainPurpose,
          InterviewTrainingActionStep.expressView,
          InterviewTrainingActionStep.respondFollowUp,
          InterviewTrainingActionStep.confirmNextStep,
          InterviewTrainingActionStep.closing,
        ],
      );
      expect(
        chain.every(
          (InterviewTrainingActionChainStep item) =>
              item.learnerTask.isNotEmpty && item.successCondition.isNotEmpty,
        ),
        isTrue,
      );
    }
  });

  test('TC-P01-002 unsupported scenes have no action chain', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();

    expect(agent.actionChainFor('custom_scene'), isEmpty);
  });

  test('TC-P01-003 keeps one active micro-action in session state', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession();

    expect(session.hasSingleActiveMicroAction, isTrue);
    expect(session.currentMicroAction, InterviewTrainingMicroAction.sayOne);

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: InterviewTrainingAttemptResult.success(),
    );
    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(next.status, InterviewTrainingSessionStatus.ready);
    expect(next.currentStep, InterviewTrainingActionStep.explainPurpose);
    expect(next.currentMicroAction, InterviewTrainingMicroAction.fillOne);
    expect(next.hasSingleActiveMicroAction, isTrue);
  });

  test('TC-P01-004 failed attempt raises hint and retries', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession();

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: InterviewTrainingAttemptResult.failure(),
    );

    expect(decision.type, InterviewTrainingDecisionType.raiseHint);
    expect(decision.nextStatus, InterviewTrainingSessionStatus.retry);
    expect(decision.nextHintLevel, InterviewTrainingHintLevel.sentenceFrame);

    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(next.failureCount, 1);
    expect(next.successCount, 0);
  });

  test('TC-P01-004 ASR failure does not mark learner expression failed', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession();

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: const InterviewTrainingAttemptResult(
        outcome: InterviewTrainingAttemptOutcome.asrFailed,
        completionStatus: InterviewTrainingSignalStatus.unknown,
        taskStatus: InterviewTrainingSignalStatus.unknown,
      ),
    );
    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(decision.type, InterviewTrainingDecisionType.textFallback);
    expect(next.textFallbackAvailable, isTrue);
    expect(next.failureCount, 0);
  });

  test('TC-P01-004 unavailable score does not block successful task flow', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession();

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: const InterviewTrainingAttemptResult(
        outcome: InterviewTrainingAttemptOutcome.scoreUnavailable,
        completionStatus: InterviewTrainingSignalStatus.met,
        taskStatus: InterviewTrainingSignalStatus.met,
        pronunciationAvailable: false,
      ),
    );

    expect(decision.type, InterviewTrainingDecisionType.advanceStep);
    expect(decision.reasonCode, 'score_unavailable_continue');
  });
}
