import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/features/training/training_backend_adapter.dart';
import 'package:speakeasy/features/training/training_contract.dart';
import 'package:speakeasy/features/training/training_session_view.dart';
import 'package:speakeasy/services/app_session.dart';

class TrainingSessionLoopPage extends StatefulWidget {
  const TrainingSessionLoopPage({
    super.key,
    required this.sceneId,
    required this.levelCode,
    required this.backendAdapter,
  });

  final String sceneId;
  final String levelCode;
  final TrainingBackendAdapter backendAdapter;

  @override
  State<TrainingSessionLoopPage> createState() =>
      _TrainingSessionLoopPageState();
}

class _TrainingSessionLoopPageState extends State<TrainingSessionLoopPage> {
  TrainingSessionState? _session;
  TrainingPlannerDecision? _rejection;
  String _textFallback = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_startSession()),
    );
  }

  Future<void> _startSession() async {
    final AppSession appSession = AppSessionScope.of(context);
    try {
      final TrainingSessionStartResult result = await widget.backendAdapter
          .startSession(
            userId: appSession.nickname,
            sceneId: widget.sceneId,
            levelCode: widget.levelCode,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = result.session;
        _rejection = result.rejection;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _session = null;
        _rejection = const TrainingPlannerDecision(
          type: TrainingDecisionType.recoverableError,
          nextStatus: TrainingSessionStatus.recoverableError,
          nextStep: TrainingActionStep.opening,
          nextMicroAction: TrainingMicroAction.sayOne,
          nextHintLevel: TrainingHintLevel.none,
          reasonCode: 'backend_training_unavailable',
        );
      });
    }
  }

  void _markAudioCaptureUnavailable() {
    final TrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    setState(() {
      _session = current.copyWith(
        status: TrainingSessionStatus.recoverableError,
        textFallbackAvailable: true,
        lastReasonCode: 'trusted_audio_ref_required',
      );
    });
  }

  Future<void> _submitBackendTextTurn() async {
    final String text = _textFallback.trim();
    final TrainingSessionState? current = _session;
    if (current == null || text.isEmpty) {
      return;
    }
    setState(() {
      _session = current.copyWith(status: TrainingSessionStatus.evaluating);
    });
    try {
      final TrainingBackendTurnResult
      result = await widget.backendAdapter.submitTextTurn(
        sessionId: current.sessionId,
        text: text,
        idempotencyKey:
            'training-turn-${current.sessionId}-${DateTime.now().microsecondsSinceEpoch}',
        fallbackUserId: current.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = result.session;
        _textFallback = '';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _session = current.copyWith(
          status: TrainingSessionStatus.recoverableError,
          textFallbackAvailable: true,
          lastReasonCode: 'backend_training_turn_failed',
        );
      });
    }
  }

  Future<void> _requestBackendHint() async {
    final TrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    try {
      final TrainingSessionState next = await widget.backendAdapter.requestHint(
        sessionId: current.sessionId,
        fallbackUserId: current.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = next;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _session = current.copyWith(
          status: TrainingSessionStatus.recoverableError,
          lastReasonCode: 'backend_training_hint_failed',
        );
      });
    }
  }

  Future<void> _refreshBackendSession() async {
    final TrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    try {
      final TrainingSessionState next = await widget.backendAdapter.getSession(
        sessionId: current.sessionId,
        fallbackUserId: current.userId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = next;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _session = current.copyWith(
          status: TrainingSessionStatus.recoverableError,
          lastReasonCode: 'backend_training_refresh_failed',
        );
      });
    }
  }

  Future<void> _completeBackendTraining() async {
    final TrainingSessionState? current = _session;
    if (current == null) {
      return;
    }
    try {
      final TrainingRecap recap = await widget.backendAdapter.completeSession(
        sessionId: current.sessionId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = current.copyWith(
          status: TrainingSessionStatus.completed,
          recap: recap,
        );
      });
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _session = current.copyWith(
          status: TrainingSessionStatus.recoverableError,
          lastReasonCode: 'backend_training_complete_failed',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('表达训练闭环'),
        leading: IconButton(
          key: const ValueKey<String>('training_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: TrainingSessionView(
        session: _session,
        rejection: _rejection,
        onRecord: _markAudioCaptureUnavailable,
        onCancelRecording: _markAudioCaptureUnavailable,
        onSubmitRecording: _markAudioCaptureUnavailable,
        onReplay: _refreshBackendSession,
        onRetry: () => unawaited(_requestBackendHint()),
        onContinue: () => unawaited(_refreshBackendSession()),
        onTextFallback: () => unawaited(_submitBackendTextTurn()),
        onFinish: () => unawaited(_completeBackendTraining()),
        onTextChanged: (String value) {
          _textFallback = value;
        },
      ),
    );
  }
}
