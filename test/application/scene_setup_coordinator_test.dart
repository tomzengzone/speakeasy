import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/scene/scene_setup_coordinator.dart';
import 'package:speakeasy/features/scenario/scene_runtime_models.dart';
import 'package:speakeasy/models/storage_models.dart';

class MockSceneSetupRemoteApi extends Mock implements SceneSetupRemoteApi {}

class MockSceneVirtualFriendsLocalStore extends Mock
    implements SceneVirtualFriendsLocalStore {}

void main() {
  late MockSceneSetupRemoteApi remoteApi;
  late MockSceneVirtualFriendsLocalStore localStore;
  late SceneSetupCoordinator coordinator;

  setUp(() {
    remoteApi = MockSceneSetupRemoteApi();
    localStore = MockSceneVirtualFriendsLocalStore();
    coordinator = SceneSetupCoordinator(
      remoteApi: remoteApi,
      localStore: localStore,
      now: () => DateTime(2026, 4, 19, 12),
    );
    when(() => localStore.saveVirtualFriends(any())).thenAnswer((_) async {});
  });

  test('loadVirtualFriends 在本地为空时会回退到默认虚拟好友', () async {
    when(
      () => localStore.getVirtualFriends(),
    ).thenReturn(const <VirtualFriendStorageModel>[]);

    final List<VirtualFriendProfile> friends = await coordinator
        .loadVirtualFriends();

    expect(friends, hasLength(4));
    expect(friends.first.name, 'Maya');
    expect(friends[1].name, 'Luna');
    expect(friends[2].name, 'Ethan');
    expect(friends[3].name, 'Yuna');
  });

  test('saveVirtualFriends 会将运行时模型转换为存储模型后写入本地', () async {
    final VirtualFriendProfile friend = VirtualFriendProfile(
      id: 'friend_custom',
      name: 'Chris',
      avatarEmoji: '🙂',
      role: '同事',
      personality: '直接',
      profession: '设计师',
      hobbies: <String>['摄影'],
      relationship: '一起推进项目',
      preferredScene: '同步设计评审',
      lastMessage: 'Can you show me the latest version?',
      isCustom: true,
      updatedAt: DateTime(2026, 4, 19, 11),
    );

    await coordinator.saveVirtualFriends(<VirtualFriendProfile>[friend]);

    verify(
      () => localStore.saveVirtualFriends(
        any(
          that: isA<List<VirtualFriendStorageModel>>().having(
            (List<VirtualFriendStorageModel> value) => value.single.name,
            'name',
            'Chris',
          ),
        ),
      ),
    ).called(1);
  });

  test('generateDraft 会结合远端返回和好友信息生成完整草稿', () async {
    when(
      () => remoteApi.generateSceneDraft(
        prompt: '模拟一个合作沟通场景',
        characterProfile: any(named: 'characterProfile'),
        desiredOutcome: any(named: 'desiredOutcome'),
      ),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'title': '推进合作方案',
          'goal': '清晰介绍方案并确认下一步。',
          'environment': '视频会议',
        },
      },
    );

    final VirtualFriendProfile friend = VirtualFriendProfile(
      id: 'friend_luna_client',
      name: 'Luna',
      avatarEmoji: '🤝',
      role: '潜在合作客户',
      personality: '礼貌、挑剔、重细节',
      profession: '品牌市场负责人',
      hobbies: <String>['展览', '咖啡'],
      relationship: '你需要和她推进合作，但她会很关注专业度和响应速度。',
      preferredScene: '第一次开场并推进合作需求',
      lastMessage: '你们这次方案和上一版相比，最大的变化是什么？',
      isCustom: false,
      updatedAt: DateTime(2026, 4, 19, 10),
    );

    final draft = await coordinator.generateDraft(
      prompt: '模拟一个合作沟通场景',
      activeFriend: friend,
    );

    expect(draft, isNotNull);
    expect(draft!.title, '推进合作方案');
    expect(draft.npcName, 'Luna');
    expect(draft.npcRole, '品牌市场负责人');
    expect(draft.relationship, '你需要和她推进合作，但她会很关注专业度和响应速度。');
    expect(draft.sceneSpec, isNotNull);
    expect(draft.sceneBlueprint, isNotNull);
  });
}
