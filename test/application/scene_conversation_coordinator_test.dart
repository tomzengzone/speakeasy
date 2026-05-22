import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/scene/scene_conversation_coordinator.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/app_session.dart';

class MockSceneConversationRemoteApi extends Mock
    implements SceneConversationRemoteApi {}

void main() {
  late MockSceneConversationRemoteApi remoteApi;
  late SceneConversationCoordinator coordinator;

  setUpAll(() {
    registerFallbackValue(
      const SceneDraft(
        title: '场景',
        emoji: '📊',
        tags: <String>[],
        userRole: 'user',
        relationship: 'rel',
        goal: 'goal',
        npcName: 'npc',
        npcRole: 'role',
        environment: 'env',
        challenge: 'challenge',
        plotDesign: 'plot',
      ),
    );
  });

  setUp(() {
    remoteApi = MockSceneConversationRemoteApi();
    coordinator = SceneConversationCoordinator(remoteApi: remoteApi);
  });

  test('sendMessageWithRecovery 会在 session 缺失时重建后重试', () async {
    int recreateCount = 0;
    String? capturedSessionId;

    Future<SceneReply> send({
      required String sessionId,
      required String userText,
      required SceneDraft draft,
      required List<SceneHistoryTurn> history,
    }) async {
      capturedSessionId = sessionId;
      if (sessionId == 'stale-session') {
        throw Exception('session not found');
      }
      return const SceneReply(npcText: 'Recovered reply');
    }

    final SceneReply reply = await coordinator.sendMessageWithRecovery(
      sessionId: 'stale-session',
      recreateSessionId: () async {
        recreateCount += 1;
        return 'fresh-session';
      },
      isSessionMissingError: (Object error) =>
          error.toString().contains('session not found'),
      sendSceneMessage: send,
      userText: 'hello',
      draft: const SceneDraft(
        title: '场景',
        emoji: '📊',
        tags: <String>[],
        userRole: 'user',
        relationship: 'rel',
        goal: 'goal',
        npcName: 'npc',
        npcRole: 'role',
        environment: 'env',
        challenge: 'challenge',
        plotDesign: 'plot',
      ),
      history: const <SceneHistoryTurn>[],
    );

    expect(reply.npcText, 'Recovered reply');
    expect(recreateCount, 1);
    expect(capturedSessionId, 'fresh-session');
  });

  test('generateTurnMeta 会解析返回的 contract 和 state', () async {
    when(
      () => remoteApi.generateSceneTurnMeta(
        draft: any(named: 'draft'),
        history: any(named: 'history'),
        assistantText: any(named: 'assistantText'),
        sceneState: any(named: 'sceneState'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'summary': 'manager sounds calm',
        'coach': '先说核心原因',
        'event': '对方点头',
        'turnContract': <String, dynamic>{
          'stageLabel': 'clarify',
          'questionFocus': 'Why is it delayed?',
          'backgroundFocus': 'review',
          'learnerTaskEn': 'Explain the reason.',
          'learnerGoalZh': '解释延期原因',
          'npcTurnSummary': 'manager asks for a reason',
          'npcTurnInstruction': 'push for concrete reason',
        },
        'sceneState': <String, dynamic>{
          'currentStageId': 'clarify',
          'currentStageLabel': 'Clarify',
          'currentStageIndex': 1,
          'totalStages': 4,
        },
      },
    );

    final SceneTurnMetaResult result = await coordinator.generateTurnMeta(
      draft: const SceneDraft(
        title: '场景',
        emoji: '📊',
        tags: <String>[],
        userRole: 'user',
        relationship: 'rel',
        goal: 'goal',
        npcName: 'npc',
        npcRole: 'role',
        environment: 'env',
        challenge: 'challenge',
        plotDesign: 'plot',
      ),
      history: const <Map<String, dynamic>>[
        <String, dynamic>{'role': 'user', 'text': 'hello'},
      ],
      assistantText: 'Why is it delayed?',
      sceneState: const <String, dynamic>{'currentStageId': 'clarify'},
    );

    expect(result.summary, 'manager sounds calm');
    expect(result.coach, '先说核心原因');
    expect(result.event, '对方点头');
    expect(result.turnContract, isNotNull);
    expect(result.turnContract!.questionFocus, 'Why is it delayed?');
    expect(result.sceneState, isNotNull);
    expect(result.sceneState!.currentStageIndex, 1);
  });
}
