import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/voice_chat_service.dart';

void main() {
  test(
    'legacy scene draft uses local fallback instead of raw AI endpoint',
    () async {
      final Map<String, dynamic> response = await ApiClient.generateSceneDraft(
        prompt: 'Practice explaining a delayed milestone',
        characterProfile: const CharacterProfile(
          name: 'Maya',
          profession: 'Project manager',
        ),
      );

      expect(response['code'], 0);
      final Map<String, dynamic> data =
          response['data'] as Map<String, dynamic>;
      expect(data['title'], 'Practice explaining a delayed milestone');
      expect(data['npcName'], 'Maya');
      expect(data['providerStatus'], 'local_fallback');
    },
  );

  test(
    'legacy translate, summary, and grammar helpers are local-only',
    () async {
      expect(
        await ApiClient.translateTextToChinese('Could we align on Friday?'),
        'Could we align on Friday?',
      );

      final String summary = await ApiClient.generateConversationSummary(
        npcName: 'Maya',
        history: const <Map<String, dynamic>>[
          <String, dynamic>{'role': 'user', 'text': 'The milestone moved.'},
          <String, dynamic>{'role': 'assistant', 'text': 'What changed?'},
        ],
      );
      expect(summary, contains('Maya:'));
      expect(summary, contains('The milestone moved.'));

      final Map<String, dynamic> grammar = await ApiClient.scoreGrammar(
        text: 'I can share the updated plan tomorrow',
        targetText: 'updated plan',
      );
      expect(grammar['provider'], 'local_heuristic');
      expect(grammar['score'], isA<int>());
    },
  );

  test(
    'realtime voice chat is disabled without audited backend gateway',
    () async {
      final VoiceChatService service = VoiceChatService();
      addTearDown(service.dispose);

      await expectLater(
        service.connect(token: 'test-token'),
        throwsA(isA<UnsupportedError>()),
      );
      expect(service.connectionState, 'error');
      expect(service.isConnected, isFalse);
    },
  );
}
