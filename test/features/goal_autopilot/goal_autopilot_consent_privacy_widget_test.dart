import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_panel.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  testWidgets(
    'TC-P02-FUD-015 renders backend-aligned consent privacy copy without release promises',
    (WidgetTester tester) async {
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          return switch (request.operation) {
            GoalAutopilotOperation.summary => goalProgressSummaryFixture(),
            GoalAutopilotOperation.control => goalProgressControlFixture(),
            GoalAutopilotOperation.progressProjection =>
              goalProgressProjectionResponseFixture(),
            _ => throw StateError('unexpected ${request.operation}'),
          };
        },
      );

      await _pumpPanel(tester, adapter);

      expect(_privacyPanel, findsOneWidget);
      expect(find.text('Privacy and controls'), findsOneWidget);
      expect(
        find.text(
          'Goal, diagnostic, plan, reminder, forecast, checkpoint and progress facts are used for product-internal training surfaces.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Export, account deletion and retention follow backend data-governance rules.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Raw audio, raw transcripts, provider payloads, idempotency keys and notification payloads stay out of this surface.',
        ),
        findsOneWidget,
      );
      expect(find.text('Notifications: consent on'), findsOneWidget);
      expect(find.text('Reminder prompts: eligible'), findsOneWidget);
      expect(find.text('Data state: ready'), findsOneWidget);
      _expectNoReleaseOrCommercialPromiseCopy();
    },
  );

  testWidgets(
    'TC-P02-FUD-015 withdrawn notification consent blocks reminder prompts and clears stale consent state',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      Map<String, dynamic> controlResponse = goalProgressControlFixture();
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return switch (request.operation) {
            GoalAutopilotOperation.summary => goalProgressSummaryFixture(),
            GoalAutopilotOperation.control => controlResponse,
            GoalAutopilotOperation.progressProjection =>
              goalProgressProjectionResponseFixture(),
            GoalAutopilotOperation.updateControl =>
              controlResponse = _controlFixture(
                notificationConsent: false,
                reminderReasonCode: 'consent_missing',
              ),
            _ => throw StateError('unexpected ${request.operation}'),
          };
        },
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Notifications: consent on'), findsOneWidget);
      expect(find.text('Reminder prompts: eligible'), findsOneWidget);

      await tester.ensureVisible(find.text('Turn reminders off'));
      await tester.tap(find.text('Turn reminders off'));
      await tester.pumpAndSettle();

      final GoalAutopilotRequest updateRequest = requests.lastWhere(
        (GoalAutopilotRequest request) =>
            request.operation == GoalAutopilotOperation.updateControl,
      );
      expect(updateRequest.body['notification_consent'], isFalse);
      expect(find.text('Notifications: consent withdrawn'), findsOneWidget);
      expect(
        find.text('Reminder prompts blocked: consent_missing'),
        findsOneWidget,
      );
      expect(
        find.text('Reminder prompts are blocked until backend consent is on.'),
        findsOneWidget,
      );
      expect(find.text('Notifications: consent on'), findsNothing);
      expect(find.text('Reminder prompts: eligible'), findsNothing);
      _expectNoReleaseOrCommercialPromiseCopy();
    },
  );

  testWidgets(
    'TC-P02-FUD-015 deleted export state renders current backend privacy state',
    (WidgetTester tester) async {
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          return switch (request.operation) {
            GoalAutopilotOperation.summary => goalProgressSummaryFixture(),
            GoalAutopilotOperation.control => _controlFixture(
              notificationConsent: false,
              reminderReasonCode: 'consent_missing',
            ),
            GoalAutopilotOperation.progressProjection =>
              _deletedProjectionResponse(),
            _ => throw StateError('unexpected ${request.operation}'),
          };
        },
      );

      await _pumpPanel(tester, adapter);

      expect(_privacyPanel, findsOneWidget);
      expect(find.text('Data state: deleted'), findsOneWidget);
      expect(find.text('Notifications: consent withdrawn'), findsOneWidget);
      expect(
        find.text('Reminder prompts blocked: consent_missing'),
        findsOneWidget,
      );
      expect(find.text('Data state: ready'), findsNothing);
      _expectNoReleaseOrCommercialPromiseCopy();
    },
  );
}

final Finder _privacyPanel = find.byKey(
  const ValueKey<String>('goal-autopilot-consent-privacy'),
);

Future<void> _pumpPanel(
  WidgetTester tester,
  GoalAutopilotAdapter adapter,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: GoalAutopilotPanel(adapter: adapter)),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _controlFixture({
  required bool notificationConsent,
  required String reminderReasonCode,
}) {
  return <String, dynamic>{
    'schema_version': 1,
    'control': <String, dynamic>{
      'control_id': 'control_id_sample',
      'control_status': 'active',
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '08:00',
      'timezone': 'Asia/Shanghai',
      'notification_consent': notificationConsent,
      'intensity_override': 'standard',
      'missed_day_policy': 'balanced',
    },
    'reason_code': 'eligible',
    'reminder_eligibility': <String, dynamic>{
      'eligible': notificationConsent,
      'reason_code': reminderReasonCode,
      'explanation_key': notificationConsent
          ? 'reminder_allowed'
          : 'reminder_blocked_$reminderReasonCode',
    },
  };
}

Map<String, dynamic> _deletedProjectionResponse() {
  final Map<String, dynamic> response = goalProgressProjectionResponseFixture();
  final Map<String, dynamic> projection =
      response['projection'] as Map<String, dynamic>;
  projection['projection_state'] = 'deleted';
  projection['downgrade_reason'] = 'deleted';
  projection['goal'] = null;
  projection['next_action'] = null;
  projection['progress'] = null;
  projection['latest_checkpoint'] = null;
  projection['source_refs'] = <String>[];
  final List<dynamic> fragments =
      projection['surface_fragments'] as List<dynamic>;
  for (final dynamic item in fragments) {
    final Map<String, dynamic> fragment = item as Map<String, dynamic>;
    fragment['display_state'] = 'deleted';
    fragment['eligible'] = false;
    fragment['downgrade_reason'] = 'deleted';
    fragment['next_action_ref'] = null;
    fragment['forecast_ref'] = null;
    fragment['checkpoint_ref'] = null;
    fragment['safe_fields'] = <String>[];
  }
  return response;
}

void _expectNoReleaseOrCommercialPromiseCopy() {
  expect(find.textContaining('guaranteed'), findsNothing);
  expect(find.textContaining('official score'), findsNothing);
  expect(find.textContaining('unlimited AI'), findsNothing);
  expect(find.textContaining('unlimited checkpoint'), findsNothing);
  expect(find.textContaining('release approved'), findsNothing);
}
