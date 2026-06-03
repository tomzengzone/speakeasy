import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/features/training/training_backend_adapter.dart';
import 'package:speakeasy/features/training/training_session_loop_page.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/storage_service.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'speakeasy_training_backend_only_',
    );
    await StorageService.instance.init(
      hivePath: hiveDir.path,
      migrateFromSharedPreferences: false,
    );
  });

  tearDownAll(() async {
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  testWidgets('TC-P01-029 loop actions call backend instead of local planner', (
    WidgetTester tester,
  ) async {
    final List<TrainingBackendRequest> requests = <TrainingBackendRequest>[];
    final TrainingBackendAdapter adapter = TrainingBackendAdapter(
      transport: (TrainingBackendRequest request) async {
        requests.add(request);
        return switch (request.operation) {
          TrainingBackendOperation.startSession => _sessionEnvelope(),
          TrainingBackendOperation.getSession => _sessionEnvelope(),
          TrainingBackendOperation.hint => _hintEnvelope(),
          TrainingBackendOperation.submitTurn => _turnEnvelope(),
          _ => _sessionEnvelope(),
        };
      },
    );

    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: MaterialApp(
          home: TrainingSessionLoopPage(
            sceneId: 'job_interview',
            levelCode: 'beginner',
            backendAdapter: adapter,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('training_continue_button')),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('training_retry_button')),
    );
    await tester.pump();
    await tester.pump();

    expect(
      requests.map((TrainingBackendRequest request) => request.operation),
      <TrainingBackendOperation>[
        TrainingBackendOperation.startSession,
        TrainingBackendOperation.getSession,
        TrainingBackendOperation.hint,
      ],
    );
    expect(
      requests.any(
        (TrainingBackendRequest request) =>
            request.operation == TrainingBackendOperation.submitTurn,
      ),
      isFalse,
    );
    expect(
      find.byKey(const ValueKey<String>('training_feedback_panel')),
      findsNothing,
    );
  });

  testWidgets('TC-P01-030 text fallback submits a backend turn only', (
    WidgetTester tester,
  ) async {
    final List<TrainingBackendRequest> requests = <TrainingBackendRequest>[];
    final TrainingBackendAdapter adapter = TrainingBackendAdapter(
      transport: (TrainingBackendRequest request) async {
        requests.add(request);
        return switch (request.operation) {
          TrainingBackendOperation.startSession => _sessionEnvelope(),
          TrainingBackendOperation.submitTurn => _turnEnvelope(),
          _ => _sessionEnvelope(),
        };
      },
    );

    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: MaterialApp(
          home: TrainingSessionLoopPage(
            sceneId: 'job_interview',
            levelCode: 'beginner',
            backendAdapter: adapter,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('training_submit_recording_button')),
    );
    await tester.pump();

    expect(find.textContaining('trusted_audio_ref_required'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('training_feedback_panel')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('training_text_fallback_field')),
      'I can explain the project clearly.',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('training_text_fallback_button')),
    );
    await tester.pump();
    await tester.pump();

    final TrainingBackendRequest submitRequest = requests.singleWhere(
      (TrainingBackendRequest request) =>
          request.operation == TrainingBackendOperation.submitTurn,
    );
    expect(
      submitRequest.body['transcript'],
      'I can explain the project clearly.',
    );
  });
}

Map<String, dynamic> _sessionEnvelope() {
  return <String, dynamic>{
    'schema_version': 1,
    'session': <String, dynamic>{
      'session_id': '11111111-1111-1111-1111-111111111111',
      'user_id': '22222222-2222-2222-2222-222222222222',
      'scenario_id': 'job_interview',
      'scenario_version_id': '33333333-3333-3333-3333-333333333333',
      'level_code': 'L1',
      'status': 'ready',
      'current_step_key': 'opening',
      'current_micro_action': 'SayOne',
      'hint_level': 'none',
      'failure_count': 0,
      'success_count': 0,
      'evidence_write_status': 'server_no_evidence_written',
      'sync_status': 'server_synced',
      'mapping_version': 'p01-training-map-v1',
      'action_chain_version': 'p01-action-chain-v1',
      'last_reason_code': '',
      'action_chain': const <Map<String, dynamic>>[],
    },
  };
}

Map<String, dynamic> _hintEnvelope() {
  return <String, dynamic>{
    ..._sessionEnvelope(),
    'planner_decision': <String, dynamic>{
      'type': 'raise_hint',
      'next_status': 'retry',
      'next_step_key': 'opening',
      'next_micro_action': 'SayOne',
      'next_hint_level': 'sentence_frame',
      'reason_code': 'hint_requested',
    },
    'prompt': 'Try a shorter sentence.',
  };
}

Map<String, dynamic> _turnEnvelope() {
  return <String, dynamic>{
    ..._sessionEnvelope(),
    'turn': <String, dynamic>{
      'turn_id': '44444444-4444-4444-4444-444444444444',
      'turn_index': 1,
      'step_key': 'opening',
      'micro_action': 'SayOne',
      'transcript': 'I can explain the project clearly.',
      'audio_ref': '',
      'selected_option_id': '',
      'result': 'accepted',
      'provider_status': 'success',
      'created_at': '2026-06-03T00:00:00Z',
    },
    'feedback': <String, dynamic>{
      'summary': 'Server feedback.',
      'main_issue_type': 'none',
      'better_expression': 'I can explain the project clearly.',
      'pronunciation_available': false,
    },
    'planner_decision': <String, dynamic>{
      'type': 'continue',
      'next_status': 'ready',
      'next_step_key': 'explain_purpose',
      'next_micro_action': 'FillOne',
      'next_hint_level': 'none',
      'reason_code': 'target_and_task_met',
    },
    'learning_evidence_candidates': const <Map<String, dynamic>>[],
  };
}
