import 'package:speakeasy/features/scenario/scene_runtime_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/storage_service.dart';

abstract class SceneSetupRemoteApi {
  Future<Map<String, dynamic>> generateSceneDraft({
    required String prompt,
    CharacterProfile? characterProfile,
    String? desiredOutcome,
  });

  Future<Map<String, dynamic>> createAiSessionData({
    required String sceneTitle,
    required String sceneGoal,
    String? roleId,
    CharacterProfile? characterProfile,
    String? discussionTopic,
    String? desiredOutcome,
    String? userRole,
    String? relationship,
    required String npcName,
    required String npcRole,
    required String environment,
    required String challenge,
    SceneSpec? sceneSpec,
    SceneBlueprint? sceneBlueprint,
  });
}

class ApiClientSceneSetupRemoteApi implements SceneSetupRemoteApi {
  const ApiClientSceneSetupRemoteApi();

  @override
  Future<Map<String, dynamic>> createAiSessionData({
    required String sceneTitle,
    required String sceneGoal,
    String? roleId,
    CharacterProfile? characterProfile,
    String? discussionTopic,
    String? desiredOutcome,
    String? userRole,
    String? relationship,
    required String npcName,
    required String npcRole,
    required String environment,
    required String challenge,
    SceneSpec? sceneSpec,
    SceneBlueprint? sceneBlueprint,
  }) {
    return ApiClient.createAiSessionData(
      sceneTitle: sceneTitle,
      sceneGoal: sceneGoal,
      roleId: roleId,
      characterProfile: characterProfile,
      discussionTopic: discussionTopic,
      desiredOutcome: desiredOutcome,
      userRole: userRole,
      relationship: relationship,
      npcName: npcName,
      npcRole: npcRole,
      environment: environment,
      challenge: challenge,
      sceneSpec: sceneSpec,
      sceneBlueprint: sceneBlueprint,
    );
  }

  @override
  Future<Map<String, dynamic>> generateSceneDraft({
    required String prompt,
    CharacterProfile? characterProfile,
    String? desiredOutcome,
  }) {
    return ApiClient.generateSceneDraft(
      prompt: prompt,
      characterProfile: characterProfile,
      desiredOutcome: desiredOutcome,
    );
  }
}

abstract class SceneVirtualFriendsLocalStore {
  List<VirtualFriendStorageModel> getVirtualFriends();

  Future<void> saveVirtualFriends(List<VirtualFriendStorageModel> friends);
}

class StorageServiceSceneVirtualFriendsLocalStore
    implements SceneVirtualFriendsLocalStore {
  const StorageServiceSceneVirtualFriendsLocalStore();

  @override
  List<VirtualFriendStorageModel> getVirtualFriends() {
    return StorageService.instance.getVirtualFriends();
  }

  @override
  Future<void> saveVirtualFriends(List<VirtualFriendStorageModel> friends) {
    return StorageService.instance.saveVirtualFriends(friends);
  }
}

class SceneSetupCoordinator {
  SceneSetupCoordinator({
    SceneSetupRemoteApi remoteApi = const ApiClientSceneSetupRemoteApi(),
    SceneVirtualFriendsLocalStore localStore =
        const StorageServiceSceneVirtualFriendsLocalStore(),
    DateTime Function()? now,
  }) : _remoteApi = remoteApi,
       _localStore = localStore,
       _now = now ?? DateTime.now;

  final SceneSetupRemoteApi _remoteApi;
  final SceneVirtualFriendsLocalStore _localStore;
  final DateTime Function() _now;

  Future<List<VirtualFriendProfile>> loadVirtualFriends() async {
    final List<VirtualFriendStorageModel> stored = _localStore
        .getVirtualFriends();
    if (stored.isEmpty) {
      return defaultVirtualFriends();
    }
    return stored
        .map(VirtualFriendProfile.fromStorage)
        .where((VirtualFriendProfile friend) => friend.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveVirtualFriends(List<VirtualFriendProfile> friends) {
    return _localStore.saveVirtualFriends(
      friends
          .map((VirtualFriendProfile friend) => friend.toStorage())
          .toList(growable: false),
    );
  }

  List<VirtualFriendProfile> defaultVirtualFriends() {
    final DateTime now = _now();
    return <VirtualFriendProfile>[
      VirtualFriendProfile(
        id: 'friend_maya_pm',
        name: 'Maya',
        avatarEmoji: '📊',
        role: '项目推进搭子',
        personality: '直接、理性、会追问',
        profession: '项目经理',
        hobbies: const <String>['徒步', '做计划'],
        relationship: '你正在向她同步项目进度，她希望你说清风险和方案。',
        preferredScene: '解释延期并重新对齐下一步',
        lastMessage: '今晚的里程碑你准备怎么跟我更新？',
        isCustom: false,
        updatedAt: now.subtract(const Duration(minutes: 8)),
      ),
      VirtualFriendProfile(
        id: 'friend_luna_client',
        name: 'Luna',
        avatarEmoji: '🤝',
        role: '潜在合作客户',
        personality: '礼貌、挑剔、重细节',
        profession: '品牌市场负责人',
        hobbies: const <String>['展览', '咖啡'],
        relationship: '你需要和她推进合作，但她会很关注专业度和响应速度。',
        preferredScene: '第一次开场并推进合作需求',
        lastMessage: '你们这次方案和上一版相比，最大的变化是什么？',
        isCustom: false,
        updatedAt: now.subtract(const Duration(hours: 2, minutes: 16)),
      ),
      VirtualFriendProfile(
        id: 'friend_ethan_hr',
        name: 'Ethan',
        avatarEmoji: '💼',
        role: '英文面试官',
        personality: '克制、专业、追结果',
        profession: '招聘经理',
        hobbies: const <String>['网球', '播客'],
        relationship: '你要在面试里迅速建立可信度，并给出结构化回答。',
        preferredScene: '英文电话面试和追问',
        lastMessage: 'Can you walk me through a project you owned end to end?',
        isCustom: false,
        updatedAt: now.subtract(const Duration(hours: 5, minutes: 40)),
      ),
      VirtualFriendProfile(
        id: 'friend_yuna_social',
        name: 'Yuna',
        avatarEmoji: '🌿',
        role: '社交聊天对象',
        personality: '温柔、松弛、会接话',
        profession: '独立插画师',
        hobbies: const <String>['Citywalk', '摄影', '甜品'],
        relationship: '你想把闲聊延续下去，不想聊两句就冷场。',
        preferredScene: '自然寒暄并延展新话题',
        lastMessage: '我刚从上海回来，你最近有发现什么好玩的地方吗？',
        isCustom: false,
        updatedAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
    ];
  }

  SceneDraft draftFromVirtualFriend(VirtualFriendProfile friend) {
    final CharacterProfile characterProfile = friend.toCharacterProfile();
    final String roleLabel = friend.profession.trim().isNotEmpty
        ? friend.profession.trim()
        : friend.role.trim();
    final String preferredScene = friend.preferredScene.trim().isNotEmpty
        ? friend.preferredScene.trim()
        : '围绕 ${friend.name} 发起一轮自然对话';
    final String hobbiesText = friend.hobbies.isEmpty
        ? '日常交流'
        : friend.hobbies.take(3).join('、');
    return withSceneSpec(
      SceneDraft(
        title: preferredScene,
        emoji: friend.avatarEmoji.isEmpty ? '🙂' : friend.avatarEmoji,
        tags: <String>[
          '虚拟角色',
          if (roleLabel.isNotEmpty) roleLabel,
          if (friend.personality.trim().isNotEmpty) friend.personality.trim(),
        ],
        roleId: friend.id,
        characterProfile: characterProfile,
        discussionTopic: preferredScene,
        desiredOutcome: '和${friend.name}围绕当前话题完成一轮自然、持续推进的英文交流。',
        userRole: '主动发起对话的人',
        relationship: friend.relationship.trim().isNotEmpty
            ? friend.relationship.trim()
            : '你和 ${friend.name} 正在进入一段新的英文对话。',
        goal: '根据 ${friend.name} 的角色设定完成一轮自然、真实的英文交流。',
        npcName: friend.name,
        npcRole: roleLabel.isEmpty ? '虚拟角色' : roleLabel,
        environment: preferredScene,
        challenge:
            '对方的性格偏${friend.personality.trim().isEmpty ? '自然真实' : friend.personality.trim()}，兴趣点包括 $hobbiesText。',
        plotDesign: '先自然破冰；再围绕角色设定展开话题；接着推进当前目标；最后把对话带到下一步。',
      ),
    );
  }

  String promptForVirtualFriend(
    VirtualFriendProfile friend, {
    String? sceneFocus,
  }) {
    final String preferredScene = (sceneFocus ?? friend.preferredScene).trim();
    final String hobbiesText = friend.hobbies.isEmpty
        ? '无特别指定'
        : friend.hobbies.join('、');
    return [
      '请帮我围绕一个虚拟角色生成英文对话场景。',
      '角色名：${friend.name}',
      '对方角色：${friend.role}',
      '职业：${friend.profession}',
      '性格：${friend.personality}',
      '爱好：$hobbiesText',
      '我们关系：${friend.relationship}',
      if (preferredScene.isNotEmpty) '本次想讨论的话题：$preferredScene',
      if (friend.lastMessage.trim().isNotEmpty)
        '参考开场：${friend.lastMessage.trim()}',
      '请让角色设定体现在语气、推进方式和追问风格里。',
    ].join('\n');
  }

  SceneDraft fallbackDraftForPrompt({
    required String prompt,
    VirtualFriendProfile? activeFriend,
  }) {
    final String normalized = prompt.trim();
    if (activeFriend != null) {
      final SceneDraft base = draftFromVirtualFriend(activeFriend);
      return withSceneSpec(
        SceneDraft(
          title: normalized.isEmpty ? base.title : normalized,
          emoji: base.emoji,
          tags: base.tags,
          roleId: base.roleId,
          characterProfile: base.characterProfile,
          discussionTopic: normalized.isEmpty
              ? base.discussionTopic
              : normalized,
          desiredOutcome: base.desiredOutcome,
          userRole: base.userRole,
          relationship: base.relationship,
          goal: base.goal,
          npcName: base.npcName,
          npcRole: base.npcRole,
          environment: base.environment,
          challenge: base.challenge,
          plotDesign: base.plotDesign,
          sceneSpec: base.sceneSpec,
          sceneBlueprint: base.sceneBlueprint,
        ),
      );
    }
    final SceneDraft base = SceneDraft(
      title: normalized,
      emoji: inferSceneEmoji(normalized),
      tags: const <String>['AI 定制', '口语练习', '沉浸式'],
      discussionTopic: normalized,
      desiredOutcome: '围绕当前话题完成一轮自然、持续推进的英文交流。',
      userRole: '沟通发起方',
      relationship: '需要向对方说明情况并争取理解的工作关系',
      goal: '在真实语境里表达核心信息，并稳住对方情绪。',
      npcName: 'Maya',
      npcRole: '项目经理',
      environment: '工作会议',
      challenge: '对方会继续追问具体影响、下一步动作和承诺时间。',
      plotDesign: '先说明当前核心情况；再解释关键原因；接着给出一个具体动作；最后锁定下一步和时间点。',
    );
    return withSceneSpec(base);
  }

  Future<SceneDraft?> generateDraft({
    required String prompt,
    VirtualFriendProfile? activeFriend,
  }) async {
    final CharacterProfile? characterProfile = activeFriend?.toCharacterProfile();
    final Map<String, dynamic> response = await _remoteApi.generateSceneDraft(
      prompt: prompt,
      characterProfile: characterProfile,
      desiredOutcome: activeFriend == null
          ? null
          : '让 ${activeFriend.name} 保持角色一致，并围绕当前话题完成一轮自然推进的讨论。',
    );
    final Map<String, dynamic> data = asMap(response['data']);
    if (response['code'] != 0 || data.isEmpty) {
      return null;
    }
    return sceneDraftFromApi(
      data,
      fallbackPrompt: prompt,
      activeFriend: activeFriend,
    );
  }

  Future<Map<String, dynamic>> createSceneSessionData({
    required SceneDraft draft,
  }) {
    final SceneDraft resolvedDraft = withSceneSpec(
      draft,
      previousSpec: draft.sceneSpec,
      previousBlueprint: draft.sceneBlueprint,
    );
    return _remoteApi.createAiSessionData(
      sceneTitle: resolvedDraft.title,
      sceneGoal: resolvedDraft.goal,
      roleId: resolvedDraft.roleId,
      characterProfile: resolvedDraft.characterProfile,
      discussionTopic: resolvedDraft.discussionTopic,
      desiredOutcome: resolvedDraft.desiredOutcome,
      userRole: resolvedDraft.userRole,
      relationship: resolvedDraft.relationship,
      npcName: resolvedDraft.npcName,
      npcRole: resolvedDraft.npcRole,
      environment: resolvedDraft.environment,
      challenge: resolvedDraft.challenge,
      sceneSpec: resolvedDraft.sceneSpec,
      sceneBlueprint: resolvedDraft.sceneBlueprint,
    );
  }

  SceneDraft sceneDraftFromApi(
    Map<String, dynamic> data, {
    required String fallbackPrompt,
    VirtualFriendProfile? activeFriend,
  }) {
    String readValue(String key, String fallback) {
      final String value = (data[key] as String? ?? '').trim();
      return value.isEmpty ? fallback : value;
    }

    final SceneSpec? parsedSpec = parseSceneSpec(data['sceneSpec']);
    final SceneBlueprint? parsedBlueprint = parseSceneBlueprint(
      data['sceneBlueprint'],
    );
    final Map<String, dynamic> parsedCharacterProfileData = asMap(
      data['characterProfile'],
    );
    final CharacterProfile? parsedCharacterProfile =
        parsedCharacterProfileData.isEmpty
        ? activeFriend?.toCharacterProfile()
        : CharacterProfile.fromJson(parsedCharacterProfileData);
    final String title = readValue('title', fallbackPrompt);
    final List<String> tags = ((data['tags'] as List<dynamic>?) ?? const [])
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);

    final SceneDraft base = SceneDraft(
      title: title,
      emoji: inferSceneEmoji(title),
      tags: tags.isEmpty ? const <String>['AI 定制', '口语练习', '沉浸式'] : tags,
      userRole: readValue('userRole', '沟通发起方'),
      roleId: readValue('roleId', activeFriend?.id ?? ''),
      characterProfile: parsedCharacterProfile,
      discussionTopic: readValue(
        'discussionTopic',
        fallbackPrompt,
      ),
      desiredOutcome: readValue(
        'desiredOutcome',
        activeFriend == null
            ? '在真实语境里表达核心信息，并稳住对方情绪。'
            : '让角色保持稳定设定，并围绕当前话题推进对话。',
      ),
      relationship: readValue(
        'relationship',
        activeFriend?.relationship.trim().isNotEmpty == true
            ? activeFriend!.relationship.trim()
            : '需要向对方说明情况并争取理解的工作关系',
      ),
      goal: readValue('goal', '在真实语境里表达核心信息，并稳住对方情绪。'),
      npcName: readValue('npcName', activeFriend?.name ?? 'Maya'),
      npcRole: readValue(
        'npcRole',
        activeFriend?.profession.trim().isNotEmpty == true
            ? activeFriend!.profession.trim()
            : activeFriend?.role ?? '项目经理',
      ),
      environment: readValue('environment', '工作会议'),
      challenge: readValue(
        'challenge',
        activeFriend == null
            ? '对方会继续追问具体影响、下一步动作和承诺时间。'
            : '对方会带着${activeFriend.personality.trim().isEmpty ? '自己的风格' : activeFriend.personality.trim()}继续追问，并把话题拉回角色设定。',
      ),
      plotDesign: readValue(
        'plotDesign',
        '先说明当前核心情况；再解释关键原因；接着给出一个具体动作；最后锁定下一步和时间点。',
      ),
      sceneBlueprint: parsedBlueprint,
    );
    return withSceneSpec(
      base,
      previousSpec: parsedSpec,
      previousBlueprint: parsedBlueprint,
    );
  }

  SceneSpec? parseSceneSpec(dynamic value) {
    final Map<String, dynamic> data = asMap(value);
    if (data.isEmpty) {
      return null;
    }
    return SceneSpec.fromJson(data);
  }

  SceneBlueprint? parseSceneBlueprint(dynamic value) {
    final Map<String, dynamic> data = asMap(value);
    if (data.isEmpty) {
      return null;
    }
    return SceneBlueprint.fromJson(data);
  }

  SceneDraft withSceneSpec(
    SceneDraft draft, {
    SceneSpec? previousSpec,
    SceneBlueprint? previousBlueprint,
  }) {
    final SceneSpec nextSpec = SceneSpec.fromDraft(
      draft,
      previousSpec: previousSpec ?? draft.sceneSpec,
    );
    final SceneBlueprint nextBlueprint = SceneBlueprint.fromDraft(
      draft,
      sceneSpec: nextSpec,
      previousBlueprint: previousBlueprint ?? draft.sceneBlueprint,
    );
    return SceneDraft(
      title: draft.title,
      emoji: draft.emoji,
      tags: draft.tags,
      roleId: draft.roleId,
      characterProfile: draft.characterProfile,
      discussionTopic: draft.discussionTopic,
      desiredOutcome: draft.desiredOutcome,
      userRole: draft.userRole,
      relationship: draft.relationship,
      goal: draft.goal,
      npcName: draft.npcName,
      npcRole: draft.npcRole,
      environment: draft.environment,
      challenge: draft.challenge,
      plotDesign: nextSpec.plotDesign,
      sceneSpec: nextSpec,
      sceneBlueprint: nextBlueprint,
    );
  }

  Map<String, dynamic> asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }

  String inferSceneEmoji(String text) {
    if (text.contains('面试')) return '💼';
    if (text.contains('老板') || text.contains('项目')) return '📊';
    if (text.contains('客户')) return '🤝';
    if (text.contains('电话')) return '☎️';
    return '🗣️';
  }
}
