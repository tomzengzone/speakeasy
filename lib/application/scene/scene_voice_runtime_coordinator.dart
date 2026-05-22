import 'package:speakeasy/services/voice_chat_service.dart';

class SceneVoiceSessionConfig {
  const SceneVoiceSessionConfig({
    this.sessionId,
    this.systemPrompt,
    this.model,
    this.manualTurnDetection = false,
    this.plannerMode = false,
    this.transcriptionOnly = false,
    this.sceneContext,
  });

  final String? sessionId;
  final String? systemPrompt;
  final String? model;
  final bool manualTurnDetection;
  final bool plannerMode;
  final bool transcriptionOnly;
  final Map<String, dynamic>? sceneContext;
}

class SceneVoiceConnectRequest {
  const SceneVoiceConnectRequest({
    required this.token,
    required this.config,
    this.connectErrorPrefix,
  });

  final String token;
  final SceneVoiceSessionConfig config;
  final String? connectErrorPrefix;
}

abstract class SceneVoiceRuntimeGateway {
  VoiceChatService createService();

  Future<void> connect({
    required VoiceChatService service,
    required SceneVoiceConnectRequest request,
  });

  void updateSession({
    required VoiceChatService service,
    required SceneVoiceSessionConfig config,
  });
}

class DefaultSceneVoiceRuntimeGateway implements SceneVoiceRuntimeGateway {
  const DefaultSceneVoiceRuntimeGateway();

  @override
  VoiceChatService createService() => VoiceChatService();

  @override
  Future<void> connect({
    required VoiceChatService service,
    required SceneVoiceConnectRequest request,
  }) {
    return service.connect(
      sessionId: request.config.sessionId,
      systemPrompt: request.config.systemPrompt,
      model: request.config.model,
      manualTurnDetection: request.config.manualTurnDetection,
      plannerMode: request.config.plannerMode,
      transcriptionOnly: request.config.transcriptionOnly,
      sceneContext: request.config.sceneContext,
      token: request.token,
    );
  }

  @override
  void updateSession({
    required VoiceChatService service,
    required SceneVoiceSessionConfig config,
  }) {
    service.updateSession(
      sessionId: config.sessionId,
      systemPrompt: config.systemPrompt,
      model: config.model,
      manualTurnDetection: config.manualTurnDetection,
      plannerMode: config.plannerMode,
      transcriptionOnly: config.transcriptionOnly,
      sceneContext: config.sceneContext,
    );
  }
}

class SceneVoiceRuntimeCoordinator {
  const SceneVoiceRuntimeCoordinator({
    SceneVoiceRuntimeGateway gateway = const DefaultSceneVoiceRuntimeGateway(),
  }) : _gateway = gateway;

  final SceneVoiceRuntimeGateway _gateway;

  VoiceChatService createService() {
    return _gateway.createService();
  }

  Future<void> connect({
    required VoiceChatService service,
    required SceneVoiceConnectRequest request,
  }) async {
    try {
      await _gateway.connect(service: service, request: request);
    } catch (error) {
      final String prefix = request.connectErrorPrefix ?? '连接失败';
      throw '$prefix: $error';
    }
  }

  void updateSession({
    required VoiceChatService service,
    required SceneVoiceSessionConfig config,
  }) {
    _gateway.updateSession(service: service, config: config);
  }
}
