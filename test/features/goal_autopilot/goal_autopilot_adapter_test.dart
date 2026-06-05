import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_panel.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';

void main() {
  test('P0.2 adapter uses OpenAPI path registry and parses summary', () async {
    final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
    final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
      transport: (GoalAutopilotRequest request) async {
        requests.add(request);
        return _summaryFixture();
      },
    );

    final summary = await adapter.loadSummary();

    expect(requests.single.path, SpeakeasyApiPaths.goalAutopilotSummary);
    expect(summary.goalType, 'ielts_speaking');
    expect(summary.targetAbility, contains('IELTS'));
    expect(summary.dailyMinutes, 30);
    expect(summary.revision, 1);
    expect(summary.sampleCount, 3);
    expect(summary.supportReasonCode, 'rubric_and_content_available');
    expect(summary.nextAction?.reasonCode, 'highest_weakness_and_memory_risk');
    expect(summary.officialScoreEquivalence, isFalse);
    expect(summary.goalCompletionClaimAllowed, isFalse);
  });

  test(
    'P0.2 adapter sends action completion and checkpoint envelopes',
    () async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.checkpoint) {
            return <String, dynamic>{'schema_version': 1};
          }
          return <String, dynamic>{'action': _summaryFixture()['next_action']};
        },
      );

      final next = await adapter.loadNextAction();
      final completed = await adapter.completeAction(
        planItemId: 'plan item/with space',
        outcome: 'deferred',
      );
      await adapter.submitCheckpoint();

      expect(next.title, 'Fluency expansion drill');
      expect(completed.reasonCode, 'highest_weakness_and_memory_risk');
      expect(requests[0].path, SpeakeasyApiPaths.goalAutopilotActionsNext);
      expect(
        requests[1].path,
        SpeakeasyApiPaths.goalAutopilotActionComplete('plan item/with space'),
      );
      expect(requests[1].body['outcome'], 'deferred');
      expect(requests[2].path, SpeakeasyApiPaths.goalAutopilotCheckpoints);
      expect(requests[2].body['checkpoint_type'], 'weekly_mock');
    },
  );

  testWidgets(
    'Followup-A form renders editable goal intake and blocks invalid values',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.summary) {
            throw Exception('not found');
          }
          return _summaryFixture();
        },
      );

      await _pumpPanel(tester, adapter);

      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();

      expect(find.text('Goal type'), findsOneWidget);
      expect(find.text('Target score'), findsOneWidget);
      expect(find.text('Target ability'), findsOneWidget);
      expect(find.text('Deadline'), findsOneWidget);
      expect(find.text('Daily minutes'), findsOneWidget);
      expect(find.text('Intensity'), findsOneWidget);
      expect(find.text('Diagnostic sample 1'), findsOneWidget);
      expect(
        find.text('IELTS speaking 8 · 30 min/day · 75 days'),
        findsNothing,
      );

      await tester.tap(find.text('Start autopilot'));
      await tester.pump();

      expect(find.text('Add at least one diagnostic sample.'), findsOneWidget);
      expect(
        requests.where(
          (GoalAutopilotRequest request) =>
              request.operation == GoalAutopilotOperation.createGoal,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Followup-A no active goal renders empty state without creating goal',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.summary) {
            throw Exception('not found');
          }
          return _summaryFixture();
        },
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('No active goal'), findsOneWidget);
      expect(find.text('Set a goal'), findsOneWidget);
      expect(find.text('Explore practice'), findsOneWidget);
      expect(find.text('Try a sample drill'), findsOneWidget);
      expect(find.text('Goal type'), findsNothing);
      expect(find.text('Start autopilot'), findsNothing);
      expect(
        requests.where(
          (GoalAutopilotRequest request) =>
              request.operation == GoalAutopilotOperation.createGoal,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Followup-A Set a goal opens intake without default goal creation',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.summary) {
            throw Exception('not found');
          }
          return _summaryFixture();
        },
      );

      await _pumpPanel(tester, adapter);
      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();

      expect(find.text('Goal type'), findsOneWidget);
      expect(find.text('Start autopilot'), findsOneWidget);
      expect(find.text('No active goal'), findsNothing);
      expect(
        find.text('IELTS speaking 8 · 30 min/day · 75 days'),
        findsNothing,
      );
      expect(
        requests.where(
          (GoalAutopilotRequest request) =>
              request.operation != GoalAutopilotOperation.summary,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Followup-A Explore practice bypasses goal-autopilot facts and claims',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.summary) {
            throw Exception('not found');
          }
          return _summaryFixture();
        },
      );

      await _pumpPanel(tester, adapter);
      await tester.tap(find.text('Explore practice'));
      await tester.pumpAndSettle();

      expect(find.text('Sample drill'), findsOneWidget);
      expect(find.textContaining('Practice feedback'), findsOneWidget);
      expect(find.text('Goal type'), findsNothing);
      expect(find.text('Generate plan'), findsNothing);
      expect(find.text('Checkpoint'), findsNothing);
      expect(find.text('Done'), findsNothing);
      expect(find.textContaining('About 2 product-rubric bands'), findsNothing);
      expect(find.textContaining('ETA'), findsNothing);
      expect(find.textContaining('goal achieved'), findsNothing);
      expect(find.textContaining('guaranteed'), findsNothing);
      expect(find.textContaining('official score'), findsNothing);
      expect(
        requests.where(
          (GoalAutopilotRequest request) =>
              request.operation != GoalAutopilotOperation.summary,
        ),
        isEmpty,
      );

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try a sample drill'));
      await tester.pumpAndSettle();

      expect(find.text('Sample drill'), findsOneWidget);
      expect(
        requests.where(
          (GoalAutopilotRequest request) =>
              request.operation != GoalAutopilotOperation.summary,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Followup-A submits user-entered GoalProfile payload without default goal path',
    (WidgetTester tester) async {
      bool created = false;
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.summary && !created) {
            throw Exception('not found');
          }
          if (request.operation == GoalAutopilotOperation.createGoal) {
            created = true;
          }
          return _summaryFixture(
            targetScore: 7.5,
            targetAbility: 'lead weekly English standups',
            dailyMinutes: 45,
            sampleCount: 1,
          );
        },
      );

      await _pumpPanel(tester, adapter);
      await tester.tap(find.text('Set a goal'));
      await tester.pumpAndSettle();

      await tester.enterText(_byKey('goal-target-score-field'), '7.5');
      await tester.enterText(
        _byKey('goal-target-ability-field'),
        'lead weekly English standups',
      );
      await tester.enterText(_byKey('goal-deadline-field'), '2099-08-31');
      await tester.enterText(_byKey('goal-daily-minutes-field'), '45');
      await tester.enterText(
        _byKey('goal-diagnostic-sample-1-field'),
        'I need sharper weekly updates and cleaner transitions.',
      );

      await tester.tap(find.text('Start autopilot'));
      await tester.pumpAndSettle();

      final GoalAutopilotRequest createRequest = requests.singleWhere(
        (GoalAutopilotRequest request) =>
            request.operation == GoalAutopilotOperation.createGoal,
      );
      expect(createRequest.path, SpeakeasyApiPaths.goalAutopilotGoals);
      expect(createRequest.body['goal_type'], 'ielts_speaking');
      expect(createRequest.body['target_score'], 7.5);
      expect(
        createRequest.body['target_ability'],
        'lead weekly English standups',
      );
      expect(createRequest.body['deadline'], '2099-08-31');
      expect(createRequest.body['daily_minutes'], 45);
      expect(createRequest.body['intensity_preference'], 'standard');
      expect(createRequest.body['diagnostic_samples'], hasLength(1));
      expect(
        createRequest.body['diagnostic_samples'][0]['transcript'],
        'I need sharper weekly updates and cleaner transitions.',
      );
      expect(
        createRequest.body['diagnostic_samples'][0]['transcript'],
        isNot(contains('I can answer familiar questions')),
      );
      expect(find.text('Fluency expansion drill'), findsOneWidget);
    },
  );

  test(
    'Followup-A filters diagnostic samples and preserves stable refs',
    () async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return _summaryFixture(sampleCount: 2);
        },
      );

      await adapter.createGoal(
        goalType: 'business_meeting',
        targetScore: null,
        targetAbility: 'handle stakeholder updates',
        deadline: DateTime(2099, 8, 31),
        dailyMinutes: 25,
        intensityPreference: 'gentle',
        diagnosticSamples: const <GoalDiagnosticSampleInput>[
          GoalDiagnosticSampleInput(
            sampleRef: 'flutter_goal_sample_1',
            transcript: 'I can open a meeting but need clearer next steps.',
          ),
          GoalDiagnosticSampleInput(
            sampleRef: 'flutter_goal_sample_2',
            transcript: '   ',
          ),
          GoalDiagnosticSampleInput(
            sampleRef: 'flutter_goal_sample_3',
            transcript: 'I need to answer objections with less hesitation.',
          ),
        ],
      );

      final List<dynamic> samples =
          requests.single.body['diagnostic_samples'] as List<dynamic>;
      expect(samples, hasLength(2));
      expect(samples[0]['sample_ref'], 'flutter_goal_sample_1');
      expect(samples[1]['sample_ref'], 'flutter_goal_sample_3');
      expect(samples[0]['transcript'], contains('open a meeting'));
      expect(samples[1]['transcript'], contains('answer objections'));
    },
  );

  test(
    'Followup-A sends diagnostic candidate evidence without fake audio facts',
    () async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return _summaryFixture();
        },
      );

      await adapter.createGoal(
        goalType: 'job_interview',
        targetScore: null,
        targetAbility: 'answer behavioral interview follow-ups',
        deadline: DateTime(2099, 7, 1),
        dailyMinutes: 35,
        intensityPreference: 'intensive',
        diagnosticSamples: const <GoalDiagnosticSampleInput>[
          GoalDiagnosticSampleInput(
            sampleRef: 'flutter_goal_sample_1',
            transcript: 'I can introduce the STAR structure.',
            durationSeconds: 42,
          ),
        ],
      );

      final List<dynamic> samples =
          requests.single.body['diagnostic_samples'] as List<dynamic>;
      expect(
        samples.single,
        containsPair('sample_ref', 'flutter_goal_sample_1'),
      );
      expect(
        samples.single,
        containsPair('transcript', 'I can introduce the STAR structure.'),
      );
      expect(samples.single, containsPair('duration_seconds', 42));
      expect(samples.single, isNot(contains('audio_ref')));
    },
  );

  testWidgets(
    'Followup-B renders server control state and does not override pause or eligibility',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      Map<String, dynamic> controlResponse = _controlFixture(
        controlStatus: 'paused',
        reminderReasonCode: 'paused',
        notificationConsent: true,
      );
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return switch (request.operation) {
            GoalAutopilotOperation.summary => _summaryFixture(),
            GoalAutopilotOperation.control => controlResponse,
            GoalAutopilotOperation.resumeControl =>
              controlResponse = _controlFixture(
                controlStatus: 'active',
                reminderReasonCode: 'consent_missing',
                notificationConsent: false,
              ),
            GoalAutopilotOperation.updateControl =>
              controlResponse = _controlFixture(
                controlStatus: 'active',
                reminderReasonCode: 'eligible',
                notificationConsent: true,
                reminderEligible: true,
              ),
            _ => _summaryFixture(),
          };
        },
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Autopilot: paused'), findsOneWidget);
      expect(find.text('Reminder: paused'), findsOneWidget);
      expect(find.text('Resume autopilot'), findsOneWidget);
      expect(find.text('Pause autopilot'), findsNothing);
      expect(find.text('Done'), findsNothing);

      await tester.tap(find.text('Resume autopilot'));
      await tester.pumpAndSettle();

      final GoalAutopilotRequest resumeRequest = requests.lastWhere(
        (GoalAutopilotRequest request) =>
            request.operation == GoalAutopilotOperation.resumeControl,
      );
      expect(resumeRequest.path, SpeakeasyApiPaths.goalAutopilotControlResume);
      expect(resumeRequest.body['source_event'], 'manual_resume');
      expect(resumeRequest.headers['Idempotency-Key'], isNotEmpty);
      expect(find.text('Autopilot: active'), findsOneWidget);
      expect(find.text('Reminder: consent_missing'), findsOneWidget);
      expect(find.text('Pause autopilot'), findsOneWidget);
      expect(find.text('Resume autopilot'), findsNothing);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Turn reminders on'));
      await tester.pumpAndSettle();

      final GoalAutopilotRequest updateRequest = requests.lastWhere(
        (GoalAutopilotRequest request) =>
            request.operation == GoalAutopilotOperation.updateControl,
      );
      expect(updateRequest.path, SpeakeasyApiPaths.goalAutopilotControl);
      expect(updateRequest.body['notification_consent'], isTrue);
      expect(updateRequest.headers['Idempotency-Key'], isNotEmpty);
      expect(find.text('Reminder: eligible'), findsOneWidget);
      expect(
        requests.where(
          (GoalAutopilotRequest request) =>
              request.operation == GoalAutopilotOperation.completeAction,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Followup-B shows quiet-hours and notification blocked reasons without treating them as completion',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final List<String> blockedReasons = <String>[
        'permission_denied',
        'entitlement_blocked',
        'quota_exhausted',
      ];
      int updateIndex = 0;
      Map<String, dynamic> controlResponse = _controlFixture(
        controlStatus: 'active',
        reminderReasonCode: 'quiet_hours',
        notificationConsent: true,
      );
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return switch (request.operation) {
            GoalAutopilotOperation.summary => _summaryFixture(),
            GoalAutopilotOperation.control => controlResponse,
            GoalAutopilotOperation.updateControl =>
              controlResponse = _controlFixture(
                controlStatus: 'active',
                reminderReasonCode: blockedReasons[updateIndex++],
                notificationConsent: true,
              ),
            _ => _summaryFixture(),
          };
        },
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Autopilot: active'), findsOneWidget);
      expect(find.text('Reminder: quiet_hours'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      for (final String reason in blockedReasons) {
        await tester.tap(find.text('Turn reminders off'));
        await tester.pumpAndSettle();
        expect(find.text('Reminder: $reason'), findsOneWidget);
      }

      expect(
        requests.where(
          (GoalAutopilotRequest request) =>
              request.operation == GoalAutopilotOperation.completeAction,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'Followup-A renders supported state with support decision and plan entry',
    (WidgetTester tester) async {
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async =>
            _summaryFixture(includePlan: false, includeAction: false),
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Support: supported'), findsOneWidget);
      expect(find.text('rubric_and_content_available'), findsOneWidget);
      expect(find.text('Samples 3 · complete'), findsOneWidget);
      expect(find.text('Generate plan'), findsOneWidget);
      expect(find.text('Edit goal'), findsOneWidget);
    },
  );

  testWidgets(
    'Followup-A renders partial low-confidence state without high-certainty claims',
    (WidgetTester tester) async {
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async => _summaryFixture(
          supportStatus: 'partial',
          supportReasonCode: 'partial_content_and_time',
          limitationMessage:
              'Limited content and time budget; plan is conservative.',
          diagnosticStatus: 'low_confidence',
          confidenceBand: 'low',
          sampleCount: 1,
          etaDate: '2099-08-24',
        ),
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Support: partial'), findsOneWidget);
      expect(
        find.textContaining('Limited content and time budget'),
        findsOneWidget,
      );
      expect(find.text('Samples 1 · low_confidence'), findsOneWidget);
      expect(find.text('Product-internal progress only'), findsOneWidget);
      expect(find.textContaining('2099-08-24'), findsNothing);
      expect(find.textContaining('official score'), findsNothing);
      expect(find.textContaining('guaranteed'), findsNothing);
    },
  );

  testWidgets(
    'Followup-A fail-closes unsupported goals and exposes edit recovery only',
    (WidgetTester tester) async {
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async => _summaryFixture(
          supportStatus: 'unsupported',
          supportReasonCode: 'target_score_out_of_supported_range',
          limitationMessage:
              'Target score is outside supported local rubric range.',
          diagnosticStatus: 'unsupported',
          confidenceBand: 'low',
          includePlan: false,
          includeAction: false,
        ),
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Support: unsupported'), findsOneWidget);
      expect(
        find.textContaining('outside supported local rubric range'),
        findsOneWidget,
      );
      expect(find.text('Edit goal'), findsOneWidget);
      expect(find.text('Generate plan'), findsNothing);
      expect(find.text('Checkpoint'), findsNothing);
      expect(find.text('Done'), findsNothing);

      await tester.tap(find.text('Edit goal'));
      await tester.pumpAndSettle();

      expect(find.text('Goal type'), findsOneWidget);
      expect(find.text('Start autopilot'), findsOneWidget);
    },
  );

  testWidgets(
    'Followup-A parses claim guards and blocks official or guaranteed outcome copy',
    (WidgetTester tester) async {
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async => _summaryFixture(
          officialScoreEquivalence: false,
          goalCompletionClaimAllowed: false,
          allowedClaim: 'product_internal_progress_only',
        ),
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Product-internal progress only'), findsOneWidget);
      expect(find.textContaining('official score'), findsNothing);
      expect(find.textContaining('guaranteed'), findsNothing);
      expect(find.textContaining('goal achieved'), findsNothing);
    },
  );

  testWidgets(
    'Followup-A exposes revision and blocks stale next action after edit',
    (WidgetTester tester) async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          if (request.operation == GoalAutopilotOperation.generatePlan) {
            return <String, dynamic>{
              'daily_plan': _summaryFixture()['daily_plan'],
            };
          }
          return _summaryFixture(
            revision: 2,
            planStatus: 'stale',
            actionStatus: 'blocked',
          );
        },
      );

      await _pumpPanel(tester, adapter);

      expect(find.text('Revision 2'), findsOneWidget);
      expect(find.text('Regenerate plan'), findsOneWidget);
      expect(find.text('Done'), findsNothing);

      await tester.tap(find.text('Regenerate plan'));
      await tester.pumpAndSettle();

      final GoalAutopilotRequest replanRequest = requests.lastWhere(
        (GoalAutopilotRequest request) =>
            request.operation == GoalAutopilotOperation.generatePlan,
      );
      expect(replanRequest.body['force_replan'], isTrue);
      expect(replanRequest.body['reason_code'], 'flutter_force_replan');
    },
  );
}

Finder _byKey(String value) {
  return find.byKey(ValueKey<String>(value));
}

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
  String controlStatus = 'active',
  String reminderReasonCode = 'eligible',
  bool reminderEligible = false,
  bool notificationConsent = true,
}) {
  return <String, dynamic>{
    'schema_version': 1,
    'control': <String, dynamic>{
      'control_id': 'control_id_sample',
      'user_id': 'user_id_sample',
      'goal_profile_id': 'goal_profile_id_sample',
      'control_status': controlStatus,
      'paused_at': controlStatus == 'paused' ? '2099-06-04T21:00:00Z' : null,
      'pause_reason': controlStatus == 'paused' ? 'user_requested_break' : null,
      'resumed_at': controlStatus == 'paused' ? null : '2099-06-04T22:00:00Z',
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '08:00',
      'timezone': 'Asia/Shanghai',
      'notification_consent': notificationConsent,
      'intensity_override': 'standard',
      'missed_day_policy': 'balanced',
      'updated_at': '2099-06-04T22:00:00Z',
      'rule_version': 'fub-control-v1',
    },
    'next_action_changed': true,
    'reminder_eligibility_changed': true,
    'replan_required': false,
    'reason_code': controlStatus == 'paused' ? 'paused' : 'eligible',
    'reminder_eligibility': <String, dynamic>{
      'decision_id': 'eligibility_decision_sample',
      'control_id': 'control_id_sample',
      'user_id': 'user_id_sample',
      'goal_profile_id': 'goal_profile_id_sample',
      'plan_item_id': reminderEligible ? 'plan_item_id_sample' : null,
      'eligible': reminderEligible,
      'reason_code': reminderReasonCode,
      'next_allowed_at': null,
      'explanation_key': reminderEligible
          ? 'reminder_allowed'
          : 'reminder_blocked_$reminderReasonCode',
      'evaluated_at': '2099-06-04T22:00:00Z',
      'rule_version': 'fub-reminder-v1',
    },
    'plan_update_signal': <String, dynamic>{
      'signal_type': 'none',
      'reason_code': 'no_replan_needed',
    },
  };
}

Map<String, dynamic> _summaryFixture({
  String goalType = 'ielts_speaking',
  double? targetScore = 8,
  String targetAbility =
      'confident IELTS-style speaking with follow-up pressure',
  int dailyMinutes = 30,
  String intensityPreference = 'standard',
  String supportStatus = 'supported',
  String supportReasonCode = 'rubric_and_content_available',
  String limitationMessage =
      'Product-internal rubric only; no official score certification.',
  String diagnosticStatus = 'complete',
  String confidenceBand = 'medium',
  int sampleCount = 3,
  int revision = 1,
  String planStatus = 'ready',
  String actionStatus = 'ready',
  bool includePlan = true,
  bool includeAction = true,
  bool officialScoreEquivalence = false,
  bool goalCompletionClaimAllowed = false,
  String allowedClaim = 'product_internal_progress_only',
  String? etaDate = '2099-08-24',
}) {
  final Map<String, dynamic> summary = <String, dynamic>{
    'schema_version': 1,
    'goal_profile': <String, dynamic>{
      'goal_profile_id': 'goal_profile_id_sample',
      'goal_type': goalType,
      'target_score': targetScore,
      'target_ability': targetAbility,
      'deadline': '2099-08-31',
      'daily_minutes': dailyMinutes,
      'intensity_preference': intensityPreference,
      'support_status': supportStatus,
      'status': supportStatus == 'supported' ? 'active' : supportStatus,
      'revision': revision,
    },
    'support_decision': <String, dynamic>{
      'decision_id': 'decision_id_sample',
      'support_status': supportStatus,
      'reason_code': supportReasonCode,
      'limitation_message': limitationMessage,
      'rubric_available': supportStatus != 'unsupported',
      'content_coverage': supportStatus == 'unsupported'
          ? 'none'
          : 'sufficient_for_local_plan',
    },
    'diagnostic': <String, dynamic>{
      'diagnostic_assessment_id': 'diagnostic_id_sample',
      'status': diagnosticStatus,
      'confidence_band': confidenceBand,
      'sample_count': sampleCount,
      'rubric_scores': const <Map<String, dynamic>>[],
      'weakness_tags': const <Map<String, dynamic>>[],
      'claim_guard': <String, dynamic>{
        'official_score_equivalence': officialScoreEquivalence,
        'goal_completion_claim_allowed': goalCompletionClaimAllowed,
        'allowed_claim': allowedClaim,
      },
    },
    'forecast': <String, dynamic>{
      'forecast_id': 'forecast_id_sample',
      'gap_summary': 'About 2 product-rubric bands below target in fluency.',
      'eta_date': etaDate,
      'eta_window': etaDate == null ? null : '2099-08-17..2099-08-31',
      'confidence_band': confidenceBand,
      'risk_level': confidenceBand == 'low' ? 'high' : 'medium',
      'risk_reason': 'checkpoint evidence is not available yet',
      'next_checkpoint_date': '2099-06-11',
      'claim_guard': <String, dynamic>{
        'official_score_equivalence': officialScoreEquivalence,
        'goal_completion_claim_allowed': goalCompletionClaimAllowed,
        'allowed_claim': allowedClaim,
      },
    },
  };
  if (includePlan) {
    summary['daily_plan'] = <String, dynamic>{
      'daily_plan_id': 'daily_plan_id_sample',
      'plan_date': '2099-06-04',
      'total_minutes': dailyMinutes,
      'status': planStatus,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'plan_item_id': 'plan_item_id_sample',
          'item_type': 'training',
          'title': 'Fluency expansion drill',
          'reason_code': 'highest_weakness_and_memory_risk',
          'duration_minutes': 12,
          'status': 'active',
          'memory_risk': 'high',
        },
      ],
      'memory_policy': <String, dynamic>{
        'policy_version': 'memory-curve-v1',
        'forgetting_risk': 'high',
        'next_review_interval_days': 1,
        'interleaving_rule': 'rotate_fluency_pronunciation_scenario_fit',
      },
    };
  }
  if (includeAction) {
    summary['next_action'] = <String, dynamic>{
      'action_id': 'action_id_sample',
      'plan_item_id': 'plan_item_id_sample',
      'action_type': 'start_training',
      'title': 'Fluency expansion drill',
      'reason_code': 'highest_weakness_and_memory_risk',
      'expected_duration_minutes': 12,
      'status': actionStatus,
    };
  }
  return summary;
}
