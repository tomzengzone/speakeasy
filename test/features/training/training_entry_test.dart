import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/features/training/training_backend_adapter.dart';
import 'package:speakeasy/features/training/training_contract.dart';
import 'package:speakeasy/features/training/training_session_loop_page.dart';
import 'package:speakeasy/features/training/training_session_view.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/storage_service.dart';

import 'training_test_helpers.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'speakeasy_training_entry_',
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

  testWidgets('TC-P01-001 backend session start renders server state', (
    WidgetTester tester,
  ) async {
    final List<TrainingBackendRequest> requests = <TrainingBackendRequest>[];
    final TrainingBackendAdapter adapter = TrainingBackendAdapter(
      transport: (TrainingBackendRequest request) async {
        requests.add(request);
        return _sessionEnvelope(
          scenarioId: request.body['scenario_id'] as String,
          levelCode: request.body['level_code'] as String,
        );
      },
    );

    await tester.pumpWidget(
      AppSessionScope(
        session: AppSession(),
        child: MaterialApp(
          home: TrainingSessionLoopPage(
            sceneId: 'future_official_scene',
            levelCode: 'advanced',
            backendAdapter: adapter,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(requests.single.operation, TrainingBackendOperation.startSession);
    expect(
      find.byKey(const ValueKey<String>('training_session_view')),
      findsOneWidget,
    );
    expect(find.textContaining('future_official_scene'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);
  });

  testWidgets('TC-P01-001 backend start failure renders unavailable state', (
    WidgetTester tester,
  ) async {
    final TrainingBackendAdapter adapter = TrainingBackendAdapter(
      transport: (_) async => throw StateError('backend down'),
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

    expect(
      find.byKey(const ValueKey<String>('training_unsupported_scene')),
      findsOneWidget,
    );
    expect(find.textContaining('backend_training_unavailable'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('training_session_view')),
      findsNothing,
    );
  });

  testWidgets('TC-P01-001 unsupported backend state renders reason only', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainingSessionView(
            session: null,
            rejection: const TrainingPlannerDecision(
              type: TrainingDecisionType.unsupportedScene,
              nextStatus: TrainingSessionStatus.unsupportedScene,
              nextStep: TrainingActionStep.opening,
              nextMicroAction: TrainingMicroAction.sayOne,
              nextHintLevel: TrainingHintLevel.none,
              reasonCode: 'server_unmapped_scenario',
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('training_unsupported_scene')),
      findsOneWidget,
    );
    expect(find.textContaining('server_unmapped_scenario'), findsOneWidget);
  });

  testWidgets(
    'TC-P01-001 ready session renders current server step and action',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrainingSessionView(session: p01TrainingSession()),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('training_action_step_label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('training_micro_action')),
        findsOneWidget,
      );
      expect(find.text('SayOne'), findsOneWidget);
    },
  );
}

Map<String, dynamic> _sessionEnvelope({
  required String scenarioId,
  required String levelCode,
}) {
  return <String, dynamic>{
    'schema_version': 1,
    'session': <String, dynamic>{
      'session_id': '11111111-1111-1111-1111-111111111111',
      'user_id': '22222222-2222-2222-2222-222222222222',
      'scenario_id': scenarioId,
      'scenario_version_id': '33333333-3333-3333-3333-333333333333',
      'level_code': levelCode,
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
