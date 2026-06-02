import 'package:flutter/material.dart';

import 'package:speakeasy/features/interview/interview_training_agent.dart';
import 'package:speakeasy/features/interview/interview_training_session_view.dart';
import 'package:speakeasy/services/app_session.dart';

class InterviewTrainingLoopPage extends StatefulWidget {
  const InterviewTrainingLoopPage({
    super.key,
    required this.sceneId,
    required this.levelCode,
  });

  final String sceneId;
  final String levelCode;

  @override
  State<InterviewTrainingLoopPage> createState() =>
      _InterviewTrainingLoopPageState();
}

class _InterviewTrainingLoopPageState extends State<InterviewTrainingLoopPage> {
  final InterviewTrainingAgent _agent = const InterviewTrainingAgent();
  InterviewTrainingSessionState? _session;
  InterviewTrainingPlannerDecision? _rejection;
  String _textFallback = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  void _startSession() {
    final AppSession appSession = AppSessionScope.of(context);
    final InterviewTrainingSessionStartResult result = _agent.startSession(
      userId: appSession.nickname,
      sceneId: widget.sceneId,
      levelCode: widget.levelCode,
    );
    setState(() {
      _session = result.session;
      _rejection = result.rejection;
    });
  }

  void _setStatus(InterviewTrainingSessionStatus status) {
    final InterviewTrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    setState(() {
      _session = current.copyWith(status: status);
    });
  }

  void _applyAttempt(InterviewTrainingAttemptResult attempt) {
    final InterviewTrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    final InterviewTrainingPlannerDecision decision = _agent.decideNext(
      session: current,
      attempt: attempt,
    );
    setState(() {
      _session = _agent.applyDecision(session: current, decision: decision);
    });
  }

  void _submitRecording() {
    _applyAttempt(
      InterviewTrainingAttemptResult(
        outcome: InterviewTrainingAttemptOutcome.asrFailed,
        completionStatus: InterviewTrainingSignalStatus.unknown,
        taskStatus: InterviewTrainingSignalStatus.unknown,
        feedbackCandidate: _feedbackCandidate(
          nextAction: InterviewTrainingNextActionType.textFallback,
          completionStatus: InterviewTrainingSignalStatus.unknown,
          taskStatus: InterviewTrainingSignalStatus.unknown,
          summary:
              'ASR unavailable. Use text fallback to keep the loop moving.',
        ),
      ),
    );
  }

  void _useTextFallback() {
    if (_textFallback.trim().isEmpty) {
      return;
    }
    _applyAttempt(
      InterviewTrainingAttemptResult.success(
        feedbackCandidate: _feedbackCandidate(
          nextAction: InterviewTrainingNextActionType.continueAction,
          summary: 'Text fallback accepted and ready for the next action.',
          evidenceTargetId: '${widget.sceneId}_opening_text_fallback',
        ),
      ),
    );
  }

  void _continueTraining() {
    final InterviewTrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    final bool closing =
        current.currentStep == InterviewTrainingActionStep.closing;
    final bool pressure =
        current.status == InterviewTrainingSessionStatus.pressureCheck;
    final bool willPressureCheck =
        !pressure &&
        current.successCount + 1 >= _agent.successesBeforePressureCheck;
    _applyAttempt(
      InterviewTrainingAttemptResult(
        outcome: pressure
            ? InterviewTrainingAttemptOutcome.pressurePassed
            : InterviewTrainingAttemptOutcome.success,
        completionStatus: InterviewTrainingSignalStatus.met,
        taskStatus: InterviewTrainingSignalStatus.met,
        pronunciationAvailable: current.currentMicroAction.requiresSpokenInput,
        feedbackCandidate: _feedbackCandidate(
          nextAction: willPressureCheck
              ? InterviewTrainingNextActionType.pressureCheck
              : closing
              ? InterviewTrainingNextActionType.recap
              : InterviewTrainingNextActionType.continueAction,
          summary: pressure
              ? 'Pressure check passed without leaving the scene task.'
              : 'Target meaning and task completion are met.',
          evidenceTargetId: closing
              ? '${widget.sceneId}_closing_polite_wrap'
              : '${widget.sceneId}_${current.currentStep.key}_usable_chunk',
        ),
      ),
    );
  }

  void _finishTraining() {
    final InterviewTrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    setState(() {
      _session = current.copyWith(
        status: InterviewTrainingSessionStatus.completed,
      );
    });
    Navigator.of(context).maybePop();
  }

  InterviewTrainingFeedbackCandidate _feedbackCandidate({
    required InterviewTrainingNextActionType nextAction,
    required String summary,
    InterviewTrainingSignalStatus completionStatus =
        InterviewTrainingSignalStatus.met,
    InterviewTrainingSignalStatus taskStatus =
        InterviewTrainingSignalStatus.met,
    String evidenceTargetId = '',
  }) {
    final InterviewTrainingSessionState? current = _session;
    final InterviewTrainingActionStep actionStep =
        current?.currentStep ?? InterviewTrainingActionStep.opening;
    final InterviewTrainingMicroAction microAction =
        current?.currentMicroAction ??
        InterviewTrainingActionStep.opening.defaultMicroAction;
    return InterviewTrainingFeedbackCandidate.fromJson(<String, dynamic>{
      'schema_version': 1,
      'output_type': 'training_feedback_candidate',
      'scene_id': widget.sceneId,
      'action_chain_step': actionStep.key,
      'micro_action': microAction.wireName,
      'hint_level':
          current?.hintLevel.key ?? InterviewTrainingHintLevel.none.key,
      'completion_signal': <String, dynamic>{'status': completionStatus.key},
      'task_signal': <String, dynamic>{'status': taskStatus.key},
      'feedback_card': <String, dynamic>{
        'summary': summary,
        'main_issue_type': completionStatus == InterviewTrainingSignalStatus.met
            ? 'none'
            : 'asr_uncertain',
        'better_expression': 'I can explain that clearly.',
        'explanation_cn': '保持当前小动作，不写入最终掌握状态。',
      },
      'recommended_next_action': <String, dynamic>{'type': nextAction.key},
      'pronunciation_signal': <String, dynamic>{
        'status': microAction.requiresSpokenInput ? 'available' : 'unavailable',
        'source': microAction.requiresSpokenInput ? 'server_side_adapter' : '',
      },
      'pressure_prompt_candidate': <String, dynamic>{
        'enabled': nextAction == InterviewTrainingNextActionType.pressureCheck,
      },
      'learning_evidence_candidates': <Map<String, dynamic>>[
        if (evidenceTargetId.trim().isNotEmpty)
          <String, dynamic>{
            'status': 'candidate',
            'evidence_type': 'weak_expression',
            'target_expression_id': evidenceTargetId,
            'confidence': 0.82,
            'rule_input': 'Learner completed the scoped training step.',
          },
      ],
      if (nextAction == InterviewTrainingNextActionType.textFallback)
        'recoverable_error': <String, dynamic>{'code': 'ASR_UNAVAILABLE'},
    }, plannerNextAction: nextAction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('表达训练闭环'),
        leading: IconButton(
          key: const ValueKey<String>('interview_training_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: InterviewTrainingSessionView(
        session: _session,
        rejection: _rejection,
        onRecord: () => _setStatus(InterviewTrainingSessionStatus.recording),
        onCancelRecording: () =>
            _setStatus(InterviewTrainingSessionStatus.ready),
        onSubmitRecording: _submitRecording,
        onReplay: () => _setStatus(InterviewTrainingSessionStatus.listening),
        onRetry: () => _applyAttempt(
          InterviewTrainingAttemptResult.failure(
            feedbackCandidate: _feedbackCandidate(
              nextAction: InterviewTrainingNextActionType.raiseHint,
              completionStatus: InterviewTrainingSignalStatus.notMet,
              taskStatus: InterviewTrainingSignalStatus.notMet,
              summary: 'Try again with a narrower sentence frame.',
            ),
          ),
        ),
        onContinue: _continueTraining,
        onTextFallback: _useTextFallback,
        onFinish: _finishTraining,
        onTextChanged: (String value) {
          _textFallback = value;
        },
      ),
    );
  }
}
