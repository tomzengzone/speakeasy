import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-012 P0.1 exposes only two official training scenes', () {
    expect(p01InterviewTrainingSceneIds, <String>{
      'job_interview',
      'onboarding_introduction',
    });
  });

  test(
    'TC-P01-012 planner rejects arbitrary scenes instead of generating one',
    () {
      const InterviewTrainingAgent agent = InterviewTrainingAgent();

      final InterviewTrainingSessionStartResult result = agent.startSession(
        userId: 'u1',
        sceneId: 'anything_the_user_types',
        levelCode: 'beginner',
      );

      expect(result.created, isFalse);
      expect(result.session, isNull);
      expect(result.rejection?.reasonCode, 'out_of_scope_scene');
    },
  );

  test('TC-P01-012 blank scene ids remain out of scope', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();

    expect(agent.isSupportedScene(''), isFalse);
    expect(agent.actionChainFor('  '), isEmpty);
  });

  test(
    'TC-P01-012 pressure check stays in-session and has no schedule fields',
    () {
      const InterviewTrainingAgent agent = InterviewTrainingAgent(
        successesBeforePressureCheck: 1,
      );
      final InterviewTrainingSessionState session = p01TrainingSession();

      final InterviewTrainingPlannerDecision decision = agent.decideNext(
        session: session,
        attempt: InterviewTrainingAttemptResult.success(),
      );
      final InterviewTrainingSessionState next = agent.applyDecision(
        session: session,
        decision: decision,
      );

      expect(next.status, InterviewTrainingSessionStatus.pressureCheck);
      expect(next.sceneId, 'job_interview');
      expect(next.scenarioVersionId, p01TrainingScenarioVersionId);
      expect(next.completedStepKeys, isEmpty);
    },
  );

  test(
    'TC-P01-012 feedback schema rejects final mastery and entitlement fields',
    () {
      final InterviewTrainingFeedbackValidationResult validation =
          InterviewTrainingFeedbackCandidate.validateJson(
            p01ValidTrainingFeedbackJson(
              learningEvidenceCandidates: const <Map<String, dynamic>>[
                <String, dynamic>{
                  'status': 'candidate',
                  'evidence_type': 'weak_expression',
                  'target_expression_id': 'job_interview_l1_opening_excited',
                  'confidence': 0.8,
                  'rule_input': 'Valid signal',
                  'entitlement': 'paid',
                },
              ],
            ),
          );

      expect(validation.isValid, isFalse);
      expect(
        validation.errors,
        contains('learning evidence contains final mastery or billing field'),
      );
    },
  );
}
