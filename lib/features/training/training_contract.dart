enum TrainingMicroAction {
  listenOne('ListenOne'),
  chooseOne('ChooseOne'),
  sayOne('SayOne'),
  shadowOne('ShadowOne'),
  fillOne('FillOne'),
  continueUnderPrompt('ContinueUnderPrompt');

  const TrainingMicroAction(this.wireName);

  final String wireName;

  bool get requiresSpokenInput {
    return this == sayOne || this == shadowOne || this == continueUnderPrompt;
  }

  static TrainingMicroAction? fromWireName(String value) {
    final String normalized = value.trim();
    for (final TrainingMicroAction action in values) {
      if (action.wireName == normalized) {
        return action;
      }
    }
    return null;
  }
}

enum TrainingHintLevel {
  none('none', 0),
  sentenceFrame('sentence_frame', 1),
  options('options', 2),
  chunkShadowing('chunk_shadowing', 3),
  modelThenRetry('model_then_retry', 4);

  const TrainingHintLevel(this.key, this.weight);

  final String key;
  final int weight;

  static TrainingHintLevel? fromKey(String value) {
    final String normalized = value.trim();
    for (final TrainingHintLevel level in values) {
      if (level.key == normalized) {
        return level;
      }
    }
    return null;
  }
}

enum TrainingActionStep {
  opening('opening', 'Opening', TrainingMicroAction.sayOne),
  explainPurpose(
    'explain_purpose',
    'Explain purpose',
    TrainingMicroAction.fillOne,
  ),
  expressView('express_view', 'Express view', TrainingMicroAction.sayOne),
  respondFollowUp(
    'respond_follow_up',
    'Respond to follow-up',
    TrainingMicroAction.continueUnderPrompt,
  ),
  confirmNextStep(
    'confirm_next_step',
    'Confirm next step',
    TrainingMicroAction.chooseOne,
  ),
  closing('closing', 'Closing', TrainingMicroAction.sayOne);

  const TrainingActionStep(this.key, this.label, this.defaultMicroAction);

  final String key;
  final String label;
  final TrainingMicroAction defaultMicroAction;

  static TrainingActionStep? fromKey(String value) {
    final String normalized = value.trim();
    for (final TrainingActionStep step in values) {
      if (step.key == normalized) {
        return step;
      }
    }
    return null;
  }
}

enum TrainingSessionStatus {
  loading('loading'),
  ready('ready'),
  listening('listening'),
  recording('recording'),
  transcribing('transcribing'),
  evaluating('evaluating'),
  feedback('feedback'),
  retry('retry'),
  pressureCheck('pressure_check'),
  recap('recap'),
  completed('completed'),
  recoverableError('recoverable_error'),
  unsupportedScene('unsupported_scene'),
  abandoned('abandoned');

  const TrainingSessionStatus(this.key);

  final String key;
}

enum TrainingSignalStatus {
  met('met'),
  partial('partial'),
  notMet('not_met'),
  unknown('unknown');

  const TrainingSignalStatus(this.key);

  final String key;

  static TrainingSignalStatus? fromKey(String value) {
    final String normalized = value.trim();
    for (final TrainingSignalStatus status in values) {
      if (status.key == normalized) {
        return status;
      }
    }
    return null;
  }
}

enum TrainingNextActionType {
  continueAction('continue'),
  retry('retry'),
  raiseHint('raise_hint'),
  lowerHint('lower_hint'),
  modelThenRetry('model_then_retry'),
  pressureCheck('pressure_check'),
  recap('recap'),
  textFallback('text_fallback'),
  fallback('fallback');

  const TrainingNextActionType(this.key);

  final String key;

  static TrainingNextActionType? fromKey(String value) {
    final String normalized = value.trim();
    for (final TrainingNextActionType type in values) {
      if (type.key == normalized) {
        return type;
      }
    }
    return null;
  }
}

enum TrainingDecisionType {
  continueAction('continue'),
  advanceStep('advance_step'),
  retry('retry'),
  raiseHint('raise_hint'),
  lowerHint('lower_hint'),
  modelThenRetry('model_then_retry'),
  pressureCheck('pressure_check'),
  retryWithHigherHint('retry_with_higher_hint'),
  textFallback('text_fallback'),
  fallback('fallback'),
  recap('recap'),
  unsupportedScene('unsupported_scene'),
  recoverableError('recoverable_error');

  const TrainingDecisionType(this.key);

  final String key;
}

class TrainingSessionStartResult {
  const TrainingSessionStartResult({
    required this.created,
    required this.resumed,
    this.session,
    this.rejection,
  });

  final bool created;
  final bool resumed;
  final TrainingSessionState? session;
  final TrainingPlannerDecision? rejection;
}

class TrainingSessionState {
  const TrainingSessionState({
    required this.sessionId,
    required this.userId,
    required this.sceneId,
    required this.levelCode,
    required this.scenarioVersionId,
    required this.status,
    required this.currentStep,
    required this.currentMicroAction,
    this.hintLevel = TrainingHintLevel.none,
    this.failureCount = 0,
    this.successCount = 0,
    this.completedStepKeys = const <String>[],
    this.textFallbackAvailable = false,
    this.lastReasonCode = '',
    this.lastFeedback,
    this.recap,
  });

  final String sessionId;
  final String userId;
  final String sceneId;
  final String levelCode;
  final String scenarioVersionId;
  final TrainingSessionStatus status;
  final TrainingActionStep currentStep;
  final TrainingMicroAction currentMicroAction;
  final TrainingHintLevel hintLevel;
  final int failureCount;
  final int successCount;
  final List<String> completedStepKeys;
  final bool textFallbackAvailable;
  final String lastReasonCode;
  final TrainingFeedbackCandidate? lastFeedback;
  final TrainingRecap? recap;

  bool get isTerminal {
    return status == TrainingSessionStatus.completed ||
        status == TrainingSessionStatus.unsupportedScene ||
        status == TrainingSessionStatus.abandoned;
  }

  bool get hasSingleActiveMicroAction {
    return status != TrainingSessionStatus.recap &&
        status != TrainingSessionStatus.completed &&
        status != TrainingSessionStatus.unsupportedScene;
  }

  TrainingSessionState copyWith({
    TrainingSessionStatus? status,
    TrainingActionStep? currentStep,
    TrainingMicroAction? currentMicroAction,
    TrainingHintLevel? hintLevel,
    int? failureCount,
    int? successCount,
    List<String>? completedStepKeys,
    bool? textFallbackAvailable,
    String? lastReasonCode,
    TrainingFeedbackCandidate? lastFeedback,
    TrainingRecap? recap,
  }) {
    return TrainingSessionState(
      sessionId: sessionId,
      userId: userId,
      sceneId: sceneId,
      levelCode: levelCode,
      scenarioVersionId: scenarioVersionId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      currentMicroAction: currentMicroAction ?? this.currentMicroAction,
      hintLevel: hintLevel ?? this.hintLevel,
      failureCount: failureCount ?? this.failureCount,
      successCount: successCount ?? this.successCount,
      completedStepKeys: completedStepKeys ?? this.completedStepKeys,
      textFallbackAvailable:
          textFallbackAvailable ?? this.textFallbackAvailable,
      lastReasonCode: lastReasonCode ?? this.lastReasonCode,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      recap: recap ?? this.recap,
    );
  }
}

class TrainingPlannerDecision {
  const TrainingPlannerDecision({
    required this.type,
    required this.nextStatus,
    required this.nextStep,
    required this.nextMicroAction,
    required this.nextHintLevel,
    required this.reasonCode,
    this.feedbackCandidate,
  });

  final TrainingDecisionType type;
  final TrainingSessionStatus nextStatus;
  final TrainingActionStep nextStep;
  final TrainingMicroAction nextMicroAction;
  final TrainingHintLevel nextHintLevel;
  final String reasonCode;
  final TrainingFeedbackCandidate? feedbackCandidate;
}

class TrainingRecap {
  const TrainingRecap({
    required this.summary,
    required this.nextFocus,
    required this.evidenceCandidates,
    this.evidenceWriteStatus = 'server_no_evidence_written',
  });

  final String summary;
  final String nextFocus;
  final List<TrainingLearningEvidenceCandidate> evidenceCandidates;
  final String evidenceWriteStatus;
}

class TrainingFeedbackCandidate {
  const TrainingFeedbackCandidate({
    required this.sceneId,
    required this.actionStep,
    required this.microAction,
    required this.completionStatus,
    required this.taskStatus,
    required this.feedbackCard,
    required this.recommendedNextAction,
    this.hintLevel = TrainingHintLevel.none,
    this.pronunciationAvailable = false,
    this.pressurePromptEnabled = false,
    this.learningEvidenceCandidates =
        const <TrainingLearningEvidenceCandidate>[],
    this.recoverableErrorCode = '',
  });

  factory TrainingFeedbackCandidate.fromJson(
    Map<String, dynamic> json, {
    TrainingNextActionType? plannerNextAction,
  }) {
    final TrainingFeedbackValidationResult validation =
        TrainingFeedbackCandidate.validateJson(
          json,
          plannerNextAction: plannerNextAction,
        );
    if (!validation.isValid) {
      throw FormatException(validation.errors.join('; '));
    }
    final Map<String, dynamic> completion =
        _map(json['completion_signal']) ?? const <String, dynamic>{};
    final Map<String, dynamic> task =
        _map(json['task_signal']) ?? const <String, dynamic>{};
    final Map<String, dynamic> recommended =
        _map(json['recommended_next_action']) ?? const <String, dynamic>{};
    final Map<String, dynamic> feedback =
        _map(json['feedback_card']) ?? const <String, dynamic>{};
    final Map<String, dynamic> pronunciation =
        _map(json['pronunciation_signal']) ?? const <String, dynamic>{};
    final Map<String, dynamic> pressure =
        _map(json['pressure_prompt_candidate']) ?? const <String, dynamic>{};
    final Map<String, dynamic>? recoverable = _map(json['recoverable_error']);

    return TrainingFeedbackCandidate(
      sceneId: _stringValue(json['scene_id']),
      actionStep: TrainingActionStep.fromKey(
        _stringValue(json['action_chain_step']),
      )!,
      microAction: TrainingMicroAction.fromWireName(
        _stringValue(json['micro_action']),
      )!,
      hintLevel:
          TrainingHintLevel.fromKey(_stringValue(json['hint_level'])) ??
          TrainingHintLevel.none,
      completionStatus: TrainingSignalStatus.fromKey(
        _stringValue(completion['status']),
      )!,
      taskStatus: TrainingSignalStatus.fromKey(_stringValue(task['status']))!,
      pronunciationAvailable:
          _stringValue(pronunciation['status']) == 'available',
      feedbackCard: TrainingFeedbackCard(
        summary: _stringValue(feedback['summary']),
        mainIssueType: _stringValue(
          feedback['main_issue_type'],
          fallback: 'none',
        ),
        betterExpression: _stringValue(feedback['better_expression']),
        explanationCn: _stringValue(feedback['explanation_cn']),
      ),
      recommendedNextAction: TrainingNextActionType.fromKey(
        _stringValue(recommended['type']),
      )!,
      pressurePromptEnabled: pressure['enabled'] == true,
      learningEvidenceCandidates: _mapList(
        json['learning_evidence_candidates'],
      ).map(TrainingLearningEvidenceCandidate.fromJson).toList(),
      recoverableErrorCode: _stringValue(recoverable?['code']),
    );
  }

  final String sceneId;
  final TrainingActionStep actionStep;
  final TrainingMicroAction microAction;
  final TrainingHintLevel hintLevel;
  final TrainingSignalStatus completionStatus;
  final TrainingSignalStatus taskStatus;
  final bool pronunciationAvailable;
  final TrainingFeedbackCard feedbackCard;
  final TrainingNextActionType recommendedNextAction;
  final bool pressurePromptEnabled;
  final List<TrainingLearningEvidenceCandidate> learningEvidenceCandidates;
  final String recoverableErrorCode;

  static TrainingFeedbackValidationResult validateJson(
    Map<String, dynamic> json, {
    TrainingNextActionType? plannerNextAction,
  }) {
    final List<String> errors = <String>[];
    final int? schemaVersion = _intValue(json['schema_version']);
    if (schemaVersion != 1) {
      errors.add('schema_version must be 1');
    }
    if (_stringValue(json['output_type']) != 'training_feedback_candidate') {
      errors.add('output_type must be training_feedback_candidate');
    }

    if (_stringValue(json['scene_id']).isEmpty) {
      errors.add('scene_id is required');
    }

    if (TrainingActionStep.fromKey(_stringValue(json['action_chain_step'])) ==
        null) {
      errors.add('action_chain_step is not allowed');
    }
    if (TrainingMicroAction.fromWireName(_stringValue(json['micro_action'])) ==
        null) {
      errors.add('micro_action is not allowed');
    }

    final Map<String, dynamic>? completion = _map(json['completion_signal']);
    final Map<String, dynamic>? task = _map(json['task_signal']);
    if (completion == null ||
        TrainingSignalStatus.fromKey(_stringValue(completion['status'])) ==
            null) {
      errors.add('completion_signal.status is not allowed');
    }
    if (task == null ||
        TrainingSignalStatus.fromKey(_stringValue(task['status'])) == null) {
      errors.add('task_signal.status is not allowed');
    }

    final Map<String, dynamic>? feedback = _map(json['feedback_card']);
    if (feedback == null) {
      errors.add('feedback_card is required');
    } else {
      final String issue = _stringValue(feedback['main_issue_type']);
      if (!_allowedMainIssueTypes.contains(issue)) {
        errors.add('feedback_card.main_issue_type is not allowed');
      }
      if (_stringValue(feedback['summary']).isEmpty) {
        errors.add('feedback_card.summary is required');
      }
    }

    final Map<String, dynamic>? recommended = _map(
      json['recommended_next_action'],
    );
    final TrainingNextActionType? nextAction = TrainingNextActionType.fromKey(
      _stringValue(recommended?['type']),
    );
    if (recommended == null || nextAction == null) {
      errors.add('recommended_next_action.type is not allowed');
    } else if (plannerNextAction != null && nextAction != plannerNextAction) {
      errors.add('recommended_next_action.type must match planner decision');
    }

    final Map<String, dynamic>? pressure = _map(
      json['pressure_prompt_candidate'],
    );
    if (pressure != null &&
        pressure.containsKey('enabled') &&
        pressure['enabled'] is! bool) {
      errors.add('pressure_prompt_candidate.enabled must be boolean');
    }
    if (pressure?['enabled'] == true &&
        nextAction != TrainingNextActionType.pressureCheck) {
      errors.add('pressure prompt requires pressure_check next action');
    }

    final Map<String, dynamic>? pronunciation = _map(
      json['pronunciation_signal'],
    );
    if (_stringValue(pronunciation?['status']) == 'available' &&
        _stringValue(pronunciation?['source']) != 'server_side_adapter') {
      errors.add('pronunciation source must be server_side_adapter');
    }

    if (_containsBannedOutputField(json)) {
      errors.add('feedback candidate contains final mastery or billing field');
    }

    for (final Map<String, dynamic> evidence in _mapList(
      json['learning_evidence_candidates'],
    )) {
      if (_stringValue(evidence['status']) != 'candidate') {
        errors.add('learning evidence status must stay candidate');
      }
      if (_containsBannedEvidenceField(evidence)) {
        errors.add('learning evidence contains final mastery or billing field');
      }
    }

    final Map<String, dynamic>? recoverable = _map(json['recoverable_error']);
    if (recoverable != null) {
      final TrainingSignalStatus? completionStatus =
          TrainingSignalStatus.fromKey(_stringValue(completion?['status']));
      final TrainingSignalStatus? taskStatus = TrainingSignalStatus.fromKey(
        _stringValue(task?['status']),
      );
      final bool signalsAreFallbackSafe =
          (completionStatus == TrainingSignalStatus.unknown ||
              completionStatus == TrainingSignalStatus.partial) &&
          (taskStatus == TrainingSignalStatus.unknown ||
              taskStatus == TrainingSignalStatus.partial);
      if (!signalsAreFallbackSafe) {
        errors.add('recoverable_error requires unknown or partial signals');
      }
      if (nextAction != TrainingNextActionType.retry &&
          nextAction != TrainingNextActionType.textFallback &&
          nextAction != TrainingNextActionType.fallback) {
        errors.add(
          'recoverable_error requires retry, text_fallback or fallback',
        );
      }
    }

    return TrainingFeedbackValidationResult(errors: errors);
  }
}

class TrainingFeedbackCard {
  const TrainingFeedbackCard({
    required this.summary,
    required this.mainIssueType,
    required this.betterExpression,
    required this.explanationCn,
  });

  final String summary;
  final String mainIssueType;
  final String betterExpression;
  final String explanationCn;
}

class TrainingLearningEvidenceCandidate {
  const TrainingLearningEvidenceCandidate({
    required this.status,
    required this.evidenceType,
    required this.targetExpressionId,
    required this.confidence,
    required this.ruleInput,
  });

  factory TrainingLearningEvidenceCandidate.fromJson(
    Map<String, dynamic> json,
  ) {
    return TrainingLearningEvidenceCandidate(
      status: _stringValue(json['status']),
      evidenceType: _stringValue(json['evidence_type']),
      targetExpressionId: _stringValue(json['target_expression_id']),
      confidence: _doubleValue(json['confidence']),
      ruleInput: _stringValue(json['rule_input']),
    );
  }

  final String status;
  final String evidenceType;
  final String targetExpressionId;
  final double confidence;
  final String ruleInput;

  bool get canBeAcceptedByRules {
    return status == 'candidate' &&
        targetExpressionId.isNotEmpty &&
        confidence >= 0.7;
  }
}

class TrainingFeedbackValidationResult {
  const TrainingFeedbackValidationResult({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

const Set<String> _allowedMainIssueTypes = <String>{
  'none',
  'grammar',
  'vocabulary',
  'naturalness',
  'tone',
  'pronunciation',
  'fluency',
  'missing_intent',
  'off_topic',
  'asr_uncertain',
};

const Set<String> _bannedEvidenceFields = <String>{
  'accepted',
  'mastered',
  'review_scheduled',
  'entitled',
  'billing_state',
  'entitlement',
  'member_plan',
  'subscription_status',
};

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

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .map(_map)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

bool _containsBannedEvidenceField(Map<String, dynamic> evidence) {
  for (final MapEntry<String, dynamic> entry in evidence.entries) {
    final String key = entry.key.trim();
    if (_bannedEvidenceFields.contains(key)) {
      return true;
    }
    final dynamic value = entry.value;
    if (value is String && _bannedEvidenceFields.contains(value.trim())) {
      return true;
    }
  }
  return false;
}

bool _containsBannedOutputField(dynamic value) {
  if (value is Map) {
    for (final MapEntry<dynamic, dynamic> entry in value.entries) {
      final String key = entry.key.toString().trim();
      if (_bannedEvidenceFields.contains(key)) {
        return true;
      }
      if (_containsBannedOutputField(entry.value)) {
        return true;
      }
    }
    return false;
  }
  if (value is List) {
    return value.any(_containsBannedOutputField);
  }
  return value is String && _bannedEvidenceFields.contains(value.trim());
}

String _stringValue(dynamic value, {String fallback = ''}) {
  return value is String ? value.trim() : fallback;
}

int? _intValue(dynamic value) {
  if (value is num) {
    return value.round();
  }
  return null;
}

double _doubleValue(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return 0;
}
