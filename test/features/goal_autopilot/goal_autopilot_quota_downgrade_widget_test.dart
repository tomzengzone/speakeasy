import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_panel.dart';
import 'package:speakeasy/features/goal_autopilot/goal_progress_surface.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  testWidgets(
    'TC-P02-FUD-012 quota downgrade clears stale Home Queue Wiki projection copy',
    (WidgetTester tester) async {
      final GoalProgressProjection ready = goalProgressProjectionFixture();
      final GoalProgressProjection quota = goalProgressIneligibleProjectionFixture(
        state: 'unavailable',
        reason: 'quota_exhausted',
      );

      await _pumpSurfaces(tester, ready);
      expect(find.textContaining('Fluency expansion drill'), findsWidgets);
      expect(
        find.textContaining('Projection fluency gap from backend'),
        findsWidgets,
      );
      expect(
        find.textContaining('Backend checkpoint conclusion only'),
        findsWidgets,
      );

      await _pumpSurfaces(tester, quota);
      expect(find.textContaining('State: quota_exhausted'), findsNWidgets(3));
      _expectNoFullDepthCopy();
    },
  );

  testWidgets(
    'TC-P02-FUD-012 entitlement and cost downgrade reasons render without local inference',
    (WidgetTester tester) async {
      await _pumpSurfaces(
        tester,
        goalProgressIneligibleProjectionFixture(
          state: 'unavailable',
          reason: 'entitlement_required',
        ),
      );
      expect(find.textContaining('State: entitlement_required'), findsNWidgets(3));
      _expectNoFullDepthCopy();

      await _pumpSurfaces(
        tester,
        goalProgressIneligibleProjectionFixture(
          state: 'unavailable',
          reason: 'cost_budget_limited',
        ),
      );
      expect(find.textContaining('State: cost_budget_limited'), findsNWidgets(3));
      _expectNoFullDepthCopy();
    },
  );

  testWidgets(
    'TC-P02-FUD-012 panel does not restore stale action plan or checkpoint controls after quota downgrade',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return switch (request.operation) {
            GoalAutopilotOperation.summary => goalProgressSummaryFixture(),
            GoalAutopilotOperation.control => goalProgressControlFixture(),
            GoalAutopilotOperation.progressProjection =>
              _downgradedProjectionResponse('quota_exhausted'),
            _ => throw StateError('unexpected ${request.operation}'),
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GoalAutopilotPanel(adapter: adapter)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('State: quota_exhausted'), findsOneWidget);
      expect(find.textContaining('Legacy summary action'), findsNothing);
      expect(find.text('Done'), findsNothing);
      expect(find.text('Checkpoint'), findsNothing);
      expect(find.textContaining('30 min'), findsNothing);
      _expectNoFullDepthCopy();
      expect(
        requests.map((GoalAutopilotRequest request) => request.operation),
        containsAllInOrder(<GoalAutopilotOperation>[
          GoalAutopilotOperation.summary,
          GoalAutopilotOperation.control,
          GoalAutopilotOperation.progressProjection,
        ]),
      );
    },
  );
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

Map<String, dynamic> _downgradedProjectionResponse(String reason) {
  final Map<String, dynamic> response = goalProgressProjectionResponseFixture();
  final Map<String, dynamic> projection =
      response['projection'] as Map<String, dynamic>;
  projection['projection_state'] = 'unavailable';
  projection['downgrade_reason'] = reason;
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
    fragment['downgrade_reason'] = reason;
    fragment['next_action_ref'] = null;
    fragment['forecast_ref'] = null;
    fragment['checkpoint_ref'] = null;
    fragment['safe_fields'] = <String>[];
  }
  return response;
}

void _expectNoFullDepthCopy() {
  expect(find.textContaining('Fluency expansion drill'), findsNothing);
  expect(find.textContaining('Projection fluency gap'), findsNothing);
  expect(find.textContaining('Backend checkpoint conclusion only'), findsNothing);
  expect(find.textContaining('ETA'), findsNothing);
  expect(find.textContaining('official score'), findsNothing);
  expect(find.textContaining('guaranteed'), findsNothing);
  expect(find.textContaining('goal achieved'), findsNothing);
}
