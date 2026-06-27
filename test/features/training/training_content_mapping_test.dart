import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/training/training_contract.dart';
import 'package:speakeasy/features/training/training_backend_adapter.dart';

void main() {
  test(
    'TC-P01-025 backend adapter uses server scenario/version mapping without local two-scene allowlist',
    () async {
      final List<TrainingBackendRequest> requests = <TrainingBackendRequest>[];
      final TrainingBackendAdapter adapter = TrainingBackendAdapter(
        transport: (TrainingBackendRequest request) async {
          requests.add(request);
          return _sessionEnvelope(
            scenarioId: 'future_business_pitch',
            levelCode: 'L1',
            scenarioVersionId: 'server-version-2026-06',
            currentStepKey: 'opening',
            currentMicroAction: 'SayOne',
          );
        },
      );

      final TrainingSessionStartResult result = await adapter.startSession(
        userId: 'user-1',
        sceneId: 'future_business_pitch',
        levelCode: 'beginner',
      );

      expect(requests.single.operation, TrainingBackendOperation.startSession);
      expect(requests.single.path, '/training/sessions');
      expect(requests.single.body['scenario_id'], 'future_business_pitch');
      expect(requests.single.body['level_code'], 'L1');
      expect(result.session?.sceneId, 'future_business_pitch');
      expect(result.session?.scenarioVersionId, 'server-version-2026-06');
      expect(result.session?.currentStep, TrainingActionStep.opening);
      expect(result.rejection, isNull);
    },
  );
}

Map<String, dynamic> _sessionEnvelope({
  required String scenarioId,
  required String levelCode,
  required String scenarioVersionId,
  required String currentStepKey,
  required String currentMicroAction,
}) {
  return <String, dynamic>{
    'schema_version': 1,
    'session': <String, dynamic>{
      'session_id': 'session-1',
      'user_id': 'user-1',
      'scenario_id': scenarioId,
      'scenario_version_id': scenarioVersionId,
      'level_code': levelCode,
      'status': 'ready',
      'current_turn_index': 0,
      'current_step_key': currentStepKey,
      'current_micro_action': currentMicroAction,
      'hint_level': 'none',
      'failure_count': 0,
      'success_count': 0,
      'evidence_write_status': 'not_started',
      'sync_status': 'server_synced',
      'mapping_version': 'training-map:2026.06',
      'action_chain_version': 'p01-action-chain-v1',
    },
  };
}
