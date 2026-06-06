import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_progress_surface.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  testWidgets(
    'TC-P02-FUC-015 Wiki renders backend checkpoint and goal-progress fragment',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoalProgressWikiSurface(
              projection: goalProgressProjectionFixture(),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('goal_progress_wiki_surface')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Projection fluency gap from backend'),
        findsOneWidget,
      );
      expect(find.textContaining('backend_checkpoint_due'), findsOneWidget);
      expect(find.textContaining('2099-06-11'), findsOneWidget);
      expect(
        find.textContaining('Backend checkpoint conclusion only'),
        findsOneWidget,
      );
      expect(find.textContaining('Fluency expansion drill'), findsNothing);
      expect(find.textContaining('target_score'), findsNothing);
      expect(find.textContaining('target ability'), findsNothing);
      expect(find.textContaining('ETA'), findsNothing);
      expect(find.textContaining('official score'), findsNothing);
      expect(find.textContaining('guaranteed'), findsNothing);
    },
  );
}
