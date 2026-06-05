import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

enum GoalAutopilotOperation {
  createGoal,
  summary,
  control,
  updateControl,
  pauseControl,
  resumeControl,
  generatePlan,
  dailyPlan,
  nextAction,
  completeAction,
  forecast,
  checkpoint,
}

class GoalAutopilotRequest {
  const GoalAutopilotRequest({
    required this.operation,
    required this.path,
    this.body = const <String, dynamic>{},
    this.headers = const <String, String>{},
  });

  final GoalAutopilotOperation operation;
  final String path;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
}

typedef GoalAutopilotTransport =
    Future<Map<String, dynamic>> Function(GoalAutopilotRequest request);

class GoalDiagnosticSampleInput {
  const GoalDiagnosticSampleInput({
    required this.sampleRef,
    required this.transcript,
    this.audioRef,
    this.durationSeconds,
  });

  final String sampleRef;
  final String transcript;
  final String? audioRef;
  final int? durationSeconds;

  bool get hasEvidence =>
      transcript.trim().isNotEmpty || (audioRef?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson({String? fallbackSampleRef}) {
    final String ref = sampleRef.trim().isEmpty
        ? fallbackSampleRef ?? ''
        : sampleRef.trim();
    return <String, dynamic>{
      if (ref.isNotEmpty) 'sample_ref': ref,
      if (transcript.trim().isNotEmpty) 'transcript': transcript.trim(),
      if (audioRef != null && audioRef!.trim().isNotEmpty)
        'audio_ref': audioRef!.trim(),
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    };
  }
}

class GoalAutopilotAdapter {
  const GoalAutopilotAdapter({GoalAutopilotTransport? transport})
    : _transport = transport ?? _apiTransport;

  final GoalAutopilotTransport _transport;

  Future<GoalAutopilotSummary> loadSummary() async {
    final Map<String, dynamic> response = await _transport(
      const GoalAutopilotRequest(
        operation: GoalAutopilotOperation.summary,
        path: SpeakeasyApiPaths.goalAutopilotSummary,
      ),
    );
    return GoalAutopilotSummary.fromJson(response);
  }

  Future<GoalAutopilotView> loadView() async {
    final GoalAutopilotSummary summary = await loadSummary();
    final GoalAutopilotControlResult controlResult = await loadControl();
    return GoalAutopilotView(summary: summary, controlResult: controlResult);
  }

  Future<GoalAutopilotControlResult> loadControl() async {
    final Map<String, dynamic> response = await _transport(
      const GoalAutopilotRequest(
        operation: GoalAutopilotOperation.control,
        path: SpeakeasyApiPaths.goalAutopilotControl,
      ),
    );
    return GoalAutopilotControlResult.fromJson(response);
  }

  Future<GoalAutopilotSummary> createGoal({
    required String goalType,
    required double? targetScore,
    required String targetAbility,
    required DateTime deadline,
    required int dailyMinutes,
    required String intensityPreference,
    List<GoalDiagnosticSampleInput> diagnosticSamples =
        const <GoalDiagnosticSampleInput>[],
  }) async {
    final List<Map<String, dynamic>> samplePayload = diagnosticSamples
        .asMap()
        .entries
        .where((MapEntry<int, GoalDiagnosticSampleInput> entry) {
          return entry.value.hasEvidence;
        })
        .map((MapEntry<int, GoalDiagnosticSampleInput> entry) {
          return entry.value.toJson(
            fallbackSampleRef: 'flutter_goal_sample_${entry.key + 1}',
          );
        })
        .toList(growable: false);
    final Map<String, dynamic> response = await _transport(
      GoalAutopilotRequest(
        operation: GoalAutopilotOperation.createGoal,
        path: SpeakeasyApiPaths.goalAutopilotGoals,
        body: <String, dynamic>{
          'schema_version': 1,
          'goal_type': goalType.trim(),
          'target_score': ?targetScore,
          if (targetAbility.trim().isNotEmpty)
            'target_ability': targetAbility.trim(),
          'deadline': _date(deadline),
          'daily_minutes': dailyMinutes,
          'intensity_preference': intensityPreference.trim(),
          'diagnostic_samples': samplePayload,
          'autopilot_control': <String, dynamic>{
            'paused': false,
            'quiet_hours_start': '22:00',
            'quiet_hours_end': '08:00',
            'notification_consent': true,
            'intensity_override': intensityPreference.trim(),
          },
        },
      ),
    );
    return GoalAutopilotSummary.fromJson(response);
  }

  Future<GoalAutopilotSummary> createDefaultGoal() {
    return createGoal(
      goalType: 'ielts_speaking',
      targetScore: 8,
      targetAbility: 'confident IELTS-style speaking with follow-up pressure',
      deadline: DateTime.now().add(const Duration(days: 75)),
      dailyMinutes: 30,
      intensityPreference: 'standard',
      diagnosticSamples: const <GoalDiagnosticSampleInput>[
        GoalDiagnosticSampleInput(
          sampleRef: 'flutter_goal_sample_1',
          transcript:
              'I can answer familiar questions, but I need more structure, examples, and smoother follow-up responses.',
          durationSeconds: 45,
        ),
        GoalDiagnosticSampleInput(
          sampleRef: 'flutter_goal_sample_2',
          transcript:
              'My target is to speak with clearer transitions, less hesitation, and better topic expansion.',
          durationSeconds: 40,
        ),
        GoalDiagnosticSampleInput(
          sampleRef: 'flutter_goal_sample_3',
          transcript:
              'I want daily practice that automatically tells me what to train, review, and retest.',
          durationSeconds: 35,
        ),
      ],
    );
  }

  Future<GoalAutopilotControlResult> updateControl({
    bool? notificationConsent,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
    String? intensityOverride,
    String? missedDayPolicy,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'schema_version': 1,
      'quiet_hours_start': ?quietHoursStart,
      'quiet_hours_end': ?quietHoursEnd,
      'timezone': ?timezone,
      'notification_consent': ?notificationConsent,
      'intensity_override': ?intensityOverride,
      'missed_day_policy': ?missedDayPolicy,
    };
    final Map<String, dynamic> response = await _transport(
      GoalAutopilotRequest(
        operation: GoalAutopilotOperation.updateControl,
        path: SpeakeasyApiPaths.goalAutopilotControl,
        body: body,
        headers: <String, String>{
          'Idempotency-Key': _idempotencyKey('control-update'),
        },
      ),
    );
    return GoalAutopilotControlResult.fromJson(response);
  }

  Future<GoalAutopilotControlResult> pauseControl({
    String pauseReason = 'user_requested_break',
  }) async {
    final Map<String, dynamic> response = await _transport(
      GoalAutopilotRequest(
        operation: GoalAutopilotOperation.pauseControl,
        path: SpeakeasyApiPaths.goalAutopilotControlPause,
        body: <String, dynamic>{
          'schema_version': 1,
          'pause_reason': pauseReason,
        },
        headers: <String, String>{
          'Idempotency-Key': _idempotencyKey('control-pause'),
        },
      ),
    );
    return GoalAutopilotControlResult.fromJson(response);
  }

  Future<GoalAutopilotControlResult> resumeControl({
    String sourceEvent = 'manual_resume',
  }) async {
    final Map<String, dynamic> response = await _transport(
      GoalAutopilotRequest(
        operation: GoalAutopilotOperation.resumeControl,
        path: SpeakeasyApiPaths.goalAutopilotControlResume,
        body: <String, dynamic>{
          'schema_version': 1,
          'source_event': sourceEvent,
        },
        headers: <String, String>{
          'Idempotency-Key': _idempotencyKey('control-resume'),
        },
      ),
    );
    return GoalAutopilotControlResult.fromJson(response);
  }

  Future<GoalDailyPlan> generatePlan({bool forceReplan = false}) async {
    final Map<String, dynamic> response = await _transport(
      GoalAutopilotRequest(
        operation: GoalAutopilotOperation.generatePlan,
        path: SpeakeasyApiPaths.goalAutopilotPlansGenerate,
        body: <String, dynamic>{
          'schema_version': 1,
          'force_replan': forceReplan,
          'reason_code': forceReplan ? 'flutter_force_replan' : 'flutter_plan',
        },
      ),
    );
    return GoalDailyPlan.fromJson(_map(response['daily_plan']));
  }

  Future<GoalAutopilotAction> loadNextAction() async {
    final Map<String, dynamic> response = await _transport(
      const GoalAutopilotRequest(
        operation: GoalAutopilotOperation.nextAction,
        path: SpeakeasyApiPaths.goalAutopilotActionsNext,
      ),
    );
    return GoalAutopilotAction.fromJson(_map(response['action']));
  }

  Future<GoalAutopilotAction> completeAction({
    required String planItemId,
    String outcome = 'completed',
  }) async {
    final Map<String, dynamic> response = await _transport(
      GoalAutopilotRequest(
        operation: GoalAutopilotOperation.completeAction,
        path: SpeakeasyApiPaths.goalAutopilotActionComplete(planItemId),
        body: <String, dynamic>{'schema_version': 1, 'outcome': outcome},
      ),
    );
    return GoalAutopilotAction.fromJson(_map(response['action']));
  }

  Future<void> submitCheckpoint() async {
    await _transport(
      const GoalAutopilotRequest(
        operation: GoalAutopilotOperation.checkpoint,
        path: SpeakeasyApiPaths.goalAutopilotCheckpoints,
        body: <String, dynamic>{
          'schema_version': 1,
          'checkpoint_type': 'weekly_mock',
          'transcript':
              'I completed the checkpoint with one example, one follow-up answer, and a short recap of the main risk.',
        },
      ),
    );
  }
}

Future<Map<String, dynamic>> _apiTransport(GoalAutopilotRequest request) {
  return switch (request.operation) {
    GoalAutopilotOperation.createGoal => ApiClient.createGoalAutopilotGoal(
      request.body,
    ),
    GoalAutopilotOperation.summary => ApiClient.getGoalAutopilotSummary(),
    GoalAutopilotOperation.control => ApiClient.getGoalAutopilotControl(),
    GoalAutopilotOperation.updateControl =>
      ApiClient.updateGoalAutopilotControl(
        request.body,
        idempotencyKey: request.headers['Idempotency-Key'] ?? '',
      ),
    GoalAutopilotOperation.pauseControl => ApiClient.pauseGoalAutopilotControl(
      pauseReason: request.body['pause_reason']?.toString(),
      idempotencyKey: request.headers['Idempotency-Key'] ?? '',
    ),
    GoalAutopilotOperation.resumeControl =>
      ApiClient.resumeGoalAutopilotControl(
        sourceEvent:
            request.body['source_event']?.toString() ?? 'manual_resume',
        idempotencyKey: request.headers['Idempotency-Key'] ?? '',
      ),
    GoalAutopilotOperation.generatePlan => ApiClient.generateGoalAutopilotPlan(
      forceReplan: request.body['force_replan'] == true,
      reasonCode: request.body['reason_code']?.toString() ?? 'flutter_plan',
    ),
    GoalAutopilotOperation.dailyPlan => ApiClient.getGoalAutopilotDailyPlan(),
    GoalAutopilotOperation.nextAction => ApiClient.getGoalAutopilotNextAction(),
    GoalAutopilotOperation.completeAction =>
      ApiClient.completeGoalAutopilotAction(
        planItemId: _planItemIdFromPath(request.path),
        outcome: request.body['outcome']?.toString() ?? 'completed',
      ),
    GoalAutopilotOperation.forecast => ApiClient.getGoalAutopilotForecast(),
    GoalAutopilotOperation.checkpoint =>
      ApiClient.submitGoalAutopilotCheckpoint(
        checkpointType:
            request.body['checkpoint_type']?.toString() ?? 'weekly_mock',
        transcript: request.body['transcript']?.toString(),
      ),
  };
}

String _idempotencyKey(String prefix) {
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

String _date(DateTime value) {
  final DateTime local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _planItemIdFromPath(String path) {
  final List<String> parts = path.split('/');
  final int actionIndex = parts.indexOf('actions');
  if (actionIndex >= 0 && actionIndex + 1 < parts.length) {
    return Uri.decodeComponent(parts[actionIndex + 1]);
  }
  return '';
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}
