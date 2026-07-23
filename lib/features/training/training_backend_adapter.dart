import 'package:speakeasy/features/training/training_contract.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

enum TrainingBackendOperation {
  createAudioUpload,
  completeAudioUpload,
  startSession,
  getSession,
  submitTurn,
  plannerNext,
  hint,
  pressureCheck,
  completeSession,
}

class TrainingBackendRequest {
  const TrainingBackendRequest({
    required this.operation,
    required this.path,
    this.body = const <String, dynamic>{},
    this.headers = const <String, String>{},
  });

  final TrainingBackendOperation operation;
  final String path;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
}

typedef TrainingBackendTransport =
    Future<Map<String, dynamic>> Function(TrainingBackendRequest request);

class TrainingBackendAdapter {
  const TrainingBackendAdapter({TrainingBackendTransport? transport})
    : _transport = transport ?? _apiTransport;

  final TrainingBackendTransport _transport;

  Future<TrainingAudioUploadHandle> createAudioUpload({
    required String contentType,
    required int byteSize,
    required int durationSeconds,
    String purpose = 'asr_input',
    String? checksumSha256,
    String? clientUploadId,
    String? idempotencyKey,
  }) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.createAudioUpload,
        path: SpeakeasyApiPaths.mediaAudioUploads,
        headers: <String, String>{
          if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty)
            'Idempotency-Key': idempotencyKey.trim(),
        },
        body: <String, dynamic>{
          'schema_version': 1,
          'purpose': purpose.trim(),
          'content_type': contentType.trim(),
          'byte_size': byteSize,
          'duration_seconds': durationSeconds,
          if (checksumSha256 != null && checksumSha256.trim().isNotEmpty)
            'checksum_sha256': checksumSha256.trim(),
          if (clientUploadId != null && clientUploadId.trim().isNotEmpty)
            'client_upload_id': clientUploadId.trim(),
        },
      ),
    );
    return TrainingAudioUploadHandle.fromJson(_map(_field(response, 'media'))!);
  }

  Future<TrainingAudioUploadHandle> completeAudioUpload({
    required String mediaId,
    String? checksumSha256,
    String? objectRef,
  }) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.completeAudioUpload,
        path: SpeakeasyApiPaths.mediaAudioUploadComplete(mediaId),
        body: <String, dynamic>{
          'schema_version': 1,
          if (checksumSha256 != null && checksumSha256.trim().isNotEmpty)
            'checksum_sha256': checksumSha256.trim(),
          if (objectRef != null && objectRef.trim().isNotEmpty)
            'object_ref': objectRef.trim(),
        },
      ),
    );
    return TrainingAudioUploadHandle.fromJson(_map(_field(response, 'media'))!);
  }

  Future<TrainingSessionStartResult> startSession({
    required String userId,
    required String sceneId,
    required String levelCode,
    bool resumeExisting = true,
  }) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.startSession,
        path: SpeakeasyApiPaths.trainingSessions,
        body: <String, dynamic>{
          'schema_version': 1,
          'scenario_id': sceneId.trim(),
          'level_code': _backendLevelCode(levelCode),
          'resume_existing': resumeExisting,
        },
      ),
    );
    final TrainingSessionState session = _sessionFromResponse(
      response,
      fallbackUserId: userId,
    );
    final Map<String, dynamic> rawSession =
        _map(_field(response, 'session')) ?? response;
    return TrainingSessionStartResult(
      created: true,
      resumed:
          resumeExisting && _int(_field(rawSession, 'current_turn_index')) > 0,
      session: session,
    );
  }

  Future<TrainingSessionState> getSession({
    required String sessionId,
    required String fallbackUserId,
  }) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.getSession,
        path: SpeakeasyApiPaths.trainingSession(sessionId),
      ),
    );
    return _sessionFromResponse(response, fallbackUserId: fallbackUserId);
  }

  Future<TrainingBackendTurnResult> submitTextTurn({
    required String sessionId,
    required String text,
    required String idempotencyKey,
    int? clientStateVersion,
    String fallbackUserId = '',
  }) {
    return submitTurn(
      sessionId: sessionId,
      transcript: text,
      idempotencyKey: idempotencyKey,
      clientStateVersion: clientStateVersion,
      fallbackUserId: fallbackUserId,
    );
  }

  Future<TrainingBackendTurnResult> submitAudioTurn({
    required String sessionId,
    required String audioRef,
    required String idempotencyKey,
    String? transcript,
    int? clientStateVersion,
    String fallbackUserId = '',
  }) {
    return submitTurn(
      sessionId: sessionId,
      transcript: transcript,
      audioRef: audioRef,
      idempotencyKey: idempotencyKey,
      clientStateVersion: clientStateVersion,
      fallbackUserId: fallbackUserId,
    );
  }

  Future<TrainingBackendTurnResult> submitTurn({
    required String sessionId,
    required String idempotencyKey,
    String? transcript,
    String? audioRef,
    String? selectedOptionId,
    int? clientStateVersion,
    String fallbackUserId = '',
  }) async {
    final String? trustedAudioRef =
        audioRef == null || audioRef.trim().isEmpty
        ? null
        : _normalizeTrustedAudioRef(audioRef);
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.submitTurn,
        path: SpeakeasyApiPaths.trainingSessionTurns(sessionId),
        headers: <String, String>{'Idempotency-Key': idempotencyKey.trim()},
        body: <String, dynamic>{
          'schema_version': 1,
          if (transcript != null && transcript.trim().isNotEmpty)
            'transcript': transcript.trim(),
          'audio_ref': ?trustedAudioRef,
          if (selectedOptionId != null && selectedOptionId.trim().isNotEmpty)
            'selected_option_id': selectedOptionId.trim(),
          'client_state_version': ?clientStateVersion,
        },
      ),
    );
    final TrainingSessionState session = _sessionFromResponse(
      response,
      fallbackUserId: fallbackUserId,
    );
    final List<TrainingLearningEvidenceCandidate> evidence =
        _evidenceCandidatesFromJson(
          _list(_field(response, 'learning_evidence_candidates')),
        );
    final TrainingPlannerDecision? decision = _decisionFromJson(
      _map(_field(response, 'planner_decision')),
      session,
    );
    final TrainingFeedbackCandidate? feedback = _feedbackFromJson(
      _map(_field(response, 'feedback')),
      session,
      decision,
      evidence,
    );
    return TrainingBackendTurnResult(
      session: session.copyWith(lastFeedback: feedback),
      plannerDecision: decision,
      feedback: feedback,
      learningEvidenceCandidates: evidence,
      recoverableErrorCode: _string(
        _field(_map(_field(response, 'recoverable_error')), 'code'),
      ),
    );
  }

  Future<TrainingPlannerDecision> plannerNext({
    required String sessionId,
    required TrainingSessionState currentSession,
  }) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.plannerNext,
        path: SpeakeasyApiPaths.trainingSessionPlannerNext(sessionId),
        body: const <String, dynamic>{'schema_version': 1},
      ),
    );
    return _decisionFromJson(
      _map(_field(response, 'planner_decision')),
      currentSession,
    )!;
  }

  Future<TrainingSessionState> requestHint({
    required String sessionId,
    required String fallbackUserId,
  }) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.hint,
        path: SpeakeasyApiPaths.trainingSessionHints(sessionId),
        body: const <String, dynamic>{'schema_version': 1},
      ),
    );
    return _sessionFromResponse(response, fallbackUserId: fallbackUserId);
  }

  Future<TrainingPlannerDecision> startPressureCheck({
    required String sessionId,
    required TrainingSessionState currentSession,
  }) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.pressureCheck,
        path: SpeakeasyApiPaths.trainingSessionPressureCheck(sessionId),
        body: const <String, dynamic>{'schema_version': 1},
      ),
    );
    return _decisionFromJson(
      _map(_field(response, 'planner_decision')),
      currentSession,
    )!;
  }

  Future<TrainingRecap> completeSession({required String sessionId}) async {
    final Map<String, dynamic> response = await _transport(
      TrainingBackendRequest(
        operation: TrainingBackendOperation.completeSession,
        path: SpeakeasyApiPaths.trainingSessionComplete(sessionId),
        body: const <String, dynamic>{'schema_version': 1},
      ),
    );
    return _recapFromJson(_map(_field(response, 'recap')));
  }
}

class TrainingBackendTurnResult {
  const TrainingBackendTurnResult({
    required this.session,
    this.plannerDecision,
    this.feedback,
    this.learningEvidenceCandidates =
        const <TrainingLearningEvidenceCandidate>[],
    this.recoverableErrorCode = '',
  });

  final TrainingSessionState session;
  final TrainingPlannerDecision? plannerDecision;
  final TrainingFeedbackCandidate? feedback;
  final List<TrainingLearningEvidenceCandidate> learningEvidenceCandidates;
  final String recoverableErrorCode;
}

class TrainingAudioUploadHandle {
  const TrainingAudioUploadHandle({
    required this.mediaId,
    required this.audioRef,
    required this.status,
    required this.uploadUrl,
    required this.uploadHeaders,
  });

  factory TrainingAudioUploadHandle.fromJson(Map<String, dynamic> json) {
    return TrainingAudioUploadHandle(
      mediaId: _string(_field(json, 'media_id')),
      audioRef: _string(_field(json, 'audio_ref')),
      status: _string(_field(json, 'status')),
      uploadUrl: _string(_field(json, 'upload_url')),
      uploadHeaders: _stringMap(_field(json, 'upload_headers')),
    );
  }

  final String mediaId;
  final String audioRef;
  final String status;
  final String uploadUrl;
  final Map<String, String> uploadHeaders;
}

String _normalizeTrustedAudioRef(String audioRef) {
  final String value = audioRef.trim();
  if (!value.startsWith('media://audio/')) {
    throw Exception('trusted audio_ref required');
  }
  return value;
}

Future<Map<String, dynamic>> _apiTransport(TrainingBackendRequest request) {
  return switch (request.operation) {
    TrainingBackendOperation.createAudioUpload => ApiClient.createAudioUpload(
      purpose: _string(request.body['purpose'], fallback: 'asr_input'),
      contentType: _string(request.body['content_type']),
      byteSize: _int(request.body['byte_size']),
      durationSeconds: _int(request.body['duration_seconds']),
      checksumSha256: _string(request.body['checksum_sha256']),
      clientUploadId: _string(request.body['client_upload_id']),
      idempotencyKey: request.headers['Idempotency-Key'],
    ),
    TrainingBackendOperation.completeAudioUpload =>
      ApiClient.completeAudioUpload(
        mediaId: request.path.split('/').reversed.skip(1).first,
        checksumSha256: _string(request.body['checksum_sha256']),
        objectRef: _string(request.body['object_ref']),
      ),
    TrainingBackendOperation.startSession => ApiClient.startTrainingSession(
      scenarioId: _string(request.body['scenario_id']),
      levelCode: _string(request.body['level_code']),
      resumeExisting: request.body['resume_existing'] != false,
    ),
    TrainingBackendOperation.getSession => ApiClient.getTrainingSession(
      request.path.split('/').last,
    ),
    TrainingBackendOperation.submitTurn => ApiClient.submitTrainingTurn(
      sessionId: request.path.split('/').reversed.skip(1).first,
      idempotencyKey: request.headers['Idempotency-Key'] ?? '',
      transcript: _string(request.body['transcript']),
      audioRef: _string(request.body['audio_ref']),
      selectedOptionId: _string(request.body['selected_option_id']),
      clientStateVersion: request.body['client_state_version'] as int?,
    ),
    TrainingBackendOperation.plannerNext =>
      ApiClient.requestTrainingPlannerNext(
        request.path.split('/').reversed.skip(2).first,
      ),
    TrainingBackendOperation.hint => ApiClient.requestTrainingHint(
      request.path.split('/').reversed.skip(1).first,
    ),
    TrainingBackendOperation.pressureCheck =>
      ApiClient.startTrainingPressureCheck(
        request.path.split('/').reversed.skip(1).first,
      ),
    TrainingBackendOperation.completeSession =>
      ApiClient.completeTrainingSession(
        request.path.split('/').reversed.skip(1).first,
      ),
  };
}

TrainingSessionState _sessionFromResponse(
  Map<String, dynamic> response, {
  required String fallbackUserId,
}) {
  final Map<String, dynamic> json =
      _map(_field(response, 'session')) ?? response;
  final TrainingSessionStatus status = _sessionStatus(
    _string(_field(json, 'status'), fallback: 'ready'),
  );
  final TrainingActionStep step = _step(
    _string(_field(json, 'current_step_key'), fallback: 'opening'),
  );
  final TrainingMicroAction microAction = _microAction(
    _string(
      _field(json, 'current_micro_action'),
      fallback: step.defaultMicroAction.wireName,
    ),
  );
  final TrainingRecap? recap = _map(_field(json, 'recap')) == null
      ? null
      : _recapFromJson(_map(_field(json, 'recap')));
  return TrainingSessionState(
    sessionId: _string(_field(json, 'session_id')),
    userId: _string(_field(json, 'user_id'), fallback: fallbackUserId),
    sceneId: _string(_field(json, 'scenario_id')),
    levelCode: _string(_field(json, 'level_code')),
    scenarioVersionId: _string(_field(json, 'scenario_version_id')),
    status: status,
    currentStep: step,
    currentMicroAction: microAction,
    hintLevel: _hintLevel(
      _string(_field(json, 'hint_level'), fallback: 'none'),
    ),
    failureCount: _int(_field(json, 'failure_count')),
    successCount: _int(_field(json, 'success_count')),
    textFallbackAvailable:
        status == TrainingSessionStatus.retry ||
        status == TrainingSessionStatus.recoverableError,
    lastReasonCode: _string(_field(json, 'last_reason_code')),
    recap: recap,
  );
}

TrainingPlannerDecision? _decisionFromJson(
  Map<String, dynamic>? json,
  TrainingSessionState session,
) {
  if (json == null || json.isEmpty) {
    return null;
  }
  final String type = _string(_field(json, 'type'), fallback: 'continue');
  final TrainingActionStep nextStep = _step(
    _string(_field(json, 'next_step_key'), fallback: session.currentStep.key),
  );
  return TrainingPlannerDecision(
    type: _decisionType(type),
    nextStatus: _sessionStatus(
      _string(_field(json, 'next_status'), fallback: session.status.key),
    ),
    nextStep: nextStep,
    nextMicroAction: _microAction(
      _string(
        _field(json, 'next_micro_action'),
        fallback: nextStep.defaultMicroAction.wireName,
      ),
    ),
    nextHintLevel: _hintLevel(
      _string(_field(json, 'next_hint_level'), fallback: session.hintLevel.key),
    ),
    reasonCode: _string(_field(json, 'reason_code')),
  );
}

TrainingFeedbackCandidate? _feedbackFromJson(
  Map<String, dynamic>? json,
  TrainingSessionState session,
  TrainingPlannerDecision? decision,
  List<TrainingLearningEvidenceCandidate> evidence,
) {
  if (json == null || json.isEmpty) {
    return null;
  }
  final String completion = _string(
    _field(json, 'completion_status'),
    fallback: decision?.type == TrainingDecisionType.recoverableError
        ? 'unknown'
        : 'met',
  );
  final String task = _string(
    _field(json, 'task_status'),
    fallback: completion,
  );
  return TrainingFeedbackCandidate(
    sceneId: session.sceneId,
    actionStep: session.currentStep,
    microAction: session.currentMicroAction,
    hintLevel: session.hintLevel,
    completionStatus: _signalStatus(completion),
    taskStatus: _signalStatus(task),
    feedbackCard: TrainingFeedbackCard(
      summary: _string(_field(json, 'summary')),
      mainIssueType: _string(_field(json, 'main_issue_type'), fallback: 'none'),
      betterExpression: _string(_field(json, 'better_expression')),
      explanationCn: '',
    ),
    recommendedNextAction: _nextAction(decision?.type),
    pronunciationAvailable: _bool(_field(json, 'pronunciation_available')),
    learningEvidenceCandidates: evidence,
    recoverableErrorCode:
        decision?.type == TrainingDecisionType.recoverableError
        ? decision!.reasonCode
        : '',
  );
}

List<TrainingLearningEvidenceCandidate> _evidenceCandidatesFromJson(
  List<Map<String, dynamic>> values,
) {
  return values
      .map(
        (Map<String, dynamic> json) => TrainingLearningEvidenceCandidate(
          status: _string(_field(json, 'status'), fallback: 'candidate'),
          evidenceType: _string(_field(json, 'evidence_type')),
          targetExpressionId: _string(_field(json, 'target_expression_id')),
          confidence: _double(_field(json, 'confidence')),
          ruleInput: _string(_field(json, 'rule_name')),
        ),
      )
      .toList(growable: false);
}

TrainingRecap _recapFromJson(Map<String, dynamic>? json) {
  final Map<String, dynamic> safe = json ?? const <String, dynamic>{};
  return TrainingRecap(
    summary: _string(_field(safe, 'summary'), fallback: 'Training recap'),
    nextFocus: _string(
      _field(safe, 'next_focus'),
      fallback: 'Review one useful expression.',
    ),
    evidenceCandidates: const <TrainingLearningEvidenceCandidate>[],
    evidenceWriteStatus:
        _stringList(_field(safe, 'accepted_evidence_ids')).isEmpty
        ? 'server_no_evidence_written'
        : 'server_evidence_written',
  );
}

String _backendLevelCode(String levelCode) {
  return switch (levelCode.trim()) {
    'beginner' => 'L1',
    'intermediate' => 'L2',
    'advanced' => 'L3',
    String value => value,
  };
}

TrainingSessionStatus _sessionStatus(String key) {
  for (final TrainingSessionStatus status in TrainingSessionStatus.values) {
    if (status.key == key) {
      return status;
    }
  }
  return TrainingSessionStatus.ready;
}

TrainingActionStep _step(String key) {
  return TrainingActionStep.fromKey(key) ?? TrainingActionStep.opening;
}

TrainingMicroAction _microAction(String key) {
  return TrainingMicroAction.fromWireName(key) ?? TrainingMicroAction.sayOne;
}

TrainingHintLevel _hintLevel(String key) {
  return TrainingHintLevel.fromKey(key) ?? TrainingHintLevel.none;
}

TrainingSignalStatus _signalStatus(String key) {
  return TrainingSignalStatus.fromKey(key) ?? TrainingSignalStatus.unknown;
}

TrainingDecisionType _decisionType(String key) {
  for (final TrainingDecisionType type in TrainingDecisionType.values) {
    if (type.key == key) {
      return type;
    }
  }
  return TrainingDecisionType.continueAction;
}

TrainingNextActionType _nextAction(TrainingDecisionType? decisionType) {
  return switch (decisionType) {
    TrainingDecisionType.raiseHint => TrainingNextActionType.raiseHint,
    TrainingDecisionType.modelThenRetry =>
      TrainingNextActionType.modelThenRetry,
    TrainingDecisionType.retry ||
    TrainingDecisionType.retryWithHigherHint => TrainingNextActionType.retry,
    TrainingDecisionType.pressureCheck => TrainingNextActionType.pressureCheck,
    TrainingDecisionType.recap => TrainingNextActionType.recap,
    TrainingDecisionType.textFallback => TrainingNextActionType.textFallback,
    TrainingDecisionType.recoverableError => TrainingNextActionType.fallback,
    _ => TrainingNextActionType.continueAction,
  };
}

dynamic _field(Map<String, dynamic>? map, String snakeName) {
  if (map == null) {
    return null;
  }
  if (map.containsKey(snakeName)) {
    return map[snakeName];
  }
  final List<String> parts = snakeName.split('_');
  final String camelName =
      parts.first +
      parts.skip(1).map((String part) {
        if (part.isEmpty) {
          return part;
        }
        return part[0].toUpperCase() + part.substring(1);
      }).join();
  return map[camelName];
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic mapValue) =>
          MapEntry<String, dynamic>(key.toString(), mapValue),
    );
  }
  return null;
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .map(_map)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

List<String> _stringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((dynamic item) => item?.toString().trim() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _stringMap(dynamic value) {
  final Map<String, dynamic>? map = _map(value);
  if (map == null) {
    return const <String, String>{};
  }
  return map.map(
    (String key, dynamic mapValue) =>
        MapEntry<String, String>(key, mapValue?.toString() ?? ''),
  );
}

String _string(dynamic value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

int _int(dynamic value) {
  if (value is num) {
    return value.round();
  }
  return 0;
}

double _double(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return 0;
}

bool _bool(dynamic value) {
  return value == true;
}
