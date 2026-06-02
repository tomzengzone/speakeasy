import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-008 accepts valid training feedback candidate', () {
    final Map<String, dynamic> json = p01ValidTrainingFeedbackJson(
      nextAction: 'pressure_check',
      pressurePromptEnabled: true,
      learningEvidenceCandidates: const <Map<String, dynamic>>[
        <String, dynamic>{
          'status': 'candidate',
          'evidence_type': 'weak_expression',
          'target_expression_id': 'job_interview_l1_opening_excited',
          'confidence': 0.72,
          'rule_input': 'Learner needed sentence-frame support.',
        },
      ],
    );

    final InterviewTrainingFeedbackValidationResult validation =
        InterviewTrainingFeedbackCandidate.validateJson(
          json,
          plannerNextAction: InterviewTrainingNextActionType.pressureCheck,
        );
    final InterviewTrainingFeedbackCandidate candidate =
        InterviewTrainingFeedbackCandidate.fromJson(
          json,
          plannerNextAction: InterviewTrainingNextActionType.pressureCheck,
        );

    expect(validation.isValid, isTrue);
    expect(candidate.sceneId, 'job_interview');
    expect(candidate.pressurePromptEnabled, isTrue);
    expect(candidate.learningEvidenceCandidates.single.status, 'candidate');
  });

  test('TC-P01-008 rejects unsupported scenes and bad next actions', () {
    final Map<String, dynamic> json = p01ValidTrainingFeedbackJson(
      sceneId: 'custom_scene',
      nextAction: 'invent_new_scene',
    );

    final InterviewTrainingFeedbackValidationResult validation =
        InterviewTrainingFeedbackCandidate.validateJson(json);

    expect(validation.isValid, isFalse);
    expect(
      validation.errors,
      contains('scene_id is outside P0.1 official scenes'),
    );
    expect(
      validation.errors,
      contains('recommended_next_action.type is not allowed'),
    );
  });

  test('TC-P01-008 rejects AI attempts to write final mastery or billing', () {
    final Map<String, dynamic> json = p01ValidTrainingFeedbackJson(
      learningEvidenceCandidates: const <Map<String, dynamic>>[
        <String, dynamic>{
          'status': 'accepted',
          'evidence_type': 'mastered_expression',
          'target_expression_id': 'job_interview_l1_opening_excited',
          'confidence': 0.9,
          'rule_input': 'AI says it is mastered.',
          'billing_state': 'entitled',
        },
      ],
    );

    final InterviewTrainingFeedbackValidationResult validation =
        InterviewTrainingFeedbackCandidate.validateJson(json);

    expect(validation.isValid, isFalse);
    expect(
      validation.errors,
      contains('learning evidence status must stay candidate'),
    );
    expect(
      validation.errors,
      contains('learning evidence contains final mastery or billing field'),
    );
  });

  test('TC-P01-014 rejects top-level final mastery or review schedule', () {
    final Map<String, dynamic> json = p01ValidTrainingFeedbackJson(
      nextAction: 'continue',
    );
    json['mastered'] = true;
    json['review_scheduled'] = 'tomorrow';

    final InterviewTrainingFeedbackValidationResult validation =
        InterviewTrainingFeedbackCandidate.validateJson(
          json,
          plannerNextAction: InterviewTrainingNextActionType.continueAction,
        );

    expect(validation.isValid, isFalse);
    expect(
      validation.errors,
      contains('feedback candidate contains final mastery or billing field'),
    );
  });

  test('TC-P01-008 recoverable errors require fallback-safe signals', () {
    final Map<String, dynamic> invalid = p01ValidTrainingFeedbackJson(
      nextAction: 'continue',
      recoverableError: const <String, dynamic>{
        'code': 'llm_timeout',
        'message': 'Provider timeout',
        'retryable': true,
      },
    );
    final Map<String, dynamic> valid = p01ValidTrainingFeedbackJson(
      completionStatus: 'unknown',
      taskStatus: 'partial',
      nextAction: 'text_fallback',
      recoverableError: const <String, dynamic>{
        'code': 'asr_uncertain',
        'message': 'ASR confidence is low',
        'retryable': true,
      },
    );

    expect(
      InterviewTrainingFeedbackCandidate.validateJson(invalid).isValid,
      isFalse,
    );
    expect(
      InterviewTrainingFeedbackCandidate.validateJson(valid).isValid,
      isTrue,
    );
  });

  test('TC-P01-008 malformed field types return validation errors', () {
    final Map<String, dynamic> malformed = p01ValidTrainingFeedbackJson();
    malformed['schema_version'] = '1';
    malformed['scene_id'] = 42;
    malformed['completion_signal'] = <String, dynamic>{'status': 1};
    malformed['feedback_card'] = <String, dynamic>{
      'summary': 7,
      'main_issue_type': <String>['grammar'],
    };
    malformed['recommended_next_action'] = <String, dynamic>{'type': true};
    malformed['pressure_prompt_candidate'] = <String, dynamic>{
      'enabled': 'yes',
    };

    late final InterviewTrainingFeedbackValidationResult validation;

    expect(
      () => validation = InterviewTrainingFeedbackCandidate.validateJson(
        malformed,
      ),
      returnsNormally,
    );
    expect(validation.isValid, isFalse);
    expect(validation.errors, contains('schema_version must be 1'));
    expect(
      validation.errors,
      contains('scene_id is outside P0.1 official scenes'),
    );
    expect(
      validation.errors,
      contains('completion_signal.status is not allowed'),
    );
    expect(
      validation.errors,
      contains('recommended_next_action.type is not allowed'),
    );
    expect(
      validation.errors,
      contains('pressure_prompt_candidate.enabled must be boolean'),
    );
    expect(
      () => InterviewTrainingFeedbackCandidate.fromJson(malformed),
      throwsA(isA<FormatException>()),
    );
  });
}
