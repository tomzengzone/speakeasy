class CoachTriggerCode {
  const CoachTriggerCode._();

  static const String firstAttempt = 'first_attempt';
  static const String semanticMatch = 'semantic_match';
  static const String targetCompleted = 'target_completed';
  static const String tooShort = 'too_short';
  static const String missingCoreIntent = 'missing_core_intent';
  static const String contentGap = 'content_gap';
  static const String grammarIssue = 'grammar_issue';
  static const String pronunciationIssue = 'pronunciation_issue';
  static const String fluencyIssue = 'fluency_issue';
  static const String unnatural = 'unnatural';
  static const String stuck = 'stuck';
  static const String askForHelp = 'ask_for_help';
  static const String questionEcho = 'question_echo';
  static const String offTopic = 'off_topic';
  static const String repeatedFailure = 'repeated_failure';
  static const String readyForTransfer = 'ready_for_transfer';

  static const Set<String> values = <String>{
    firstAttempt,
    semanticMatch,
    targetCompleted,
    tooShort,
    missingCoreIntent,
    contentGap,
    grammarIssue,
    pronunciationIssue,
    fluencyIssue,
    unnatural,
    stuck,
    askForHelp,
    questionEcho,
    offTopic,
    repeatedFailure,
    readyForTransfer,
  };
}

class TeachingStage {
  const TeachingStage._();

  static const String activate = 'activate';
  static const String firstAttempt = 'first_attempt';
  static const String scaffold = 'scaffold';
  static const String retry = 'retry';
  static const String microDrill = 'micro_drill';
  static const String recast = 'recast';
  static const String followup = 'followup';
  static const String transfer = 'transfer';
  static const String completed = 'completed';

  static const Set<String> values = <String>{
    activate,
    firstAttempt,
    scaffold,
    retry,
    microDrill,
    recast,
    followup,
    transfer,
    completed,
  };
}

class MasteryStatus {
  const MasteryStatus._();

  static const String unknown = 'unknown';
  static const String missed = 'missed';
  static const String nearMiss = 'near_miss';
  static const String mastered = 'mastered';

  static const Set<String> values = <String>{
    unknown,
    missed,
    nearMiss,
    mastered,
  };
}

class CoachNextAction {
  const CoachNextAction._();

  static const String advance = 'advance';
  static const String askFollowup = 'ask_followup';
  static const String coachRetry = 'coach_retry';
  static const String scaffold = 'scaffold';
  static const String modelThenRetry = 'model_then_retry';
  static const String pronunciationFocus = 'pronunciation_focus';
  static const String grammarFocus = 'grammar_focus';
  static const String repairMisunderstanding = 'repair_misunderstanding';
  static const String transferPractice = 'transfer_practice';

  static const Set<String> values = <String>{
    advance,
    askFollowup,
    coachRetry,
    scaffold,
    modelThenRetry,
    pronunciationFocus,
    grammarFocus,
    repairMisunderstanding,
    transferPractice,
  };
}

class CoachErrorType {
  const CoachErrorType._();

  static const String none = 'none';
  static const String missingIntent = 'missing_intent';
  static const String tooShort = 'too_short';
  static const String contentGap = 'content_gap';
  static const String grammar = 'grammar';
  static const String pronunciation = 'pronunciation';
  static const String fluency = 'fluency';
  static const String tone = 'tone';
  static const String naturalness = 'naturalness';
  static const String offTopic = 'off_topic';
  static const String questionEcho = 'question_echo';

  static const Set<String> values = <String>{
    none,
    missingIntent,
    tooShort,
    contentGap,
    grammar,
    pronunciation,
    fluency,
    tone,
    naturalness,
    offTopic,
    questionEcho,
  };
}

class CoachMoveId {
  const CoachMoveId._();

  static const String targetActivation = 'target_activation';
  static const String expressionReshape = 'expression_reshape';
  static const String sentenceBridge = 'sentence_bridge';
  static const String choicePrompt = 'choice_prompt';
  static const String chunkShadowing = 'chunk_shadowing';
  static const String naturalnessTuning = 'naturalness_tuning';
  static const String transferPractice = 'transfer_practice';
  static const String similarExpressionContrast = 'similar_expression_contrast';
  static const String errorDiagnosis = 'error_diagnosis';
  static const String instantRecastFollowup = 'instant_recast_followup';
  static const String difficultyProgression = 'difficulty_progression';
  static const String adaptiveSupport = 'adaptive_support';
  static const String pronunciationFluencyFeedback =
      'pronunciation_fluency_feedback';
  static const String masteryAssessment = 'mastery_assessment';

  static const Set<String> values = <String>{
    targetActivation,
    expressionReshape,
    sentenceBridge,
    choicePrompt,
    chunkShadowing,
    naturalnessTuning,
    transferPractice,
    similarExpressionContrast,
    errorDiagnosis,
    instantRecastFollowup,
    difficultyProgression,
    adaptiveSupport,
    pronunciationFluencyFeedback,
    masteryAssessment,
  };
}

class InterviewCoachSchema {
  const InterviewCoachSchema._();

  static const int schemaVersion = 1;

  static bool isTriggerCode(String value) {
    return CoachTriggerCode.values.contains(value.trim());
  }

  static bool isTeachingStage(String value) {
    return TeachingStage.values.contains(value.trim());
  }

  static bool isMasteryStatus(String value) {
    return MasteryStatus.values.contains(value.trim());
  }

  static bool isNextAction(String value) {
    return CoachNextAction.values.contains(value.trim());
  }

  static bool isErrorType(String value) {
    return CoachErrorType.values.contains(value.trim());
  }

  static bool isCoachMoveId(String value) {
    return CoachMoveId.values.contains(value.trim());
  }

  static bool isAdaptivePolicyAction(String value) {
    final String normalized = value.trim();
    return isCoachMoveId(normalized) ||
        isTeachingStage(normalized) ||
        isNextAction(normalized);
  }

  static String safeTeachingStage(String value, {String fallback = ''}) {
    final String normalized = value.trim();
    return isTeachingStage(normalized) ? normalized : fallback;
  }

  static String safeNextAction(String value, {String fallback = ''}) {
    final String normalized = value.trim();
    return isNextAction(normalized) ? normalized : fallback;
  }

  static String safeCoachMoveId(String value, {String fallback = ''}) {
    final String normalized = value.trim();
    return isCoachMoveId(normalized) ? normalized : fallback;
  }

  static List<String> safeCoachMoveIds(Iterable<String> values) {
    return values
        .map((String value) => value.trim())
        .where(isCoachMoveId)
        .toSet()
        .toList(growable: false);
  }

  static List<String> safeTriggerCodes(Iterable<String> values) {
    return values
        .map((String value) => value.trim())
        .where(isTriggerCode)
        .toSet()
        .toList(growable: false);
  }
}
