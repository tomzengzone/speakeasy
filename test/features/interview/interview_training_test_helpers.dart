import 'package:speakeasy/features/interview/interview_training_agent.dart';

InterviewTrainingSessionState p01TrainingSession({
  String userId = 'user-1',
  String sceneId = 'job_interview',
  String levelCode = 'beginner',
  InterviewTrainingSessionStatus status = InterviewTrainingSessionStatus.ready,
  InterviewTrainingActionStep currentStep = InterviewTrainingActionStep.opening,
  InterviewTrainingMicroAction currentMicroAction =
      InterviewTrainingMicroAction.sayOne,
  InterviewTrainingHintLevel hintLevel = InterviewTrainingHintLevel.none,
  int failureCount = 0,
  int successCount = 0,
  bool textFallbackAvailable = false,
  InterviewTrainingFeedbackCandidate? lastFeedback,
  InterviewTrainingRecap? recap,
}) {
  return InterviewTrainingSessionState(
    sessionId: 'p01_${userId}_${sceneId}_$levelCode',
    userId: userId,
    sceneId: sceneId,
    levelCode: levelCode,
    scenarioVersionId: p01TrainingScenarioVersionId,
    status: status,
    currentStep: currentStep,
    currentMicroAction: currentMicroAction,
    hintLevel: hintLevel,
    failureCount: failureCount,
    successCount: successCount,
    textFallbackAvailable: textFallbackAvailable,
    lastFeedback: lastFeedback,
    recap: recap,
  );
}

Map<String, dynamic> p01ValidTrainingFeedbackJson({
  String sceneId = 'job_interview',
  String actionStep = 'opening',
  String microAction = 'SayOne',
  String hintLevel = 'sentence_frame',
  String completionStatus = 'met',
  String taskStatus = 'met',
  String nextAction = 'retry',
  bool pressurePromptEnabled = false,
  bool pronunciationAvailable = true,
  Map<String, dynamic>? recoverableError,
  List<Map<String, dynamic>> learningEvidenceCandidates =
      const <Map<String, dynamic>>[],
}) {
  return <String, dynamic>{
    'schema_version': 1,
    'output_type': 'training_feedback_candidate',
    'scene_id': sceneId,
    'action_chain_step': actionStep,
    'micro_action': microAction,
    'hint_level': hintLevel,
    'completion_signal': <String, dynamic>{
      'status': completionStatus,
      'confidence': 0.82,
      'reason_code': 'target_meaning_covered',
    },
    'task_signal': <String, dynamic>{
      'status': taskStatus,
      'confidence': 0.8,
      'missing_piece': '',
    },
    'pronunciation_signal': <String, dynamic>{
      'status': pronunciationAvailable ? 'available' : 'unavailable',
      'summary': pronunciationAvailable ? 'Clear enough for this step.' : '',
      'source': pronunciationAvailable ? 'server_side_adapter' : '',
    },
    'feedback_card': <String, dynamic>{
      'summary': 'You covered the main idea.',
      'main_issue_type': 'naturalness',
      'better_expression':
          'I am excited to discuss how my experience fits this role.',
      'explanation_cn': 'The response is more natural and task-fit.',
    },
    'retry_hint': <String, dynamic>{
      'hint_level': hintLevel,
      'prompt': 'Try starting with: I am excited to...',
    },
    'recommended_next_action': <String, dynamic>{
      'type': nextAction,
      'micro_action': microAction,
      'prompt': 'Say it again with the sentence frame.',
    },
    'pressure_prompt_candidate': <String, dynamic>{
      'enabled': pressurePromptEnabled,
      'prompt': pressurePromptEnabled ? 'Could you add one example?' : '',
      'success_condition': pressurePromptEnabled
          ? 'Learner continues with one relevant detail.'
          : '',
    },
    'learning_evidence_candidates': learningEvidenceCandidates,
    'recoverable_error': recoverableError,
  };
}

InterviewTrainingFeedbackCandidate p01FeedbackCandidate({
  String nextAction = 'retry',
  List<Map<String, dynamic>> learningEvidenceCandidates =
      const <Map<String, dynamic>>[],
}) {
  return InterviewTrainingFeedbackCandidate.fromJson(
    p01ValidTrainingFeedbackJson(
      nextAction: nextAction,
      learningEvidenceCandidates: learningEvidenceCandidates,
    ),
  );
}
