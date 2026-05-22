import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/application/scene/scene_voice_runtime_coordinator.dart';
import 'package:speakeasy/services/voice_chat_service.dart';

void main() {
  test('createService 会委托 gateway 创建 VoiceChatService', () {
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    final _FakeSceneVoiceRuntimeGateway gateway = _FakeSceneVoiceRuntimeGateway(
      service: service,
    );
    final SceneVoiceRuntimeCoordinator coordinator =
        SceneVoiceRuntimeCoordinator(gateway: gateway);

    final VoiceChatService created = coordinator.createService();

    expect(created, same(service));
    expect(gateway.createServiceCallCount, 1);
  });

  test('connect 会透传 connect 参数', () async {
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    final _FakeSceneVoiceRuntimeGateway gateway = _FakeSceneVoiceRuntimeGateway(
      service: service,
    );
    final SceneVoiceRuntimeCoordinator coordinator =
        SceneVoiceRuntimeCoordinator(gateway: gateway);
    const SceneVoiceConnectRequest request = SceneVoiceConnectRequest(
      token: 'voice-token',
      config: SceneVoiceSessionConfig(
        sessionId: 'session-1',
        systemPrompt: 'prompt',
        model: 'qwen',
        manualTurnDetection: true,
        plannerMode: true,
        transcriptionOnly: false,
        sceneContext: <String, dynamic>{'draft': 'demo'},
      ),
    );

    await coordinator.connect(service: service, request: request);

    expect(gateway.lastConnectedService, same(service));
    expect(gateway.lastConnectRequest, same(request));
  });

  test('connect 在 gateway 抛错时会加上前缀', () async {
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    final _FakeSceneVoiceRuntimeGateway gateway = _FakeSceneVoiceRuntimeGateway(
      service: service,
    )..connectError = StateError('socket closed');
    final SceneVoiceRuntimeCoordinator coordinator =
        SceneVoiceRuntimeCoordinator(gateway: gateway);

    expect(
      () => coordinator.connect(
        service: service,
        request: const SceneVoiceConnectRequest(
          token: 'voice-token',
          connectErrorPrefix: '语音连接失败',
          config: SceneVoiceSessionConfig(systemPrompt: 'prompt'),
        ),
      ),
      throwsA(
        predicate<Object>(
          (Object error) => error.toString().contains('语音连接失败'),
        ),
      ),
    );
  });

  test('updateSession 会委托 gateway 更新 session 配置', () {
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    final _FakeSceneVoiceRuntimeGateway gateway = _FakeSceneVoiceRuntimeGateway(
      service: service,
    );
    final SceneVoiceRuntimeCoordinator coordinator =
        SceneVoiceRuntimeCoordinator(gateway: gateway);
    const SceneVoiceSessionConfig config = SceneVoiceSessionConfig(
      sessionId: 'session-2',
      systemPrompt: 'updated prompt',
      manualTurnDetection: true,
      plannerMode: false,
    );

    coordinator.updateSession(service: service, config: config);

    expect(gateway.lastUpdatedService, same(service));
    expect(gateway.lastUpdatedConfig, same(config));
  });
}

class _FakeSceneVoiceRuntimeGateway implements SceneVoiceRuntimeGateway {
  _FakeSceneVoiceRuntimeGateway({required this.service});

  final VoiceChatService service;
  int createServiceCallCount = 0;
  VoiceChatService? lastConnectedService;
  SceneVoiceConnectRequest? lastConnectRequest;
  VoiceChatService? lastUpdatedService;
  SceneVoiceSessionConfig? lastUpdatedConfig;
  Object? connectError;

  @override
  Future<void> connect({
    required VoiceChatService service,
    required SceneVoiceConnectRequest request,
  }) async {
    lastConnectedService = service;
    lastConnectRequest = request;
    if (connectError != null) {
      throw connectError!;
    }
  }

  @override
  VoiceChatService createService() {
    createServiceCallCount++;
    return service;
  }

  @override
  void updateSession({
    required VoiceChatService service,
    required SceneVoiceSessionConfig config,
  }) {
    lastUpdatedService = service;
    lastUpdatedConfig = config;
  }
}

class _FakeVoiceChatService extends VoiceChatService {}
