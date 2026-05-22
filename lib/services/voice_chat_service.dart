import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';

class RealtimeAudioChunk {
  const RealtimeAudioChunk({required this.bytes, required this.format});

  final Uint8List bytes;
  final String format;
}

class AssistantTurnMeta {
  const AssistantTurnMeta({
    this.summary = '',
    this.coach = '',
    this.event = '',
    this.turnContract,
    this.sceneState,
  });

  final String summary;
  final String coach;
  final String event;
  final SceneTurnContract? turnContract;
  final SceneStateSnapshot? sceneState;
}

enum VoiceChatAssistantEventType { started, textDelta, audioChunk, speaking, done }

class VoiceChatAssistantEvent {
  const VoiceChatAssistantEvent({
    required this.type,
    this.text = '',
    this.audioChunk,
    this.speaking,
    this.assistantMeta,
  });

  final VoiceChatAssistantEventType type;
  final String text;
  final RealtimeAudioChunk? audioChunk;
  final bool? speaking;
  final AssistantTurnMeta? assistantMeta;
}

enum VoiceChatTurnEventType {
  assistantStarted,
  assistantTextDelta,
  assistantAudioChunk,
  assistantSpeaking,
  assistantDone,
  userPreview,
  userFinal,
}

class VoiceChatTurnEvent {
  const VoiceChatTurnEvent({
    required this.type,
    this.text = '',
    this.audioChunk,
    this.speaking,
    this.assistantMeta,
  });

  final VoiceChatTurnEventType type;
  final String text;
  final RealtimeAudioChunk? audioChunk;
  final bool? speaking;
  final AssistantTurnMeta? assistantMeta;
}

enum _VoiceChatProtocol { auto, official, custom, legacy }

/// Qwen3-Omni 实时语音对话服务
/// 通过 WebSocket 连接后端代理，实现双向语音对话
class VoiceChatService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isSpeaking = false;
  bool _disposed = false;
  String _connectionState =
      'disconnected'; // disconnected | connecting | connected | error
  _VoiceChatProtocol _protocol = _VoiceChatProtocol.auto;
  Timer? _startupFallbackTimer;
  String? _pendingSessionId;
  String? _pendingSystemPrompt;
  String? _pendingModel;
  bool _pendingManualTurnDetection = false;
  bool _pendingPlannerMode = false;
  bool _pendingTranscriptionOnly = false;
  bool _plannerModeActive = false;
  bool _officialSessionConfigured = false;
  AssistantTurnMeta? _lastAssistantTurnMeta;
  final StringBuffer _assistantTextBuffer = StringBuffer();
  final StringBuffer _userTranscriptBuffer = StringBuffer();
  String _lastUserTranscript = '';
  DateTime? _lastUserTranscriptAt;

  /// 识别出的文本流
  final StreamController<String> _textController =
      StreamController<String>.broadcast();

  /// 用户语音转录文本流
  final StreamController<String> _userTextController =
      StreamController<String>.broadcast();

  /// 用户语音实时预览文本流
  final StreamController<String> _userTextPreviewController =
      StreamController<String>.broadcast();

  /// 音频流（后端返回的 PCM/WAV 等音频数据）
  final StreamController<RealtimeAudioChunk> _audioController =
      StreamController<RealtimeAudioChunk>.broadcast();

  /// 连接状态变更流
  final StreamController<String> _connectionController =
      StreamController<String>.broadcast();

  /// NPC 是否正在说话
  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  /// 助手本轮回复已完成
  final StreamController<void> _assistantDoneController =
      StreamController<void>.broadcast();

  /// 助手本轮回复已开始
  final StreamController<void> _assistantStartedController =
      StreamController<void>.broadcast();

  /// 助手标准事件流
  final StreamController<VoiceChatAssistantEvent> _assistantEventController =
      StreamController<VoiceChatAssistantEvent>.broadcast();

  /// 用户与助手统一回合事件流
  final StreamController<VoiceChatTurnEvent> _turnEventController =
      StreamController<VoiceChatTurnEvent>.broadcast();

  Stream<String> get textStream => _textController.stream;
  Stream<String> get userTextStream => _userTextController.stream;
  Stream<String> get userTextPreviewStream => _userTextPreviewController.stream;
  Stream<RealtimeAudioChunk> get audioStream => _audioController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<void> get assistantDoneStream => _assistantDoneController.stream;
  Stream<void> get assistantStartedStream => _assistantStartedController.stream;
  Stream<VoiceChatAssistantEvent> get assistantEventStream =>
      _assistantEventController.stream;
  Stream<VoiceChatTurnEvent> get turnEventStream => _turnEventController.stream;

  bool get isConnected => _isConnected;
  bool get isSpeaking => _isSpeaking;
  String get connectionState => _connectionState;
  bool get plannerModeActive => _plannerModeActive;
  AssistantTurnMeta? get lastAssistantTurnMeta => _lastAssistantTurnMeta;
  AssistantTurnMeta? consumeLastAssistantTurnMeta() {
    final AssistantTurnMeta? meta = _lastAssistantTurnMeta;
    _lastAssistantTurnMeta = null;
    return meta;
  }

  /// 连接到后端 WebSocket 代理
  /// 后端会转发到 DashScope Qwen3-Omni Realtime API
  Future<void> connect({
    String? sessionId,
    String? systemPrompt,
    String? model,
    bool manualTurnDetection = false,
    bool plannerMode = false,
    bool transcriptionOnly = false,
    Map<String, dynamic>? sceneContext,
    required String token,
  }) async {
    if (_disposed) return;
    if (_isConnected || _connectionState == 'connecting') return;

    _connectionState = 'connecting';
    _connectionController.add(_connectionState);
    notifyListeners();

    try {
      _protocol = _VoiceChatProtocol.auto;
      _pendingSessionId = sessionId;
      _pendingSystemPrompt = systemPrompt;
      _pendingModel = model;
      _pendingManualTurnDetection = manualTurnDetection;
      _pendingPlannerMode = plannerMode;
      _pendingTranscriptionOnly = transcriptionOnly;
      _plannerModeActive = false;
      _officialSessionConfigured = false;
      _lastAssistantTurnMeta = null;
      _assistantTextBuffer.clear();
      _userTranscriptBuffer.clear();

      // 构建 WebSocket URL，替换 https:// 为 wss://
      String wsBase = AppConfig.apiBaseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final Uri wsUri = Uri.parse('$wsBase/ai/voice-chat?token=$token');
      debugPrint('[VoiceChat] Connecting to: $wsUri');

      // 用 dart:io WebSocket 直接连接，确保连接成功后再发数据
      final WebSocket socket = await WebSocket.connect(
        wsUri.toString(),
      ).timeout(const Duration(seconds: 15));
      debugPrint('[VoiceChat] WebSocket connected');

      _channel = IOWebSocketChannel(socket);

      // 先设置监听，再发送数据
      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);

      _sendCustomStart(
        sessionId: sessionId,
        systemPrompt: systemPrompt,
        model: model,
        manualTurnDetection: manualTurnDetection,
        plannerMode: plannerMode,
        transcriptionOnly: transcriptionOnly,
        sceneContext: sceneContext,
      );
      _startupFallbackTimer?.cancel();
      _startupFallbackTimer = Timer(const Duration(milliseconds: 2800), () {
        if (_channel == null ||
            _isConnected ||
            _connectionState != 'connecting') {
          return;
        }
        debugPrint('[VoiceChat] No start ack, falling back to legacy config');
        _protocol = _VoiceChatProtocol.legacy;
        _sendLegacyConfig(
          sessionId: sessionId,
          systemPrompt: systemPrompt,
          model: model,
          manualTurnDetection: manualTurnDetection,
          plannerMode: plannerMode,
          transcriptionOnly: transcriptionOnly,
          sceneContext: sceneContext,
        );
      });
    } catch (e) {
      _startupFallbackTimer?.cancel();
      _connectionState = 'error';
      _connectionController.add(_connectionState);
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  void _onMessage(dynamic message) {
    if (message is String) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(message) as Map<String, dynamic>;
        final String type = data['type'] as String? ?? '';

        switch (type) {
          case 'session.created':
          case 'session.updated':
            _setProtocol(_VoiceChatProtocol.official);
            if (!_officialSessionConfigured) {
              _officialSessionConfigured = true;
              _sendOfficialSessionUpdate(
                sessionId: _pendingSessionId,
                systemPrompt: _pendingSystemPrompt,
                model: _pendingModel,
                plannerMode: _pendingPlannerMode,
              );
            }
            _markConnected();
            break;
          case 'response.created':
          case 'response.output_item.added':
            _setProtocol(_VoiceChatProtocol.official);
            _assistantTextBuffer.clear();
            _markConnected();
            _setSpeaking(true);
            _assistantStartedController.add(null);
            _assistantEventController.add(
              const VoiceChatAssistantEvent(
                type: VoiceChatAssistantEventType.started,
              ),
            );
            _turnEventController.add(
              const VoiceChatTurnEvent(
                type: VoiceChatTurnEventType.assistantStarted,
              ),
            );
            break;
          case 'response.audio.delta':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            _setSpeaking(true);
            final String audioBase64 = _pickFirstString(data, const <String>[
              'delta',
              'audio',
              'data',
            ]).trim();
            if (audioBase64.isNotEmpty) {
              final RealtimeAudioChunk audioChunk = RealtimeAudioChunk(
                bytes: base64Decode(audioBase64),
                format: _normalizeAudioFormat(
                  data['audio_format'] as String? ?? 'pcm',
                ),
              );
              _audioController.add(audioChunk);
              _assistantEventController.add(
                VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.audioChunk,
                  audioChunk: audioChunk,
                ),
              );
              _turnEventController.add(
                VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantAudioChunk,
                  audioChunk: audioChunk,
                ),
              );
            }
            break;
          case 'response.audio.done':
          case 'response.done':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            _setSpeaking(false);
            _assistantDoneController.add(null);
            _assistantEventController.add(
              VoiceChatAssistantEvent(
                type: VoiceChatAssistantEventType.done,
                assistantMeta: _lastAssistantTurnMeta,
              ),
            );
            _turnEventController.add(
              VoiceChatTurnEvent(
                type: VoiceChatTurnEventType.assistantDone,
                assistantMeta: _lastAssistantTurnMeta,
              ),
            );
            break;
          case 'response.audio_transcript.delta':
          case 'response.text.delta':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            final String text = _pickFirstString(data, const <String>[
              'delta',
              'text',
              'transcript',
              'content',
            ]).trim();
            if (text.isNotEmpty) {
              _assistantTextBuffer.write(text);
              _textController.add(text);
              _assistantEventController.add(
                VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.textDelta,
                  text: text,
                ),
              );
              _turnEventController.add(
                VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantTextDelta,
                  text: text,
                ),
              );
            }
            break;
          case 'response.audio_transcript.done':
          case 'response.text.done':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            final String streamedText = _assistantTextBuffer.toString().trim();
            final String finalText = _pickFirstString(data, const <String>[
              'text',
              'transcript',
              'content',
            ]).trim();
            if (finalText.isNotEmpty && streamedText.isEmpty) {
              _textController.add(finalText);
              _assistantEventController.add(
                VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.textDelta,
                  text: finalText,
                ),
              );
              _turnEventController.add(
                VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantTextDelta,
                  text: finalText,
                ),
              );
            }
            _assistantDoneController.add(null);
            _assistantEventController.add(
              VoiceChatAssistantEvent(
                type: VoiceChatAssistantEventType.done,
                assistantMeta: _lastAssistantTurnMeta,
              ),
            );
            _turnEventController.add(
              VoiceChatTurnEvent(
                type: VoiceChatTurnEventType.assistantDone,
                assistantMeta: _lastAssistantTurnMeta,
              ),
            );
            break;
          case 'input_audio_buffer.speech_started':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            break;
          case 'input_audio_buffer.speech_stopped':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            break;
          case 'conversation.item.input_audio_transcription.completed':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            final String finalTranscript = _pickFirstString(
              data,
              const <String>['transcript', 'text'],
            ).trim();
            _emitUserTranscriptPreview(finalTranscript);
            _emitUserTranscriptIfAvailable(finalTranscript);
            break;
          case 'conversation.item.input_audio_transcription.text':
            _setProtocol(_VoiceChatProtocol.official);
            _markConnected();
            _emitUserTranscriptPreview(
              _pickFirstString(data, const <String>[
                'text',
                'transcript',
                'stash',
              ]).trim(),
            );
            break;
          case 'ready':
          case 'started':
            _setProtocol(_VoiceChatProtocol.custom);
            _plannerModeActive = data['planner_mode'] == true;
            _markConnected();
            break;
          case 'connection':
            final String state = (data['state'] as String? ?? '')
                .trim()
                .toLowerCase();
            if (state == 'connected') {
              _plannerModeActive = data['planner_mode'] == true;
              _markConnected();
            }
            break;
          case 'assistant_started':
            _setProtocol(_VoiceChatProtocol.custom);
            _assistantTextBuffer.clear();
            _lastAssistantTurnMeta = null;
            _markConnected();
            _setSpeaking(true);
            _assistantStartedController.add(null);
            _assistantEventController.add(
              const VoiceChatAssistantEvent(
                type: VoiceChatAssistantEventType.started,
              ),
            );
            _turnEventController.add(
              const VoiceChatTurnEvent(
                type: VoiceChatTurnEventType.assistantStarted,
              ),
            );
            break;
          case 'assistant_text_delta':
          case 'text_delta':
            _setProtocol(_VoiceChatProtocol.custom);
            final String text = _pickFirstString(data, const <String>[
              'text',
              'delta',
              'content',
            ]).trim();
            if (text.isNotEmpty) {
              _assistantTextBuffer.write(text);
              _textController.add(text);
              _assistantEventController.add(
                VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.textDelta,
                  text: text,
                ),
              );
              _turnEventController.add(
                VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantTextDelta,
                  text: text,
                ),
              );
            }
            break;
          case 'assistant_done':
            _setProtocol(_VoiceChatProtocol.custom);
            final String streamedText = _assistantTextBuffer.toString().trim();
            final String finalText = _pickFirstString(data, const <String>[
              'text',
              'response_text',
              'content',
            ]).trim();
            if (finalText.isNotEmpty && streamedText.isEmpty) {
              _textController.add(finalText);
            }
            _assistantTextBuffer.clear();
            _lastAssistantTurnMeta = AssistantTurnMeta(
              summary: (data['summary'] as String? ?? '').trim(),
              coach: (data['coach'] as String? ?? '').trim(),
              event: (data['event'] as String? ?? '').trim(),
              turnContract: _sceneTurnContractFromDynamic(data['turnContract']),
              sceneState: _sceneStateFromDynamic(data['sceneState']),
            );
            _emitUserTranscriptIfAvailable(
              (data['user_transcript'] as String? ?? '').trim(),
            );
            _setSpeaking(false);
            _assistantDoneController.add(null);
            _assistantEventController.add(
              VoiceChatAssistantEvent(
                type: VoiceChatAssistantEventType.done,
                assistantMeta: _lastAssistantTurnMeta,
              ),
            );
            _turnEventController.add(
              VoiceChatTurnEvent(
                type: VoiceChatTurnEventType.assistantDone,
                assistantMeta: _lastAssistantTurnMeta,
              ),
            );
            break;
          case 'assistant_audio_chunk':
            _setProtocol(_VoiceChatProtocol.custom);
            final String audioBase64 = _pickFirstString(data, const <String>[
              'audio_base64',
              'data',
              'chunk',
            ]).trim();
            if (audioBase64.isNotEmpty) {
              final RealtimeAudioChunk audioChunk = RealtimeAudioChunk(
                bytes: base64Decode(audioBase64),
                format: _normalizeAudioFormat(
                  data['audio_format'] as String? ?? 'pcm',
                ),
              );
              _audioController.add(audioChunk);
              _assistantEventController.add(
                VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.audioChunk,
                  audioChunk: audioChunk,
                ),
              );
              _turnEventController.add(
                VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantAudioChunk,
                  audioChunk: audioChunk,
                ),
              );
            }
            break;
          case 'user_transcript_delta':
          case 'input_transcript_delta':
            _setProtocol(_VoiceChatProtocol.custom);
            final String delta = _pickFirstString(data, const <String>[
              'text',
              'transcript',
              'delta',
            ]).trim();
            if (delta.isNotEmpty) {
              _userTranscriptBuffer.write(delta);
            }
            _emitUserTranscriptPreview(delta);
            break;
          case 'user_transcript_done':
            _setProtocol(_VoiceChatProtocol.custom);
            final String finalTranscript = _pickFirstString(
              data,
              const <String>['text', 'transcript'],
            ).trim();
            _emitUserTranscriptPreview(finalTranscript);
            _emitUserTranscriptIfAvailable(finalTranscript);
            break;
          case 'text':
            // AI 回复的文本
            _setProtocol(_VoiceChatProtocol.legacy);
            _markConnected();
            final String? text = data['text'] as String?;
            if (text != null && text.isNotEmpty) {
              _assistantTextBuffer.write(text);
              _textController.add(text);
              _assistantEventController.add(
                VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.textDelta,
                  text: text,
                ),
              );
              _turnEventController.add(
                VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantTextDelta,
                  text: text,
                ),
              );
            }
            break;
          case 'user_text':
            _setProtocol(_VoiceChatProtocol.legacy);
            _markConnected();
            final String? text = data['text'] as String?;
            if (text != null && text.isNotEmpty) {
              _emitUserTranscriptIfAvailable(text.trim());
            }
            break;
          case 'audio':
            // AI 回复的音频数据（base64 编码）
            _setProtocol(_VoiceChatProtocol.legacy);
            _markConnected();
            final String? audioBase64 = data['data'] as String?;
            if (audioBase64 != null && audioBase64.isNotEmpty) {
              final RealtimeAudioChunk audioChunk = RealtimeAudioChunk(
                bytes: base64Decode(audioBase64),
                format: _normalizeAudioFormat(
                  data['audio_format'] as String? ??
                      data['format'] as String? ??
                      'pcm',
                ),
              );
              _audioController.add(audioChunk);
              _assistantEventController.add(
                VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.audioChunk,
                  audioChunk: audioChunk,
                ),
              );
              _turnEventController.add(
                VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantAudioChunk,
                  audioChunk: audioChunk,
                ),
              );
            }
            break;
          case 'speaking':
            // AI 开始/停止说话
            _setProtocol(_VoiceChatProtocol.legacy);
            _markConnected();
            final bool speaking = data['speaking'] as bool? ?? false;
            if (speaking) {
              _assistantTextBuffer.clear();
              _assistantStartedController.add(null);
              _assistantEventController.add(
                const VoiceChatAssistantEvent(
                  type: VoiceChatAssistantEventType.started,
                ),
              );
              _turnEventController.add(
                const VoiceChatTurnEvent(
                  type: VoiceChatTurnEventType.assistantStarted,
                ),
              );
            }
            _setSpeaking(speaking);
            _assistantEventController.add(
              VoiceChatAssistantEvent(
                type: VoiceChatAssistantEventType.speaking,
                speaking: speaking,
              ),
            );
            _turnEventController.add(
              VoiceChatTurnEvent(
                type: VoiceChatTurnEventType.assistantSpeaking,
                speaking: speaking,
              ),
            );
            break;
          case 'error':
            final String? errorMsg = data['message'] as String?;
            if (errorMsg != null) {
              debugPrint('[VoiceChat] Server error: $errorMsg');
            }
            break;
          default:
            if (!_isConnected) {
              _markConnected();
            }
        }
      } catch (e) {
        final String plainText = message.trim();
        if (plainText.isNotEmpty) {
          _setProtocol(_VoiceChatProtocol.legacy);
          _markConnected();
          _textController.add(plainText);
        } else {
          debugPrint('[VoiceChat] Parse error: $e');
        }
      }
    } else if (message is List<int>) {
      _setProtocol(_VoiceChatProtocol.legacy);
      _markConnected();
      _audioController.add(
        RealtimeAudioChunk(bytes: Uint8List.fromList(message), format: 'pcm'),
      );
    }
  }

  void _onError(Object error) {
    if (_disposed) {
      return;
    }
    debugPrint('[VoiceChat] WebSocket error: $error');
    debugPrint('[VoiceChat] Error type: ${error.runtimeType}');
    _startupFallbackTimer?.cancel();
    _officialSessionConfigured = false;
    _connectionState = 'error';
    _connectionController.add(_connectionState);
    _isConnected = false;
    _isSpeaking = false;
    _plannerModeActive = false;
    notifyListeners();
  }

  void _onDone() {
    if (_disposed) {
      return;
    }
    debugPrint('[VoiceChat] WebSocket closed (onDone)');
    _startupFallbackTimer?.cancel();
    _officialSessionConfigured = false;
    _connectionState = 'disconnected';
    _connectionController.add(_connectionState);
    _isConnected = false;
    _isSpeaking = false;
    _plannerModeActive = false;
    notifyListeners();
  }

  /// 发送用户音频数据（base64 编码的 PCM）
  void sendAudio(Uint8List audioBytes) {
    if (!_isConnected || _channel == null) return;
    final String audioBase64 = base64Encode(audioBytes);
    if (_pendingTranscriptionOnly) {
      _channel!.sink.add(
        jsonEncode(<String, dynamic>{
          'type': 'user_audio',
          'input_audio': <String, dynamic>{
            'data': audioBase64,
            'format': 'pcm_16000',
            'sample_rate': 16000,
            'channels': 1,
            'streaming': true,
          },
        }),
      );
      return;
    }
    if (_protocol == _VoiceChatProtocol.official) {
      _channel!.sink.add(
        jsonEncode(<String, dynamic>{
          'type': 'input_audio_buffer.append',
          'audio': audioBase64,
        }),
      );
      return;
    }
    if (_protocol == _VoiceChatProtocol.custom) {
      _channel!.sink.add(
        jsonEncode(<String, dynamic>{
          'type': 'user_audio',
          'input_audio': <String, dynamic>{
            'data': audioBase64,
            'format': 'pcm_16000',
            'sample_rate': 16000,
            'channels': 1,
            'streaming': true,
          },
        }),
      );
      return;
    }

    _channel!.sink.add(
      jsonEncode(<String, dynamic>{'type': 'audio', 'data': audioBase64}),
    );
  }

  /// 发送用户文本消息
  void sendText(String text) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(
      jsonEncode(<String, dynamic>{'type': 'text', 'text': text}),
    );
  }

  void commitTurn() {
    if (!_isConnected || _channel == null) return;
    if (_pendingTranscriptionOnly) {
      _channel!.sink.add(jsonEncode(<String, dynamic>{'type': 'commit'}));
      return;
    }
    if (_protocol == _VoiceChatProtocol.official) {
      _channel!.sink.add(
        jsonEncode(<String, dynamic>{'type': 'input_audio_buffer.commit'}),
      );
      _channel!.sink.add(
        jsonEncode(<String, dynamic>{'type': 'response.create'}),
      );
      return;
    }
    if (_protocol == _VoiceChatProtocol.custom) {
      _channel!.sink.add(jsonEncode(<String, dynamic>{'type': 'commit'}));
      return;
    }
    _channel!.sink.add(jsonEncode(<String, dynamic>{'type': 'commit'}));
  }

  /// 发送调试信息到服务端
  void sendDebug(String message) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(
      jsonEncode(<String, dynamic>{'type': 'debug', 'message': message}),
    );
  }

  /// 中断 AI 当前说话
  void interrupt() {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode(<String, dynamic>{'type': 'interrupt'}));
    _isSpeaking = false;
    _speakingController.add(false);
    notifyListeners();
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_disposed) {
      return;
    }
    _startupFallbackTimer?.cancel();
    _officialSessionConfigured = false;
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _isSpeaking = false;
    _connectionState = 'disconnected';
    _plannerModeActive = false;
    notifyListeners();
  }

  void finishSession() {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode(<String, dynamic>{'type': 'finish'}));
  }

  void updateSession({
    String? sessionId,
    String? systemPrompt,
    String? model,
    bool? manualTurnDetection,
    bool? plannerMode,
    bool? transcriptionOnly,
    Map<String, dynamic>? sceneContext,
  }) {
    if (_disposed || _channel == null) {
      return;
    }
    _pendingSessionId = sessionId ?? _pendingSessionId;
    _pendingSystemPrompt = systemPrompt ?? _pendingSystemPrompt;
    _pendingModel = model ?? _pendingModel;
    if (manualTurnDetection != null) {
      _pendingManualTurnDetection = manualTurnDetection;
    }
    if (plannerMode != null) {
      _pendingPlannerMode = plannerMode;
    }
    if (transcriptionOnly != null) {
      _pendingTranscriptionOnly = transcriptionOnly;
    }

    switch (_protocol) {
      case _VoiceChatProtocol.official:
        _sendOfficialSessionUpdate(
          sessionId: _pendingSessionId,
          systemPrompt: _pendingSystemPrompt,
          model: _pendingModel,
          manualTurnDetection: _pendingManualTurnDetection,
          plannerMode: _pendingPlannerMode,
        );
        break;
      case _VoiceChatProtocol.custom:
        _sendCustomStart(
          sessionId: _pendingSessionId,
          systemPrompt: _pendingSystemPrompt,
          model: _pendingModel,
          manualTurnDetection: _pendingManualTurnDetection,
          plannerMode: _pendingPlannerMode,
          transcriptionOnly: _pendingTranscriptionOnly,
          sceneContext: sceneContext,
        );
        break;
      case _VoiceChatProtocol.legacy:
        _sendLegacyConfig(
          sessionId: _pendingSessionId,
          systemPrompt: _pendingSystemPrompt,
          model: _pendingModel,
          manualTurnDetection: _pendingManualTurnDetection,
          plannerMode: _pendingPlannerMode,
          transcriptionOnly: _pendingTranscriptionOnly,
          sceneContext: sceneContext,
        );
        break;
      case _VoiceChatProtocol.auto:
        break;
    }
  }

  void _sendCustomStart({
    required String? sessionId,
    required String? systemPrompt,
    required String? model,
    required bool manualTurnDetection,
    required bool plannerMode,
    required bool transcriptionOnly,
    Map<String, dynamic>? sceneContext,
  }) {
    _channel?.sink.add(
      jsonEncode(<String, dynamic>{
        'type': 'start',
        'model': model ?? AppConfig.realtimeVoiceModel,
        'audio_format': 'pcm',
        'modalities': const <String>['text', 'audio'],
        'reset_history': true,
        if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        'turn_detection_mode': manualTurnDetection ? 'manual' : 'server_vad',
        'planner_mode': plannerMode,
        'transcription_only': transcriptionOnly,
        'transcriptionOnly': transcriptionOnly,
        if (sceneContext != null && sceneContext.isNotEmpty)
          'scene_context': sceneContext,
        if (systemPrompt != null && systemPrompt.isNotEmpty)
          'system_prompt': systemPrompt,
        if (systemPrompt != null && systemPrompt.isNotEmpty)
          'systemPrompt': systemPrompt,
      }),
    );
    debugPrint('[VoiceChat] Custom start sent, waiting for realtime ack...');
  }

  void _sendOfficialSessionUpdate({
    required String? sessionId,
    required String? systemPrompt,
    required String? model,
    bool? manualTurnDetection,
    bool? plannerMode,
  }) {
    final bool isManualTurnDetection =
        manualTurnDetection ?? _pendingManualTurnDetection;
    final bool isPlannerMode = plannerMode ?? _pendingPlannerMode;
    if (_channel == null) {
      return;
    }
    _channel!.sink.add(
      jsonEncode(<String, dynamic>{
        'type': 'session.update',
        'session': <String, dynamic>{
          'model': model ?? AppConfig.realtimeVoiceModel,
          'modalities': const <String>['text', 'audio'],
          'input_audio_format': 'pcm16',
          'output_audio_format': 'pcm16',
          'turn_detection': isManualTurnDetection
              ? null
              : <String, dynamic>{
                  'type': 'server_vad',
                  'prefix_padding_ms': 300,
                  'silence_duration_ms': 700,
                  'create_response': !isPlannerMode,
                },
          if (systemPrompt != null && systemPrompt.isNotEmpty)
            'instructions': systemPrompt,
          if (sessionId != null && sessionId.isNotEmpty)
            'metadata': <String, dynamic>{'sessionId': sessionId},
        },
      }),
    );
    debugPrint('[VoiceChat] Official session.update sent');
  }

  void _sendLegacyConfig({
    required String? sessionId,
    required String? systemPrompt,
    required String? model,
    required bool manualTurnDetection,
    required bool plannerMode,
    required bool transcriptionOnly,
    Map<String, dynamic>? sceneContext,
  }) {
    _channel?.sink.add(
      jsonEncode(<String, dynamic>{
        'type': 'config',
        'model': model ?? AppConfig.realtimeVoiceModel,
        'turnDetection': manualTurnDetection
            ? null
            : const <String, dynamic>{
                'type': 'server_vad',
                'prefixPaddingMs': 300,
                'silenceDurationMs': 700,
              },
        'plannerMode': plannerMode,
        'transcriptionOnly': transcriptionOnly,
        if (sceneContext != null && sceneContext.isNotEmpty)
          'sceneContext': sceneContext,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        if (systemPrompt != null && systemPrompt.isNotEmpty)
          'systemPrompt': systemPrompt,
      }),
    );
    debugPrint('[VoiceChat] Legacy config sent');
  }

  SceneTurnContract? _sceneTurnContractFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SceneTurnContract.fromJson(value);
    }
    if (value is Map) {
      return SceneTurnContract.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  SceneStateSnapshot? _sceneStateFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SceneStateSnapshot.fromJson(value);
    }
    if (value is Map) {
      return SceneStateSnapshot.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  void _markConnected() {
    if (_disposed) {
      return;
    }
    if (_isConnected && _connectionState == 'connected') {
      return;
    }
    _startupFallbackTimer?.cancel();
    _isConnected = true;
    _connectionState = 'connected';
    _connectionController.add(_connectionState);
    notifyListeners();
  }

  void _setSpeaking(bool speaking) {
    if (_disposed) {
      return;
    }
    _isSpeaking = speaking;
    _speakingController.add(_isSpeaking);
    notifyListeners();
  }

  void _setProtocol(_VoiceChatProtocol protocol) {
    if (_protocol == protocol) {
      return;
    }
    if (_protocol == _VoiceChatProtocol.auto ||
        (_protocol == _VoiceChatProtocol.custom &&
            protocol == _VoiceChatProtocol.official)) {
      _protocol = protocol;
    }
  }

  void _emitUserTranscriptIfAvailable(String text) {
    final String finalText = text.isNotEmpty
        ? text
        : _userTranscriptBuffer.toString().trim();
    _userTranscriptBuffer.clear();
    if (finalText.isNotEmpty && !_isRecentDuplicateUserTranscript(finalText)) {
      _lastUserTranscript = finalText;
      _lastUserTranscriptAt = DateTime.now();
      debugPrint('[VoiceChat] User transcript: $finalText');
      _userTextController.add(finalText);
      _turnEventController.add(
        VoiceChatTurnEvent(
          type: VoiceChatTurnEventType.userFinal,
          text: finalText,
        ),
      );
    }
  }

  void _emitUserTranscriptPreview(String text) {
    final String preview = text.trim();
    if (preview.isEmpty || _disposed) {
      return;
    }
    _userTextPreviewController.add(preview);
    _turnEventController.add(
      VoiceChatTurnEvent(
        type: VoiceChatTurnEventType.userPreview,
        text: preview,
      ),
    );
  }

  bool _isRecentDuplicateUserTranscript(String text) {
    if (_lastUserTranscript.isEmpty || _lastUserTranscript != text) {
      return false;
    }
    final DateTime? lastAt = _lastUserTranscriptAt;
    if (lastAt == null) {
      return false;
    }
    return DateTime.now().difference(lastAt) < const Duration(seconds: 3);
  }

  String _pickFirstString(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _normalizeAudioFormat(String raw) {
    final String format = raw.trim().toLowerCase();
    if (format.isEmpty) {
      return 'pcm';
    }
    if (format.startsWith('pcm')) {
      return 'pcm';
    }
    if (format.contains('wav')) {
      return 'wav';
    }
    if (format.contains('mp3')) {
      return 'mp3';
    }
    if (format.contains('aac')) {
      return 'aac';
    }
    if (format.contains('m4a')) {
      return 'm4a';
    }
    if (format.contains('ogg') || format.contains('opus')) {
      return 'ogg';
    }
    return format;
  }

  @override
  void dispose() {
    _disposed = true;
    _startupFallbackTimer?.cancel();
    _officialSessionConfigured = false;
    _channel?.sink.close();
    _channel = null;
    _textController.close();
    _userTextController.close();
    _userTextPreviewController.close();
    _audioController.close();
    _connectionController.close();
    _speakingController.close();
    _assistantDoneController.close();
    _assistantStartedController.close();
    _assistantEventController.close();
    _turnEventController.close();
    super.dispose();
  }
}
