import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-010 recap keeps rule-accepted learning evidence candidates', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingFeedbackCandidate feedback = p01FeedbackCandidate(
      nextAction: 'recap',
      learningEvidenceCandidates: const <Map<String, dynamic>>[
        <String, dynamic>{
          'status': 'candidate',
          'evidence_type': 'weak_expression',
          'target_expression_id': 'job_interview_l1_opening_excited',
          'confidence': 0.82,
          'rule_input': 'Covered the idea with support.',
        },
        <String, dynamic>{
          'status': 'candidate',
          'evidence_type': 'weak_expression',
          'target_expression_id': '',
          'confidence': 0.95,
          'rule_input': 'No stable target expression.',
        },
      ],
    );
    final InterviewTrainingSessionState session = p01TrainingSession(
      currentStep: InterviewTrainingActionStep.closing,
    );

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: InterviewTrainingAttemptResult.success(
        feedbackCandidate: feedback,
      ),
    );
    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(decision.type, InterviewTrainingDecisionType.recap);
    expect(next.status, InterviewTrainingSessionStatus.recap);
    expect(next.recap, isNotNull);
    expect(next.recap?.evidenceCandidates, hasLength(1));
    expect(
      next.recap?.evidenceCandidates.single.targetExpressionId,
      'job_interview_l1_opening_excited',
    );
    expect(next.recap?.evidenceWriteStatus, 'pending_local_write');
  });

  test('TC-P01-010 recap survives when no candidate can be accepted', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession(
      currentStep: InterviewTrainingActionStep.closing,
    );

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: InterviewTrainingAttemptResult.success(),
    );
    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(next.status, InterviewTrainingSessionStatus.recap);
    expect(next.recap?.summary, contains('job_interview'));
    expect(next.recap?.nextFocus, isNotEmpty);
    expect(next.recap?.evidenceCandidates, isEmpty);
  });
}
