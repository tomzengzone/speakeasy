import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_progress_surface.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  testWidgets(
    'TC-P02-FUC-020 surface projection adapter and widget p95 stays under budget',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return goalProgressProjectionResponseFixture();
        },
      );

      final List<int> durations = <int>[];
      for (int i = 0; i < 24; i++) {
        final Stopwatch stopwatch = Stopwatch()..start();
        final projection = await adapter.loadProgressProjection();
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
        stopwatch.stop();
        durations.add(stopwatch.elapsedMicroseconds);
      }

      expect(
        requests.map((GoalAutopilotRequest request) => request.operation),
        everyElement(GoalAutopilotOperation.progressProjection),
      );
      expect(
        requests.map((GoalAutopilotRequest request) => request.path),
        everyElement(SpeakeasyApiPaths.goalAutopilotProgressProjection),
      );
      expect(
        find.byKey(const ValueKey<String>('goal_progress_home_surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('goal_progress_queue_surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('goal_progress_wiki_surface')),
        findsOneWidget,
      );
      expect(
        p95(durations),
        lessThan(1000000),
        reason: 'TC-P02-FUC-020 surface propagation p95 must stay <=1s',
      );
    },
  );
}

int p95(List<int> values) {
  final List<int> sorted = List<int>.of(values)..sort();
  return sorted[((sorted.length * 0.95).ceil()) - 1];
}
