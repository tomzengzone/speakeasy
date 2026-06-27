import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_panel.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  testWidgets('TC-P02-FUC-013 Home renders backend projection surface', (
    WidgetTester tester,
  ) async {
    final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
    final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
      transport: (GoalAutopilotRequest request) async {
        requests.add(request);
        return switch (request.operation) {
          GoalAutopilotOperation.summary => goalProgressSummaryFixture(),
          GoalAutopilotOperation.control => goalProgressControlFixture(),
          GoalAutopilotOperation.progressProjection =>
            goalProgressProjectionResponseFixture(),
          _ => goalProgressSummaryFixture(),
        };
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GoalAutopilotPanel(adapter: adapter)),
      ),
    );
    await tester.pumpAndSettle();

    final GoalAutopilotRequest projectionRequest = requests.singleWhere(
      (GoalAutopilotRequest request) =>
          request.operation == GoalAutopilotOperation.progressProjection,
    );
    expect(
      projectionRequest.path,
      SpeakeasyApiPaths.goalAutopilotProgressProjection,
    );
    expect(
      find.byKey(const ValueKey<String>('goal_progress_home_surface')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Projection fluency gap from backend'),
      findsOneWidget,
    );
    expect(find.textContaining('backend_checkpoint_due'), findsOneWidget);
    expect(
      find.textContaining('Backend checkpoint conclusion only'),
      findsOneWidget,
    );
    expect(find.textContaining('Fluency expansion drill'), findsOneWidget);
    expect(find.textContaining('Legacy summary gap'), findsNothing);
    expect(find.textContaining('sensitive target ability'), findsNothing);
    expect(find.textContaining('official score'), findsNothing);
    expect(find.textContaining('guaranteed'), findsNothing);
    expect(find.textContaining('ETA'), findsNothing);
  });
}
