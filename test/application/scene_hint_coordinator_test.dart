import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/scene/scene_hint_coordinator.dart';
import 'package:speakeasy/features/scenario/scene_runtime_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';

class MockSceneHintRemoteApi extends Mock implements SceneHintRemoteApi {}

void main() {
  late MockSceneHintRemoteApi remoteApi;
  late SceneHintCoordinator coordinator;

  setUp(() {
    remoteApi = MockSceneHintRemoteApi();
    coordinator = SceneHintCoordinator(remoteApi: remoteApi);
  });

  test('generateHint 会创建 helper session 并返回 refined hint', () async {
    when(
      () => remoteApi.createAiSessionData(
        sceneTitle: any(named: 'sceneTitle'),
        sceneGoal: any(named: 'sceneGoal'),
        userRole: any(named: 'userRole'),
        relationship: any(named: 'relationship'),
        npcName: any(named: 'npcName'),
        npcRole: any(named: 'npcRole'),
        environment: any(named: 'environment'),
        challenge: any(named: 'challenge'),
        sceneSpec: any(named: 'sceneSpec'),
        sceneBlueprint: any(named: 'sceneBlueprint'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{'sessionId': 'hint-session'});
    when(
      () => remoteApi.sendSceneMessage(
        'hint-session',
        any(),
        draft: any(named: 'draft'),
        history: any(named: 'history'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'reply':
            '{"starter":"I think the main issue is the timeline.","sample":"I think the main issue is the timeline, and I want to explain how we will fix it.","keywords":["timeline","fix","next step"]}',
      },
    );

    final SceneResponseHint? hint = await coordinator.generateHint(
      SceneHintRequest(
        draft: const SceneDraft(
          title: '解释项目延期',
          emoji: '📊',
          tags: <String>['AI 定制'],
          userRole: '项目负责人',
          relationship: '向项目经理汇报项目进展的内部协作关系',
          goal: '清楚解释项目延期原因，并稳住对方预期。',
          npcName: 'Maya',
          npcRole: '项目经理',
          environment: '周会汇报',
          challenge: '对方会追问延期影响和补救方案。',
          plotDesign: '先说明当前延期现状；再解释延期原因；接着给出补救动作；最后锁定负责人和时间点。',
        ),
        contract: const SceneTurnRuntimeContract(
          stageLabel: 'clarify',
          questionFocus: 'Why is the timeline delayed?',
          backgroundFocus: 'Internal project review',
          learnerTaskEn: 'Explain the key cause clearly.',
          learnerGoalZh: '说明延期原因并稳住对方预期',
          npcTurnSummary: 'The manager asks about the delay.',
          npcTurnInstruction: 'Push for a concrete explanation.',
          keywords: <String>['delay', 'cause'],
          starter: 'The main reason is ...',
          sampleAnswer: 'The main reason is that one dependency slipped.',
        ),
        fallbackHint: const SceneResponseHint(
          stageLabel: 'clarify',
          questionFocus: 'Why is the timeline delayed?',
          backgroundFocus: 'Internal project review',
          goalHint: '说明延期原因并稳住对方预期',
          keywords: <String>['delay', 'cause'],
          starter: 'The main reason is ...',
          sampleAnswer: 'The main reason is that one dependency slipped.',
        ),
        recentTurns: const <SceneHistoryTurn>[
          SceneHistoryTurn(role: 'npc', text: 'Why is the timeline delayed?'),
        ],
      ),
    );

    expect(hint, isNotNull);
    expect(hint!.starter, 'I think the main issue is the timeline.');
    expect(hint.sampleAnswer, contains('fix'));
    expect(hint.keywords, <String>['timeline', 'fix', 'next step']);
    verify(
      () => remoteApi.createAiSessionData(
        sceneTitle: any(named: 'sceneTitle'),
        sceneGoal: any(named: 'sceneGoal'),
        userRole: any(named: 'userRole'),
        relationship: any(named: 'relationship'),
        npcName: any(named: 'npcName'),
        npcRole: any(named: 'npcRole'),
        environment: any(named: 'environment'),
        challenge: any(named: 'challenge'),
        sceneSpec: any(named: 'sceneSpec'),
        sceneBlueprint: any(named: 'sceneBlueprint'),
      ),
    ).called(1);
  });

  test('generateHint 在 reply 不是合法 JSON 时返回 null', () async {
    when(
      () => remoteApi.createAiSessionData(
        sceneTitle: any(named: 'sceneTitle'),
        sceneGoal: any(named: 'sceneGoal'),
        userRole: any(named: 'userRole'),
        relationship: any(named: 'relationship'),
        npcName: any(named: 'npcName'),
        npcRole: any(named: 'npcRole'),
        environment: any(named: 'environment'),
        challenge: any(named: 'challenge'),
        sceneSpec: any(named: 'sceneSpec'),
        sceneBlueprint: any(named: 'sceneBlueprint'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{'sessionId': 'hint-session'});
    when(
      () => remoteApi.sendSceneMessage(
        'hint-session',
        any(),
        draft: any(named: 'draft'),
        history: any(named: 'history'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{'reply': 'not json'});

    final SceneResponseHint? hint = await coordinator.generateHint(
      SceneHintRequest(
        draft: const SceneDraft(
          title: '解释项目延期',
          emoji: '📊',
          tags: <String>[],
          userRole: '项目负责人',
          relationship: '内部协作关系',
          goal: '解释原因',
          npcName: 'Maya',
          npcRole: '项目经理',
          environment: '周会汇报',
          challenge: '对方会追问',
          plotDesign: '先说明问题，再给动作。',
        ),
        contract: const SceneTurnRuntimeContract(
          stageLabel: 'clarify',
          questionFocus: 'Why?',
          backgroundFocus: 'review',
          learnerTaskEn: 'Explain it',
          learnerGoalZh: '解释原因',
          npcTurnSummary: 'manager asks why',
          npcTurnInstruction: 'push',
          keywords: <String>['reason'],
          starter: 'The main reason is ...',
          sampleAnswer: 'The main reason is ...',
        ),
        fallbackHint: const SceneResponseHint(
          stageLabel: 'clarify',
          questionFocus: 'Why?',
          backgroundFocus: 'review',
          goalHint: '解释原因',
          keywords: <String>['reason'],
          starter: 'The main reason is ...',
          sampleAnswer: 'The main reason is ...',
        ),
        recentTurns: const <SceneHistoryTurn>[],
      ),
    );

    expect(hint, isNull);
  });
}
