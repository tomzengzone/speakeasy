import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:speakeasy/config/app_config.dart';

/// Qwen3-Omni 实时语音对话服务
/// 通过 WebSocket 连接后端代理，实现双向语音对话
class VoiceChatService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isSpeaking = false;
  String _connectionState = 'disconnected'; // disconnected | connecting | connected | error

  /// 识别出的文本流
  final StreamController<String> _textController = StreamController<String>.broadcast();
  /// 音频流（后端返回的 PCM/Opus 音频数据）
  final StreamController<Uint8List> _audioController = StreamController<Uint8List>.broadcast();
  /// 连接状态变更流
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  /// NPC 是否正在说话
  final StreamController<bool> _speakingController = StreamController<bool>.broadcast();

  Stream<String> get textStream => _textController.stream;
  Stream<Uint8List> get audioStream => _audioController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  Stream<bool> get speakingStream => _speakingController.stream;

  bool get isConnected => _isConnected;
  bool get isSpeaking => _isSpeaking;
  String get connectionState => _connectionState;

  /// 连接到后端 WebSocket 代理
  /// 后端会转发到 DashScope Qwen3-Omni Realtime API
  Future<void> connect({
    String? sessionId,
    String? systemPrompt,
    String? model,
  }) async {
    if (_isConnected || _connectionState == 'connecting') return;

    _connectionState = 'connecting';
    _connectionController.add(_connectionState);
    notifyListeners();

    try {
      // 构建 WebSocket URL，替换 https:// 为 wss://
      String wsBase = AppConfig.apiBaseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final Uri wsUri = Uri.parse('$wsBase/ai/voice-chat');

      _channel = WebSocketChannel.connect(
        wsUri,
      );

      // 发送连接配置
      final Map<String, dynamic> config = <String, dynamic>{
        'type': 'config',
        'model': model ?? AppConfig.realtimeVoiceModel,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        if (systemPrompt != null && systemPrompt.isNotEmpty) 'systemPrompt': systemPrompt,
      };
      _channel!.sink.add(jsonEncode(config));

      _isConnected = true;
      _connectionState = 'connected';
      _connectionController.add(_connectionState);
      notifyListeners();

      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
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
        final Map<String, dynamic> data = jsonDecode(message) as Map<String, dynamic>;
        final String type = data['type'] as String? ?? '';

        switch (type) {
          case 'text':
            // AI 回复的文本
            final String? text = data['text'] as String?;
            if (text != null && text.isNotEmpty) {
              _textController.add(text);
            }
            break;
          case 'audio':
            // AI 回复的音频数据（base64 编码）
            final String? audioBase64 = data['data'] as String?;
            if (audioBase64 != null && audioBase64.isNotEmpty) {
              final Uint8List audioBytes = base64Decode(audioBase64);
              _audioController.add(audioBytes);
            }
            break;
          case 'speaking':
            // AI 开始/停止说话
            _isSpeaking = data['speaking'] as bool? ?? false;
            _speakingController.add(_isSpeaking);
            notifyListeners();
            break;
          case 'error':
            final String? errorMsg = data['message'] as String?;
            if (errorMsg != null) {
              debugPrint('[VoiceChat] Server error: $errorMsg');
            }
            break;
        }
      } catch (e) {
        debugPrint('[VoiceChat] Parse error: $e');
      }
    } else if (message is List<int>) {
      // 二进制音频数据
      _audioController.add(Uint8List.fromList(message));
    }
  }

  void _onError(Object error) {
    debugPrint('[VoiceChat] WebSocket error: $error');
    _connectionState = 'error';
    _connectionController.add(_connectionState);
    _isConnected = false;
    _isSpeaking = false;
    notifyListeners();
  }

  void _onDone() {
    _connectionState = 'disconnected';
    _connectionController.add(_connectionState);
    _isConnected = false;
    _isSpeaking = false;
    notifyListeners();
  }

  /// 发送用户音频数据（base64 编码的 PCM）
  void sendAudio(Uint8List audioBytes) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode(<String, dynamic>{
      'type': 'audio',
      'data': base64Encode(audioBytes),
    }));
  }

  /// 发送用户文本消息
  void sendText(String text) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode(<String, dynamic>{
      'type': 'text',
      'text': text,
    }));
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
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _isSpeaking = false;
    _connectionState = 'disconnected';
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _textController.close();
    _audioController.close();
    _connectionController.close();
    _speakingController.close();
    super.dispose();
  }
}
