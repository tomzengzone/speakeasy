import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/scene/scene_auxiliary_coordinator.dart';

class MockSceneAuxiliaryRemoteApi extends Mock
    implements SceneAuxiliaryRemoteApi {}

void main() {
  late MockSceneAuxiliaryRemoteApi remoteApi;
  late SceneAuxiliaryCoordinator coordinator;

  setUp(() {
    remoteApi = MockSceneAuxiliaryRemoteApi();
    coordinator = SceneAuxiliaryCoordinator(remoteApi: remoteApi);
  });

  test('translateText 会委托远端翻译接口', () async {
    when(
      () => remoteApi.translateTextToChinese('hello'),
    ).thenAnswer((_) async => '你好');

    final String translated = await coordinator.translateText('hello');

    expect(translated, '你好');
    verify(() => remoteApi.translateTextToChinese('hello')).called(1);
  });

  test(
    'legacyTranscribeLocalAudioForScene 会透传 hintText 和 sceneDraft',
    () async {
      final File audioFile = File('/tmp/audio.wav');
      when(
        () => remoteApi.legacyTranscribeLocalAudioForScene(
          audioFile,
          hintText: 'preview',
          sceneDraft: <String, dynamic>{'title': '场景'},
        ),
      ).thenAnswer((_) async => 'transcript');

      final String transcript = await coordinator
          .legacyTranscribeLocalAudioForScene(
            audioFile,
            hintText: 'preview',
            sceneDraft: <String, dynamic>{'title': '场景'},
          );

      expect(transcript, 'transcript');
      verify(
        () => remoteApi.legacyTranscribeLocalAudioForScene(
          audioFile,
          hintText: 'preview',
          sceneDraft: <String, dynamic>{'title': '场景'},
        ),
      ).called(1);
    },
  );

  test('generateConversationSummary 会透传 history 和 existingSummary', () async {
    when(
      () => remoteApi.generateConversationSummary(
        npcName: 'Maya',
        history: <Map<String, dynamic>>[
          <String, dynamic>{'role': 'user', 'text': 'hello'},
        ],
        existingSummary: 'old summary',
      ),
    ).thenAnswer((_) async => 'new summary');

    final String summary = await coordinator.generateConversationSummary(
      npcName: 'Maya',
      history: <Map<String, dynamic>>[
        <String, dynamic>{'role': 'user', 'text': 'hello'},
      ],
      existingSummary: 'old summary',
    );

    expect(summary, 'new summary');
    verify(
      () => remoteApi.generateConversationSummary(
        npcName: 'Maya',
        history: <Map<String, dynamic>>[
          <String, dynamic>{'role': 'user', 'text': 'hello'},
        ],
        existingSummary: 'old summary',
      ),
    ).called(1);
  });
}
