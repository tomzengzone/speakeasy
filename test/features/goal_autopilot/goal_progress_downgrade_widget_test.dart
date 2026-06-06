import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';
import 'package:speakeasy/features/goal_autopilot/goal_progress_surface.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  testWidgets('TC-P02-FUC-018 downgraded surfaces remove stale progress copy', (
    WidgetTester tester,
  ) async {
    final GoalProgressProjection ready = goalProgressProjectionFixture();
    final GoalProgressProjection deleted =
        goalProgressIneligibleProjectionFixture(
          state: 'deleted',
          reason: 'deleted',
        );

    await _expectDowngradeRemovesStaleCopy(
      tester,
      readyWidget: GoalProgressHomeSurface(projection: ready),
      downgradedWidget: GoalProgressHomeSurface(projection: deleted),
      surfaceKey: 'goal_progress_home_surface',
    );
    await _expectDowngradeRemovesStaleCopy(
      tester,
      readyWidget: GoalProgressQueueSurface(projection: ready),
      downgradedWidget: GoalProgressQueueSurface(projection: deleted),
      surfaceKey: 'goal_progress_queue_surface',
    );
    await _expectDowngradeRemovesStaleCopy(
      tester,
      readyWidget: GoalProgressWikiSurface(projection: ready),
      downgradedWidget: GoalProgressWikiSurface(projection: deleted),
      surfaceKey: 'goal_progress_wiki_surface',
    );
  });

  testWidgets(
    'TC-P02-FUC-018 limited and low-confidence surfaces show backend reason without claims',
    (WidgetTester tester) async {
      await _pumpSurface(
        tester,
        GoalProgressHomeSurface(
          projection: goalProgressEligibleDowngradeProjectionFixture(
            state: 'low_confidence',
            reason: 'low_confidence',
          ),
        ),
      );

      expect(find.textContaining('State: low_confidence'), findsOneWidget);
      expect(
        find.textContaining('Projection fluency gap from backend'),
        findsOneWidget,
      );
      _expectNoSensitiveOrCompletionCopy();

      await _pumpSurface(
        tester,
        GoalProgressQueueSurface(
          projection: goalProgressEligibleDowngradeProjectionFixture(
            state: 'limited',
            reason: 'partial_goal_limited',
          ),
        ),
      );

      expect(
        find.textContaining('State: partial_goal_limited'),
        findsOneWidget,
      );
      expect(find.textContaining('Fluency expansion drill'), findsOneWidget);
      _expectNoSensitiveOrCompletionCopy();
    },
  );
}

Future<void> _expectDowngradeRemovesStaleCopy(
  WidgetTester tester, {
  required Widget readyWidget,
  required Widget downgradedWidget,
  required String surfaceKey,
}) async {
  await _pumpSurface(tester, readyWidget);
  expect(find.byKey(ValueKey<String>(surfaceKey)), findsOneWidget);
  expect(
    find.textContaining('Backend checkpoint conclusion only'),
    findsOneWidget,
  );

  await _pumpSurface(tester, downgradedWidget);
  expect(find.byKey(ValueKey<String>(surfaceKey)), findsOneWidget);
  expect(find.textContaining('State: deleted'), findsOneWidget);
  expect(find.textContaining('Projection fluency gap'), findsNothing);
  expect(
    find.textContaining('Backend checkpoint conclusion only'),
    findsNothing,
  );
  expect(find.textContaining('Fluency expansion drill'), findsNothing);
  _expectNoSensitiveOrCompletionCopy();
}

Future<void> _pumpSurface(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}

void _expectNoSensitiveOrCompletionCopy() {
  expect(find.textContaining('ETA'), findsNothing);
  expect(find.textContaining('target_score'), findsNothing);
  expect(find.textContaining('target ability'), findsNothing);
  expect(find.textContaining('official score'), findsNothing);
  expect(find.textContaining('guaranteed'), findsNothing);
  expect(find.textContaining('goal achieved'), findsNothing);
}
