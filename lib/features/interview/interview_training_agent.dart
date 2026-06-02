import 'package:speakeasy/features/interview/interview_models.dart';

const Set<String> p01InterviewTrainingSceneIds = <String>{
  defaultInterviewSceneId,
  'onboarding_introduction',
};

const String p01TrainingScenarioVersionId = 'p0.1-local-v1';

enum InterviewTrainingMicroAction {
  listenOne('ListenOne'),
  chooseOne('ChooseOne'),
  sayOne('SayOne'),
  shadowOne('ShadowOne'),
  fillOne('FillOne'),
  continueUnderPrompt('ContinueUnderPrompt');

  const InterviewTrainingMicroAction(this.wireName);

  final String wireName;

  bool get requiresSpokenInput {
    return this == sayOne || this == shadowOne || this == continueUnderPrompt;
  }

  static InterviewTrainingMicroAction? fromWireName(String value) {
    final String normalized = value.trim();
    for (final InterviewTrainingMicroAction action in values) {
      if (action.wireName == normalized) {
        return action;
      }
    }
    return null;
  }
}

enum InterviewTrainingHintLevel {
  none('none', 0),
  sentenceFrame('sentence_frame', 1),
  options('options', 2),
  chunkShadowing('chunk_shadowing', 3),
  modelThenRetry('model_then_retry', 4);

  const InterviewTrainingHintLevel(this.key, this.weight);

  final String key;
  final int weight;

  static InterviewTrainingHintLevel? fromKey(String value) {
    final String normalized = value.trim();
    for (final InterviewTrainingHintLevel level in values) {
      if (level.key == normalized) {
        return level;
      }
    }
    return null;
  }
}

enum InterviewTrainingActionStep {
  opening('opening', 'Opening', InterviewTrainingMicroAction.sayOne),
  explainPurpose(
    'explain_purpose',
    'Explain purpose',
    InterviewTrainingMicroAction.fillOne,
  ),
  expressView(
    'express_view',
    'Express view',
    InterviewTrainingMicroAction.sayOne,
  ),
  respondFollowUp(
    'respond_follow_up',
    'Respond to follow-up',
    InterviewTrainingMicroAction.continueUnderPrompt,
  ),
  confirmNextStep(
    'confirm_next_step',
    'Confirm next step',
    InterviewTrainingMicroAction.chooseOne,
  ),
  closing('closing', 'Closing', InterviewTrainingMicroAction.sayOne);

  const InterviewTrainingActionStep(
    this.key,
    this.label,
    this.defaultMicroAction,
  );

  final String key;
  final String label;
  final InterviewTrainingMicroAction defaultMicroAction;

  static InterviewTrainingActionStep? fromKey(String value) {
    final String normalized = value.trim();
    for (final InterviewTrainingActionStep step in values) {
      if (step.key == normalized) {
        return step;
      }
    }
    return null;
  }
}

enum InterviewTrainingSessionStatus {
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

  const InterviewTrainingSessionStatus(this.key);

  final String key;
}

enum InterviewTrainingSignalStatus {
  met('met'),
  partial('partial'),
  notMet('not_met'),
  unknown('unknown');

  const InterviewTrainingSignalStatus(this.key);

  final String key;

  static InterviewTrainingSignalStatus? fromKey(String value) {
    final String normalized = value.trim();
    for (final InterviewTrainingSignalStatus status in values) {
      if (status.key == normalized) {
        return status;
      }
    }
    return null;
  }
}

enum InterviewTrainingAttemptOutcome {
  success,
  failure,
  asrFailed,
  scoreUnavailable,
  pressurePassed,
  pressureFailed,
  recoverableFailure,
}

enum InterviewTrainingNextActionType {
  continueAction('continue'),
  retry('retry'),
  raiseHint('raise_hint'),
  lowerHint('lower_hint'),
  modelThenRetry('model_then_retry'),
  pressureCheck('pressure_check'),
  recap('recap'),
  textFallback('text_fallback'),
  fallback('fallback');

  const InterviewTrainingNextActionType(this.key);

  final String key;

  static InterviewTrainingNextActionType? fromKey(String value) {
    final String normalized = value.trim();
    for (final InterviewTrainingNextActionType type in values) {
      if (type.key == normalized) {
        return type;
      }
    }
    return null;
  }
}

enum InterviewTrainingDecisionType {
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

  const InterviewTrainingDecisionType(this.key);

  final String key;
}

class InterviewTrainingActionChainStep {
  const InterviewTrainingActionChainStep({
    required this.step,
    required this.orderIndex,
    required this.learnerTask,
    required this.successCondition,
    this.targetExpressionIds = const <String>[],
  });

  final InterviewTrainingActionStep step;
  final int orderIndex;
  final String learnerTask;
  final String successCondition;
  final List<String> targetExpressionIds;
}

class InterviewTrainingSessionStartResult {
  const InterviewTrainingSessionStartResult({
    required this.created,
    required this.resumed,
    this.session,
    this.rejection,
  });

  final bool created;
  final bool resumed;
  final InterviewTrainingSessionState? session;
  final InterviewTrainingPlannerDecision? rejection;
}

class InterviewTrainingSessionState {
  const InterviewTrainingSessionState({
    required this.sessionId,
    required this.userId,
    required this.sceneId,
    required this.levelCode,
    required this.scenarioVersionId,
    required this.status,
    required this.currentStep,
    required this.currentMicroAction,
    this.hintLevel = InterviewTrainingHintLevel.none,
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
  final InterviewTrainingSessionStatus status;
  final InterviewTrainingActionStep currentStep;
  final InterviewTrainingMicroAction currentMicroAction;
  final InterviewTrainingHintLevel hintLevel;
  final int failureCount;
  final int successCount;
  final List<String> completedStepKeys;
  final bool textFallbackAvailable;
  final String lastReasonCode;
  final InterviewTrainingFeedbackCandidate? lastFeedback;
  final InterviewTrainingRecap? recap;

  bool get isTerminal {
    return status == InterviewTrainingSessionStatus.completed ||
        status == InterviewTrainingSessionStatus.unsupportedScene ||
        status == InterviewTrainingSessionStatus.abandoned;
  }

  bool get hasSingleActiveMicroAction {
    return status != InterviewTrainingSessionStatus.recap &&
        status != InterviewTrainingSessionStatus.completed &&
        status != InterviewTrainingSessionStatus.unsupportedScene;
  }

  InterviewTrainingSessionState copyWith({
    InterviewTrainingSessionStatus? status,
    InterviewTrainingActionStep? currentStep,
    InterviewTrainingMicroAction? currentMicroAction,
    InterviewTrainingHintLevel? hintLevel,
    int? failureCount,
    int? successCount,
    List<String>? completedStepKeys,
    bool? textFallbackAvailable,
    String? lastReasonCode,
    InterviewTrainingFeedbackCandidate? lastFeedback,
    InterviewTrainingRecap? recap,
  }) {
    return InterviewTrainingSessionState(
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

class InterviewTrainingAttemptResult {
  const InterviewTrainingAttemptResult({
    required this.outcome,
    this.completionStatus = InterviewTrainingSignalStatus.unknown,
    this.taskStatus = InterviewTrainingSignalStatus.unknown,
    this.pronunciationAvailable = false,
    this.recoverableErrorCode = '',
    this.feedbackCandidate,
  });

  factory InterviewTrainingAttemptResult.success({
    bool pronunciationAvailable = false,
    InterviewTrainingFeedbackCandidate? feedbackCandidate,
  }) {
    return InterviewTrainingAttemptResult(
      outcome: InterviewTrainingAttemptOutcome.success,
      completionStatus: InterviewTrainingSignalStatus.met,
      taskStatus: InterviewTrainingSignalStatus.met,
      pronunciationAvailable: pronunciationAvailable,
      feedbackCandidate: feedbackCandidate,
    );
  }

  factory InterviewTrainingAttemptResult.failure({
    InterviewTrainingFeedbackCandidate? feedbackCandidate,
  }) {
    return InterviewTrainingAttemptResult(
      outcome: InterviewTrainingAttemptOutcome.failure,
      completionStatus: InterviewTrainingSignalStatus.notMet,
      taskStatus: InterviewTrainingSignalStatus.notMet,
      feedbackCandidate: feedbackCandidate,
    );
  }

  final InterviewTrainingAttemptOutcome outcome;
  final InterviewTrainingSignalStatus completionStatus;
  final InterviewTrainingSignalStatus taskStatus;
  final bool pronunciationAvailable;
  final String recoverableErrorCode;
  final InterviewTrainingFeedbackCandidate? feedbackCandidate;

  bool get passed {
    return outcome == InterviewTrainingAttemptOutcome.success ||
        outcome == InterviewTrainingAttemptOutcome.pressurePassed ||
        outcome == InterviewTrainingAttemptOutcome.scoreUnavailable &&
            completionStatus == InterviewTrainingSignalStatus.met &&
            taskStatus == InterviewTrainingSignalStatus.met;
  }
}

class InterviewTrainingPlannerDecision {
  const InterviewTrainingPlannerDecision({
    required this.type,
    required this.nextStatus,
    required this.nextStep,
    required this.nextMicroAction,
    required this.nextHintLevel,
    required this.reasonCode,
    this.feedbackCandidate,
  });

  final InterviewTrainingDecisionType type;
  final InterviewTrainingSessionStatus nextStatus;
  final InterviewTrainingActionStep nextStep;
  final InterviewTrainingMicroAction nextMicroAction;
  final InterviewTrainingHintLevel nextHintLevel;
  final String reasonCode;
  final InterviewTrainingFeedbackCandidate? feedbackCandidate;
}

class InterviewTrainingRecap {
  const InterviewTrainingRecap({
    required this.summary,
    required this.nextFocus,
    required this.evidenceCandidates,
    this.evidenceWriteStatus = 'pending_local_write',
  });

  final String summary;
  final String nextFocus;
  final List<InterviewTrainingLearningEvidenceCandidate> evidenceCandidates;
  final String evidenceWriteStatus;
}

class InterviewTrainingFeedbackCandidate {
  const InterviewTrainingFeedbackCandidate({
    required this.sceneId,
    required this.actionStep,
    required this.microAction,
    required this.completionStatus,
    required this.taskStatus,
    required this.feedbackCard,
    required this.recommendedNextAction,
    this.hintLevel = InterviewTrainingHintLevel.none,
    this.pronunciationAvailable = false,
    this.pressurePromptEnabled = false,
    this.learningEvidenceCandidates =
        const <InterviewTrainingLearningEvidenceCandidate>[],
    this.recoverableErrorCode = '',
  });

  factory InterviewTrainingFeedbackCandidate.fromJson(
    Map<String, dynamic> json, {
    InterviewTrainingNextActionType? plannerNextAction,
  }) {
    final InterviewTrainingFeedbackValidationResult validation =
        InterviewTrainingFeedbackCandidate.validateJson(
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

    return InterviewTrainingFeedbackCandidate(
      sceneId: _stringValue(json['scene_id']),
      actionStep: InterviewTrainingActionStep.fromKey(
        _stringValue(json['action_chain_step']),
      )!,
      microAction: InterviewTrainingMicroAction.fromWireName(
        _stringValue(json['micro_action']),
      )!,
      hintLevel:
          InterviewTrainingHintLevel.fromKey(
            _stringValue(json['hint_level']),
          ) ??
          InterviewTrainingHintLevel.none,
      completionStatus: InterviewTrainingSignalStatus.fromKey(
        _stringValue(completion['status']),
      )!,
      taskStatus: InterviewTrainingSignalStatus.fromKey(
        _stringValue(task['status']),
      )!,
      pronunciationAvailable:
          _stringValue(pronunciation['status']) == 'available',
      feedbackCard: InterviewTrainingFeedbackCard(
        summary: _stringValue(feedback['summary']),
        mainIssueType: _stringValue(
          feedback['main_issue_type'],
          fallback: 'none',
        ),
        betterExpression: _stringValue(feedback['better_expression']),
        explanationCn: _stringValue(feedback['explanation_cn']),
      ),
      recommendedNextAction: InterviewTrainingNextActionType.fromKey(
        _stringValue(recommended['type']),
      )!,
      pressurePromptEnabled: pressure['enabled'] == true,
      learningEvidenceCandidates: _mapList(
        json['learning_evidence_candidates'],
      ).map(InterviewTrainingLearningEvidenceCandidate.fromJson).toList(),
      recoverableErrorCode: _stringValue(recoverable?['code']),
    );
  }

  final String sceneId;
  final InterviewTrainingActionStep actionStep;
  final InterviewTrainingMicroAction microAction;
  final InterviewTrainingHintLevel hintLevel;
  final InterviewTrainingSignalStatus completionStatus;
  final InterviewTrainingSignalStatus taskStatus;
  final bool pronunciationAvailable;
  final InterviewTrainingFeedbackCard feedbackCard;
  final InterviewTrainingNextActionType recommendedNextAction;
  final bool pressurePromptEnabled;
  final List<InterviewTrainingLearningEvidenceCandidate>
  learningEvidenceCandidates;
  final String recoverableErrorCode;

  static InterviewTrainingFeedbackValidationResult validateJson(
    Map<String, dynamic> json, {
    InterviewTrainingNextActionType? plannerNextAction,
  }) {
    final List<String> errors = <String>[];
    final int? schemaVersion = _intValue(json['schema_version']);
    if (schemaVersion != 1) {
      errors.add('schema_version must be 1');
    }
    if (_stringValue(json['output_type']) != 'training_feedback_candidate') {
      errors.add('output_type must be training_feedback_candidate');
    }

    final String sceneId = _stringValue(json['scene_id']);
    if (!p01InterviewTrainingSceneIds.contains(sceneId)) {
      errors.add('scene_id is outside P0.1 official scenes');
    }

    if (InterviewTrainingActionStep.fromKey(
          _stringValue(json['action_chain_step']),
        ) ==
        null) {
      errors.add('action_chain_step is not allowed');
    }
    if (InterviewTrainingMicroAction.fromWireName(
          _stringValue(json['micro_action']),
        ) ==
        null) {
      errors.add('micro_action is not allowed');
    }

    final Map<String, dynamic>? completion = _map(json['completion_signal']);
    final Map<String, dynamic>? task = _map(json['task_signal']);
    if (completion == null ||
        InterviewTrainingSignalStatus.fromKey(
              _stringValue(completion['status']),
            ) ==
            null) {
      errors.add('completion_signal.status is not allowed');
    }
    if (task == null ||
        InterviewTrainingSignalStatus.fromKey(_stringValue(task['status'])) ==
            null) {
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
    final InterviewTrainingNextActionType? nextAction =
        InterviewTrainingNextActionType.fromKey(
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
        nextAction != InterviewTrainingNextActionType.pressureCheck) {
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
      final InterviewTrainingSignalStatus? completionStatus =
          InterviewTrainingSignalStatus.fromKey(
            _stringValue(completion?['status']),
          );
      final InterviewTrainingSignalStatus? taskStatus =
          InterviewTrainingSignalStatus.fromKey(_stringValue(task?['status']));
      final bool signalsAreFallbackSafe =
          (completionStatus == InterviewTrainingSignalStatus.unknown ||
              completionStatus == InterviewTrainingSignalStatus.partial) &&
          (taskStatus == InterviewTrainingSignalStatus.unknown ||
              taskStatus == InterviewTrainingSignalStatus.partial);
      if (!signalsAreFallbackSafe) {
        errors.add('recoverable_error requires unknown or partial signals');
      }
      if (nextAction != InterviewTrainingNextActionType.retry &&
          nextAction != InterviewTrainingNextActionType.textFallback &&
          nextAction != InterviewTrainingNextActionType.fallback) {
        errors.add(
          'recoverable_error requires retry, text_fallback or fallback',
        );
      }
    }

    return InterviewTrainingFeedbackValidationResult(errors: errors);
  }
}

class InterviewTrainingFeedbackCard {
  const InterviewTrainingFeedbackCard({
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

class InterviewTrainingLearningEvidenceCandidate {
  const InterviewTrainingLearningEvidenceCandidate({
    required this.status,
    required this.evidenceType,
    required this.targetExpressionId,
    required this.confidence,
    required this.ruleInput,
  });

  factory InterviewTrainingLearningEvidenceCandidate.fromJson(
    Map<String, dynamic> json,
  ) {
    return InterviewTrainingLearningEvidenceCandidate(
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

class InterviewTrainingFeedbackValidationResult {
  const InterviewTrainingFeedbackValidationResult({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class InterviewTrainingAgent {
  const InterviewTrainingAgent({this.successesBeforePressureCheck = 2});

  final int successesBeforePressureCheck;

  bool isSupportedScene(String sceneId) {
    final String normalized = _normalizeSceneId(sceneId);
    return p01InterviewTrainingSceneIds.contains(normalized);
  }

  InterviewTrainingSessionStartResult startSession({
    required String userId,
    required String sceneId,
    required String levelCode,
    InterviewTrainingSessionState? existingSession,
    String scenarioVersionId = p01TrainingScenarioVersionId,
  }) {
    final String normalizedSceneId = _normalizeSceneId(sceneId);
    if (!isSupportedScene(normalizedSceneId)) {
      return InterviewTrainingSessionStartResult(
        created: false,
        resumed: false,
        rejection: InterviewTrainingPlannerDecision(
          type: InterviewTrainingDecisionType.unsupportedScene,
          nextStatus: InterviewTrainingSessionStatus.unsupportedScene,
          nextStep: InterviewTrainingActionStep.opening,
          nextMicroAction: InterviewTrainingMicroAction.sayOne,
          nextHintLevel: InterviewTrainingHintLevel.none,
          reasonCode: 'out_of_scope_scene',
        ),
      );
    }
    if (existingSession != null &&
        existingSession.userId == userId.trim() &&
        existingSession.sceneId == normalizedSceneId &&
        existingSession.levelCode == _normalizeLevel(levelCode) &&
        !existingSession.isTerminal) {
      return InterviewTrainingSessionStartResult(
        created: true,
        resumed: true,
        session: existingSession,
      );
    }
    return InterviewTrainingSessionStartResult(
      created: true,
      resumed: false,
      session: InterviewTrainingSessionState(
        sessionId: _sessionIdFor(
          userId: userId,
          sceneId: normalizedSceneId,
          levelCode: levelCode,
        ),
        userId: userId.trim(),
        sceneId: normalizedSceneId,
        levelCode: _normalizeLevel(levelCode),
        scenarioVersionId: scenarioVersionId,
        status: InterviewTrainingSessionStatus.ready,
        currentStep: InterviewTrainingActionStep.opening,
        currentMicroAction:
            InterviewTrainingActionStep.opening.defaultMicroAction,
      ),
    );
  }

  List<InterviewTrainingActionChainStep> actionChainFor(String sceneId) {
    final String normalizedSceneId = _normalizeSceneId(sceneId);
    if (!isSupportedScene(normalizedSceneId)) {
      return const <InterviewTrainingActionChainStep>[];
    }
    return <InterviewTrainingActionChainStep>[
      const InterviewTrainingActionChainStep(
        step: InterviewTrainingActionStep.opening,
        orderIndex: 0,
        learnerTask: 'Open the conversation naturally.',
        successCondition: 'Learner greets and frames the conversation.',
      ),
      const InterviewTrainingActionChainStep(
        step: InterviewTrainingActionStep.explainPurpose,
        orderIndex: 1,
        learnerTask: 'Explain the reason or context for speaking.',
        successCondition: 'Learner states the purpose with a complete chunk.',
      ),
      const InterviewTrainingActionChainStep(
        step: InterviewTrainingActionStep.expressView,
        orderIndex: 2,
        learnerTask: 'Express one clear view or answer.',
        successCondition: 'Learner covers the target meaning.',
      ),
      const InterviewTrainingActionChainStep(
        step: InterviewTrainingActionStep.respondFollowUp,
        orderIndex: 3,
        learnerTask: 'Respond to a short follow-up prompt.',
        successCondition: 'Learner continues without leaving the scene task.',
      ),
      const InterviewTrainingActionChainStep(
        step: InterviewTrainingActionStep.confirmNextStep,
        orderIndex: 4,
        learnerTask: 'Confirm the next step or shared understanding.',
        successCondition: 'Learner chooses or says a fitting next step.',
      ),
      const InterviewTrainingActionChainStep(
        step: InterviewTrainingActionStep.closing,
        orderIndex: 5,
        learnerTask: 'Close the exchange politely.',
        successCondition: 'Learner closes with a usable sentence.',
      ),
    ];
  }

  InterviewTrainingPlannerDecision decideNext({
    required InterviewTrainingSessionState session,
    required InterviewTrainingAttemptResult attempt,
  }) {
    if (!isSupportedScene(session.sceneId)) {
      return InterviewTrainingPlannerDecision(
        type: InterviewTrainingDecisionType.unsupportedScene,
        nextStatus: InterviewTrainingSessionStatus.unsupportedScene,
        nextStep: session.currentStep,
        nextMicroAction: session.currentMicroAction,
        nextHintLevel: session.hintLevel,
        reasonCode: 'out_of_scope_scene',
      );
    }

    switch (attempt.outcome) {
      case InterviewTrainingAttemptOutcome.asrFailed:
        return _decision(
          session,
          type: InterviewTrainingDecisionType.textFallback,
          status: InterviewTrainingSessionStatus.retry,
          hintLevel: session.hintLevel,
          reasonCode: 'asr_failed_text_fallback_available',
          feedbackCandidate: attempt.feedbackCandidate,
        );
      case InterviewTrainingAttemptOutcome.scoreUnavailable:
        return _successDecision(
          session,
          attempt,
          reasonCode: 'score_unavailable_continue',
        );
      case InterviewTrainingAttemptOutcome.pressurePassed:
        return _advanceOrRecap(
          session,
          attempt,
          reasonCode: 'pressure_check_passed',
        );
      case InterviewTrainingAttemptOutcome.pressureFailed:
        return _decision(
          session,
          type: InterviewTrainingDecisionType.retryWithHigherHint,
          status: InterviewTrainingSessionStatus.retry,
          microAction: InterviewTrainingMicroAction.sayOne,
          hintLevel: _raiseHint(session.hintLevel),
          reasonCode: 'pressure_check_failed_raise_hint',
          feedbackCandidate: attempt.feedbackCandidate,
        );
      case InterviewTrainingAttemptOutcome.recoverableFailure:
        return _decision(
          session,
          type: InterviewTrainingDecisionType.recoverableError,
          status: InterviewTrainingSessionStatus.recoverableError,
          hintLevel: session.hintLevel,
          reasonCode: attempt.recoverableErrorCode.isEmpty
              ? 'recoverable_failure'
              : attempt.recoverableErrorCode,
          feedbackCandidate: attempt.feedbackCandidate,
        );
      case InterviewTrainingAttemptOutcome.success:
        return _successDecision(session, attempt);
      case InterviewTrainingAttemptOutcome.failure:
        return _failureDecision(session, attempt);
    }
  }

  InterviewTrainingSessionState applyDecision({
    required InterviewTrainingSessionState session,
    required InterviewTrainingPlannerDecision decision,
  }) {
    return switch (decision.type) {
      InterviewTrainingDecisionType.unsupportedScene => session.copyWith(
        status: InterviewTrainingSessionStatus.unsupportedScene,
        lastReasonCode: decision.reasonCode,
      ),
      InterviewTrainingDecisionType.recoverableError => session.copyWith(
        status: InterviewTrainingSessionStatus.recoverableError,
        lastReasonCode: decision.reasonCode,
        lastFeedback: decision.feedbackCandidate,
      ),
      InterviewTrainingDecisionType.textFallback => session.copyWith(
        status: decision.nextStatus,
        currentStep: decision.nextStep,
        currentMicroAction: decision.nextMicroAction,
        hintLevel: decision.nextHintLevel,
        textFallbackAvailable: true,
        lastReasonCode: decision.reasonCode,
        lastFeedback: decision.feedbackCandidate,
      ),
      InterviewTrainingDecisionType.retry ||
      InterviewTrainingDecisionType.raiseHint ||
      InterviewTrainingDecisionType.modelThenRetry ||
      InterviewTrainingDecisionType.retryWithHigherHint => session.copyWith(
        status: decision.nextStatus,
        currentStep: decision.nextStep,
        currentMicroAction: decision.nextMicroAction,
        hintLevel: decision.nextHintLevel,
        failureCount: session.failureCount + 1,
        successCount: 0,
        lastReasonCode: decision.reasonCode,
        lastFeedback: decision.feedbackCandidate,
      ),
      InterviewTrainingDecisionType.pressureCheck => session.copyWith(
        status: InterviewTrainingSessionStatus.pressureCheck,
        currentStep: decision.nextStep,
        currentMicroAction: InterviewTrainingMicroAction.continueUnderPrompt,
        hintLevel: decision.nextHintLevel,
        failureCount: 0,
        successCount: session.successCount + 1,
        lastReasonCode: decision.reasonCode,
        lastFeedback: decision.feedbackCandidate,
      ),
      InterviewTrainingDecisionType.advanceStep ||
      InterviewTrainingDecisionType.lowerHint ||
      InterviewTrainingDecisionType.continueAction => session.copyWith(
        status: decision.nextStatus,
        currentStep: decision.nextStep,
        currentMicroAction: decision.nextMicroAction,
        hintLevel: decision.nextHintLevel,
        failureCount: 0,
        successCount: session.successCount + 1,
        completedStepKeys: _completedStepKeys(session, decision),
        textFallbackAvailable: false,
        lastReasonCode: decision.reasonCode,
        lastFeedback: decision.feedbackCandidate,
      ),
      InterviewTrainingDecisionType.fallback => session.copyWith(
        status: InterviewTrainingSessionStatus.retry,
        currentStep: decision.nextStep,
        currentMicroAction: decision.nextMicroAction,
        hintLevel: decision.nextHintLevel,
        lastReasonCode: decision.reasonCode,
        lastFeedback: decision.feedbackCandidate,
      ),
      InterviewTrainingDecisionType.recap => session.copyWith(
        status: InterviewTrainingSessionStatus.recap,
        currentStep: decision.nextStep,
        currentMicroAction: decision.nextMicroAction,
        completedStepKeys: _completedStepKeys(session, decision),
        lastReasonCode: decision.reasonCode,
        lastFeedback: decision.feedbackCandidate,
        recap: buildRecap(session: session, decision: decision),
      ),
    };
  }

  InterviewTrainingRecap buildRecap({
    required InterviewTrainingSessionState session,
    required InterviewTrainingPlannerDecision decision,
  }) {
    final List<InterviewTrainingLearningEvidenceCandidate> evidence =
        decision.feedbackCandidate?.learningEvidenceCandidates
            .where(
              (InterviewTrainingLearningEvidenceCandidate item) =>
                  item.canBeAcceptedByRules,
            )
            .toList(growable: false) ??
        const <InterviewTrainingLearningEvidenceCandidate>[];
    final String nextFocus = evidence.isEmpty
        ? 'Repeat one useful sentence from this session.'
        : 'Review ${evidence.first.targetExpressionId}.';
    return InterviewTrainingRecap(
      summary: 'Training recap for ${session.sceneId} ${session.levelCode}.',
      nextFocus: nextFocus,
      evidenceCandidates: evidence,
    );
  }

  InterviewTrainingPlannerDecision _successDecision(
    InterviewTrainingSessionState session,
    InterviewTrainingAttemptResult attempt, {
    String reasonCode = 'target_and_task_met',
  }) {
    final int nextSuccessCount = session.successCount + 1;
    if (nextSuccessCount >= successesBeforePressureCheck &&
        session.status != InterviewTrainingSessionStatus.pressureCheck) {
      return _decision(
        session,
        type: InterviewTrainingDecisionType.pressureCheck,
        status: InterviewTrainingSessionStatus.pressureCheck,
        microAction: InterviewTrainingMicroAction.continueUnderPrompt,
        hintLevel: _lowerHint(session.hintLevel),
        reasonCode: 'consecutive_success_pressure_check',
        feedbackCandidate: attempt.feedbackCandidate,
      );
    }
    return _advanceOrRecap(session, attempt, reasonCode: reasonCode);
  }

  InterviewTrainingPlannerDecision _failureDecision(
    InterviewTrainingSessionState session,
    InterviewTrainingAttemptResult attempt,
  ) {
    final InterviewTrainingHintLevel raised = _raiseHint(session.hintLevel);
    final bool maxSupportReached =
        session.hintLevel == InterviewTrainingHintLevel.modelThenRetry ||
        raised == InterviewTrainingHintLevel.modelThenRetry;
    return _decision(
      session,
      type: maxSupportReached
          ? InterviewTrainingDecisionType.modelThenRetry
          : InterviewTrainingDecisionType.raiseHint,
      status: InterviewTrainingSessionStatus.retry,
      hintLevel: raised,
      reasonCode: maxSupportReached
          ? 'repeated_failure_model_then_retry'
          : 'failure_raise_hint',
      feedbackCandidate: attempt.feedbackCandidate,
    );
  }

  InterviewTrainingPlannerDecision _advanceOrRecap(
    InterviewTrainingSessionState session,
    InterviewTrainingAttemptResult attempt, {
    required String reasonCode,
  }) {
    final InterviewTrainingActionStep? nextStep = _nextStep(
      session.currentStep,
    );
    if (nextStep == null) {
      return _decision(
        session,
        type: InterviewTrainingDecisionType.recap,
        status: InterviewTrainingSessionStatus.recap,
        hintLevel: session.hintLevel,
        reasonCode: 'action_chain_completed',
        feedbackCandidate: attempt.feedbackCandidate,
      );
    }
    return _decision(
      session,
      type: session.hintLevel == InterviewTrainingHintLevel.none
          ? InterviewTrainingDecisionType.advanceStep
          : InterviewTrainingDecisionType.lowerHint,
      status: InterviewTrainingSessionStatus.ready,
      step: nextStep,
      microAction: nextStep.defaultMicroAction,
      hintLevel: _lowerHint(session.hintLevel),
      reasonCode: reasonCode,
      feedbackCandidate: attempt.feedbackCandidate,
    );
  }

  InterviewTrainingPlannerDecision _decision(
    InterviewTrainingSessionState session, {
    required InterviewTrainingDecisionType type,
    required InterviewTrainingSessionStatus status,
    required InterviewTrainingHintLevel hintLevel,
    required String reasonCode,
    InterviewTrainingActionStep? step,
    InterviewTrainingMicroAction? microAction,
    InterviewTrainingFeedbackCandidate? feedbackCandidate,
  }) {
    final InterviewTrainingActionStep nextStep = step ?? session.currentStep;
    return InterviewTrainingPlannerDecision(
      type: type,
      nextStatus: status,
      nextStep: nextStep,
      nextMicroAction: microAction ?? nextStep.defaultMicroAction,
      nextHintLevel: hintLevel,
      reasonCode: reasonCode,
      feedbackCandidate: feedbackCandidate,
    );
  }

  InterviewTrainingHintLevel _raiseHint(InterviewTrainingHintLevel current) {
    return switch (current) {
      InterviewTrainingHintLevel.none =>
        InterviewTrainingHintLevel.sentenceFrame,
      InterviewTrainingHintLevel.sentenceFrame =>
        InterviewTrainingHintLevel.options,
      InterviewTrainingHintLevel.options =>
        InterviewTrainingHintLevel.chunkShadowing,
      InterviewTrainingHintLevel.chunkShadowing =>
        InterviewTrainingHintLevel.modelThenRetry,
      InterviewTrainingHintLevel.modelThenRetry =>
        InterviewTrainingHintLevel.modelThenRetry,
    };
  }

  InterviewTrainingHintLevel _lowerHint(InterviewTrainingHintLevel current) {
    return switch (current) {
      InterviewTrainingHintLevel.modelThenRetry =>
        InterviewTrainingHintLevel.chunkShadowing,
      InterviewTrainingHintLevel.chunkShadowing =>
        InterviewTrainingHintLevel.options,
      InterviewTrainingHintLevel.options =>
        InterviewTrainingHintLevel.sentenceFrame,
      InterviewTrainingHintLevel.sentenceFrame =>
        InterviewTrainingHintLevel.none,
      InterviewTrainingHintLevel.none => InterviewTrainingHintLevel.none,
    };
  }

  InterviewTrainingActionStep? _nextStep(InterviewTrainingActionStep current) {
    final int index = InterviewTrainingActionStep.values.indexOf(current);
    if (index < 0 || index + 1 >= InterviewTrainingActionStep.values.length) {
      return null;
    }
    return InterviewTrainingActionStep.values[index + 1];
  }

  List<String> _completedStepKeys(
    InterviewTrainingSessionState session,
    InterviewTrainingPlannerDecision decision,
  ) {
    final Set<String> completed = <String>{
      ...session.completedStepKeys,
      session.currentStep.key,
    };
    return completed.toList(growable: false);
  }
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

String _normalizeSceneId(String sceneId) {
  return sceneId.trim();
}

String _normalizeLevel(String levelCode) {
  final String trimmed = levelCode.trim();
  return switch (trimmed) {
    'L2' || 'intermediate' => 'intermediate',
    'L3' || 'advanced' => 'advanced',
    _ => 'beginner',
  };
}

String _sessionIdFor({
  required String userId,
  required String sceneId,
  required String levelCode,
}) {
  return 'p01_${userId.trim()}_${sceneId}_${_normalizeLevel(levelCode)}';
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
