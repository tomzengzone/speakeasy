import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_panel.dart';
import 'package:speakeasy/features/goal_autopilot/goal_progress_surface.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  testWidgets(
    'TC-P02-FUD-003 disabled projection closes goal entry and mutation controls',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      GoalProgressProjection? replacementProjection;
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return switch (request.operation) {
            GoalAutopilotOperation.summary => goalProgressSummaryFixture(),
            GoalAutopilotOperation.control => goalProgressControlFixture(),
            GoalAutopilotOperation.progressProjection =>
              _runtimeUnavailableProjectionResponse('feature_disabled'),
            _ => throw StateError('unexpected ${request.operation}'),
          };
        },
      );

      await _pumpPanel(
        tester,
        adapter,
        onRuntimeUnavailableProjection: (GoalProgressProjection? projection) {
          replacementProjection = projection;
        },
      );

      expect(find.byKey(_runtimeUnavailableKey), findsOneWidget);
      expect(find.text('Goal autopilot unavailable'), findsOneWidget);
      expect(find.textContaining('State: feature_disabled'), findsWidgets);
      expect(replacementProjection, isNotNull);
      expect(replacementProjection!.goal, isNull);
      expect(replacementProjection!.nextAction, isNull);
      expect(replacementProjection!.progress, isNull);
      expect(replacementProjection!.latestCheckpoint, isNull);
      expect(replacementProjection!.sourceRefs, isEmpty);
      _expectNoEntryOrMutationCopy();
      _expectNoSensitiveOrCompletionCopy();
      _expectNoMutationRequests(requests);
    },
  );

  testWidgets(
    'TC-P02-FUD-003 runtime backend failure does not fall back to no-goal entry',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.summary) {
            throw const GoalAutopilotRuntimeDisabledException(
              'kill_switch_active',
            );
          }
          if (request.operation == GoalAutopilotOperation.progressProjection) {
            return _runtimeUnavailableProjectionResponse('kill_switch_active');
          }
          throw StateError('unexpected ${request.operation}');
        },
      );

      await _pumpPanel(tester, adapter);

      expect(find.byKey(_runtimeUnavailableKey), findsOneWidget);
      expect(find.textContaining('State: kill_switch_active'), findsWidgets);
      expect(find.text('No active goal'), findsNothing);
      _expectNoEntryOrMutationCopy();
      _expectNoSensitiveOrCompletionCopy();
      _expectNoMutationRequests(requests);
    },
  );

  testWidgets(
    'TC-P02-FUD-003 unavailable projection replacement clears stale surface copy',
    (WidgetTester tester) async {
      final GoalProgressProjection ready = goalProgressProjectionFixture();
      final GoalProgressProjection unavailable =
          GoalProgressProjection.unavailable('backend_unavailable');

      await _pumpSurfaces(tester, ready);
      expect(find.textContaining('Fluency expansion drill'), findsWidgets);
      expect(
        find.textContaining('Backend checkpoint conclusion only'),
        findsWidgets,
      );

      await _pumpSurfaces(tester, unavailable);
      expect(find.textContaining('State: backend_unavailable'), findsWidgets);
      expect(find.textContaining('Fluency expansion drill'), findsNothing);
      expect(find.textContaining('Projection fluency gap'), findsNothing);
      expect(
        find.textContaining('Backend checkpoint conclusion only'),
        findsNothing,
      );
      _expectNoSensitiveOrCompletionCopy();
    },
  );

  test(
    'TC-P02-FUD-003 runtime gate projection exposes unavailable state without local facts',
    () async {
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          throw Exception('请求失败（503）');
        },
      );

      final GoalProgressProjection? projection = await adapter
          .loadRuntimeGateProjection();

      expect(projection, isNotNull);
      expect(projection!.projectionState, 'unavailable');
      expect(projection.downgradeReason, 'backend_unavailable');
      expect(projection.goal, isNull);
      expect(projection.nextAction, isNull);
      expect(projection.progress, isNull);
      expect(projection.latestCheckpoint, isNull);
      expect(projection.sourceRefs, isEmpty);
      for (final GoalProgressSurfaceFragment fragment
          in projection.surfaceFragments) {
        expect(fragment.eligible, isFalse);
        expect(fragment.safeFields, isEmpty);
      }
    },
  );
}

const Key _runtimeUnavailableKey = ValueKey<String>(
  'goal-autopilot-runtime-unavailable',
);

Future<void> _pumpPanel(
  WidgetTester tester,
  GoalAutopilotAdapter adapter, {
  ValueChanged<GoalProgressProjection?>? onRuntimeUnavailableProjection,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GoalAutopilotPanel(
          adapter: adapter,
          onRuntimeUnavailableProjection: onRuntimeUnavailableProjection,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSurfaces(
  WidgetTester tester,
  GoalProgressProjection projection,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            GoalProgressHomeSurface(projection: projection),
            GoalProgressQueueSurface(projection: projection),
            GoalProgressWikiSurface(projection: projection),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
}

Map<String, dynamic> _runtimeUnavailableProjectionResponse(String reasonCode) {
  final Map<String, dynamic> response = goalProgressProjectionResponseFixture();
  final Map<String, dynamic> projection =
      response['projection'] as Map<String, dynamic>;
  projection['projection_state'] = 'unavailable';
  projection['downgrade_reason'] = reasonCode;
  projection['goal'] = null;
  projection['next_action'] = null;
  projection['progress'] = null;
  projection['latest_checkpoint'] = null;
  projection['source_refs'] = <String>[];
  final List<dynamic> fragments =
      projection['surface_fragments'] as List<dynamic>;
  for (final dynamic item in fragments) {
    final Map<String, dynamic> fragment = item as Map<String, dynamic>;
    fragment['display_state'] = 'unavailable';
    fragment['eligible'] = false;
    fragment['downgrade_reason'] = reasonCode;
    fragment['next_action_ref'] = null;
    fragment['forecast_ref'] = null;
    fragment['checkpoint_ref'] = null;
    fragment['safe_fields'] = <String>[];
  }
  return response;
}

void _expectNoEntryOrMutationCopy() {
  expect(find.text('No active goal'), findsNothing);
  expect(find.text('Set a goal'), findsNothing);
  expect(find.text('Explore practice'), findsNothing);
  expect(find.text('Try a sample drill'), findsNothing);
  expect(find.text('Goal type'), findsNothing);
  expect(find.text('Start autopilot'), findsNothing);
  expect(find.text('Edit goal'), findsNothing);
  expect(find.text('Generate plan'), findsNothing);
  expect(find.text('Regenerate plan'), findsNothing);
  expect(find.text('Done'), findsNothing);
  expect(find.text('Checkpoint'), findsNothing);
  expect(find.text('Pause autopilot'), findsNothing);
  expect(find.text('Resume autopilot'), findsNothing);
  expect(find.text('Turn reminders on'), findsNothing);
  expect(find.text('Turn reminders off'), findsNothing);
}

void _expectNoSensitiveOrCompletionCopy() {
  expect(find.textContaining('ETA'), findsNothing);
  expect(find.textContaining('target_score'), findsNothing);
  expect(find.textContaining('target ability'), findsNothing);
  expect(find.textContaining('official score'), findsNothing);
  expect(find.textContaining('guaranteed'), findsNothing);
  expect(find.textContaining('goal achieved'), findsNothing);
}

void _expectNoMutationRequests(List<GoalAutopilotRequest> requests) {
  const Set<GoalAutopilotOperation> mutationOperations =
      <GoalAutopilotOperation>{
        GoalAutopilotOperation.createGoal,
        GoalAutopilotOperation.updateControl,
        GoalAutopilotOperation.pauseControl,
        GoalAutopilotOperation.resumeControl,
        GoalAutopilotOperation.generatePlan,
        GoalAutopilotOperation.completeAction,
        GoalAutopilotOperation.checkpoint,
      };
  expect(
    requests.where(
      (GoalAutopilotRequest request) =>
          mutationOperations.contains(request.operation),
    ),
    isEmpty,
  );
}
