import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-009 consecutive success enters in-session pressure check', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent(
      successesBeforePressureCheck: 2,
    );
    final InterviewTrainingSessionState session = p01TrainingSession(
      successCount: 1,
      hintLevel: InterviewTrainingHintLevel.sentenceFrame,
    );

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: InterviewTrainingAttemptResult.success(),
    );
    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(decision.type, InterviewTrainingDecisionType.pressureCheck);
    expect(next.status, InterviewTrainingSessionStatus.pressureCheck);
    expect(
      next.currentMicroAction,
      InterviewTrainingMicroAction.continueUnderPrompt,
    );
    expect(next.hintLevel, InterviewTrainingHintLevel.none);
  });

  test('TC-P01-009 pressure pass advances to next step or recap', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession(
      status: InterviewTrainingSessionStatus.pressureCheck,
      currentMicroAction: InterviewTrainingMicroAction.continueUnderPrompt,
      currentStep: InterviewTrainingActionStep.respondFollowUp,
    );

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: const InterviewTrainingAttemptResult(
        outcome: InterviewTrainingAttemptOutcome.pressurePassed,
        completionStatus: InterviewTrainingSignalStatus.met,
        taskStatus: InterviewTrainingSignalStatus.met,
      ),
    );

    expect(decision.type, InterviewTrainingDecisionType.advanceStep);
    expect(decision.nextStep, InterviewTrainingActionStep.confirmNextStep);
  });

  test('TC-P01-009 pressure failure returns to higher-hint retry', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession(
      status: InterviewTrainingSessionStatus.pressureCheck,
      currentMicroAction: InterviewTrainingMicroAction.continueUnderPrompt,
    );

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: const InterviewTrainingAttemptResult(
        outcome: InterviewTrainingAttemptOutcome.pressureFailed,
        completionStatus: InterviewTrainingSignalStatus.notMet,
        taskStatus: InterviewTrainingSignalStatus.notMet,
      ),
    );

    expect(decision.type, InterviewTrainingDecisionType.retryWithHigherHint);
    expect(decision.nextStatus, InterviewTrainingSessionStatus.retry);
    expect(decision.nextHintLevel, InterviewTrainingHintLevel.sentenceFrame);
  });
}
