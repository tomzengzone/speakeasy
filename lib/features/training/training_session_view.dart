import 'package:flutter/material.dart';

import 'package:speakeasy/features/training/training_contract.dart';

class TrainingSessionView extends StatelessWidget {
  const TrainingSessionView({
    super.key,
    required this.session,
    this.rejection,
    this.onRecord,
    this.onCancelRecording,
    this.onSubmitRecording,
    this.onReplay,
    this.onRetry,
    this.onContinue,
    this.onTextFallback,
    this.onFinish,
    this.onTextChanged,
  });

  final TrainingSessionState? session;
  final TrainingPlannerDecision? rejection;
  final VoidCallback? onRecord;
  final VoidCallback? onCancelRecording;
  final VoidCallback? onSubmitRecording;
  final VoidCallback? onReplay;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;
  final VoidCallback? onTextFallback;
  final VoidCallback? onFinish;
  final ValueChanged<String>? onTextChanged;

  @override
  Widget build(BuildContext context) {
    final TrainingSessionState? current = session;
    if (current == null) {
      return _UnsupportedTrainingState(reasonCode: rejection?.reasonCode ?? '');
    }
    if (current.status == TrainingSessionStatus.unsupportedScene) {
      return _UnsupportedTrainingState(reasonCode: current.lastReasonCode);
    }
    return ListView(
      key: const ValueKey<String>('training_session_view'),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SessionHeader(session: current),
        const SizedBox(height: 16),
        _MicroActionPanel(
          session: current,
          onRecord: onRecord,
          onCancelRecording: onCancelRecording,
          onSubmitRecording: onSubmitRecording,
          onReplay: onReplay,
          onTextFallback: onTextFallback,
          onTextChanged: onTextChanged,
        ),
        if (current.lastFeedback != null) ...<Widget>[
          const SizedBox(height: 12),
          _FeedbackPanel(feedback: current.lastFeedback!),
        ],
        if (current.status == TrainingSessionStatus.pressureCheck)
          const _StatusBanner(
            key: ValueKey<String>('training_pressure_banner'),
            text: 'Pressure check',
          ),
        if (current.status == TrainingSessionStatus.recoverableError)
          _StatusBanner(
            key: const ValueKey<String>('training_error_banner'),
            text: 'Recoverable error: ${current.lastReasonCode}',
          ),
        if (current.status == TrainingSessionStatus.recap &&
            current.recap != null)
          _RecapPanel(recap: current.recap!),
        const SizedBox(height: 16),
        _ActionButtons(
          session: current,
          onRetry: onRetry,
          onContinue: onContinue,
          onFinish: onFinish,
        ),
      ],
    );
  }
}

class _UnsupportedTrainingState extends StatelessWidget {
  const _UnsupportedTrainingState({required this.reasonCode});

  final String reasonCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('training_unsupported_scene'),
      child: Text(
        reasonCode.isEmpty
            ? 'P0.1 training is unavailable for this scene.'
            : 'P0.1 training is unavailable: $reasonCode',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session});

  final TrainingSessionState session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      key: const ValueKey<String>('training_session_header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${session.sceneId} · ${session.levelCode}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          session.currentStep.label,
          key: const ValueKey<String>('training_action_step_label'),
          style: theme.textTheme.bodyMedium,
        ),
        if (session.hintLevel != TrainingHintLevel.none) ...<Widget>[
          const SizedBox(height: 8),
          _StatusBanner(
            key: const ValueKey<String>('training_hint_banner'),
            text: 'Hint: ${session.hintLevel.key}',
          ),
        ],
      ],
    );
  }
}

class _MicroActionPanel extends StatelessWidget {
  const _MicroActionPanel({
    required this.session,
    required this.onRecord,
    required this.onCancelRecording,
    required this.onSubmitRecording,
    required this.onReplay,
    required this.onTextFallback,
    required this.onTextChanged,
  });

  final TrainingSessionState session;
  final VoidCallback? onRecord;
  final VoidCallback? onCancelRecording;
  final VoidCallback? onSubmitRecording;
  final VoidCallback? onReplay;
  final VoidCallback? onTextFallback;
  final ValueChanged<String>? onTextChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey<String>('training_micro_action_panel'),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              session.currentMicroAction.wireName,
              key: const ValueKey<String>('training_micro_action'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(_instructionFor(session)),
            const SizedBox(height: 12),
            if (_needsPlayback(session))
              OutlinedButton.icon(
                key: const ValueKey<String>('training_replay_button'),
                onPressed: onReplay,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Replay'),
              ),
            if (session.currentMicroAction.requiresSpokenInput)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.icon(
                    key: const ValueKey<String>('training_record_button'),
                    onPressed: onRecord,
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey<String>(
                      'training_cancel_recording_button',
                    ),
                    onPressed: onCancelRecording,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey<String>(
                      'training_submit_recording_button',
                    ),
                    onPressed: onSubmitRecording,
                    icon: const Icon(Icons.check),
                    label: const Text('Submit'),
                  ),
                ],
              ),
            if (session.textFallbackAvailable) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('training_text_fallback_field'),
                onChanged: onTextChanged,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Text fallback',
                  helperText: 'Fallback path after mic or ASR issue.',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey<String>('training_text_fallback_button'),
                onPressed: onTextFallback,
                icon: const Icon(Icons.keyboard),
                label: const Text('Use text fallback'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _needsPlayback(TrainingSessionState session) {
    return session.currentMicroAction == TrainingMicroAction.listenOne ||
        session.currentMicroAction == TrainingMicroAction.shadowOne;
  }

  String _instructionFor(TrainingSessionState session) {
    return switch (session.currentMicroAction) {
      TrainingMicroAction.listenOne =>
        'Listen to one model line before continuing.',
      TrainingMicroAction.chooseOne =>
        'Choose the best response for this step.',
      TrainingMicroAction.sayOne => 'Say one complete response for this step.',
      TrainingMicroAction.shadowOne => 'Shadow the model in short chunks.',
      TrainingMicroAction.fillOne =>
        'Fill the missing chunk in the sentence frame.',
      TrainingMicroAction.continueUnderPrompt =>
        'Answer one short follow-up under the current prompt.',
    };
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.feedback});

  final TrainingFeedbackCandidate feedback;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey<String>('training_feedback_panel'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(feedback.feedbackCard.summary),
            if (feedback.feedbackCard.betterExpression.isNotEmpty)
              Text(feedback.feedbackCard.betterExpression),
            if (feedback.pronunciationAvailable)
              const Text(
                'Pronunciation feedback available',
                key: ValueKey<String>('training_pronunciation_feedback'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecapPanel extends StatelessWidget {
  const _RecapPanel({required this.recap});

  final TrainingRecap recap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey<String>('training_recap_panel'),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(recap.summary),
            Text(recap.nextFocus),
            Text(recap.evidenceWriteStatus),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.session,
    required this.onRetry,
    required this.onContinue,
    required this.onFinish,
  });

  final TrainingSessionState session;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    if (session.status == TrainingSessionStatus.recap) {
      return FilledButton(
        key: const ValueKey<String>('training_finish_button'),
        onPressed: onFinish,
        child: const Text('Finish'),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton(
          key: const ValueKey<String>('training_retry_button'),
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
        FilledButton(
          key: const ValueKey<String>('training_continue_button'),
          onPressed: onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
