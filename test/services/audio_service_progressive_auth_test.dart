import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/authenticated_request_executor.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _MockFlutterTts extends Mock implements FlutterTts {}

class _ProgressiveSecurityAudioService extends AudioService {
  _ProgressiveSecurityAudioService({
    required AudioPlayer player,
    required AudioPlayer feedbackPlayer,
    required FlutterTts systemTts,
  }) : super(
         player: player,
         feedbackPlayer: feedbackPlayer,
         systemTts: systemTts,
       );

  int requestCalls = 0;
  bool siblingObservedCancellation = false;

  @override
  Future<String?> createTtsAudioFile(
    String text, {
    String? voice,
    int maxAttempts = 2,
    Duration requestTimeout = const Duration(seconds: 20),
    RequestCancellationToken? cancellation,
  }) async {
    requestCalls += 1;
    if (requestCalls == 1) {
      throw const SessionSecurityFailure(
        reason: SessionSecurityReason.sessionRevoked,
        backendCode: 'SESSION_REVOKED',
        userMessage: '请重新登录',
      );
    }
    await cancellation!.whenCancelled;
    siblingObservedCancellation = true;
    throw const RequestCancelledException();
  }
}

void main() {
  testWidgets(
    'progressive TTS cancels and drains prefetched siblings on auth failure',
    (WidgetTester tester) async {
      final _MockAudioPlayer player = _MockAudioPlayer();
      final _MockAudioPlayer feedbackPlayer = _MockAudioPlayer();
      final _MockFlutterTts systemTts = _MockFlutterTts();
      when(player.stop).thenAnswer((_) async {});
      when(player.dispose).thenAnswer((_) async {});
      when(feedbackPlayer.dispose).thenAnswer((_) async {});
      when(systemTts.stop).thenAnswer((_) async => 1);
      when(() => systemTts.setLanguage(any())).thenAnswer((_) async => 1);
      when(() => systemTts.setSpeechRate(any())).thenAnswer((_) async => 1);
      when(() => systemTts.setVolume(any())).thenAnswer((_) async => 1);
      final _ProgressiveSecurityAudioService service =
          _ProgressiveSecurityAudioService(
            player: player,
            feedbackPlayer: feedbackPlayer,
            systemTts: systemTts,
          );

      await expectLater(
        service.playTtsProgressiveBackend(
          '第一段语音内容用于触发并发预取并覆盖认证终止错误处理，这一段长度足够形成独立分块。'
          '第二段语音内容会作为兄弟请求提前启动，并且必须在首段认证失败时收到取消信号。',
          prefetchAllChunks: true,
        ),
        throwsA(
          isA<SessionSecurityFailure>().having(
            (SessionSecurityFailure failure) => failure.backendCode,
            'backendCode',
            'SESSION_REVOKED',
          ),
        ),
      );

      expect(service.requestCalls, greaterThanOrEqualTo(2));
      expect(service.siblingObservedCancellation, isTrue);
    },
  );
}
