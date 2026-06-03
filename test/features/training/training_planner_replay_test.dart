import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/training/training_contract.dart';
import 'package:speakeasy/features/training/training_backend_adapter.dart';

import 'training_test_helpers.dart';

void main() {
  test(
    'TC-P01-027 backend adapter maps planner replay, hint and recap audit responses',
    () async {
      final List<TrainingBackendRequest> requests = <TrainingBackendRequest>[];
      final TrainingBackendAdapter adapter = TrainingBackendAdapter(
        transport: (TrainingBackendRequest request) async {
          requests.add(request);
          return switch (request.operation) {
            TrainingBackendOperation.plannerNext => _plannerEnvelope(
              type: 'pressure_check',
            ),
            TrainingBackendOperation.hint => _hintEnvelope(),
            TrainingBackendOperation.completeSession => _recapEnvelope(),
            _ => throw StateError('Unexpected ${request.operation}'),
          };
        },
      );
      final TrainingSessionState current = p01TrainingSession();

      final TrainingPlannerDecision decision = await adapter.plannerNext(
        sessionId: current.sessionId,
        currentSession: current,
      );
      final TrainingSessionState hinted = await adapter.requestHint(
        sessionId: current.sessionId,
        fallbackUserId: current.userId,
      );
      final TrainingRecap recap = await adapter.completeSession(
        sessionId: current.sessionId,
      );

      expect(
        requests.map((TrainingBackendRequest r) => r.operation),
        <TrainingBackendOperation>[
          TrainingBackendOperation.plannerNext,
          TrainingBackendOperation.hint,
          TrainingBackendOperation.completeSession,
        ],
      );
      expect(decision.type, TrainingDecisionType.pressureCheck);
      expect(decision.reasonCode, 'consecutive_success_pressure_check');
      expect(hinted.hintLevel, TrainingHintLevel.sentenceFrame);
      expect(hinted.lastReasonCode, 'hint_requested_raise_support');
      expect(recap.evidenceWriteStatus, 'server_evidence_written');
    },
  );
}

Map<String, dynamic> _plannerEnvelope({required String type}) {
  return <String, dynamic>{
    'schema_version': 1,
    'planner_decision': <String, dynamic>{
      'decision_id': 'decision-1',
      'type': type,
      'next_status': 'pressure_check',
      'next_step_key': 'opening',
      'next_micro_action': 'ContinueUnderPrompt',
      'next_hint_level': 'none',
      'reason_code': 'consecutive_success_pressure_check',
      'planner_version': 'p01-training-planner-v1',
    },
  };
}

Map<String, dynamic> _hintEnvelope() {
  return <String, dynamic>{
    'schema_version': 1,
    'session': <String, dynamic>{
      'session_id': 'session-1',
      'user_id': 'user-1',
      'scenario_id': 'job_interview',
      'scenario_version_id': 'server-version-1',
      'level_code': 'L1',
      'status': 'ready',
      'current_turn_index': 0,
      'current_step_key': 'opening',
      'current_micro_action': 'SayOne',
      'hint_level': 'sentence_frame',
      'failure_count': 0,
      'success_count': 0,
      'last_reason_code': 'hint_requested_raise_support',
    },
    'planner_decision': <String, dynamic>{
      'decision_id': 'decision-2',
      'type': 'raise_hint',
      'next_status': 'ready',
      'next_step_key': 'opening',
      'next_micro_action': 'SayOne',
      'next_hint_level': 'sentence_frame',
      'reason_code': 'hint_requested_raise_support',
      'planner_version': 'p01-training-planner-v1',
    },
  };
}

Map<String, dynamic> _recapEnvelope() {
  return <String, dynamic>{
    'schema_version': 1,
    'recap': <String, dynamic>{
      'recap_id': 'recap-1',
      'session_id': 'session-1',
      'learned_items': <String>['target-1'],
      'weak_points': <String>['none'],
      'next_focus': 'Review target-1.',
      'accepted_evidence_ids': <String>['evidence-1'],
    },
  };
}
