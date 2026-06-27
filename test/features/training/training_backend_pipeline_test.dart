import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/training/training_contract.dart';
import 'package:speakeasy/features/training/training_backend_adapter.dart';

void main() {
  test(
    'TC-P01-026 backend adapter sends trusted audio_ref turn and maps AI/evidence response',
    () async {
      final List<TrainingBackendRequest> requests = <TrainingBackendRequest>[];
      final TrainingBackendAdapter adapter = TrainingBackendAdapter(
        transport: (TrainingBackendRequest request) async {
          requests.add(request);
          return switch (request.operation) {
            TrainingBackendOperation.createAudioUpload => _mediaEnvelope(
              status: 'pending',
            ),
            TrainingBackendOperation.completeAudioUpload => _mediaEnvelope(
              status: 'validated',
            ),
            TrainingBackendOperation.submitTurn => _turnEnvelope(),
            _ => throw StateError('Unexpected ${request.operation}'),
          };
        },
      );

      final TrainingAudioUploadHandle pending = await adapter.createAudioUpload(
        contentType: 'audio/m4a',
        byteSize: 12000,
        durationSeconds: 8,
        idempotencyKey: 'upload-key-1',
      );
      final TrainingAudioUploadHandle validated = await adapter
          .completeAudioUpload(mediaId: pending.mediaId);
      final TrainingBackendTurnResult result = await adapter.submitAudioTurn(
        sessionId: 'session-1',
        audioRef: validated.audioRef,
        idempotencyKey: 'turn-key-1',
        fallbackUserId: 'user-1',
      );

      expect(requests[0].headers['Idempotency-Key'], 'upload-key-1');
      expect(requests[0].body['purpose'], 'asr_input');
      expect(validated.status, 'validated');
      expect(requests[2].path, '/training/sessions/session-1/turns');
      expect(requests[2].headers['Idempotency-Key'], 'turn-key-1');
      expect(requests[2].body['audio_ref'], startsWith('media://audio/'));
      expect(result.session.currentStep, TrainingActionStep.explainPurpose);
      expect(result.feedback?.pronunciationAvailable, isTrue);
      expect(
        result.feedback?.recommendedNextAction,
        TrainingNextActionType.continueAction,
      );
      expect(result.learningEvidenceCandidates.single.status, 'accepted');
      expect(
        result.learningEvidenceCandidates.single.ruleInput,
        'training_signal_v1',
      );
    },
  );
}

Map<String, dynamic> _mediaEnvelope({required String status}) {
  return <String, dynamic>{
    'schema_version': 1,
    'media': <String, dynamic>{
      'media_id': 'media-1',
      'audio_ref': 'media://audio/media-1',
      'status': status,
      'upload_url': 'https://upload.test.local/media-1.m4a',
      'upload_headers': <String, dynamic>{
        'Content-Type': 'audio/m4a',
        'x-speakeasy-media-purpose': 'asr_input',
      },
    },
  };
}

Map<String, dynamic> _turnEnvelope() {
  return <String, dynamic>{
    'schema_version': 1,
    'session': <String, dynamic>{
      'session_id': 'session-1',
      'user_id': 'user-1',
      'scenario_id': 'job_interview',
      'scenario_version_id': 'server-version-1',
      'level_code': 'L1',
      'status': 'ready',
      'current_turn_index': 1,
      'current_step_key': 'explain_purpose',
      'current_micro_action': 'FillOne',
      'hint_level': 'none',
      'failure_count': 0,
      'success_count': 1,
      'evidence_write_status': 'accepted_written',
      'sync_status': 'server_synced',
    },
    'turn': <String, dynamic>{
      'turn_id': 'turn-1',
      'turn_index': 1,
      'result': 'accepted',
    },
    'feedback': <String, dynamic>{
      'summary': 'Clear enough for the target task.',
      'main_issue_type': 'none',
      'better_expression': 'My main contribution was coordinating priorities.',
      'pronunciation_available': true,
      'completion_status': 'met',
      'task_status': 'met',
      'provider_status': 'success',
    },
    'planner_decision': <String, dynamic>{
      'decision_id': 'decision-1',
      'type': 'advance_step',
      'next_status': 'ready',
      'next_step_key': 'explain_purpose',
      'next_micro_action': 'FillOne',
      'next_hint_level': 'none',
      'reason_code': 'target_and_task_met',
      'planner_version': 'p01-training-planner-v1',
    },
    'learning_evidence_candidates': <Map<String, dynamic>>[
      <String, dynamic>{
        'candidate_id': 'candidate-1',
        'learning_evidence_id': 'evidence-1',
        'evidence_type': 'mastered_expression',
        'target_expression_id': 'target-1',
        'confidence': 0.86,
        'status': 'accepted',
        'rule_name': 'training_signal_v1',
        'reason_code': 'target_and_task_met',
        'schema_version': 1,
      },
    ],
  };
}
