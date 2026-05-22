import 'dart:async';

import 'package:speakeasy/services/voice_chat_service.dart';

enum VoiceTurnMode { realtime, turnBased }

enum VoiceTurnFinalizeReason { idle, signal }

class VoiceAssistantTurnReady {
  const VoiceAssistantTurnReady({
    required this.mode,
    required this.sessionKey,
    required this.bufferedText,
    required this.hasAudio,
    required this.reason,
    this.assistantMeta,
  });

  final VoiceTurnMode mode;
  final int sessionKey;
  final String bufferedText;
  final bool hasAudio;
  final VoiceTurnFinalizeReason reason;
  final AssistantTurnMeta? assistantMeta;
}

class VoiceTurnOrchestrator {
  VoiceTurnOrchestrator({
    this.turnBasedIdleDelay = const Duration(milliseconds: 900),
    this.signalDelay = const Duration(milliseconds: 180),
  });

  final Duration turnBasedIdleDelay;
  final Duration signalDelay;

  final StreamController<VoiceAssistantTurnReady> _readyController =
      StreamController<VoiceAssistantTurnReady>.broadcast();

  Stream<VoiceAssistantTurnReady> get readyStream => _readyController.stream;

  Timer? _finalizeTimer;
  VoiceTurnMode? _mode;
  int _sessionKey = -1;
  String _bufferedAssistantText = '';
  bool _hasAudio = false;
  bool _assistantTurnActive = false;
  bool _finalizeInFlight = false;
  AssistantTurnMeta? _assistantMeta;

  String get bufferedAssistantText => _bufferedAssistantText;

  bool get hasBufferedAssistantTurn =>
      _bufferedAssistantText.trim().isNotEmpty || _hasAudio;

  void startSession({
    required int sessionKey,
    required VoiceTurnMode mode,
  }) {
    _cancelFinalizeTimer();
    _mode = mode;
    _sessionKey = sessionKey;
    _resetTurnState();
  }

  void beginAssistantTurn() {
    _cancelFinalizeTimer();
    _assistantTurnActive = true;
    _finalizeInFlight = false;
    _bufferedAssistantText = '';
    _hasAudio = false;
    _assistantMeta = null;
  }

  String appendAssistantText(String delta) {
    final String cleanedDelta = delta.trim();
    if (cleanedDelta.isEmpty) {
      return _bufferedAssistantText;
    }
    if (!_assistantTurnActive) {
      beginAssistantTurn();
    }
    _bufferedAssistantText += delta;
    if (_mode == VoiceTurnMode.turnBased) {
      _scheduleFinalize(turnBasedIdleDelay, VoiceTurnFinalizeReason.idle);
    }
    return _bufferedAssistantText;
  }

  void noteAssistantAudio() {
    if (!_assistantTurnActive) {
      beginAssistantTurn();
    }
    _hasAudio = true;
    if (_mode == VoiceTurnMode.turnBased) {
      _scheduleFinalize(turnBasedIdleDelay, VoiceTurnFinalizeReason.idle);
    }
  }

  void noteSpeaking(bool speaking) {
    if (speaking) {
      if (!_assistantTurnActive) {
        beginAssistantTurn();
      }
      _cancelFinalizeTimer();
      return;
    }
    _scheduleFinalize(signalDelay, VoiceTurnFinalizeReason.signal);
  }

  void noteAssistantDone([AssistantTurnMeta? assistantMeta]) {
    if (assistantMeta != null) {
      _assistantMeta = assistantMeta;
    }
    _scheduleFinalize(signalDelay, VoiceTurnFinalizeReason.signal);
  }

  void completeFinalize(int sessionKey) {
    if (sessionKey != _sessionKey) {
      return;
    }
    _resetTurnState();
  }

  void clearSession() {
    _cancelFinalizeTimer();
    _mode = null;
    _sessionKey = -1;
    _resetTurnState();
  }

  void dispose() {
    _cancelFinalizeTimer();
    _readyController.close();
  }

  void _scheduleFinalize(
    Duration delay,
    VoiceTurnFinalizeReason reason,
  ) {
    if (_mode == null || _sessionKey < 0) {
      return;
    }
    _cancelFinalizeTimer();
    _finalizeTimer = Timer(delay, () {
      _emitReady(reason);
    });
  }

  void _emitReady(VoiceTurnFinalizeReason reason) {
    if (_mode == null || _sessionKey < 0 || _finalizeInFlight) {
      return;
    }
    final String bufferedText = _bufferedAssistantText.trim();
    if (bufferedText.isEmpty && !_hasAudio) {
      return;
    }
    _finalizeInFlight = true;
    _readyController.add(
      VoiceAssistantTurnReady(
        mode: _mode!,
        sessionKey: _sessionKey,
        bufferedText: bufferedText,
        hasAudio: _hasAudio,
        reason: reason,
        assistantMeta: _assistantMeta,
      ),
    );
  }

  void _cancelFinalizeTimer() {
    _finalizeTimer?.cancel();
    _finalizeTimer = null;
  }

  void _resetTurnState() {
    _cancelFinalizeTimer();
    _bufferedAssistantText = '';
    _hasAudio = false;
    _assistantTurnActive = false;
    _finalizeInFlight = false;
    _assistantMeta = null;
  }
}
