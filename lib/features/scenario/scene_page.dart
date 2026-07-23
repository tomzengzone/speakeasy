import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:speakeasy/application/scene/scene_auxiliary_coordinator.dart';
import 'package:speakeasy/application/scene/scene_conversation_coordinator.dart';
import 'package:speakeasy/application/scene/scene_hint_coordinator.dart';
import 'package:speakeasy/application/scene/scene_runtime_support_coordinator.dart';
import 'package:speakeasy/application/scene/scene_setup_coordinator.dart';
import 'package:speakeasy/application/scene/scene_voice_session_binding_coordinator.dart';
import 'package:speakeasy/application/scene/scene_voice_session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/scene/scene_voice_runtime_coordinator.dart';
import 'package:speakeasy/application/scene/scene_voice_turn_rules_coordinator.dart';
import 'package:speakeasy/application/scene/scene_voice_user_turn_coordinator.dart';
import 'package:speakeasy/features/scenario/scene_runtime_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/voice_chat_service.dart';
import 'package:speakeasy/services/voice_turn_orchestrator.dart';
import 'package:speakeasy/l10n/l10n.dart';

part 'scene_logic.dart';
part 'scene_widgets.dart';

enum SceneFlowView { home, create, draft, edit, chat, feedback }

enum _VoiceSessionMode { none, realtime, turnBased }

typedef _RecentScene = RecentSceneSummary;
typedef _VirtualFriend = VirtualFriendProfile;
typedef _SceneAgendaCue = SceneAgendaCue;
typedef _SceneFeedbackRequestData = SceneFeedbackRequestData;
typedef _SceneHintTemplate = SceneHintTemplate;
typedef _SceneResponseHint = SceneResponseHint;
typedef _SceneTurnContract = SceneTurnRuntimeContract;
typedef _ServiceSlot = ServiceSlot;
typedef _ServiceNextNpcAction = ServiceNextNpcAction;
typedef _ServiceDialogueState = ServiceDialogueState;
typedef _ServicePolicyDecision = ServicePolicyDecision;
typedef _ServiceTurnTrace = ServiceTurnTrace;
typedef _ChatInputType = SceneChatInputType;
typedef _MessageRole = SceneMessageRole;
typedef _ChatMessage = SceneChatMessage;

class ScenePage extends StatefulWidget {
  const ScenePage({super.key, this.onBottomBarVisibilityChanged});

  final ValueChanged<bool>? onBottomBarVisibilityChanged;

  @override
  State<ScenePage> createState() => _ScenePageState();
}
class _ScenePageState extends State<ScenePage> {
  final SceneAuxiliaryCoordinator _sceneAuxiliaryCoordinator =
      const SceneAuxiliaryCoordinator();
  final SceneConversationCoordinator _sceneConversationCoordinator =
      const SceneConversationCoordinator();
  final SceneHintCoordinator _sceneHintCoordinator = SceneHintCoordinator();
  final SceneRuntimeSupportCoordinator _sceneRuntimeSupportCoordinator =
      const SceneRuntimeSupportCoordinator();
  final SceneSetupCoordinator _sceneSetupCoordinator = SceneSetupCoordinator();
  final SceneVoiceSessionBindingCoordinator
  _sceneVoiceSessionBindingCoordinator =
      const SceneVoiceSessionBindingCoordinator();
  final SceneVoiceSessionLifecycleCoordinator
  _sceneVoiceSessionLifecycleCoordinator =
      const SceneVoiceSessionLifecycleCoordinator();
  final SceneVoiceRuntimeCoordinator _sceneVoiceRuntimeCoordinator =
      const SceneVoiceRuntimeCoordinator();
  final SceneVoiceTurnRulesCoordinator _sceneVoiceTurnRulesCoordinator =
      const SceneVoiceTurnRulesCoordinator();
  final SceneVoiceUserTurnCoordinator _sceneVoiceUserTurnCoordinator =
      const SceneVoiceUserTurnCoordinator();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _friendSearchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final FocusNode _scenePromptFocusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  List<_VirtualFriend> _virtualFriends = <_VirtualFriend>[];

  SceneFlowView _view = SceneFlowView.home;
  int _activePromptIndex = 0;
  String? _activeFriendId;
  bool _inputFocused = false;
  bool _isLoadingVirtualFriends = true;
  bool _isHomeSpeechRecording = false;
  bool _isRecording = false;
  bool _isNpcThinking = false;
  bool _isDraftGenerating = false;
  bool _isStartingConversation = false;
  bool _scenePracticePendingRecorded = false;
  bool _showHintReferenceAnswer = false;
  SceneFeedback? _feedback;
  bool _isFeedbackLoading = false;
  bool _chatRecordingWillCancel = false;
  bool _showTextComposer = false;
  String? _chatSpeechLocaleId;
  String _chatRecordingPreviewText = '';
  String _chatRecordingHintText = '';
  bool _chatSpeechPreviewUnavailable = false;
  Timer? _chatSpeechPreviewRestartTimer;
  int _chatSpeechPreviewGeneration = 0;
  VoiceChatService? _chatPreviewVoiceService;
  StreamSubscription<String>? _chatPreviewConnSub;
  StreamSubscription<String>? _chatPreviewTextSub;
  StreamSubscription<String>? _chatPreviewFinalSub;
  Completer<String>? _chatPreviewTranscriptCompleter;
  int _chatPreviewSentChunkCount = 0;
  int? _expandedCoachMessageIndex;
  bool _showCoachAssistant = false;
  bool _realtimeMode = false;
  VoiceChatService? _voiceChatService;
  bool _voiceChatConnecting = false;
  late AudioService _realtimeAudioService;
  bool _hasRealtimeAudioService = false;
  bool _isAiSpeaking = false;
  bool _isFinalizingAiTurn = false;
  int _realtimeCallGeneration = 0;
  _VoiceSessionMode _voiceSessionMode = _VoiceSessionMode.none;
  final VoiceTurnOrchestrator _voiceTurnOrchestrator = VoiceTurnOrchestrator(
    signalDelay: _voiceFinalizeSignalDelay,
  );
  StreamSubscription<String>? _voiceChatConnSub;
  StreamSubscription<VoiceChatTurnEvent>? _voiceChatTurnEventSub;
  StreamSubscription<VoiceAssistantTurnReady>? _voiceTurnReadySub;
  final List<Uint8List> _pendingTurnVoiceChunks = <Uint8List>[];
  List<Uint8List>? _queuedTurnVoiceChunks;
  int _pendingVoiceMessageDuration = 3;
  String _lastRealtimeNpcText = '';
  bool _awaitingUserReplyForLastNpc = false;
  String _sessionId = '';
  SceneTurnContract? _serverTurnContract;
  SceneStateSnapshot? _serverSceneState;
  List<String> _sceneRoleMemoryHints = const <String>[];
  List<String> _sceneLearningProfileHints = const <String>[];
  final Set<int> _expandedVoiceMessageIndexes = <int>{};
  final Map<int, String> _voiceMessageTranslations = <int, String>{};
  final Set<int> _translatedVoiceMessageIndexes = <int>{};
  final Set<int> _translatingVoiceMessageIndexes = <int>{};
  final List<Uint8List> _pendingRealtimeUserVoiceChunks = <Uint8List>[];
  SceneDraft _draft = sampleSceneDraft;
  Timer? _promptTimer;
  Timer? _mockInputTimer;
  bool _scenePracticeRecorded = false;
  String? _lastAutoPlayedOpeningText;
  String? _lastFeedbackError;
  String? _feedbackCacheKey;
  String? _feedbackPendingKey;
  String? _feedbackCompletionAnnouncedKey;
  int _feedbackTaskGeneration = 0;
  DateTime? _feedbackStartedAt;
  _SceneFeedbackRequestData? _restoredFeedbackRequestData;
  bool _feedbackOpenedFromRecentSummary = false;
  final List<_ServiceTurnTrace> _serviceTurnTraces = <_ServiceTurnTrace>[];
  final Map<String, _SceneResponseHint> _llmHintCache =
      <String, _SceneResponseHint>{};
  final Set<String> _llmHintLoadingKeys = <String>{};

  // --- 对话摘要机制 ---
  static const int _recentHistoryKeepCount = 8;
  static const int _summaryTriggerThreshold = 4;
  String? _conversationSummary;
  int _summaryLastTurnCount = 0;
  bool _summaryGenerating = false;
  String _homeSpeechBaseText = '';
  String? _homeSpeechLocaleId;
  static const Duration _voiceFinalizeSignalDelay = Duration(milliseconds: 180);

  SceneSpec get _effectiveSceneSpec =>
      SceneSpec.fromDraft(_draft, previousSpec: _draft.sceneSpec);

  SceneSpec _sceneSpecForDraft(SceneDraft draft) =>
      SceneSpec.fromDraft(draft, previousSpec: draft.sceneSpec);

  _VirtualFriend? get _activeFriend {
    final String friendId = _activeFriendId?.trim() ?? '';
    if (friendId.isEmpty) {
      return null;
    }
    for (final _VirtualFriend friend in _virtualFriends) {
      if (friend.id == friendId) {
        return friend;
      }
    }
    return null;
  }

  List<_VirtualFriend> get _filteredVirtualFriends {
    final String query = _friendSearchController.text.trim().toLowerCase();
    final List<_VirtualFriend> friends =
        List<_VirtualFriend>.from(_virtualFriends)..sort(
          (_VirtualFriend a, _VirtualFriend b) =>
              b.updatedAt.compareTo(a.updatedAt),
        );
    if (query.isEmpty) {
      return friends;
    }
    return friends
        .where((_VirtualFriend friend) {
          return friend.name.toLowerCase().contains(query) ||
              friend.role.toLowerCase().contains(query) ||
              friend.personality.toLowerCase().contains(query) ||
              friend.profession.toLowerCase().contains(query) ||
              friend.relationship.toLowerCase().contains(query) ||
              friend.preferredScene.toLowerCase().contains(query) ||
              friend.hobbies.any(
                (String hobby) => hobby.toLowerCase().contains(query),
              );
        })
        .toList(growable: false);
  }

  Future<void> _loadVirtualFriends() async {
    final List<_VirtualFriend> next = await _sceneSetupCoordinator
        .loadVirtualFriends();
    if (!mounted) {
      return;
    }
    setState(() {
      _virtualFriends = next;
      _isLoadingVirtualFriends = false;
    });
    unawaited(_syncVirtualFriendsToServer(next).catchError((Object _) {}));
  }

  Future<void> _persistVirtualFriends() async {
    await _sceneSetupCoordinator.saveVirtualFriends(_virtualFriends);
    if (!mounted) {
      return;
    }
    await _syncVirtualFriendsToServer();
  }

  Future<void> _syncVirtualFriendsToServer([
    List<_VirtualFriend>? friends,
  ]) async {
    final AppSession session = AppSessionScope.of(context);
    if (!session.isLoggedIn) {
      return;
    }
    final List<Map<String, dynamic>> payload = (friends ?? _virtualFriends)
        .map(
          (_VirtualFriend friend) => <String, dynamic>{
            'clientRoleId': friend.id,
            'name': friend.name,
            'role': friend.role,
            'profession': friend.profession,
            'personality': friend.personality,
            'hobbies': friend.hobbies,
            'relationship': friend.relationship,
            'preferredScene': friend.preferredScene,
            'lastMessage': friend.lastMessage,
          },
        )
        .toList(growable: false);
    if (payload.isEmpty) {
      return;
    }
    await session.syncRoleProfiles(payload);
  }

  @override
  void initState() {
    super.initState();
    _resetChatSession();
    _loadVirtualFriends();
    _voiceTurnReadySub = _voiceTurnOrchestrator.readyStream.listen((
      VoiceAssistantTurnReady ready,
    ) {
      unawaited(_handleVoiceAssistantTurnReady(ready));
    });
    _controller.addListener(_handleControllerChanged);
    _friendSearchController.addListener(_handleFriendSearchChanged);
    _scenePromptFocusNode.addListener(_handleScenePromptFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _notifyBottomBarVisibility();
    });
    _promptTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted || _inputFocused || _controller.text.isNotEmpty) {
        return;
      }
      setState(() {
        _activePromptIndex = (_activePromptIndex + 1) % examplePrompts.length;
      });
    });
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _mockInputTimer?.cancel();
    _chatSpeechPreviewRestartTimer?.cancel();
    _voiceTurnReadySub?.cancel();
    _voiceChatTurnEventSub?.cancel();
    _voiceTurnOrchestrator.dispose();
    unawaited(_disposeChatPreviewVoiceService());
    _cleanupVoiceChatSession();
    unawaited(_speechToText.cancel().catchError((Object _) {}));
    _controller.removeListener(_handleControllerChanged);
    _friendSearchController.removeListener(_handleFriendSearchChanged);
    _scenePromptFocusNode.removeListener(_handleScenePromptFocusChanged);
    _chatScrollController.dispose();
    _scenePromptFocusNode.dispose();
    _friendSearchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleFriendSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleScenePromptFocusChanged() {
    if (!mounted || _inputFocused == _scenePromptFocusNode.hasFocus) {
      return;
    }
    setState(() {
      _inputFocused = _scenePromptFocusNode.hasFocus;
    });
  }

  void _dismissKeyboard() {
    if (!_scenePromptFocusNode.hasFocus) {
      return;
    }
    _scenePromptFocusNode.unfocus();
  }

  Future<bool> _ensureHomeSpeechReady() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    final bool available = await _speechToText.initialize(
      onError: _handleHomeSpeechError,
      onStatus: _handleHomeSpeechStatus,
      finalTimeout: const Duration(milliseconds: 600),
    );
    if (available) {
      _homeSpeechLocaleId = await _resolveHomeSpeechLocaleId();
    }
    return available;
  }

  Future<String?> _resolveHomeSpeechLocaleId() async {
    return _resolveSpeechLocaleId(const <String>[
      'zh_CN',
      'zh-CN',
      'cmn_CN',
      'cmn-Hans-CN',
      'yue_CN',
      'zh_HK',
      'zh-TW',
      'en_US',
      'en-US',
    ]);
  }

  Future<String?> _resolveSpeechLocaleId(List<String> preferredLocales) async {
    final List<LocaleName> locales = await _speechToText.locales();
    for (final String localeId in preferredLocales) {
      final LocaleName? match = locales.cast<LocaleName?>().firstWhere(
        (LocaleName? item) => item?.localeId == localeId,
        orElse: () => null,
      );
      if (match != null) {
        return match.localeId;
      }
    }
    final LocaleName? systemLocale = await _speechToText.systemLocale();
    return systemLocale?.localeId;
  }

  void _handleHomeSpeechStatus(String status) {
    if (!mounted) {
      return;
    }
    if ((status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) &&
        _isHomeSpeechRecording) {
      setState(() {
        _isHomeSpeechRecording = false;
      });
    }
  }

  void _handleHomeSpeechError(SpeechRecognitionError error) {
    if (!mounted) {
      return;
    }
    if (_isHomeSpeechRecording) {
      setState(() {
        _isHomeSpeechRecording = false;
      });
    }
    if (error.errorMsg == 'error_no_match' ||
        error.errorMsg == 'error_speech_timeout') {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_homeSpeechErrorMessage(error)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _homeSpeechErrorMessage(SpeechRecognitionError error) {
    switch (error.errorMsg) {
      case 'error_permission':
      case 'error_speech_recognizer_disabled':
        return '请在系统设置中开启麦克风和语音识别权限';
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        return '当前设备暂不支持所选识别语言';
      default:
        return '语音识别失败，请重试';
    }
  }

  String _friendlyErrorMessage(Object error) {
    final String raw = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
    if (raw.isEmpty) {
      return '请求失败，请重试';
    }
    if (raw.contains('未登录') || raw.contains('401')) {
      return '登录状态失效，请重新登录';
    }
    if (error is TimeoutException ||
        raw.contains('TimeoutException') ||
        raw.contains('timed out')) {
      return '请求超时，请稍后重试';
    }
    if (error is SocketException) {
      return '当前网络不可用，请检查后重试';
    }
    if (raw == '服务器未返回场景回复') {
      return 'AI 暂时没有返回内容，请重试';
    }
    return raw;
  }

  String _normalizeVoiceTranscriptForScene(String transcript) {
    return _sceneVoiceTurnRulesCoordinator.normalizeTranscript(transcript);
  }

  String _mergeVoiceTranscriptSegments(String base, String incoming) {
    return _sceneVoiceTurnRulesCoordinator.mergeTranscriptSegments(
      base,
      incoming,
    );
  }

  void _scheduleChatSpeechPreviewRestart() {
    _chatSpeechPreviewRestartTimer?.cancel();
    final int generation = _chatSpeechPreviewGeneration;
    _chatSpeechPreviewRestartTimer = Timer(
      const Duration(milliseconds: 120),
      () {
        if (!mounted ||
            !_isRecording ||
            generation != _chatSpeechPreviewGeneration) {
          return;
        }
        unawaited(_startChatSpeechPreview());
      },
    );
  }

  bool _containsChineseText(String text) {
    return RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
  }

  bool _looksLikeCoachReply(String text) {
    final String lower = text.toLowerCase();
    return text.contains('先聚焦') ||
        text.contains('直接回应') ||
        text.contains('先回应') ||
        text.contains('这一点') ||
        lower.contains('focus on this') ||
        lower.contains('directly answer') ||
        lower.contains('respond to that') ||
        lower.contains('let us focus') ||
        lower.contains('you should');
  }

  bool _serviceReplyMentionsSlot(String text, _ServiceSlot slot) {
    final String lower = text.toLowerCase();
    switch (slot) {
      case _ServiceSlot.item:
        return _containsAny(lower, <String>[
          'what would you like',
          'what would you like to order',
          'what can i get',
          'what can i get started',
          'can i get started for you',
          'may i take your order',
          'order',
        ]);
      case _ServiceSlot.flavor:
        return _containsAny(lower, <String>[
          'flavor',
          'vanilla',
          'caramel',
          'plain',
        ]);
      case _ServiceSlot.temperature:
        return _containsAny(lower, <String>[
          'hot or iced',
          'iced or hot',
          'hot',
          'iced',
          'cold',
        ]);
      case _ServiceSlot.sweetness:
        return _containsAny(lower, <String>[
          'sugar',
          'sweet',
          'less sugar',
          'no sugar',
        ]);
      case _ServiceSlot.milk:
        return _containsAny(lower, <String>['milk', 'oat', 'soy', 'whole']);
      case _ServiceSlot.size:
        return _containsAny(lower, <String>[
          'size',
          'small',
          'medium',
          'large',
        ]);
      case _ServiceSlot.pickup:
        return _containsAny(lower, <String>[
          'to go',
          'for here',
          'take away',
          'takeaway',
          'dine in',
          'sit in',
        ]);
      case _ServiceSlot.closing:
        return _containsAny(lower, <String>[
          'anything else',
          'all set',
          'that\'s all',
          'have a nice',
        ]);
    }
  }

  String _serviceCanonicalNpcReply(_ServicePolicyDecision plan) {
    final bool shouldAcknowledge = plan.latestUserAnsweredSlots.isNotEmpty;
    final String prefix = shouldAcknowledge ? 'Got it. ' : '';
    switch (plan.nextNpcSlot) {
      case null:
        return '${prefix}Great, that\'s all set.';
      case _ServiceSlot.item:
        if (plan.askedSlots.contains(_ServiceSlot.item) &&
            plan.latestUserAnsweredSlots.isEmpty) {
          return 'Sorry, I didn\'t catch the drink name. Could you say the drink again?';
        }
        return '${prefix}What would you like to order today?';
      case _ServiceSlot.flavor:
        if (plan.askedSlots.contains(_ServiceSlot.flavor) &&
            plan.latestUserAnsweredSlots.isEmpty) {
          return 'Sorry, I didn\'t catch the flavor. Could you say the flavor again?';
        }
        return '${prefix}Which flavor would you like: vanilla, caramel, or plain?';
      case _ServiceSlot.temperature:
        if (plan.askedSlots.contains(_ServiceSlot.temperature) &&
            plan.latestUserAnsweredSlots.isEmpty) {
          return 'Sorry, I didn\'t catch that. Would you like it hot or iced?';
        }
        return '${prefix}Would you like it hot or iced?';
      case _ServiceSlot.sweetness:
        if (plan.askedSlots.contains(_ServiceSlot.sweetness) &&
            plan.latestUserAnsweredSlots.isEmpty) {
          return 'Sorry, I didn\'t catch the sweetness. Could you say the sweetness again?';
        }
        return '${prefix}How sweet would you like it: regular, less sugar, or no sugar?';
      case _ServiceSlot.milk:
        if (plan.askedSlots.contains(_ServiceSlot.milk) &&
            plan.latestUserAnsweredSlots.isEmpty) {
          return 'Sorry, I didn\'t catch the milk choice. Could you say the milk again?';
        }
        return '${prefix}Which milk would you like: regular, oat, or soy?';
      case _ServiceSlot.size:
        if (plan.askedSlots.contains(_ServiceSlot.size) &&
            plan.latestUserAnsweredSlots.isEmpty) {
          return 'Sorry, I didn\'t catch the size. Could you say the size again?';
        }
        return '${prefix}What size would you like: small, medium, or large?';
      case _ServiceSlot.pickup:
        if (plan.askedSlots.contains(_ServiceSlot.pickup) &&
            plan.latestUserAnsweredSlots.isEmpty) {
          return 'Sorry, I didn\'t catch that. Is that for here or to go?';
        }
        return '${prefix}Is that for here or to go?';
      case _ServiceSlot.closing:
        return '${prefix}Great, that\'s everything.';
    }
  }

  String _serviceNpcTurnContract(
    _ServicePolicyDecision plan,
    String latestUserText,
  ) {
    final String confirmed = plan.state.confirmedSummary().join('; ');
    final String normalizedLatestUserText = latestUserText.trim();
    if (plan.nextNpcSlot == null) {
      return 'For the next NPC turn, stay in role as the service staff, briefly confirm the completed order, and close naturally in short English. Do not ask a new question. Confirmed details: ${confirmed.isEmpty ? 'none' : confirmed}.';
    }
    return 'For the next NPC turn, respond directly to the learner\'s latest message "${normalizedLatestUserText.isEmpty ? 'N/A' : normalizedLatestUserText}". Stay fully in role as the service staff. If the learner just gave a useful detail, acknowledge it briefly. Then ask exactly one natural follow-up about ${_serviceSlotLabelEn(plan.nextNpcSlot!)}. Do not ask about any other detail in this turn. Confirmed details: ${confirmed.isEmpty ? 'none' : confirmed}.';
  }

  SceneReply _sanitizeSceneReplyForScene({
    required SceneReply reply,
    required List<SceneHistoryTurn> requestTurns,
  }) {
    if (_effectiveSceneSpec.category != 'service') {
      return reply;
    }
    final String npcText = reply.npcText.trim();
    final _ServicePolicyDecision plan = _servicePolicyDecision(requestTurns);
    final String canonicalText = _serviceCanonicalNpcReply(plan);
    final bool invalidLanguage =
        npcText.isEmpty ||
        _containsChineseText(npcText) ||
        _looksLikeCoachReply(npcText);
    final bool invalidFocus =
        !invalidLanguage &&
        plan.nextNpcSlot != null &&
        !_serviceReplyMentionsSlot(npcText, plan.nextNpcSlot!);
    if (!invalidLanguage && !invalidFocus) {
      return reply;
    }
    debugPrint(
      '[Scene] Canonicalized service reply. original="$npcText" canonical="$canonicalText"',
    );
    return SceneReply(
      npcText: canonicalText,
      coachHint: reply.coachHint,
      eventLabel: reply.eventLabel,
      eventColor: reply.eventColor,
      mood: reply.mood,
      summary: reply.summary,
      turnContract: reply.turnContract,
      sceneState: reply.sceneState,
      roleMemoryHints: reply.roleMemoryHints,
      learningProfileHints: reply.learningProfileHints,
    );
  }

  bool _isSceneSessionMissingError(Object error) {
    final String raw = error.toString();
    return raw.contains('会话不存在') ||
        raw.contains('session not found') ||
        raw.contains('Session not found');
  }

  Future<Map<String, dynamic>> _createSceneSessionData() {
    return _sceneSetupCoordinator.createSceneSessionData(draft: _draft);
  }

  Future<String> _recreateSceneSessionId() async {
    final Map<String, dynamic> sessionData = await _createSceneSessionData();
    final String sessionId = (sessionData['sessionId'] as String? ?? '').trim();
    if (sessionId.isEmpty) {
      throw Exception('场景会话创建失败');
    }
    final SceneTurnContract? turnContract = _parseSceneTurnContract(
      sessionData['turnContract'],
    );
    final SceneStateSnapshot? sceneState = _parseSceneStateSnapshot(
      sessionData['sceneState'],
    );
    final List<String> roleMemoryHints = _parseSceneHints(
      sessionData['roleMemory'],
    );
    final List<String> learningProfileHints = _parseSceneHints(
      sessionData['learningProfileHints'],
    );
    if (mounted) {
      setState(() {
        _sessionId = sessionId;
        _serverTurnContract = turnContract;
        _serverSceneState = sceneState;
        _sceneRoleMemoryHints = roleMemoryHints;
        _sceneLearningProfileHints = learningProfileHints;
      });
    } else {
      _sessionId = sessionId;
      _serverTurnContract = turnContract;
      _serverSceneState = sceneState;
      _sceneRoleMemoryHints = roleMemoryHints;
      _sceneLearningProfileHints = learningProfileHints;
    }
    _persistConversationHistory();
    return sessionId;
  }

  Future<SceneReply> _sendSceneMessageWithRecovery({
    required AppSession session,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) async {
    return _sceneConversationCoordinator.sendMessageWithRecovery(
      sessionId: _sessionId,
      recreateSessionId: _recreateSceneSessionId,
      isSessionMissingError: _isSceneSessionMissingError,
      sendSceneMessage: session.sendSceneMessage,
      userText: userText,
      draft: draft,
      history: history,
    );
  }

  String _mergeHomeSpeechText(String recognizedWords) {
    final String baseText = _homeSpeechBaseText.trim();
    final String liveText = recognizedWords.trim();
    if (baseText.isEmpty) {
      return liveText;
    }
    if (liveText.isEmpty) {
      return baseText;
    }
    return '$baseText $liveText';
  }

  void _handleHomeSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) {
      return;
    }
    final String mergedText = _mergeHomeSpeechText(result.recognizedWords);
    _controller.value = TextEditingValue(
      text: mergedText,
      selection: TextSelection.collapsed(offset: mergedText.length),
    );
  }

  Future<void> _startHomeSpeechInput() async {
    if (_isHomeSpeechRecording || _isDraftGenerating || _isRecording) {
      return;
    }
    _mockInputTimer?.cancel();
    _dismissKeyboard();
    final bool ready = await _ensureHomeSpeechReady();
    if (!mounted) {
      return;
    }
    final bool hasPermission = ready && await _speechToText.hasPermission;
    if (!mounted) {
      return;
    }
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请在系统设置中开启麦克风和语音识别权限'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    _homeSpeechBaseText = _controller.text.trim();
    setState(() {
      _isHomeSpeechRecording = true;
      _showTextComposer = false;
    });
    try {
      await _speechToText.listen(
        onResult: _handleHomeSpeechResult,
        localeId: _homeSpeechLocaleId,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isHomeSpeechRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('语音输入启动失败: ${error.toString().split(':').last}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopHomeSpeechInput() async {
    if (!_isHomeSpeechRecording && !_speechToText.isListening) {
      return;
    }
    if (mounted && _isHomeSpeechRecording) {
      setState(() {
        _isHomeSpeechRecording = false;
      });
    }
    await _speechToText.stop();
  }

  Future<bool> _ensureChatSpeechReady() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    final bool available = await _speechToText.initialize(
      onError: _handleChatSpeechError,
      onStatus: _handleChatSpeechStatus,
      finalTimeout: const Duration(milliseconds: 400),
    );
    if (available) {
      _chatSpeechLocaleId ??= await _resolveSpeechLocaleId(const <String>[
        'en_US',
        'en-US',
        'en_GB',
        'en-GB',
        'en_AU',
        'en-AU',
      ]);
    }
    return available;
  }

  void _handleChatSpeechError(SpeechRecognitionError error) {
    debugPrint('[Scene] Chat speech preview error: ${error.errorMsg}');
    if (!mounted || !_isRecording) {
      return;
    }
    if (error.errorMsg == 'error_no_match' ||
        error.errorMsg == 'error_speech_timeout') {
      return;
    }
    setState(() {
      _chatSpeechPreviewUnavailable = true;
    });
  }

  void _handleChatSpeechStatus(String status) {
    if (!mounted || !_isRecording) {
      return;
    }
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      setState(() {
        if (_chatRecordingPreviewText.trim().isNotEmpty) {
          _chatRecordingHintText = _mergeVoiceTranscriptSegments(
            _chatRecordingHintText,
            _chatRecordingPreviewText,
          );
          _chatRecordingPreviewText = _chatRecordingHintText;
        }
        _chatSpeechPreviewUnavailable = _chatRecordingHintText.trim().isEmpty;
      });
      _scheduleChatSpeechPreviewRestart();
    }
  }

  void _handleChatSpeechResult(SpeechRecognitionResult result) {
    if (!mounted || !_isRecording) {
      return;
    }
    final String recognized = _normalizeVoiceTranscriptForScene(
      result.recognizedWords,
    );
    if (recognized.isEmpty) {
      return;
    }
    final String mergedPreview = _mergeVoiceTranscriptSegments(
      _chatRecordingHintText,
      recognized,
    );
    setState(() {
      _chatRecordingPreviewText = mergedPreview;
      if (result.finalResult ||
          mergedPreview.length >= _chatRecordingHintText.length) {
        _chatRecordingHintText = mergedPreview;
      }
      _chatSpeechPreviewUnavailable = false;
    });
  }

  Future<void> _startChatSpeechPreview() async {
    try {
      _chatSpeechPreviewRestartTimer?.cancel();
      final bool ready = await _ensureChatSpeechReady();
      if (!mounted || !_isRecording) {
        return;
      }
      final bool hasPermission = ready && await _speechToText.hasPermission;
      if (!mounted || !_isRecording) {
        return;
      }
      if (!hasPermission) {
        setState(() {
          _chatSpeechPreviewUnavailable = true;
        });
        return;
      }
      await _speechToText.listen(
        onResult: _handleChatSpeechResult,
        localeId: _chatSpeechLocaleId,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 2),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          autoPunctuation: false,
        ),
      );
    } catch (error) {
      debugPrint('[Scene] Chat speech preview start failed: $error');
      if (!mounted || !_isRecording) {
        return;
      }
      setState(() {
        _chatSpeechPreviewUnavailable = true;
      });
    }
  }

  Future<void> _disposeChatPreviewVoiceService() async {
    await _chatPreviewConnSub?.cancel();
    await _chatPreviewTextSub?.cancel();
    await _chatPreviewFinalSub?.cancel();
    _chatPreviewConnSub = null;
    _chatPreviewTextSub = null;
    _chatPreviewFinalSub = null;
    final VoiceChatService? service = _chatPreviewVoiceService;
    _chatPreviewVoiceService = null;
    _chatPreviewTranscriptCompleter = null;
    _chatPreviewSentChunkCount = 0;
    if (service != null) {
      await service.disconnect();
      service.dispose();
    }
  }

  void _flushChatPreviewAudio() {
    final VoiceChatService? service = _chatPreviewVoiceService;
    if (service == null || !service.isConnected) {
      return;
    }
    while (_chatPreviewSentChunkCount < _pendingTurnVoiceChunks.length) {
      service.sendAudio(_pendingTurnVoiceChunks[_chatPreviewSentChunkCount]);
      _chatPreviewSentChunkCount++;
    }
  }

  Future<void> _startChatPreviewVoiceService() async {
    final String? token = await _sceneRuntimeSupportCoordinator.loadToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _chatSpeechPreviewUnavailable = true;
        });
      }
      return;
    }
    await _disposeChatPreviewVoiceService();
    if (!mounted || !_isRecording) {
      return;
    }
    final VoiceChatService service = _sceneVoiceRuntimeCoordinator
        .createService();
    final Completer<String> transcriptCompleter = Completer<String>();
    _chatPreviewVoiceService = service;
    _chatPreviewTranscriptCompleter = transcriptCompleter;
    final int generation = _chatSpeechPreviewGeneration;

    _chatPreviewConnSub = service.connectionStream.listen((String state) {
      if (!mounted ||
          _chatPreviewVoiceService != service ||
          !_isRecording ||
          generation != _chatSpeechPreviewGeneration) {
        return;
      }
      if (state == 'connected') {
        _flushChatPreviewAudio();
      }
    });

    _chatPreviewTextSub = service.userTextPreviewStream.listen((String text) {
      if (!mounted ||
          _chatPreviewVoiceService != service ||
          !_isRecording ||
          generation != _chatSpeechPreviewGeneration) {
        return;
      }
      final String preview = _normalizeVoiceTranscriptForScene(text);
      if (preview.isEmpty) {
        return;
      }
      setState(() {
        _chatRecordingPreviewText = preview;
        _chatRecordingHintText = preview;
        _chatSpeechPreviewUnavailable = false;
      });
    });

    _chatPreviewFinalSub = service.userTextStream.listen((String text) {
      final String transcript = _normalizeVoiceTranscriptForScene(text);
      if (transcript.isEmpty) {
        return;
      }
      if (mounted &&
          _chatPreviewVoiceService == service &&
          generation == _chatSpeechPreviewGeneration) {
        setState(() {
          _chatRecordingPreviewText = transcript;
          _chatRecordingHintText = transcript;
          _chatSpeechPreviewUnavailable = false;
        });
      }
      if (!transcriptCompleter.isCompleted) {
        transcriptCompleter.complete(transcript);
      }
    });

    try {
      await _sceneVoiceRuntimeCoordinator.connect(
        service: service,
        request: SceneVoiceConnectRequest(
          token: token,
          config: const SceneVoiceSessionConfig(
            manualTurnDetection: true,
            transcriptionOnly: true,
          ),
        ),
      );
    } catch (error) {
      debugPrint('[Scene] Chat preview voice connect failed: $error');
      if (mounted && _chatPreviewVoiceService == service) {
        setState(() {
          _chatSpeechPreviewUnavailable = true;
        });
      }
      await _disposeChatPreviewVoiceService();
    }
  }

  Future<String> _finishChatPreviewVoiceService({required bool send}) async {
    final String fallbackTranscript = _chatRecordingHintText.trim().isNotEmpty
        ? _chatRecordingHintText.trim()
        : _chatRecordingPreviewText.trim();
    final VoiceChatService? service = _chatPreviewVoiceService;
    final Completer<String>? transcriptCompleter =
        _chatPreviewTranscriptCompleter;
    _chatSpeechPreviewGeneration++;
    if (service == null) {
      return fallbackTranscript;
    }
    try {
      if (send) {
        if (!service.isConnected) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
        _flushChatPreviewAudio();
        service.commitTurn();
        if (transcriptCompleter != null) {
          return await transcriptCompleter.future.timeout(
            const Duration(seconds: 4),
            onTimeout: () => fallbackTranscript,
          );
        }
      }
      return fallbackTranscript;
    } finally {
      service.finishSession();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _disposeChatPreviewVoiceService();
    }
  }

  List<_ChatMessage> _initialMessagesForDraft({
    String? openingNpcText,
    String? openingMood,
    String? openingCoachHint,
    String? openingEventLabel,
    String? openingAudioPath,
    int? openingVoiceDuration,
  }) {
    final String resolvedOpeningText =
        (openingNpcText ?? _buildInitialNpcOpener(_effectiveSceneSpec)).trim();
    final SceneSpec spec = _effectiveSceneSpec;
    final List<_ChatMessage> messages = <_ChatMessage>[
      if (openingEventLabel != null && openingEventLabel.trim().isNotEmpty)
        _ChatMessage(
          role: _MessageRole.event,
          text: openingEventLabel.trim(),
          accent: const Color(0xFF7ACFBD),
        )
      else
        _ChatMessage(
          role: _MessageRole.event,
          text: '对话已接通 · ${_draft.npcName} 正在等待',
          accent: const Color(0xFF7ACFBD),
        ),
      _ChatMessage(
        role: _MessageRole.npc,
        text: resolvedOpeningText,
        inputType: _ChatInputType.voice,
        voiceDuration:
            openingVoiceDuration ??
            _fallbackVoiceDurationFromText(resolvedOpeningText, fallback: 8),
        mood: (openingMood ?? _buildInitialNpcMood(spec)).trim(),
        audioPath: openingAudioPath?.trim().isEmpty ?? true
            ? null
            : openingAudioPath!.trim(),
      ),
      _ChatMessage(
        role: _MessageRole.coach,
        text: (openingCoachHint ?? _buildInitialCoachHint(spec)).trim(),
      ),
    ];
    return messages;
  }

  String _buildInitialNpcOpener(SceneSpec spec) {
    final bool highPressure = spec.pressureLevel >= 4;
    switch (spec.category) {
      case 'process_review':
        if (highPressure) {
          return 'Thanks for joining. Let us focus on the biggest process gap first. What is slowing the team down most right now?';
        }
        return 'Thanks for making time. To improve the development process, where do you think the biggest friction is today?';
      case 'work_review':
        if (highPressure) {
          return 'Thanks for joining on short notice. Let us get straight to the update. What happened?';
        }
        return 'Thanks for joining. Give me a quick update on the situation.';
      case 'client':
        if (highPressure) {
          return 'Thanks for making time. I need a clear explanation of the issue first.';
        }
        return 'Thanks for joining. Could you briefly explain the situation and what outcome you are aiming for today?';
      case 'interview':
        if (highPressure) {
          return 'Let us begin. Give me a direct answer first.';
        }
        return 'Let us start with a brief answer, and then expand on the most relevant detail.';
      case 'service':
        return 'Hi there, what can I get started for you today?';
      case 'social':
        return 'Thanks for being here. Pick up the conversation naturally and tell me what is on your mind.';
      default:
        if (highPressure) {
          return 'Thanks for joining on short notice. Let us keep this focused. Start with the situation.';
        }
        return 'Thanks for joining. Give me a clear summary of the situation.';
    }
  }

  String _buildInitialNpcMood(SceneSpec spec) {
    switch (spec.category) {
      case 'process_review':
        return spec.pressureLevel >= 4 ? '聚焦改进中' : '理性讨论中';
      case 'work_review':
        return spec.pressureLevel >= 4 ? '冷静施压中' : '等待你回应';
      case 'client':
        return spec.pressureLevel >= 4 ? '紧盯风险中' : '等待你说明';
      case 'interview':
        return spec.pressureLevel >= 4 ? '评估表达中' : '等待你回答';
      case 'service':
        return '等待你点单';
      case 'social':
        return '轻松交流中';
      default:
        return spec.pressureLevel >= 4 ? '保持推进中' : '等待你回应';
    }
  }

  String _buildInitialCoachHint(SceneSpec spec) {
    switch (spec.category) {
      case 'process_review':
        return '先点出最大卡点，再提一个优先改动';
      case 'interview':
        return '先直接回答，再补一个具体例子';
      case 'service':
        return '先说你想点什么，再补冷热甜度这些偏好';
      default:
        break;
    }
    if (spec.pressureLevel >= 4) {
      return '先给结论，不要先铺垫';
    }
    if (spec.followupDepth >= 4) {
      return '准备好时间点和下一步动作';
    }
    return '先说结果，再补一个关键原因';
  }

  SceneTurnContract? _parseSceneTurnContract(dynamic value) {
    return _sceneConversationCoordinator.parseSceneTurnContract(value);
  }

  SceneStateSnapshot? _parseSceneStateSnapshot(dynamic value) {
    return _sceneConversationCoordinator.parseSceneStateSnapshot(value);
  }

  List<String> _parseSceneHints(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) {
          if (item is String) {
            return item.trim();
          }
          if (item is Map<String, dynamic>) {
            return (item['text'] as String? ?? '').trim();
          }
          if (item is Map) {
            return (item['text'] as String? ?? '').trim();
          }
          return '';
        })
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _resolvedCoachHintFallback([List<SceneHistoryTurn>? turns]) {
    final String serverHint = (_serverTurnContract?.learnerGoalZh ?? '').trim();
    if (serverHint.isNotEmpty) {
      return serverHint;
    }
    return _sceneAgendaCueForTurns(
      turns ?? _currentSceneHistoryTurns(),
    ).coachHintZh;
  }

  void _resetChatSession({
    String? sessionId,
    String? openingNpcText,
    String? openingMood,
    String? openingCoachHint,
    String? openingEventLabel,
    String? openingAudioPath,
    int? openingVoiceDuration,
    SceneTurnContract? turnContract,
    SceneStateSnapshot? sceneState,
    List<String> roleMemoryHints = const <String>[],
    List<String> learningProfileHints = const <String>[],
  }) {
    final String resolvedSessionId = (sessionId ?? _sessionId).trim();
    _sessionId = resolvedSessionId.isNotEmpty
        ? resolvedSessionId
        : DateTime.now().millisecondsSinceEpoch.toString();
    _messages
      ..clear()
      ..addAll(
        _initialMessagesForDraft(
          openingNpcText: openingNpcText,
          openingMood: openingMood,
          openingCoachHint: openingCoachHint,
          openingEventLabel: openingEventLabel,
          openingAudioPath: openingAudioPath,
          openingVoiceDuration: openingVoiceDuration,
        ),
      );
    _expandedVoiceMessageIndexes.clear();
    _voiceMessageTranslations.clear();
    _translatedVoiceMessageIndexes.clear();
    _translatingVoiceMessageIndexes.clear();
    _pendingRealtimeUserVoiceChunks.clear();
    _serverTurnContract = turnContract;
    _serverSceneState = sceneState;
    _sceneRoleMemoryHints = List<String>.unmodifiable(roleMemoryHints);
    _sceneLearningProfileHints = List<String>.unmodifiable(
      learningProfileHints,
    );
    _feedback = null;
    _isFeedbackLoading = false;
    _lastFeedbackError = null;
    _feedbackCacheKey = null;
    _feedbackPendingKey = null;
    _feedbackStartedAt = null;
    _feedbackCompletionAnnouncedKey = null;
    _feedbackTaskGeneration += 1;
    _scenePracticeRecorded = false;
    _scenePracticePendingRecorded = false;
    _lastAutoPlayedOpeningText = null;
    _restoredFeedbackRequestData = null;
    _feedbackOpenedFromRecentSummary = false;
    _serviceTurnTraces.clear();
    _conversationSummary = null;
    _summaryLastTurnCount = 0;
    _summaryGenerating = false;
    _persistConversationHistory();
  }

  Future<void> _generateDraft([
    String? prompt,
    bool openChatDirectly = false,
  ]) async {
    final _VirtualFriend? friend = _activeFriend;
    final String rawInput = (prompt ?? _controller.text).trim();
    final String input = friend != null && prompt == null
        ? _promptForVirtualFriend(friend, sceneFocus: rawInput).trim()
        : rawInput;
    if (input.isEmpty || _isDraftGenerating) {
      return;
    }
    setState(() {
      _isDraftGenerating = true;
    });

    SceneDraft nextDraft = _fallbackDraftForPrompt(input);
    try {
      final SceneDraft? generatedDraft = await _sceneSetupCoordinator
          .generateDraft(prompt: input, activeFriend: friend);
      if (generatedDraft != null) {
        nextDraft = generatedDraft;
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      _draft = nextDraft;
      _feedback = null;
      _feedbackCacheKey = null;
      _feedbackPendingKey = null;
      _feedbackStartedAt = null;
      _feedbackCompletionAnnouncedKey = null;
      _feedbackTaskGeneration += 1;
      _isFeedbackLoading = false;
      _isDraftGenerating = false;
      _scenePracticeRecorded = false;
      _feedbackOpenedFromRecentSummary = false;
    });
    if (openChatDirectly) {
      await _startConversation();
      return;
    }
    _setView(SceneFlowView.draft);
  }

  void _openRecommendedScene(String prompt) {
    unawaited(_generateDraft(prompt, true));
  }

  SceneDraft _fallbackDraftForPrompt(String prompt) {
    return _sceneSetupCoordinator.fallbackDraftForPrompt(
      prompt: prompt,
      activeFriend: _activeFriend,
    );
  }

  SceneDraft _withSceneSpec(
    SceneDraft draft, {
    SceneSpec? previousSpec,
    SceneBlueprint? previousBlueprint,
  }) {
    return _sceneSetupCoordinator.withSceneSpec(
      draft,
      previousSpec: previousSpec,
      previousBlueprint: previousBlueprint,
    );
  }

  SceneDraft _draftFromVirtualFriend(_VirtualFriend friend) {
    return _sceneSetupCoordinator.draftFromVirtualFriend(friend);
  }

  String _promptForVirtualFriend(_VirtualFriend friend, {String? sceneFocus}) {
    return _sceneSetupCoordinator.promptForVirtualFriend(
      friend,
      sceneFocus: sceneFocus,
    );
  }

  String _editablePromptFromDraft(SceneDraft draft) {
    final String plotSummary = _plotSummaryForDraft(draft);
    final String plotSteps = _plotStepsPromptForDraft(draft);
    return [
      '场景主题：${draft.title}',
      '我的身份：${draft.userRole}',
      '对方角色：${draft.npcName}（${draft.npcRole}）',
      '双方关系：${draft.relationship}',
      '发生场景：${draft.environment}',
      '我的目标：${draft.goal}',
      '主要难点：${draft.challenge}',
      '剧情介绍：$plotSummary',
      if (plotSteps.isNotEmpty) '剧情顺序：\n$plotSteps',
    ].join('\n');
  }

  String _composeEditablePromptFromDraft() => _editablePromptFromDraft(_draft);

  String _draftOverviewSubtitle() {
    final List<String> parts = _draft.goal
        .split(RegExp(r'[，。；;]'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isNotEmpty) {
      return parts.first;
    }
    return _draft.challenge.trim();
  }

  String _draftOverviewBackgroundText() {
    final String environment = _draft.environment.trim();
    final String relationship = _draft.relationship.trim();
    if (environment.isEmpty) {
      return relationship;
    }
    if (relationship.isEmpty) {
      return environment;
    }
    return '$environment · $relationship';
  }

  String _plotSummaryForDraft(SceneDraft draft) {
    final SceneSpec spec = _sceneSpecForDraft(draft);
    final String plotDesign = spec.plotDesign.trim().isNotEmpty
        ? spec.plotDesign.trim()
        : draft.plotDesign.trim();
    if (plotDesign.isNotEmpty) {
      return plotDesign;
    }
    final String goal = draft.goal.trim();
    final String challenge = draft.challenge.trim();
    if (goal.isNotEmpty && challenge.isNotEmpty) {
      return '$goal；$challenge';
    }
    return goal.isNotEmpty ? goal : challenge;
  }

  bool _isConditionOnlyPlotClause(String text) {
    final String value = text.trim();
    if (value.isEmpty) {
      return true;
    }
    return value.startsWith('当') ||
        value.startsWith('如果') ||
        value.startsWith('若') ||
        value.startsWith('在') ||
        value.startsWith('遇到') ||
        value.startsWith('用户') ||
        value.startsWith('对方');
  }

  String _compactPlotStepForDisplay(String text, {String? npcName}) {
    String value = text.trim();
    if (value.isEmpty) {
      return value;
    }
    if (npcName != null && npcName.trim().isNotEmpty) {
      value = value.replaceAll(npcName.trim(), '');
    }
    final List<String> replacements = <String>[
      '对话从',
      '对话在',
      '对话里',
      '逐步',
      '继续',
      '随后',
      '然后',
      '接着',
      '最后要求',
      '最后请',
      '最后',
      '先',
      '再',
      '立即',
      '会',
      '请用户',
      '让用户',
      '要求用户',
      '要求对方',
      '让对方',
      'Sarah请用户',
      'Sarah追问',
      'Sarah要求',
      'Sarah请',
      '抛出',
      '给出一个',
      '个人',
    ];
    for (final String target in replacements) {
      value = value.replaceAll(target, '');
    }
    value = value
        .replaceAll('1句话', '1 句话')
        .replaceAll('一句话', '1 句话')
        .replaceAll('三项', '3 项')
        .replaceAll('具体技术选项', '技术选项')
        .replaceAll('追问权衡', '追问方案权衡')
        .replaceAll('总结个人技术判断标准', '总结技术判断标准')
        .replaceAll('总结技术判断标准', '1 句话总结技术判断标准')
        .replaceAll(RegExp(r'^[，,、；;\s]+'), '')
        .replaceAll(RegExp(r'[，,、；;\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return value;
  }

  String _draftOverviewPlotSummary() {
    final List<String> steps = _draftOverviewPlotSteps();
    if (steps.isNotEmpty) {
      return '';
    }
    return _plotSummaryForDraft(_draft);
  }

  List<String> _plotStepsForDraft(SceneDraft draft) {
    final SceneSpec spec = _sceneSpecForDraft(draft);
    final List<String> plotBeats = spec.plotBeats
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (plotBeats.isNotEmpty) {
      return plotBeats;
    }

    final List<String> parsedPlotDesign = draft.plotDesign
        .split(RegExp(r'[；;。\n]'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (parsedPlotDesign.isNotEmpty) {
      return parsedPlotDesign;
    }

    final List<String> fallbackSteps = <String>[
      draft.goal.trim(),
      draft.challenge.trim(),
    ].where((String item) => item.isNotEmpty).toList(growable: false);

    return fallbackSteps;
  }

  List<String> _draftOverviewPlotSteps() {
    final String plotDesign = _effectiveSceneSpec.plotDesign.trim().isNotEmpty
        ? _effectiveSceneSpec.plotDesign.trim()
        : _draft.plotDesign.trim();
    final List<String> displaySteps = <String>[];

    if (plotDesign.isNotEmpty) {
      final List<String> clauses = plotDesign
          .split(RegExp(r'[；;。\n]'))
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
      for (final String clause in clauses) {
        final List<String> segments = clause
            .split(RegExp(r'[，,]'))
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false);
        if (segments.length > 1) {
          for (final String segment in segments) {
            if (_isConditionOnlyPlotClause(segment)) {
              continue;
            }
            final String compact = _compactPlotStepForDisplay(
              segment,
              npcName: _draft.npcName,
            );
            if (compact.isNotEmpty) {
              displaySteps.add(compact);
            }
            if (displaySteps.length >= 4) {
              return displaySteps;
            }
          }
          continue;
        }
        final String compact = _compactPlotStepForDisplay(
          clause,
          npcName: _draft.npcName,
        );
        if (compact.isNotEmpty) {
          displaySteps.add(compact);
        }
        if (displaySteps.length >= 4) {
          return displaySteps;
        }
      }
    }

    if (displaySteps.isNotEmpty) {
      return displaySteps;
    }

    return _plotStepsForDraft(_draft)
        .map(
          (String item) =>
              _compactPlotStepForDisplay(item, npcName: _draft.npcName),
        )
        .where((String item) => item.isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  String _plotStepsPromptForDraft(SceneDraft draft) {
    final List<String> steps = _plotStepsForDraft(draft);
    return steps
        .asMap()
        .entries
        .map(
          (MapEntry<int, String> entry) => '${entry.key + 1}. ${entry.value}',
        )
        .join('\n');
  }

  void _continueAdjustDraftPrompt() {
    final String prompt = _composeEditablePromptFromDraft();
    setState(() {
      _controller.text = prompt;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    _setView(SceneFlowView.create);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scenePromptFocusNode.requestFocus();
    });
  }

  String _toneSelectionForChallenge() {
    final String challenge = _draft.challenge;
    if (challenge.contains('打断') ||
        challenge.contains('施压') ||
        challenge.contains('逼') ||
        challenge.contains('立刻')) {
      return '咄咄';
    }
    if (challenge.contains('追问') || challenge.contains('直接')) {
      return '直接';
    }
    if (challenge.contains('温和') || challenge.contains('安抚')) {
      return '温和';
    }
    return '中性';
  }

  String _traitSelectionForChallenge() {
    final String challenge = _draft.challenge;
    if (challenge.contains('拒绝') || challenge.contains('强硬')) {
      return '强硬';
    }
    if (challenge.contains('追问') || challenge.contains('施压')) {
      return '强势';
    }
    if (challenge.contains('配合') || challenge.contains('理解')) {
      return '随和';
    }
    return '中性';
  }

  Future<void> _startConversation() async {
    if (_isStartingConversation) {
      return;
    }
    setState(() {
      _isStartingConversation = true;
    });
    try {
      try {
        final SceneSpec sceneSpec = _effectiveSceneSpec;
        final Map<String, dynamic> sessionData =
            await _createSceneSessionData();
        final String sessionId = (sessionData['sessionId'] as String? ?? '')
            .trim();
        if (sessionId.isEmpty) {
          throw Exception('场景会话创建失败');
        }
        String? openingNpcText;
        String? openingMood;
        String? openingCoachHint;
        String? openingEventLabel;
        String? openingAudioPath;
        final SceneTurnContract? openingTurnContract = _parseSceneTurnContract(
          sessionData['turnContract'],
        );
        final SceneStateSnapshot? openingSceneState = _parseSceneStateSnapshot(
          sessionData['sceneState'],
        );
        final List<String> roleMemoryHints = _parseSceneHints(
          sessionData['roleMemory'],
        );
        final List<String> learningProfileHints = _parseSceneHints(
          sessionData['learningProfileHints'],
        );
        _sessionId = sessionId;
        openingNpcText = (sessionData['openingNpcText'] as String? ?? '')
            .trim();
        openingMood = (sessionData['openingMood'] as String? ?? '').trim();
        openingCoachHint = (sessionData['openingCoachHint'] as String? ?? '')
            .trim();
        openingEventLabel = (sessionData['openingEventLabel'] as String? ?? '')
            .trim();
        if (openingCoachHint.isEmpty &&
            (openingTurnContract?.learnerGoalZh.trim().isNotEmpty ?? false)) {
          openingCoachHint = openingTurnContract!.learnerGoalZh.trim();
        }
        if (!mounted) {
          return;
        }
        final String resolvedOpeningText = openingNpcText.trim().isNotEmpty
            ? openingNpcText.trim()
            : _buildInitialNpcOpener(sceneSpec).trim();
        int? openingVoiceDuration;
        if (resolvedOpeningText.isNotEmpty) {
          try {
            final AudioService audioService = AudioServiceScope.of(context);
            openingAudioPath = await audioService
                .createTtsAudioFile(resolvedOpeningText)
                .timeout(const Duration(seconds: 8));
            final String? cleanedOpeningAudioPath = openingAudioPath?.trim();
            if (cleanedOpeningAudioPath != null &&
                cleanedOpeningAudioPath.isNotEmpty) {
              openingVoiceDuration = await audioService.getAudioDurationSeconds(
                cleanedOpeningAudioPath,
              );
            }
          } catch (_) {
            openingAudioPath = null;
          }
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _resetChatSession(
            sessionId: sessionId,
            openingNpcText: openingNpcText,
            openingMood: openingMood,
            openingCoachHint: openingCoachHint,
            openingEventLabel: openingEventLabel,
            openingAudioPath: openingAudioPath,
            openingVoiceDuration: openingVoiceDuration,
            turnContract: openingTurnContract,
            sceneState: openingSceneState,
            roleMemoryHints: roleMemoryHints,
            learningProfileHints: learningProfileHints,
          );
        });
        _setView(SceneFlowView.chat);
        unawaited(_autoPlayOpeningNpcMessage());
      } finally {
        if (mounted && _isStartingConversation) {
          setState(() {
            _isStartingConversation = false;
          });
        }
      }
    } catch (_) {
      if (mounted && _isStartingConversation) {
        setState(() {
          _isStartingConversation = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _autoPlayOpeningNpcMessage() async {
    final _ChatMessage? openingMessage = _messages
        .cast<_ChatMessage?>()
        .firstWhere(
          (_ChatMessage? message) => message?.role == _MessageRole.npc,
          orElse: () => null,
        );
    final String openingText = openingMessage?.text.trim() ?? '';
    if (openingText.isEmpty || openingText == _lastAutoPlayedOpeningText) {
      return;
    }
    debugPrint(
      '[ScenePage] autoPlayOpening start hasAudioPath=${(openingMessage?.audioPath?.trim().isNotEmpty ?? false)} text="${openingText.substring(0, openingText.length.clamp(0, 48))}"',
    );
    _lastAutoPlayedOpeningText = openingText;
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted || _view != SceneFlowView.chat) {
      return;
    }
    final AudioService audioService = AudioServiceScope.of(context);
    final String? openingAudioPath = openingMessage?.audioPath?.trim();
    if (openingAudioPath != null && openingAudioPath.isNotEmpty) {
      debugPrint('[ScenePage] autoPlayOpening using prebuilt file');
      await audioService.playFile(openingAudioPath);
      return;
    }
    for (int attempt = 0; attempt < 3; attempt++) {
      debugPrint(
        '[ScenePage] autoPlayOpening fallback TTS attempt=${attempt + 1}',
      );
      final bool played = await audioService.playTts(
        openingText,
        allowSystemFallback: false,
      );
      if (played) {
        return;
      }
      if (!mounted || _view != SceneFlowView.chat) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 320));
    }
  }

  Future<String?> _prepareNpcAudioPath(String text) async {
    final String cleanedText = text.trim();
    if (cleanedText.isEmpty || !mounted) {
      return null;
    }
    final AudioService audioService = AudioServiceScope.of(context);
    try {
      final String? path = await audioService
          .createTtsAudioFile(cleanedText)
          .timeout(const Duration(seconds: 8));
      debugPrint(
        '[ScenePage] prepared npc audio path success=${path != null && path.trim().isNotEmpty}',
      );
      return path;
    } catch (_) {
      debugPrint('[ScenePage] prepared npc audio path failed');
      return null;
    }
  }

  void _notifyBottomBarVisibility() {
    widget.onBottomBarVisibilityChanged?.call(_view == SceneFlowView.home);
  }

  List<_RecentScene> _recentScenes(AppSession session) {
    final Map<String, List<PracticeHistoryModel>> grouped =
        <String, List<PracticeHistoryModel>>{};
    for (final PracticeHistoryModel item in session.stats.recentPractices) {
      final String title = item.title.trim();
      if (title.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(title, () => <PracticeHistoryModel>[]).add(item);
    }

    final List<_RecentScene> scenes = grouped.entries
        .map((MapEntry<String, List<PracticeHistoryModel>> entry) {
          final List<PracticeHistoryModel> practices = entry.value
            ..sort((PracticeHistoryModel a, PracticeHistoryModel b) {
              final DateTime aAt =
                  a.practicedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final DateTime bAt =
                  b.practicedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bAt.compareTo(aAt);
            });
          final PracticeHistoryModel latest = practices.first;
          final int latestScore = latest.score ?? 72;
          return _RecentScene(
            title: entry.key,
            emoji: latest.emoji.isEmpty ? '🎯' : latest.emoji,
            tags: latest.tags.isEmpty
                ? const <String>['AI 定制', '场景练习']
                : latest.tags.take(3).toList(growable: false),
            color: _recentSceneColorForTitle(entry.key),
            practiceCount: practices.length,
            lastTime: _recentSceneLastTime(latest.practicedAt),
            progress: latestScore.clamp(0, 100),
            practice: latest,
          );
        })
        .toList(growable: false);

    scenes.sort(
      (_RecentScene a, _RecentScene b) =>
          b.practiceCount.compareTo(a.practiceCount),
    );
    return scenes.take(6).toList(growable: false);
  }

  Color _recentSceneColorForTitle(String title) {
    const List<Color> palette = <Color>[
      Color(0xFF4A7C6F),
      Color(0xFF5A6FA8),
      Color(0xFFA0622A),
      Color(0xFF8A5A9E),
      Color(0xFFB06A3C),
    ];
    final int hash = title.runes.fold<int>(
      0,
      (int sum, int rune) => sum + rune,
    );
    return palette[hash % palette.length];
  }

  String _recentSceneLastTime(DateTime? practicedAt) {
    if (practicedAt == null) {
      return '刚刚';
    }
    final Duration diff = DateTime.now().difference(practicedAt);
    if (diff.inDays <= 0) {
      return '今天';
    }
    if (diff.inDays == 1) {
      return '昨天';
    }
    return '${diff.inDays} 天前';
  }

  String _friendLastActiveLabel(DateTime updatedAt) {
    final Duration diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) {
      return '刚刚';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    }
    if (diff.inDays == 1) {
      return '昨天';
    }
    return '${updatedAt.month}/${updatedAt.day}';
  }

  String _chatElapsedLabel() {
    int totalSeconds = 0;
    for (final _ChatMessage message in _messages) {
      if (message.role != _MessageRole.user &&
          message.role != _MessageRole.npc) {
        continue;
      }
      totalSeconds +=
          message.voiceDuration ??
          (message.text.trim().isEmpty
              ? 0
              : math.max(3, (message.text.length / 18).ceil()));
    }
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<PracticeHistoryModel> _recentPracticesForFriend(
    AppSession session,
    _VirtualFriend friend,
  ) {
    final List<PracticeHistoryModel> practices =
        session.stats.recentPractices
            .where(
              (PracticeHistoryModel item) =>
                  _practiceBelongsToFriend(item, friend),
            )
            .toList(growable: false)
          ..sort((PracticeHistoryModel a, PracticeHistoryModel b) {
            final DateTime aAt =
                a.practicedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final DateTime bAt =
                b.practicedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bAt.compareTo(aAt);
          });
    return practices.take(4).toList(growable: false);
  }

  bool _practiceBelongsToFriend(
    PracticeHistoryModel practice,
    _VirtualFriend friend,
  ) {
    final Map<String, dynamic>? sceneDraft = practice.sceneDraftData;
    final String npcName = (sceneDraft?['npcName'] as String? ?? '').trim();
    if (npcName.isNotEmpty) {
      return npcName == friend.name;
    }
    final String prompt = (practice.promptText ?? '').trim();
    final String title = practice.title.trim();
    final String preferredScene = friend.preferredScene.trim();
    return prompt.contains(friend.name) ||
        title.contains(friend.name) ||
        (preferredScene.isNotEmpty && title.contains(preferredScene));
  }

  List<({String label, String prompt})> _friendQuickRecommendations(
    _VirtualFriend friend,
  ) {
    final String roleSource = '${friend.role} ${friend.profession}'
        .toLowerCase();
    if (roleSource.contains('hr') ||
        roleSource.contains('招聘') ||
        roleSource.contains('面试')) {
      return <({String label, String prompt})>[
        (
          label: '模拟一场英文面试',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '模拟一场英文面试'),
        ),
        (
          label: '练习自我介绍',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '练习英文自我介绍'),
        ),
        (
          label: '项目经历追问',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '围绕项目经历做深挖追问'),
        ),
        (
          label: '职业规划问答',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '回答职业规划和未来目标'),
        ),
      ];
    }
    if (roleSource.contains('客户') ||
        roleSource.contains('合作') ||
        roleSource.contains('品牌')) {
      return <({String label, String prompt})>[
        (
          label: '初次破冰沟通',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '第一次破冰并建立合作氛围'),
        ),
        (
          label: '需求澄清',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '澄清对方需求和目标'),
        ),
        (
          label: '方案介绍',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '用英文介绍项目方案'),
        ),
        (
          label: '推进下一步',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '推动对方确认下一步计划'),
        ),
      ];
    }
    if (roleSource.contains('经理') ||
        roleSource.contains('项目') ||
        roleSource.contains('同事')) {
      return <({String label, String prompt})>[
        (
          label: '同步项目进展',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '同步项目进展和关键风险'),
        ),
        (
          label: '解释延期原因',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '解释延期原因并给出补救方案'),
        ),
        (
          label: '周会汇报',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '练习在周会上做英文汇报'),
        ),
        (
          label: '争取资源支持',
          prompt: _promptForVirtualFriend(friend, sceneFocus: '申请资源并说服对方支持'),
        ),
      ];
    }
    return <({String label, String prompt})>[
      (
        label: friend.preferredScene.trim().isEmpty
            ? '自然开场'
            : friend.preferredScene.trim(),
        prompt: _promptForVirtualFriend(
          friend,
          sceneFocus: friend.preferredScene.trim().isEmpty
              ? '自然开场聊天'
              : friend.preferredScene.trim(),
        ),
      ),
      (
        label: '延展共同话题',
        prompt: _promptForVirtualFriend(friend, sceneFocus: '围绕共同兴趣延展一个自然话题'),
      ),
      (
        label: '深入追问',
        prompt: _promptForVirtualFriend(friend, sceneFocus: '让对方继续追问细节并保持对话推进'),
      ),
      (
        label: '轻松收尾',
        prompt: _promptForVirtualFriend(friend, sceneFocus: '自然把对话带到下一步或轻松收尾'),
      ),
    ];
  }

  Future<void> _upsertVirtualFriend(_VirtualFriend friend) async {
    final List<_VirtualFriend> next = List<_VirtualFriend>.from(
      _virtualFriends,
    );
    final int existingIndex = next.indexWhere(
      (_VirtualFriend item) => item.id == friend.id,
    );
    if (existingIndex >= 0) {
      next[existingIndex] = friend;
    } else {
      next.insert(0, friend);
    }
    next.sort(
      (_VirtualFriend a, _VirtualFriend b) =>
          b.updatedAt.compareTo(a.updatedAt),
    );
    setState(() {
      _virtualFriends = next;
      _activeFriendId = friend.id;
    });
    await _persistVirtualFriends();
  }

  Future<void> _deleteVirtualFriend(_VirtualFriend friend) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('删除这个虚拟角色？'),
              content: Text('会删除“${friend.name}”的自定义设定，但不会影响已完成的场景记录。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    setState(() {
      _virtualFriends = _virtualFriends
          .where((_VirtualFriend item) => item.id != friend.id)
          .toList(growable: false);
      if (_activeFriendId == friend.id) {
        _activeFriendId = null;
      }
    });
    await _persistVirtualFriends();
  }

  void _openSceneCreate({_VirtualFriend? friend}) {
    setState(() {
      _activeFriendId = friend?.id;
      if (friend != null) {
        _draft = _draftFromVirtualFriend(friend);
        _controller.clear();
      } else if (_controller.text.trim().isEmpty) {
        _controller.clear();
      }
    });
    _setView(SceneFlowView.create);
  }

  Future<void> _showVirtualFriendEditor({_VirtualFriend? friend}) async {
    final TextEditingController nameController = TextEditingController(
      text: friend?.name ?? '',
    );
    final TextEditingController emojiController = TextEditingController(
      text: friend?.avatarEmoji ?? '🙂',
    );
    final TextEditingController roleController = TextEditingController(
      text: friend?.role ?? '',
    );
    final TextEditingController professionController = TextEditingController(
      text: friend?.profession ?? '',
    );
    final TextEditingController personalityController = TextEditingController(
      text: friend?.personality ?? '',
    );
    final TextEditingController hobbiesController = TextEditingController(
      text: friend?.hobbies.join('、') ?? '',
    );
    final TextEditingController relationshipController = TextEditingController(
      text: friend?.relationship ?? '',
    );
    final TextEditingController sceneController = TextEditingController(
      text: friend?.preferredScene ?? '',
    );
    final TextEditingController messageController = TextEditingController(
      text: friend?.lastMessage ?? '',
    );

    Future<void> submit() async {
      final String name = nameController.text.trim();
      final String role = roleController.text.trim();
      if (name.isEmpty || role.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('至少填写角色名称和角色定位')));
        return;
      }
      Navigator.of(context).pop();
      final _VirtualFriend nextFriend = _VirtualFriend(
        id:
            friend?.id ??
            'friend_${DateTime.now().microsecondsSinceEpoch.toString()}',
        name: name,
        avatarEmoji: emojiController.text.trim().isEmpty
            ? '🙂'
            : emojiController.text.trim(),
        role: role,
        personality: personalityController.text.trim(),
        profession: professionController.text.trim(),
        hobbies: hobbiesController.text
            .split(RegExp(r'[、,，/]'))
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
        relationship: relationshipController.text.trim(),
        preferredScene: sceneController.text.trim(),
        lastMessage: messageController.text.trim(),
        isCustom: true,
        updatedAt: DateTime.now(),
      );
      await _upsertVirtualFriend(nextFriend);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: appBackground,
      showDragHandle: true,
      builder: (BuildContext context) {
        final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: borderColor),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          friend == null ? '新建虚拟角色' : '编辑虚拟角色',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '支持配置角色、性格、爱好、职业和关系设定，保存后会直接出现在聊天列表。',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _VirtualFriendEditorField(
                    label: '角色名称',
                    hintText: '例如：Luna',
                    controller: nameController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VirtualFriendEditorField(
                          label: '头像 Emoji',
                          hintText: '🙂',
                          controller: emojiController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VirtualFriendEditorField(
                          label: '角色定位',
                          hintText: '例如：潜在客户 / 同事 / 面试官',
                          controller: roleController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VirtualFriendEditorField(
                          label: '职业',
                          hintText: '例如：品牌经理',
                          controller: professionController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VirtualFriendEditorField(
                          label: '性格',
                          hintText: '例如：理性、直接、细节控',
                          controller: personalityController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _VirtualFriendEditorField(
                    label: '爱好',
                    hintText: '多个爱好用 顿号 / 逗号 分隔',
                    controller: hobbiesController,
                  ),
                  const SizedBox(height: 12),
                  _VirtualFriendEditorField(
                    label: '你们的关系',
                    hintText: '例如：正在推进合作的甲乙方',
                    controller: relationshipController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _VirtualFriendEditorField(
                    label: '偏好的场景',
                    hintText: '例如：周会追问、初次破冰、需求澄清',
                    controller: sceneController,
                  ),
                  const SizedBox(height: 12),
                  _VirtualFriendEditorField(
                    label: '最近一句 / 开场白',
                    hintText: '用于聊天列表预览和场景生成参考',
                    controller: messageController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1AAD19),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(friend == null ? '保存并加入列表' : '保存修改'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  SceneFeedback? _sceneFeedbackFromStoredPractice(
    PracticeHistoryModel practice,
  ) {
    final Map<String, dynamic>? data = practice.feedbackData;
    if (data == null || data.isEmpty) {
      return null;
    }
    try {
      return SceneFeedback.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  SceneDraft? _sceneDraftFromStoredPractice(PracticeHistoryModel practice) {
    final Map<String, dynamic>? data = practice.sceneDraftData;
    if (data == null || data.isEmpty) {
      return null;
    }
    try {
      return _withSceneSpec(SceneDraft.fromJson(data));
    } catch (_) {
      return null;
    }
  }

  void _setView(SceneFlowView view) {
    if (_view == view) {
      _notifyBottomBarVisibility();
      return;
    }
    if (_isHomeSpeechRecording && view != SceneFlowView.create) {
      unawaited(_stopHomeSpeechInput().catchError((Object _) {}));
    }
    if (_view == SceneFlowView.chat && view != SceneFlowView.chat) {
      unawaited(_stopScenarioAudioPlayback().catchError((Object _) {}));
    }
    setState(() {
      _view = view;
      if (view == SceneFlowView.feedback && _feedback == null) {
        _ensureFeedbackReady();
      }
    });
    _notifyBottomBarVisibility();
    if (view == SceneFlowView.chat) {
      _scrollChatToLatest(animated: false);
    }
  }

  _SceneFeedbackRequestData? _buildFeedbackRequestData() {
    if (_restoredFeedbackRequestData != null) {
      return _restoredFeedbackRequestData;
    }
    final List<SceneHistoryTurn> history = _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => SceneHistoryTurn(
            role: m.role == _MessageRole.user ? 'user' : 'npc',
            text: m.text,
          ),
        )
        .toList(growable: false);
    if (history.isEmpty) {
      return null;
    }
    final List<SceneFeedbackVoiceTurn> allVoiceTurns = _messages
        .where(
          (m) =>
              m.role == _MessageRole.user &&
              m.inputType == _ChatInputType.voice &&
              m.text.trim().isNotEmpty,
        )
        .toList(growable: false)
        .indexed
        .map(
          (entry) => SceneFeedbackVoiceTurn(
            turnIndex: entry.$1 + 1,
            text: entry.$2.text.trim(),
          ),
        )
        .toList(growable: false);
    final List<SceneHistoryTurn> limitedHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;
    final List<SceneFeedbackVoiceTurn> limitedVoiceTurns =
        allVoiceTurns.length > 3
        ? allVoiceTurns.sublist(allVoiceTurns.length - 3)
        : allVoiceTurns;
    final String key = [
      _draft.title.trim(),
      _draft.goal.trim(),
      _draft.npcName.trim(),
      for (final SceneHistoryTurn turn in limitedHistory)
        '${turn.role}:${turn.text.trim()}',
      'voices',
      for (final SceneFeedbackVoiceTurn turn in limitedVoiceTurns)
        '${turn.turnIndex}:${turn.text.trim()}',
    ].join('|');
    return _SceneFeedbackRequestData(
      key: key,
      history: history,
      voiceTurns: allVoiceTurns,
    );
  }

  Map<String, dynamic>? _feedbackContextJson() {
    final _SceneFeedbackRequestData? data = _buildFeedbackRequestData();
    if (data == null) {
      return null;
    }
    return _feedbackContextJsonForData(data);
  }

  Map<String, dynamic> _feedbackContextJsonForData(
    _SceneFeedbackRequestData data,
  ) {
    return <String, dynamic>{
      'key': data.key,
      'history': data.history
          .map(
            (SceneHistoryTurn turn) => <String, dynamic>{
              'role': turn.role,
              'text': turn.text,
            },
          )
          .toList(growable: false),
      'voiceTurns': data.voiceTurns
          .map(
            (SceneFeedbackVoiceTurn turn) => <String, dynamic>{
              'turnIndex': turn.turnIndex,
              'text': turn.text,
            },
          )
          .toList(growable: false),
      if (_serviceTurnTraces.isNotEmpty)
        'serviceTurnTraces': _serviceTurnTraces
            .map((_ServiceTurnTrace item) => item.toJson())
            .toList(growable: false),
    };
  }

  void _persistScenePracticeFeedback({
    required AppSession session,
    required _SceneFeedbackRequestData data,
    required int score,
    required SceneFeedback feedback,
  }) {
    if (_scenePracticeRecorded) {
      return;
    }
    final int userTurns = data.history
        .where((SceneHistoryTurn turn) => turn.role == 'user')
        .length;
    if (userTurns == 0) {
      return;
    }
    _scenePracticeRecorded = true;
    _scenePracticePendingRecorded = false;
    unawaited(
      session.upsertPracticeFeedback(
        durationSeconds: (userTurns * 90).clamp(120, 900),
        score: score,
        title: _draft.title,
        emoji: _draft.emoji,
        tags: _draft.tags,
        feedback: feedback,
        promptText: _composeEditablePromptFromDraft(),
        sceneDraft: _draft,
        feedbackContext: _feedbackContextJsonForData(data),
      ),
    );
  }

  _SceneFeedbackRequestData? _feedbackRequestDataFromStoredPractice(
    PracticeHistoryModel practice,
  ) {
    final Map<String, dynamic>? data = practice.feedbackContextData;
    if (data == null || data.isEmpty) {
      return null;
    }
    final List<SceneHistoryTurn> history =
        ((data['history'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map item) {
              final Map<String, dynamic> map = item.cast<String, dynamic>();
              return SceneHistoryTurn(
                role: (map['role'] as String? ?? '').trim(),
                text: (map['text'] as String? ?? '').trim(),
              );
            })
            .where(
              (SceneHistoryTurn item) =>
                  item.role.isNotEmpty && item.text.isNotEmpty,
            )
            .toList(growable: false);
    final List<SceneFeedbackVoiceTurn> voiceTurns =
        ((data['voiceTurns'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map item) {
              final Map<String, dynamic> map = item.cast<String, dynamic>();
              return SceneFeedbackVoiceTurn(
                turnIndex: (map['turnIndex'] as num?)?.toInt() ?? 0,
                text: (map['text'] as String? ?? '').trim(),
              );
            })
            .where((SceneFeedbackVoiceTurn item) => item.text.isNotEmpty)
            .toList(growable: false);
    if (history.isEmpty) {
      return null;
    }
    return _SceneFeedbackRequestData(
      key: (data['key'] as String? ?? '').trim().isNotEmpty
          ? (data['key'] as String).trim()
          : [
              practice.title.trim(),
              for (final SceneHistoryTurn turn in history)
                '${turn.role}:${turn.text.trim()}',
            ].join('|'),
      history: history,
      voiceTurns: voiceTurns,
    );
  }

  SceneFeedback _buildInstantFeedback(_SceneFeedbackRequestData data) {
    final int rounds = data.history
        .where((SceneHistoryTurn t) => t.role == 'user')
        .length;
    final int overall = (64 + rounds * 4).clamp(64, 92);
    final List<SceneFeedbackTurnReview> turnReviews =
        const <SceneFeedbackTurnReview>[];

    final int clarity = turnReviews.isEmpty
        ? 78
        : (turnReviews
                      .map(
                        (SceneFeedbackTurnReview item) =>
                            item.pronunciationScore,
                      )
                      .reduce((int a, int b) => a + b) ~/
                  turnReviews.length)
              .clamp(60, 92);
    final int structure = (70 + rounds * 3).clamp(68, 90);
    final int adaptability = (68 + rounds * 2).clamp(66, 88);

    return SceneFeedback(
      overallScore: overall,
      headline: rounds >= 3 ? '复盘已就绪，先修关键表达' : '复盘已就绪，继续开口会更稳',
      summary: '这轮对话已经完成即时复盘。建议先看你最近几条语音的发音、语法和表达方式，再把替代表达复述一遍。',
      metrics: <SceneFeedbackMetric>[
        SceneFeedbackMetric(
          label: '清晰度',
          score: clarity,
          color: const Color(0xFF4A7C6F),
        ),
        SceneFeedbackMetric(
          label: '结构感',
          score: structure,
          color: const Color(0xFF5A6FA8),
        ),
        SceneFeedbackMetric(
          label: '临场应对',
          score: adaptability,
          color: const Color(0xFFA0622A),
        ),
      ],
      coachTip: '下一轮只优先修正最近一条最关键表达，再重复练一遍，提升会最明显。',
      improvements: const <(String, String, String)>[
        ('🗣️', '先修关键词发音', '把场景里的关键词先读准，比同时改很多问题更有效。'),
        ('✂️', '一句只说一个重点', '句子更短、更直接，语法错误和理解成本都会一起下降。'),
        ('✨', '替换成更自然表达', '把直译句换成更常见的职场英文，整体会更像真实沟通。'),
      ],
      turnReviews: turnReviews,
    );
  }

  void _ensureFeedbackReady() {
    final AppSession session = AppSessionScope.of(context);
    final _SceneFeedbackRequestData? data = _buildFeedbackRequestData();
    if (data == null) {
      _isFeedbackLoading = false;
      return;
    }
    if (_feedback != null && _feedbackCacheKey == data.key) {
      _isFeedbackLoading = false;
      _lastFeedbackError = null;
      _persistScenePracticeFeedback(
        session: session,
        data: data,
        score: _feedback!.overallScore,
        feedback: _feedback!,
      );
      return;
    }
    _generateFeedback(force: true);
  }

  void _generateFeedback({bool silent = false, bool force = false}) {
    final AppSession session = AppSessionScope.of(context);
    final _SceneFeedbackRequestData? data = _buildFeedbackRequestData();
    if (data == null) {
      if (mounted) {
        setState(() {
          _isFeedbackLoading = false;
        });
      }
      return;
    }
    if (!force && _feedback != null && _feedbackCacheKey == data.key) {
      if (mounted) {
        setState(() {
          _isFeedbackLoading = false;
        });
      }
      return;
    }
    if (!force && _feedbackPendingKey == data.key) {
      if (!silent && mounted) {
        setState(() {
          _isFeedbackLoading = true;
        });
      }
      return;
    }

    final int generation = ++_feedbackTaskGeneration;
    _recordScenePracticePendingIfNeeded();
    if (mounted) {
      setState(() {
        _feedbackPendingKey = data.key;
        _feedbackStartedAt = DateTime.now();
        if (!silent) {
          _isFeedbackLoading = true;
        }
        _lastFeedbackError = null;
      });
    } else {
      _feedbackPendingKey = data.key;
      _feedbackStartedAt = DateTime.now();
    }

    session
        .generateSceneFeedback(
          draft: _draft,
          history: data.history,
          voiceTurns: data.voiceTurns,
        )
        .then((SceneFeedback feedback) {
          _persistScenePracticeFeedback(
            session: session,
            data: data,
            score: feedback.overallScore,
            feedback: feedback,
          );
          if (!mounted ||
              generation != _feedbackTaskGeneration ||
              _feedbackPendingKey != data.key) {
            return;
          }
          final bool shouldAnnounce = _view != SceneFlowView.feedback;
          setState(() {
            _feedback = feedback;
            _feedbackCacheKey = data.key;
            _feedbackPendingKey = null;
            _feedbackStartedAt = null;
            _isFeedbackLoading = false;
            _lastFeedbackError = null;
          });
          if (_view == SceneFlowView.feedback) {
            return;
          }
          if (shouldAnnounce && _feedbackCompletionAnnouncedKey != data.key) {
            _feedbackCompletionAnnouncedKey = data.key;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('高质量复盘已生成'),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: '查看',
                  onPressed: () => _setView(SceneFlowView.feedback),
                ),
              ),
            );
          }
        })
        .catchError((Object error) {
          final String message = error.toString().split(':').last.trim();
          final SceneFeedback fallback = _buildInstantFeedback(data);
          _persistScenePracticeFeedback(
            session: session,
            data: data,
            score: fallback.overallScore,
            feedback: fallback,
          );
          if (!mounted ||
              generation != _feedbackTaskGeneration ||
              _feedbackPendingKey != data.key) {
            return;
          }
          setState(() {
            _feedback = fallback;
            _feedbackCacheKey = data.key;
            _feedbackPendingKey = null;
            _feedbackStartedAt = null;
            _isFeedbackLoading = false;
            _lastFeedbackError = message;
          });
          if (_view == SceneFlowView.feedback) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('高质量复盘失败，已切换到快速版: $message'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
  }

  void _recordScenePracticePendingIfNeeded() {
    if (_scenePracticePendingRecorded || _scenePracticeRecorded) {
      return;
    }
    final int userTurns = _messages
        .where((m) => m.role == _MessageRole.user)
        .length;
    if (userTurns == 0) {
      return;
    }
    _scenePracticePendingRecorded = true;
    final AppSession session = AppSessionScope.of(context);
    unawaited(
      session.recordPracticeSession(
        durationSeconds: (userTurns * 90).clamp(120, 900),
        score: 0,
        title: _draft.title,
        emoji: _draft.emoji,
        tags: _draft.tags,
        promptText: _composeEditablePromptFromDraft(),
        sceneDraft: _draft,
        feedbackStatus: 'pending',
        feedbackContext: _feedbackContextJson(),
      ),
    );
  }

  Widget _buildFeedbackStatusBanner() {
    final _SceneFeedbackRequestData? data = _buildFeedbackRequestData();
    if (data == null) {
      return const SizedBox.shrink();
    }
    final bool pending = _feedbackPendingKey == data.key;
    if (!pending) {
      return const SizedBox.shrink();
    }

    const Color accent = Color(0xFF8A6A2F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33C7A96B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0x14C7A96B),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A6A2F)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '高质量复盘生成中',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '后台仍在继续生成，预计还需要 10-15 秒。',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Color(0xFF6E675F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.24)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(76, 38),
            ),
            child: const Text('生成中'),
          ),
        ],
      ),
    );
  }

  int get _practiceRoundCount =>
      _messages.where((m) => m.role == _MessageRole.user).length;

  bool get _hasPracticeContent => _practiceRoundCount > 0;
  bool get _hasActiveVoiceSession =>
      _voiceChatConnecting ||
      (_voiceChatService?.isConnected ?? false) ||
      _voiceSessionMode != _VoiceSessionMode.none;

  Future<void> _exitPracticeDirectly() async {
    if (_hasActiveVoiceSession) {
      await _stopRealtimeCall();
    } else if (_isRecording) {
      _finishChatRecording(send: false);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _expandedCoachMessageIndex = null;
      _showTextComposer = false;
      _feedback = null;
      _feedbackCacheKey = null;
      _feedbackPendingKey = null;
      _feedbackStartedAt = null;
      _feedbackCompletionAnnouncedKey = null;
      _feedbackTaskGeneration += 1;
      _isFeedbackLoading = false;
      _scenePracticeRecorded = false;
      _feedbackOpenedFromRecentSummary = false;
    });
    _setView(SceneFlowView.draft);
  }

  Future<void> _endPracticeAndReview({bool confirm = true}) async {
    if (!_hasPracticeContent) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('至少完成一轮对话后再复盘'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isNpcThinking) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请等 AI 当前回复完成后再结束'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    bool shouldEnd = !confirm;
    bool shouldExitDirectly = false;
    if (confirm && mounted) {
      final String? decision = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '结束本轮练习？',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '会停止当前对话，并基于这轮内容生成复盘反馈。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop('exit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEAE7E2),
                            side: const BorderSide(color: Color(0x26FFFFFF)),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('直接退出'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop('review'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E6058),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('结束并复盘'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      shouldExitDirectly = decision == 'exit';
      shouldEnd = decision == 'review';
    }

    if (shouldExitDirectly) {
      await _exitPracticeDirectly();
      return;
    }

    if (!shouldEnd || !mounted) {
      return;
    }

    if (_hasActiveVoiceSession) {
      await _stopRealtimeCall();
    } else if (_isRecording) {
      _finishChatRecording(send: false);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _expandedCoachMessageIndex = null;
      _showTextComposer = false;
      _feedbackOpenedFromRecentSummary = false;
    });
    _setView(SceneFlowView.feedback);
  }

  void _scrollChatToLatest({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) {
        return;
      }
      final double target = _chatScrollController.position.maxScrollExtent;
      if (animated) {
        _chatScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      _chatScrollController.jumpTo(target);
    });
  }

  void _toggleVoiceMessageTranscript(int index) {
    setState(() {
      if (_expandedVoiceMessageIndexes.contains(index)) {
        _expandedVoiceMessageIndexes.remove(index);
      } else {
        _expandedVoiceMessageIndexes.add(index);
      }
    });
  }

  Future<void> _toggleVoiceMessageTranslation(int index) async {
    if (index < 0 || index >= _messages.length) {
      return;
    }
    final String sourceText = _messages[index].text.trim();
    if (sourceText.isEmpty) {
      return;
    }
    if (_voiceMessageTranslations.containsKey(index)) {
      setState(() {
        if (_translatedVoiceMessageIndexes.contains(index)) {
          _translatedVoiceMessageIndexes.remove(index);
        } else {
          _translatedVoiceMessageIndexes.add(index);
        }
      });
      return;
    }

    setState(() {
      _translatingVoiceMessageIndexes.add(index);
    });

    try {
      final String translated = await _sceneAuxiliaryCoordinator.translateText(
        sourceText,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceMessageTranslations[index] = translated;
        _translatedVoiceMessageIndexes.add(index);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('翻译失败: ${e.toString().split(':').last.trim()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _translatingVoiceMessageIndexes.remove(index);
        });
      }
    }
  }

  int _fallbackVoiceDurationFromText(String text, {int fallback = 3}) {
    final String cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      return fallback;
    }
    return ((cleanedText.length / 18).round()).clamp(1, 18);
  }

  Future<int> _resolveVoiceDurationSeconds({
    String? audioPath,
    String? fallbackText,
    int fallback = 3,
  }) async {
    final String? cleanedPath = audioPath?.trim();
    if (cleanedPath != null && cleanedPath.isNotEmpty && mounted) {
      final AudioService audioService = AudioServiceScope.of(context);
      final int? seconds = await audioService.getAudioDurationSeconds(
        cleanedPath,
      );
      if (seconds != null && seconds > 0) {
        return seconds;
      }
    }
    return _fallbackVoiceDurationFromText(
      fallbackText ?? '',
      fallback: fallback,
    );
  }

  Future<void> _playVoiceMessage(_ChatMessage message) async {
    if (!mounted || message.inputType != _ChatInputType.voice) {
      return;
    }
    final AudioService audioService = AudioServiceScope.of(context);
    final String? audioPath = message.audioPath?.trim();
    if (audioPath != null && audioPath.isNotEmpty) {
      await audioService.playFile(audioPath);
      return;
    }
    if (message.role == _MessageRole.npc) {
      await audioService.playTts(message.text);
    }
  }

  Widget _buildDraftOverviewCard() {
    final String plotSummary = _draftOverviewPlotSummary();
    final List<String> plotSteps = _draftOverviewPlotSteps();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9E3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 28,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x144A7C6F),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0x384A7C6F),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _draft.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _draft.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Color(0xFF18160F),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _draftOverviewSubtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: Color(0xFF9A938A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFFEDE9E3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DraftOverviewInfoCard(
                        tintColor: const Color(0x104A7244),
                        borderColor: const Color(0x124A7244),
                        iconBackgroundColor: const Color(0x154A7C6F),
                        label: '你的角色',
                        labelColor: const Color(0xFF4A7244),
                        value: _draft.userRole,
                        icon: '🙋',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DraftOverviewInfoCard(
                        tintColor: const Color(0x106B8BBB),
                        borderColor: const Color(0x126B8BBB),
                        iconBackgroundColor: const Color(0x156B8BBB),
                        label: '对方角色',
                        labelColor: const Color(0xFF6B8BBB),
                        value: '${_draft.npcName} ${_draft.npcRole}',
                        icon: '🗣️',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DraftOverviewWideCard(
                  tintColor: const Color(0xFFF7F4EF),
                  borderColor: const Color(0xFFEDE9E3),
                  iconBackgroundColor: const Color(0x188B6914),
                  label: '对话背景',
                  labelColor: const Color(0xFF8B6914),
                  value: _draftOverviewBackgroundText(),
                  icon: '💬',
                ),
                const SizedBox(height: 10),
                _DraftOverviewGoalCard(
                  label: '剧情介绍',
                  labelColor: const Color(0xFFC0641A),
                  icon: '🎬',
                  summary: plotSummary,
                  steps: plotSteps,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startChatRecording() {
    if (_isRecording || _isNpcThinking || _voiceChatConnecting) {
      return;
    }
    _mockInputTimer?.cancel();
    _scrollChatToLatest(animated: false);
    setState(() {
      _isRecording = true;
      _chatRecordingWillCancel = false;
      _chatRecordingPreviewText = '';
      _chatRecordingHintText = '';
      _chatSpeechPreviewUnavailable = false;
      _controller.clear();
    });
    _chatSpeechPreviewGeneration++;
    _chatSpeechPreviewRestartTimer?.cancel();
    _chatPreviewSentChunkCount = 0;

    final AudioService audioService = AudioServiceScope.of(context);
    _pendingTurnVoiceChunks.clear();
    audioService
        .requestPermission()
        .then((bool hasPermission) async {
          if (!mounted || !_isRecording) {
            return;
          }
          if (!hasPermission) {
            setState(() {
              _isRecording = false;
              _chatRecordingWillCancel = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('请先允许麦克风权限'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          await audioService.startStreamRecording((Uint8List pcmData) {
            if (pcmData.isEmpty) {
              return;
            }
            _pendingTurnVoiceChunks.add(Uint8List.fromList(pcmData));
            _flushChatPreviewAudio();
          });
          unawaited(_startChatPreviewVoiceService());
        })
        .catchError((Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isRecording = false;
            _chatRecordingWillCancel = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('录音启动失败: $error'),
              duration: const Duration(seconds: 2),
            ),
          );
        });
  }

  void _updateChatRecordingDrag(LongPressMoveUpdateDetails details) {
    if (!_isRecording) {
      return;
    }
    final bool shouldCancel = details.offsetFromOrigin.dy < -56;
    if (_chatRecordingWillCancel == shouldCancel) {
      return;
    }
    setState(() {
      _chatRecordingWillCancel = shouldCancel;
    });
  }

  void _finishChatRecording({required bool send}) {
    if (!_isRecording) {
      return;
    }
    _mockInputTimer?.cancel();
    final Future<String> previewTranscriptFuture =
        _finishChatPreviewVoiceService(send: send);
    setState(() {
      _isRecording = false;
      _chatRecordingWillCancel = false;
    });

    if (!send) {
      final AudioService audioService = AudioServiceScope.of(context);
      _pendingTurnVoiceChunks.clear();
      unawaited(audioService.stopStreamRecording().catchError((Object _) {}));
      unawaited(
        previewTranscriptFuture.whenComplete(() {
          if (!mounted) {
            return;
          }
          setState(() {
            _chatRecordingPreviewText = '';
            _chatRecordingHintText = '';
            _chatSpeechPreviewUnavailable = false;
          });
        }),
      );
      return;
    }

    final AudioService audioService = AudioServiceScope.of(context);
    final List<Uint8List> recordedChunks = List<Uint8List>.from(
      _pendingTurnVoiceChunks,
    );
    _pendingTurnVoiceChunks.clear();
    audioService
        .stopStreamRecording()
        .then((_) async {
          await previewTranscriptFuture;
          if (!mounted) {
            return;
          }
          if (recordedChunks.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('未录到语音，请重试'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('语音提交暂未接入可信上传流程，请改用文字输入'),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _chatRecordingPreviewText = '';
            _chatRecordingHintText = '';
            _chatSpeechPreviewUnavailable = false;
          });
        })
        .catchError((Object error) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('录音结束失败: $error'),
              duration: const Duration(seconds: 2),
            ),
          );
        });
  }

  void _toggleChatRecording() {
    if (_realtimeMode) {
      if (_voiceChatConnecting) {
        _cleanupVoiceChatSession();
        setState(() {
          _voiceChatConnecting = false;
          _isRecording = false;
        });
        return;
      }
      if (_isRecording || (_voiceChatService?.isConnected ?? false)) {
        _stopRealtimeCall();
      } else {
        _startRealtimeCall();
      }
      return;
    }
    if (_isRecording) {
      _finishChatRecording(send: true);
      return;
    }
    _startChatRecording();
  }

  /// 构建 WebSocket 实时通话的 system prompt
  String _buildRealtimeSystemPrompt() {
    final bool hasPriorUserTurns = _messages.any(
      (m) => m.role == _MessageRole.user,
    );
    final List<SceneHistoryTurn> recentTurns = _recentSceneTurnsOnly(
      includeOpeningNpcTurn: hasPriorUserTurns,
    );
    final SceneDraft promptDraft = _draftForAssistantTurn(recentTurns);
    final String historyText = _buildHistoryWithSummary(
      includeOpeningNpcTurn: hasPriorUserTurns,
    );
    final String agendaPrompt = _buildAgendaPromptOnly(recentTurns);
    final String historyPrompt = historyText.isEmpty
        ? agendaPrompt
        : '$historyText\n\n$agendaPrompt';
    return _sceneSpecForDraft(promptDraft).buildSystemPrompt(
      promptDraft,
      hasPriorUserTurns: hasPriorUserTurns,
      historyPrompt: historyPrompt,
      isRealtime: true,
      roleMemoryHints: _sceneRoleMemoryHints,
      learningProfileHints: _sceneLearningProfileHints,
    );
  }

  String _buildTurnBasedSystemPrompt() {
    final bool hasPriorUserTurns = _messages.any(
      (m) => m.role == _MessageRole.user,
    );
    final List<SceneHistoryTurn> recentTurns = _recentSceneTurnsOnly(
      includeOpeningNpcTurn: hasPriorUserTurns,
    );
    final SceneDraft promptDraft = _draftForAssistantTurn(recentTurns);
    final String historyText = _buildHistoryWithSummary(
      includeOpeningNpcTurn: hasPriorUserTurns,
    );
    final String agendaPrompt = _buildAgendaPromptOnly(recentTurns);
    final String historyPrompt = historyText.isEmpty
        ? agendaPrompt
        : '$historyText\n\n$agendaPrompt';
    return _sceneSpecForDraft(promptDraft).buildSystemPrompt(
      promptDraft,
      hasPriorUserTurns: hasPriorUserTurns,
      historyPrompt: historyPrompt,
      isRealtime: false,
      roleMemoryHints: _sceneRoleMemoryHints,
      learningProfileHints: _sceneLearningProfileHints,
    );
  }

  Map<String, dynamic> _buildVoiceSceneContext({
    required List<SceneHistoryTurn> historyTurns,
  }) {
    return <String, dynamic>{
      'draft': <String, dynamic>{
        'title': _draft.title,
        if (_draft.roleId?.trim().isNotEmpty ?? false)
          'roleId': _draft.roleId!.trim(),
        if (_draft.characterProfile != null)
          'characterProfile': _draft.characterProfile!.toJson(),
        if (_draft.discussionTopic?.trim().isNotEmpty ?? false)
          'discussionTopic': _draft.discussionTopic!.trim(),
        if (_draft.desiredOutcome?.trim().isNotEmpty ?? false)
          'desiredOutcome': _draft.desiredOutcome!.trim(),
        'userRole': _draft.userRole,
        'relationship': _draft.relationship,
        'goal': _draft.goal,
        'npcName': _draft.npcName,
        'npcRole': _draft.npcRole,
        'environment': _draft.environment,
        'challenge': _draft.challenge,
        'plotDesign': _draft.plotDesign,
      },
      'sceneSpec': _effectiveSceneSpec.toJson(),
      if (_sceneRoleMemoryHints.isNotEmpty)
        'roleMemory': _sceneRoleMemoryHints
            .map((String item) => <String, dynamic>{'text': item})
            .toList(growable: false),
      if (_sceneLearningProfileHints.isNotEmpty)
        'learningProfileHints': _sceneLearningProfileHints
            .map((String item) => <String, dynamic>{'text': item})
            .toList(growable: false),
      'history': historyTurns
          .map(
            (SceneHistoryTurn turn) => <String, dynamic>{
              'role': turn.role,
              'text': turn.text,
            },
          )
          .toList(growable: false),
      if (_serverSceneState != null)
        'sceneState': <String, dynamic>{
          'currentStageId': _serverSceneState!.currentStageId,
          'currentStageLabel': _serverSceneState!.currentStageLabel,
          'currentStageIndex': _serverSceneState!.currentStageIndex,
          'totalStages': _serverSceneState!.totalStages,
          'userTurnCount': _serverSceneState!.userTurnCount,
          'topic': _serverSceneState!.topic,
          'filledFacts': _serverSceneState!.filledFacts,
          'missingFacts': _serverSceneState!.missingFacts,
          'repairCount': _serverSceneState!.repairCount,
          'offTopicCount': _serverSceneState!.offTopicCount,
          'lastUserIntent': _serverSceneState!.lastUserIntent,
          'stageSatisfied': _serverSceneState!.stageSatisfied,
          'confidence': _serverSceneState!.confidence,
        },
    };
  }

  /// 仅获取最近 N 轮对话（给 _draftForAssistantTurn 等需要 turn 列表的方法用）。
  List<SceneHistoryTurn> _recentSceneTurnsOnly({
    bool includeOpeningNpcTurn = true,
  }) {
    final List<SceneHistoryTurn> recentTurns = _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => SceneHistoryTurn(
            role: m.role == _MessageRole.user ? 'user' : 'npc',
            text: _stripSceneMetadataSuffix(m.text),
          ),
        )
        .where((SceneHistoryTurn turn) => turn.text.trim().isNotEmpty)
        .toList(growable: false);
    if (recentTurns.isEmpty) {
      return const <SceneHistoryTurn>[];
    }
    final List<SceneHistoryTurn> filteredTurns = includeOpeningNpcTurn
        ? recentTurns
        : recentTurns
              .skipWhile((SceneHistoryTurn turn) => turn.role == 'npc')
              .toList(growable: false);
    if (filteredTurns.isEmpty) {
      return const <SceneHistoryTurn>[];
    }
    final Iterable<SceneHistoryTurn> window =
        filteredTurns.length > _recentHistoryKeepCount
        ? filteredTurns.skip(filteredTurns.length - _recentHistoryKeepCount)
        : filteredTurns;
    return window.toList(growable: false);
  }

  /// 仅构建 agenda 控制提示（不含对话历史）。
  String _buildAgendaPromptOnly(List<SceneHistoryTurn> recentTurns) {
    final _SceneTurnContract contract = _buildSceneTurnContract(recentTurns);
    final List<String> agendaLines = <String>[
      'Current agenda control:',
      '- Current stage: ${contract.stageLabel}.',
      '- Current learner task: ${contract.learnerTaskEn}.',
      '- Learner hint goal (hidden): ${contract.learnerGoalZh}.',
      '- Question focus: ${contract.questionFocus}.',
      '- NPC turn summary: ${contract.npcTurnSummary}.',
      '- NPC turn instruction: ${contract.npcTurnInstruction}.',
      '- Keep the conversation on this stage until it is answered clearly enough.',
      if (contract.mustAsk.isNotEmpty)
        '- This turn must stay on: ${contract.mustAsk.join(', ')}.',
      if (contract.mustAvoid.isNotEmpty)
        '- Avoid these turn-level drifts: ${contract.mustAvoid.join(', ')}.',
    ];
    if (contract.confirmedFacts.isNotEmpty) {
      agendaLines.add(
        '- Confirmed facts so far: ${contract.confirmedFacts.join('; ')}.',
      );
    }
    return agendaLines.join('\n');
  }

  SceneDraft _draftWithSceneSpec(SceneSpec sceneSpec) {
    return SceneDraft(
      title: _draft.title,
      emoji: _draft.emoji,
      tags: _draft.tags,
      roleId: _draft.roleId,
      characterProfile: _draft.characterProfile,
      discussionTopic: _draft.discussionTopic,
      desiredOutcome: _draft.desiredOutcome,
      userRole: _draft.userRole,
      relationship: _draft.relationship,
      goal: _draft.goal,
      npcName: _draft.npcName,
      npcRole: _draft.npcRole,
      environment: _draft.environment,
      challenge: _draft.challenge,
      plotDesign: _draft.plotDesign,
      sceneSpec: sceneSpec,
    );
  }

  SceneDraft _draftForAssistantTurn(List<SceneHistoryTurn> turns) {
    final _SceneTurnContract contract = _buildSceneTurnContract(turns);
    final SceneSpec base = _effectiveSceneSpec;
    final Set<String> mustInclude = <String>{
      ...base.mustInclude,
      contract.npcTurnSummary,
      contract.npcTurnInstruction,
      '当前用户任务：${contract.learnerTaskEn}',
      if (contract.questionFocus.trim().isNotEmpty)
        '当前问题焦点：${contract.questionFocus.trim()}',
      if (contract.mustAsk.isNotEmpty) '本轮必须围绕：${contract.mustAsk.join(', ')}',
    }..removeWhere((String item) => item.trim().isEmpty);
    final Set<String> mustNot = <String>{
      ...base.mustNot,
      '不要偏离当前回合目标',
      '不要输出教练提示、提醒语或元解释',
      if (_effectiveSceneSpec.category == 'service') ...<String>[
        '不要重复询问已经确认过的点单细节',
        '不要在一个回合里追问多个点单细节',
        '不要切换到和当前点单无关的话题',
      ],
      ...contract.mustAvoid.map((String item) => '避免：$item'),
    };
    final SceneSpec enhancedSpec = SceneSpec(
      category: base.category,
      timeContext: base.timeContext,
      tone: base.tone,
      pressureLevel: base.pressureLevel,
      interruptionLevel: base.interruptionLevel,
      followupDepth: base.followupDepth,
      warmth: base.warmth,
      responseLength: base.responseLength,
      mustNot: mustNot.toList(growable: false),
      mustInclude: mustInclude.toList(growable: false),
      version: base.version,
      plotDesign: base.plotDesign,
      plotBeats: base.plotBeats,
      lastUserIntent: base.lastUserIntent,
    );
    return _draftWithSceneSpec(enhancedSpec);
  }

  void _refreshVoiceSessionGuidance() {
    final VoiceChatService? service = _voiceChatService;
    if (service == null || !service.isConnected) {
      return;
    }
    _sceneVoiceRuntimeCoordinator.updateSession(
      service: service,
      config: SceneVoiceSessionConfig(
        sessionId: _sessionId,
        systemPrompt: _voiceSessionMode == _VoiceSessionMode.realtime
            ? _buildRealtimeSystemPrompt()
            : _buildTurnBasedSystemPrompt(),
        manualTurnDetection: _voiceSessionMode == _VoiceSessionMode.turnBased,
        plannerMode: _voiceSessionMode == _VoiceSessionMode.realtime,
      ),
    );
    unawaited(_refreshConversationSummary());
  }

  /// 构建对话历史提示（含摘要 + 最近 N 轮完整对话）。
  String _buildHistoryWithSummary({bool includeOpeningNpcTurn = true}) {
    final List<SceneHistoryTurn> allTurns = _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => SceneHistoryTurn(
            role: m.role == _MessageRole.user ? 'user' : 'npc',
            text: _stripSceneMetadataSuffix(m.text),
          ),
        )
        .where((SceneHistoryTurn turn) => turn.text.trim().isNotEmpty)
        .toList(growable: false);
    if (allTurns.isEmpty) {
      return '';
    }
    final List<SceneHistoryTurn> filteredTurns = includeOpeningNpcTurn
        ? allTurns
        : allTurns
              .skipWhile((SceneHistoryTurn turn) => turn.role == 'npc')
              .toList(growable: false);
    if (filteredTurns.isEmpty) {
      return '';
    }

    // 如果所有对话都装得下，直接用完整对话
    if (filteredTurns.length <= _recentHistoryKeepCount) {
      return _buildRecentConversationPromptFromTurns(filteredTurns);
    }

    // 超出窗口：摘要 + 最近 N 轮
    final List<SceneHistoryTurn> recentTurns = filteredTurns.sublist(
      filteredTurns.length - _recentHistoryKeepCount,
    );
    final StringBuffer buffer = StringBuffer();

    if (_conversationSummary != null && _conversationSummary!.isNotEmpty) {
      buffer.writeln('Earlier conversation summary:');
      buffer.writeln(_conversationSummary!);
      buffer.writeln();
    }

    buffer.writeln('Recent conversation context:');
    for (final SceneHistoryTurn turn in recentTurns) {
      final String speaker = turn.role == 'user' ? 'Learner' : _draft.npcName;
      buffer.writeln('$speaker: ${turn.text}');
    }
    buffer.write(
      'Continue from this context naturally. Do not repeat earlier lines unless needed.',
    );
    return buffer.toString();
  }

  /// 异步生成或更新对话摘要（fire-and-forget，不阻塞主流程）。
  Future<void> _refreshConversationSummary() async {
    if (_summaryGenerating) {
      return;
    }
    final List<SceneHistoryTurn> allTurns = _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => SceneHistoryTurn(
            role: m.role == _MessageRole.user ? 'user' : 'npc',
            text: _stripSceneMetadataSuffix(m.text),
          ),
        )
        .where((SceneHistoryTurn turn) => turn.text.trim().isNotEmpty)
        .toList(growable: false);

    // 需要超过摘要阈值 + 最近保留窗口，才有必要摘要
    if (allTurns.length < _recentHistoryKeepCount + _summaryTriggerThreshold) {
      return;
    }

    // 检查自上次摘要以来是否有足够新消息
    if (allTurns.length - _summaryLastTurnCount < _summaryTriggerThreshold) {
      return;
    }

    _summaryGenerating = true;
    try {
      final List<SceneHistoryTurn> turnsToSummarize =
          allTurns.length > _recentHistoryKeepCount + _summaryTriggerThreshold
          ? allTurns.sublist(0, allTurns.length - _recentHistoryKeepCount)
          : allTurns;
      final String summary = await _sceneAuxiliaryCoordinator
          .generateConversationSummary(
            npcName: _draft.npcName,
            history: turnsToSummarize
                .map(
                  (SceneHistoryTurn turn) => <String, dynamic>{
                    'role': turn.role,
                    'text': turn.text,
                  },
                )
                .toList(growable: false),
            existingSummary: _conversationSummary,
          );
      if (summary.trim().isNotEmpty) {
        _conversationSummary = summary.trim();
        _summaryLastTurnCount = allTurns.length;
      }
    } catch (error) {
      debugPrint('[Scene] Conversation summary generation failed: $error');
    } finally {
      _summaryGenerating = false;
    }
  }

  /// 兼容别名：仅返回最近 N 轮对话（供 service trace、coach hint 等使用）。
  List<SceneHistoryTurn> _currentSceneHistoryTurns({
    bool includeOpeningNpcTurn = true,
  }) {
    return _recentSceneTurnsOnly(includeOpeningNpcTurn: includeOpeningNpcTurn);
  }

  String _buildRecentConversationPromptFromTurns(List<SceneHistoryTurn> turns) {
    if (turns.isEmpty) {
      return '';
    }
    final StringBuffer buffer = StringBuffer('Recent conversation context:\n');
    for (final SceneHistoryTurn turn in turns) {
      final String speaker = turn.role == 'user' ? 'Learner' : _draft.npcName;
      buffer.writeln('$speaker: ${turn.text}');
    }
    buffer.write(
      'Continue from this context naturally. Do not repeat earlier lines unless needed.',
    );
    return buffer.toString();
  }

  _SceneAgendaCue _sceneAgendaCueForTurns(List<SceneHistoryTurn> turns) {
    if (_effectiveSceneSpec.category == 'service') {
      return _servicePolicyDecision(turns).cue;
    }
    final int userTurnCount = turns
        .where((SceneHistoryTurn turn) => turn.role == 'user')
        .length;
    final List<String> customPlotBeats = _effectiveSceneSpec.plotBeats;
    if (customPlotBeats.isNotEmpty) {
      final int index = userTurnCount.clamp(0, customPlotBeats.length - 1);
      final String currentBeat = customPlotBeats[index];
      return _SceneAgendaCue(
        stageLabel: '剧情阶段 ${index + 1}',
        learnerTaskEn:
            'move the conversation through this plot beat: $currentBeat',
        coachHintZh: currentBeat,
      );
    }
    final List<_SceneAgendaCue> cues;
    switch (_effectiveSceneSpec.category) {
      case 'process_review':
        cues = const <_SceneAgendaCue>[
          _SceneAgendaCue(
            stageLabel: '问题定位',
            learnerTaskEn:
                'name the single biggest process bottleneck and why it hurts delivery',
            coachHintZh: '先点出最大流程卡点',
          ),
          _SceneAgendaCue(
            stageLabel: '原因定位',
            learnerTaskEn:
                'explain the main cause behind that bottleneck with one concrete example',
            coachHintZh: '再说卡点背后的原因',
          ),
          _SceneAgendaCue(
            stageLabel: '方案聚焦',
            learnerTaskEn:
                'propose one change you would try first and why it should come first',
            coachHintZh: '给一个优先改动方案',
          ),
          _SceneAgendaCue(
            stageLabel: '落地动作',
            learnerTaskEn: 'give the owner, the next step, and the timeline',
            coachHintZh: '补负责人和下一步',
          ),
        ];
        break;
      case 'work_review':
        cues = const <_SceneAgendaCue>[
          _SceneAgendaCue(
            stageLabel: '进展结论',
            learnerTaskEn: 'give the current status in one clear sentence',
            coachHintZh: '先说当前进展结论',
          ),
          _SceneAgendaCue(
            stageLabel: '阻塞原因',
            learnerTaskEn: 'explain the main blocker or root cause',
            coachHintZh: '再讲主要阻塞原因',
          ),
          _SceneAgendaCue(
            stageLabel: '补救方案',
            learnerTaskEn:
                'describe the recovery plan with one concrete action',
            coachHintZh: '给出一个补救动作',
          ),
          _SceneAgendaCue(
            stageLabel: '时间责任',
            learnerTaskEn: 'state the owner and the target date clearly',
            coachHintZh: '补时间点和负责人',
          ),
        ];
        break;
      case 'client':
        cues = const <_SceneAgendaCue>[
          _SceneAgendaCue(
            stageLabel: '回应关切',
            learnerTaskEn: 'answer the client’s main concern directly',
            coachHintZh: '先回应对方最关心点',
          ),
          _SceneAgendaCue(
            stageLabel: '补充说明',
            learnerTaskEn: 'briefly explain the reason behind the issue',
            coachHintZh: '再补一句核心原因',
          ),
          _SceneAgendaCue(
            stageLabel: '缓解动作',
            learnerTaskEn: 'offer one mitigation action or workaround',
            coachHintZh: '给一个缓解动作',
          ),
          _SceneAgendaCue(
            stageLabel: '承诺动作',
            learnerTaskEn: 'give the next commitment and timeline',
            coachHintZh: '补承诺和时间点',
          ),
        ];
        break;
      case 'interview':
        cues = const <_SceneAgendaCue>[
          _SceneAgendaCue(
            stageLabel: '直接回答',
            learnerTaskEn: 'answer the question directly in one clear sentence',
            coachHintZh: '先直接回答问题',
          ),
          _SceneAgendaCue(
            stageLabel: '具体例子',
            learnerTaskEn: 'support your answer with one specific example',
            coachHintZh: '补一个具体例子',
          ),
          _SceneAgendaCue(
            stageLabel: '结果影响',
            learnerTaskEn: 'explain the result or impact of your action',
            coachHintZh: '再说结果和影响',
          ),
          _SceneAgendaCue(
            stageLabel: '复盘反思',
            learnerTaskEn: 'briefly share what you learned or would improve',
            coachHintZh: '最后补一句你的反思',
          ),
        ];
        break;
      case 'service':
        cues = const <_SceneAgendaCue>[
          _SceneAgendaCue(
            stageLabel: '点单需求',
            learnerTaskEn:
                'state clearly what you want to order or what service you need',
            coachHintZh: '先直接说你想点什么',
          ),
          _SceneAgendaCue(
            stageLabel: '口味细节',
            learnerTaskEn:
                'answer only the missing preference such as size, temperature, sweetness, or milk choice',
            coachHintZh: '只补还没确认的口味细节',
          ),
          _SceneAgendaCue(
            stageLabel: '取餐方式',
            learnerTaskEn:
                'confirm dine-in or takeaway, or the final missing detail only',
            coachHintZh: '补取餐方式或最后一个缺失细节',
          ),
          _SceneAgendaCue(
            stageLabel: '礼貌收尾',
            learnerTaskEn: 'close the order briefly and politely',
            coachHintZh: '最后简短确认并礼貌收尾',
          ),
        ];
        break;
      default:
        cues = const <_SceneAgendaCue>[
          _SceneAgendaCue(
            stageLabel: '核心信息',
            learnerTaskEn: 'state the main point clearly',
            coachHintZh: '先说最核心的信息',
          ),
          _SceneAgendaCue(
            stageLabel: '原因补充',
            learnerTaskEn: 'explain the main reason behind it',
            coachHintZh: '再补主要原因',
          ),
          _SceneAgendaCue(
            stageLabel: '动作方案',
            learnerTaskEn: 'give one concrete next action',
            coachHintZh: '给一个具体动作',
          ),
          _SceneAgendaCue(
            stageLabel: '承诺收束',
            learnerTaskEn: 'add the owner, timing, or commitment',
            coachHintZh: '补时间点或承诺',
          ),
        ];
        break;
    }
    final int index = userTurnCount.clamp(0, cues.length - 1);
    return cues[index];
  }

  int _sceneHintStageIndexForTurns(List<SceneHistoryTurn> turns) {
    if (_effectiveSceneSpec.category == 'service') {
      switch (_sceneAgendaCueForTurns(turns).stageLabel) {
        case '点单需求':
          return 0;
        case '口味细节':
          return 1;
        case '取餐方式':
          return 2;
        case '礼貌收尾':
          return 3;
      }
    }
    final int userTurnCount = turns
        .where((SceneHistoryTurn turn) => turn.role == 'user')
        .length;
    final int stageCount = _effectiveSceneSpec.plotBeats.isNotEmpty
        ? _effectiveSceneSpec.plotBeats.length
        : 4;
    return userTurnCount.clamp(0, stageCount - 1);
  }

  List<SceneHistoryTurn> _hintContextTurns() {
    return _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => SceneHistoryTurn(
            role: m.role == _MessageRole.user ? 'user' : 'npc',
            text: m.text,
          ),
        )
        .toList(growable: false);
  }

  String _latestNpcPromptText(List<SceneHistoryTurn> turns) {
    for (final SceneHistoryTurn turn in turns.reversed) {
      if (turn.role != 'npc') {
        continue;
      }
      final String text = turn.text.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String _latestUserPromptText(List<SceneHistoryTurn> turns) {
    for (final SceneHistoryTurn turn in turns.reversed) {
      if (turn.role != 'user') {
        continue;
      }
      final String text = turn.text.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String _serviceSlotLabelEn(_ServiceSlot slot) {
    return switch (slot) {
      _ServiceSlot.item => 'the item',
      _ServiceSlot.flavor => 'the flavor',
      _ServiceSlot.size => 'the size',
      _ServiceSlot.temperature => 'the temperature',
      _ServiceSlot.sweetness => 'the sweetness',
      _ServiceSlot.milk => 'the milk choice',
      _ServiceSlot.pickup => 'dine-in or takeaway',
      _ServiceSlot.closing => 'a polite close',
    };
  }

  String _serviceValueSummaryForSlots(
    _ServiceDialogueState state,
    List<_ServiceSlot> slots,
  ) {
    final List<String> parts = slots
        .map((_ServiceSlot slot) {
          final String? value = state.valueOf(slot);
          if (value == null || value.isEmpty) {
            return '';
          }
          return '${_serviceSlotLabelEn(slot)}: $value';
        })
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    return parts.join(', ');
  }

  List<_ServiceSlot> _serviceSlotsFromText(String rawText) {
    final List<_ServiceSlot> slots = <_ServiceSlot>[];
    if (_serviceOrderItemFromText(rawText) != null) {
      slots.add(_ServiceSlot.item);
    }
    if (_serviceFlavorFromText(rawText) != null) {
      slots.add(_ServiceSlot.flavor);
    }
    if (_serviceSizeFromText(rawText) != null) {
      slots.add(_ServiceSlot.size);
    }
    if (_serviceTemperatureFromText(rawText) != null) {
      slots.add(_ServiceSlot.temperature);
    }
    if (_serviceSweetnessFromText(rawText) != null) {
      slots.add(_ServiceSlot.sweetness);
    }
    if (_serviceMilkFromText(rawText) != null) {
      slots.add(_ServiceSlot.milk);
    }
    if (_servicePickupFromText(rawText) != null) {
      slots.add(_ServiceSlot.pickup);
    }
    return slots;
  }

  void _recordServiceTurnTrace(
    _ServicePolicyDecision plan, {
    required String source,
    String assistantReplyText = '',
    List<SceneHistoryTurn>? turns,
  }) {
    if (_effectiveSceneSpec.category != 'service') {
      return;
    }
    final List<SceneHistoryTurn> contextTurns =
        turns ?? _currentSceneHistoryTurns();
    _serviceTurnTraces.add(
      _ServiceTurnTrace(
        source: source,
        createdAt: DateTime.now(),
        latestUserText: _latestUserPromptText(contextTurns),
        latestNpcText: _latestNpcPromptText(contextTurns),
        assistantReplyText: assistantReplyText.trim(),
        plan: plan,
      ),
    );
    if (_serviceTurnTraces.length > 24) {
      _serviceTurnTraces.removeRange(0, _serviceTurnTraces.length - 24);
    }
    _persistConversationHistory();
  }

  String _colorToStorageHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  void _persistConversationHistory() {
    final String sessionId = _sessionId.trim();
    if (sessionId.isEmpty) {
      return;
    }
    final ConversationHistoryStorageModel payload =
        ConversationHistoryStorageModel(
          sessionId: sessionId,
          sceneTitle: _draft.title.trim(),
          npcName: _draft.npcName.trim(),
          updatedAt: DateTime.now(),
          messages: _messages
              .map(
                (_ChatMessage message) => ConversationHistoryTurnStorageModel(
                  role: message.role.name,
                  text: message.text,
                  note: message.note,
                  mood: message.mood,
                  inputType: message.inputType?.name,
                  voiceDuration: message.voiceDuration,
                  accentColorHex: message.accent == null
                      ? null
                      : _colorToStorageHex(message.accent!),
                ),
              )
              .toList(growable: false),
          debugData: _serviceTurnTraces.isEmpty
              ? null
              : <String, dynamic>{
                  'serviceTurnTraces': _serviceTurnTraces
                      .map((_ServiceTurnTrace item) => item.toJson())
                      .toList(growable: false),
                },
        );
    unawaited(_sceneRuntimeSupportCoordinator.saveConversationHistory(payload));
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final String pattern in patterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  bool _serviceHasAmbiguousDrinkPhrase(String rawText) {
    final String text = rawText.toLowerCase();
    return _containsAny(text, <String>[
      'lute',
      'loot',
      'latee',
      'lattee',
      'lattie',
      'latti',
      'lotte',
      'light tea',
      'lite tea',
      'late tea',
    ]);
  }

  String? _serviceOrderItemFromText(String rawText) {
    final String text = rawText.toLowerCase();
    if (_serviceHasAmbiguousDrinkPhrase(text)) {
      return null;
    }
    if (_containsAny(text, <String>['latte', '拿铁'])) {
      return 'a latte';
    }
    if (_containsAny(text, <String>['americano', '美式'])) {
      return 'an Americano';
    }
    if (_containsAny(text, <String>['cappuccino', '卡布奇诺'])) {
      return 'a cappuccino';
    }
    if (_containsAny(text, <String>['mocha', '摩卡'])) return 'a mocha';
    if (_containsAny(text, <String>['tea', '红茶', '绿茶'])) return 'a tea';
    if (_containsAny(text, <String>['milk tea', '奶茶'])) return 'a milk tea';
    if (_containsAny(text, <String>['coffee', '咖啡'])) return 'a coffee';
    return null;
  }

  String? _serviceTemperatureFromText(String rawText) {
    final String text = rawText.toLowerCase();
    if (_containsAny(text, <String>['iced', 'ice', 'cold', '冰'])) {
      return 'iced';
    }
    if (_containsAny(text, <String>['hot', 'warm', '热'])) {
      return 'hot';
    }
    return null;
  }

  String? _serviceFlavorFromText(String rawText) {
    final String text = rawText.toLowerCase();
    if (_containsAny(text, <String>['vanilla', '香草'])) {
      return 'vanilla';
    }
    if (_containsAny(text, <String>['caramel', '焦糖'])) {
      return 'caramel';
    }
    if (_containsAny(text, <String>['plain', 'original', '原味'])) {
      return 'plain';
    }
    return null;
  }

  String? _serviceSweetnessFromText(String rawText) {
    final String text = rawText.toLowerCase();
    if (_containsAny(text, <String>['no sugar', 'sugar free', '无糖'])) {
      return 'no sugar';
    }
    if (_containsAny(text, <String>['less sugar', 'low sugar', '少糖'])) {
      return 'less sugar';
    }
    if (_containsAny(text, <String>['regular sugar', 'normal sugar', '全糖'])) {
      return 'regular sugar';
    }
    return null;
  }

  String? _serviceMilkFromText(String rawText) {
    final String text = rawText.toLowerCase();
    if (_containsAny(text, <String>['oat milk', '燕麦奶'])) return 'oat milk';
    if (_containsAny(text, <String>['soy milk', '豆奶'])) return 'soy milk';
    if (_containsAny(text, <String>['whole milk', 'regular milk', '牛奶'])) {
      return 'whole milk';
    }
    return null;
  }

  String? _serviceSizeFromText(String rawText) {
    final String text = rawText.toLowerCase();
    if (_containsAny(text, <String>['small', '小杯'])) return 'small';
    if (_containsAny(text, <String>['medium', '中杯'])) return 'medium';
    if (_containsAny(text, <String>['large', '大杯'])) return 'large';
    return null;
  }

  String? _servicePickupFromText(String rawText) {
    final String text = rawText.toLowerCase();
    if (_containsAny(text, <String>['to go', 'take away', 'takeaway', '外带'])) {
      return 'to go';
    }
    if (_containsAny(text, <String>['for here', 'dine in', 'sit in', '堂食'])) {
      return 'for here';
    }
    return null;
  }

  _ServiceDialogueState _serviceOrderState(List<SceneHistoryTurn> turns) {
    String? item;
    String? flavor;
    String? size;
    String? temperature;
    String? sweetness;
    String? milk;
    String? pickup;
    for (final SceneHistoryTurn turn in turns) {
      if (turn.role != 'user') {
        continue;
      }
      final String text = turn.text.trim();
      if (text.isEmpty) {
        continue;
      }
      final String? detectedItem = _serviceOrderItemFromText(text);
      final String? detectedFlavor = _serviceFlavorFromText(text);
      final String? detectedSize = _serviceSizeFromText(text);
      final String? detectedTemperature = _serviceTemperatureFromText(text);
      final String? detectedSweetness = _serviceSweetnessFromText(text);
      final String? detectedMilk = _serviceMilkFromText(text);
      final String? detectedPickup = _servicePickupFromText(text);
      if (detectedItem != null) {
        item = detectedItem;
      }
      if (detectedFlavor != null) {
        flavor = detectedFlavor;
      }
      if (detectedSize != null) {
        size = detectedSize;
      }
      if (detectedTemperature != null) {
        temperature = detectedTemperature;
      }
      if (detectedSweetness != null) {
        sweetness = detectedSweetness;
      }
      if (detectedMilk != null) {
        milk = detectedMilk;
      }
      if (detectedPickup != null) {
        pickup = detectedPickup;
      }
    }
    return _ServiceDialogueState(
      item: item,
      flavor: flavor,
      size: size,
      temperature: temperature,
      sweetness: sweetness,
      milk: milk,
      pickup: pickup,
    );
  }

  List<String> _serviceQuestionSegments(String rawText) {
    final List<String> segments = rawText
        .split(RegExp(r'(?<=[\.\?\!。！？])\s*'))
        .map((String segment) => segment.trim())
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);
    final List<String> questions = segments
        .where((String segment) {
          final String normalized = segment.toLowerCase();
          return segment.contains('?') ||
              segment.contains('？') ||
              normalized.startsWith('are you ') ||
              normalized.startsWith('would you ') ||
              normalized.startsWith('what ') ||
              normalized.startsWith('which ') ||
              normalized.startsWith('hot or') ||
              normalized.startsWith('iced or') ||
              segment.contains('还是') ||
              segment.contains('要多少') ||
              segment.contains('别的吗');
        })
        .toList(growable: false);
    if (questions.isNotEmpty) {
      return questions;
    }
    final String trimmed = rawText.trim();
    return trimmed.isEmpty ? const <String>[] : <String>[trimmed];
  }

  String _serviceQuestionFocusText(String rawText) {
    return _serviceQuestionSegments(rawText).join(' ');
  }

  List<_ServiceSlot> _serviceCoachTargets(String rawText) {
    final String text = rawText.trim();
    final List<_ServiceSlot> targets = <_ServiceSlot>[];
    if (text.isEmpty) {
      return targets;
    }
    if (_containsAny(text, <String>['点什么', '点单', '饮品', '先直接说'])) {
      targets.add(_ServiceSlot.item);
    }
    if (_containsAny(text, <String>['口味', '风味', '香草', '焦糖', '原味'])) {
      targets.add(_ServiceSlot.flavor);
    }
    if (_containsAny(text, <String>['冷热', '冰', '热'])) {
      targets.add(_ServiceSlot.temperature);
    }
    if (_containsAny(text, <String>['甜度', '糖', '少糖', '无糖'])) {
      targets.add(_ServiceSlot.sweetness);
    }
    if (_containsAny(text, <String>['奶', '燕麦奶', '豆奶'])) {
      targets.add(_ServiceSlot.milk);
    }
    if (_containsAny(text, <String>['尺寸', '杯型', '中杯', '大杯', '小杯'])) {
      targets.add(_ServiceSlot.size);
    }
    if (_containsAny(text, <String>['堂食', '外带', '取餐'])) {
      targets.add(_ServiceSlot.pickup);
    }
    if (_containsAny(text, <String>['收尾', '结束', '礼貌确认'])) {
      targets.add(_ServiceSlot.closing);
    }
    return targets;
  }

  List<_ServiceSlot> _serviceQuestionTargets(String rawText) {
    final String text = _serviceQuestionFocusText(rawText).toLowerCase();
    final List<_ServiceSlot> targets = <_ServiceSlot>[];
    if (_containsAny(text, <String>[
      'what can i get',
      'what can i get started',
      'what would you like',
      'can i help you',
      '有什么可以帮',
      '想点什么',
      '要喝点什么',
    ])) {
      targets.add(_ServiceSlot.item);
    }
    if (_containsAny(text, <String>[
      'what kind of latte',
      'which flavor',
      'what flavor',
      'flavor',
      'vanilla',
      'caramel',
      'plain',
      '口味',
      '风味',
      '香草',
      '焦糖',
      '原味',
    ])) {
      targets.add(_ServiceSlot.flavor);
    }
    if (_containsAny(text, <String>[
      'hot or iced',
      'iced or hot',
      '热的还是冰的',
      '冰的还是热的',
      '冷热',
    ])) {
      targets.add(_ServiceSlot.temperature);
    }
    if (_containsAny(text, <String>[
      'sweet',
      'sugar',
      'any sugar',
      '甜度要多少',
      '少糖还是无糖',
      '糖',
    ])) {
      targets.add(_ServiceSlot.sweetness);
    }
    if (_containsAny(text, <String>[
      'milk',
      'oat milk',
      'soy milk',
      '牛奶',
      '燕麦奶',
    ])) {
      targets.add(_ServiceSlot.milk);
    }
    if (_containsAny(text, <String>[
      'what size',
      'which size',
      'small, medium',
      '大杯',
      '中杯',
      '小杯',
    ])) {
      targets.add(_ServiceSlot.size);
    }
    if (_containsAny(text, <String>[
      'to go',
      'for here',
      'sit in',
      'take away',
      '堂食',
      '外带',
    ])) {
      targets.add(_ServiceSlot.pickup);
    }
    if (_containsAny(text, <String>[
      'anything else',
      'would you like anything else',
      '还需要别的',
      '还要别的吗',
    ])) {
      targets.add(_ServiceSlot.closing);
    }
    return targets;
  }

  List<_ServiceSlot> _serviceMissingSlots(_ServiceDialogueState state) {
    final List<_ServiceSlot> missing = <_ServiceSlot>[];
    if (!state.has(_ServiceSlot.item)) {
      missing.add(_ServiceSlot.item);
      return missing;
    }
    for (final _ServiceSlot slot in <_ServiceSlot>[
      _ServiceSlot.temperature,
      _ServiceSlot.sweetness,
      _ServiceSlot.milk,
      _ServiceSlot.size,
      _ServiceSlot.pickup,
    ]) {
      if (!state.has(slot)) {
        missing.add(slot);
      }
    }
    return missing;
  }

  String _serviceNextNpcSummary(
    _ServiceDialogueState state,
    List<_ServiceSlot> missingSlots,
  ) {
    final String confirmed = state.confirmedSummary().join('; ');
    if (missingSlots.isEmpty) {
      return confirmed.isEmpty
          ? 'All required order details are already confirmed.'
          : 'All required order details are already confirmed: $confirmed.';
    }
    return confirmed.isEmpty
        ? 'Still missing only ${_serviceSlotLabelEn(missingSlots.first)}.'
        : 'Confirmed so far: $confirmed. Still missing only ${_serviceSlotLabelEn(missingSlots.first)}.';
  }

  String _serviceNextNpcInstruction(
    _ServiceDialogueState state,
    List<_ServiceSlot> missingSlots,
    List<_ServiceSlot> latestUserAnsweredSlots,
  ) {
    if (missingSlots.isEmpty) {
      final String confirmed = state.confirmedSummary().join('; ');
      return confirmed.isEmpty
          ? 'Briefly confirm the order and close naturally. Do not ask for any detail again.'
          : 'All required order details are confirmed ($confirmed). Briefly confirm the order and close naturally. Do not ask for any detail again.';
    }
    final _ServiceSlot nextSlot = missingSlots.first;
    if (nextSlot == _ServiceSlot.item) {
      return 'The learner still has not clearly chosen an item. Ask only what they want to order. Do not ask about size, temperature, sweetness, milk choice, or pickup yet.';
    }
    final String confirmed = state.confirmedSummary().isEmpty
        ? 'No order detail is confirmed yet.'
        : 'Already confirmed: ${state.confirmedSummary().join('; ')}.';
    if (latestUserAnsweredSlots.isEmpty) {
      return 'The learner did not clearly answer the pending ${_serviceSlotLabelEn(nextSlot)}. Ask only for ${_serviceSlotLabelEn(nextSlot)} in simpler words. $confirmed Do not bundle a second question.';
    }
    final String latestAnswered = _serviceValueSummaryForSlots(
      state,
      latestUserAnsweredSlots,
    );
    return 'The learner just confirmed $latestAnswered. Briefly acknowledge it, then ask only for ${_serviceSlotLabelEn(nextSlot)}. $confirmed Do not repeat any confirmed detail.';
  }

  _SceneAgendaCue _serviceCueForSlots(List<_ServiceSlot> slots) {
    if (slots.contains(_ServiceSlot.closing)) {
      return const _SceneAgendaCue(
        stageLabel: '礼貌收尾',
        learnerTaskEn: 'close the order briefly and politely',
        coachHintZh: '最后简短确认并礼貌收尾',
      );
    }
    if (slots.contains(_ServiceSlot.pickup)) {
      return const _SceneAgendaCue(
        stageLabel: '取餐方式',
        learnerTaskEn:
            'confirm dine-in or takeaway, or the final missing detail only',
        coachHintZh: '补取餐方式或最后一个缺失细节',
      );
    }
    if (slots.contains(_ServiceSlot.item)) {
      return const _SceneAgendaCue(
        stageLabel: '点单需求',
        learnerTaskEn:
            'state clearly what you want to order or what service you need',
        coachHintZh: '先直接说你想点什么',
      );
    }
    return const _SceneAgendaCue(
      stageLabel: '口味细节',
      learnerTaskEn:
          'answer only the missing preference such as size, temperature, sweetness, or milk choice',
      coachHintZh: '只补还没确认的口味细节',
    );
  }

  List<String> _serviceKeywordsForSlots(
    List<_ServiceSlot> slots,
    _ServiceDialogueState state,
  ) {
    return slots
        .map((_ServiceSlot slot) {
          return switch (slot) {
            _ServiceSlot.item => 'I\'d like',
            _ServiceSlot.flavor => state.flavor ?? 'vanilla / caramel / plain',
            _ServiceSlot.temperature => state.temperature ?? 'iced / hot',
            _ServiceSlot.sweetness =>
              state.sweetness ?? 'less sugar / no sugar',
            _ServiceSlot.milk => state.milk ?? 'oat milk / soy milk',
            _ServiceSlot.size => state.size ?? 'small / medium / large',
            _ServiceSlot.pickup => state.pickup ?? 'to go / for here',
            _ServiceSlot.closing => 'that\'s all / thank you',
          };
        })
        .toList(growable: false);
  }

  String _serviceReferenceAnswer(
    List<_ServiceSlot> targets,
    _ServiceDialogueState state,
  ) {
    final String item = state.item ?? 'a latte';
    final String flavor = state.flavor ?? 'vanilla';
    final String size = state.size ?? 'medium';
    final String temperature = state.temperature ?? 'iced';
    final String sweetness = state.sweetness ?? 'less sugar';
    final String milk = state.milk ?? 'oat milk';
    final String pickup = state.pickup ?? 'to go';

    if (targets.contains(_ServiceSlot.closing)) {
      return 'That\'s all, thank you.';
    }
    if (targets.contains(_ServiceSlot.item)) {
      final List<String> parts = <String>[];
      if (state.flavor != null) parts.add(flavor);
      if (state.size != null) parts.add(size);
      if (state.temperature != null) parts.add(temperature);
      parts.add(item);
      String answer = 'I\'d like ${parts.join(' ')}';
      if (state.milk != null) {
        answer += ' with $milk';
      }
      if (state.sweetness != null) {
        answer += ' and $sweetness';
      }
      return '$answer, please.';
    }
    if (targets.contains(_ServiceSlot.flavor)) {
      if (state.item != null) {
        return '$flavor, please.';
      }
      return 'I\'d like a $flavor latte, please.';
    }
    if (targets.contains(_ServiceSlot.temperature) &&
        targets.contains(_ServiceSlot.sweetness)) {
      return 'I\'d like it $temperature with $sweetness, please.';
    }
    if (targets.contains(_ServiceSlot.temperature) &&
        targets.contains(_ServiceSlot.pickup)) {
      return 'I\'d like it $temperature and $pickup, please.';
    }
    if (targets.contains(_ServiceSlot.temperature)) {
      return 'I\'d like it $temperature, please.';
    }
    if (targets.contains(_ServiceSlot.sweetness)) {
      return '$sweetness, please.';
    }
    if (targets.contains(_ServiceSlot.milk)) {
      return '$milk, please.';
    }
    if (targets.contains(_ServiceSlot.size) &&
        targets.contains(_ServiceSlot.pickup)) {
      return '$size, $pickup, please.';
    }
    if (targets.contains(_ServiceSlot.size)) {
      return '$size, please.';
    }
    if (targets.contains(_ServiceSlot.pickup)) {
      return '$pickup, please.';
    }
    return 'I\'d like $item, please.';
  }

  _ServicePolicyDecision _servicePolicyDecision(
    List<SceneHistoryTurn> turns, {
    String? coachText,
  }) {
    final _ServiceDialogueState state = _serviceOrderState(turns);
    final String latestNpcText = _latestNpcPromptText(turns);
    final String latestUserText = _latestUserPromptText(turns);
    final String questionFocus = _serviceQuestionFocusText(latestNpcText);
    final List<_ServiceSlot> latestUserAnsweredSlots = _serviceSlotsFromText(
      latestUserText,
    );
    final List<_ServiceSlot> coachTargets = _serviceCoachTargets(
      (coachText ?? '').trim(),
    );
    final List<_ServiceSlot> npcTargets = _serviceQuestionTargets(
      latestNpcText,
    );
    final List<_ServiceSlot> explicitTargets = coachTargets.isNotEmpty
        ? coachTargets
        : npcTargets;
    final List<_ServiceSlot> missingTargets = _serviceMissingSlots(state);
    List<_ServiceSlot> answerSlots;
    final List<_ServiceSlot> unresolvedExplicitTargets = explicitTargets
        .where(
          (_ServiceSlot slot) =>
              slot == _ServiceSlot.closing || !state.has(slot),
        )
        .toList(growable: false);
    if (explicitTargets.isNotEmpty) {
      answerSlots = unresolvedExplicitTargets.isNotEmpty
          ? unresolvedExplicitTargets
          : explicitTargets;
      if (answerSlots.contains(_ServiceSlot.pickup) &&
          missingTargets.contains(_ServiceSlot.pickup)) {
        answerSlots = <_ServiceSlot>[_ServiceSlot.pickup];
      }
    } else if (missingTargets.isNotEmpty) {
      answerSlots = <_ServiceSlot>[missingTargets.first];
    } else {
      answerSlots = const <_ServiceSlot>[_ServiceSlot.closing];
    }
    final _SceneAgendaCue cue = _serviceCueForSlots(answerSlots);
    final bool repeatedKnownDetails =
        explicitTargets.isNotEmpty &&
        explicitTargets
            .where(
              (_ServiceSlot slot) =>
                  slot != _ServiceSlot.item && slot != _ServiceSlot.closing,
            )
            .every((_ServiceSlot slot) => state.has(slot));
    final bool needsRepeatForCurrentSlot =
        explicitTargets.isNotEmpty &&
        latestUserText.trim().isNotEmpty &&
        latestUserAnsweredSlots.isEmpty;
    final String resolvedCoachText = (coachText ?? '').trim();
    final String goalHint = resolvedCoachText.isNotEmpty
        ? resolvedCoachText
        : needsRepeatForCurrentSlot &&
              explicitTargets.first == _ServiceSlot.item
        ? '对方没听清饮品名，再清楚重复一次饮品名称。'
        : needsRepeatForCurrentSlot &&
              explicitTargets.first == _ServiceSlot.temperature
        ? '对方没听清冷热，再清楚说一次 hot 或 iced。'
        : needsRepeatForCurrentSlot &&
              explicitTargets.first == _ServiceSlot.sweetness
        ? '对方没听清甜度，再清楚说一次 regular、less sugar 或 no sugar。'
        : needsRepeatForCurrentSlot &&
              explicitTargets.first == _ServiceSlot.milk
        ? '对方没听清奶型，再清楚说一次 regular、oat 或 soy。'
        : needsRepeatForCurrentSlot &&
              explicitTargets.first == _ServiceSlot.size
        ? '对方没听清杯型，再清楚说一次 small、medium 或 large。'
        : needsRepeatForCurrentSlot &&
              explicitTargets.first == _ServiceSlot.pickup
        ? '对方没听清取餐方式，再清楚说一次 for here 或 to go。'
        : repeatedKnownDetails
        ? '对方重复带过你已经说过的信息时，你只要简短确认真正还需要的那个点。'
        : cue.coachHintZh;
    final String starter = _serviceReferenceAnswer(answerSlots, state);
    final String sampleAnswer = answerSlots.contains(_ServiceSlot.pickup)
        ? '$starter That\'s all, thank you.'
        : starter;
    final List<_ServiceSlot> nextNpcTargets = unresolvedExplicitTargets
        .where((_ServiceSlot slot) => slot != _ServiceSlot.closing)
        .toList(growable: false);
    final _ServiceSlot? nextNpcSlot = nextNpcTargets.isNotEmpty
        ? nextNpcTargets.first
        : missingTargets.isEmpty
        ? null
        : missingTargets.first;
    final _ServiceNextNpcAction nextNpcAction = nextNpcSlot == null
        ? _ServiceNextNpcAction.closeOrder
        : _ServiceNextNpcAction.askMissingDetail;
    return _ServicePolicyDecision(
      cue: cue,
      goalHint: goalHint,
      questionFocus: questionFocus.isEmpty
          ? latestNpcText.trim()
          : questionFocus,
      keywords: _serviceKeywordsForSlots(answerSlots, state),
      starter: starter,
      sampleAnswer: sampleAnswer,
      askedSlots: explicitTargets,
      answerSlots: answerSlots,
      state: state,
      missingSlots: missingTargets,
      latestUserAnsweredSlots: latestUserAnsweredSlots,
      nextNpcAction: nextNpcAction,
      nextNpcSlot: nextNpcSlot,
      nextNpcInstruction: _serviceNextNpcInstruction(
        state,
        missingTargets,
        latestUserAnsweredSlots,
      ),
      nextNpcSummary: _serviceNextNpcSummary(state, missingTargets),
    );
  }

  String _hintProjectTopic() {
    final String source =
        '${_draft.title} ${_draft.userRole} ${_draft.challenge} ${_draft.plotDesign}'
            .toLowerCase();
    if (source.contains('front') ||
        source.contains('web') ||
        source.contains('ui') ||
        source.contains('页面') ||
        source.contains('前端')) {
      return 'a frontend project';
    }
    if (source.contains('perform') ||
        source.contains('性能') ||
        source.contains('memory') ||
        source.contains('worker')) {
      return 'a performance optimization project';
    }
    if (source.contains('client') || source.contains('客户')) {
      return 'a client delivery project';
    }
    if (source.contains('interview') || source.contains('面试')) {
      return 'a recent project';
    }
    return 'a recent project';
  }

  String _hintSceneSource() {
    return [
      _draft.title,
      _draft.userRole,
      _draft.npcRole,
      _draft.environment,
      _draft.goal,
      _draft.challenge,
      _draft.plotDesign,
    ].join(' ');
  }

  bool _isDrinkOrderScene() {
    final String source = _hintSceneSource().toLowerCase();
    return source.contains('点单') ||
        source.contains('点餐') ||
        source.contains('咖啡店') ||
        source.contains('奶茶店') ||
        source.contains('饮品') ||
        source.contains('拿铁') ||
        source.contains('美式') ||
        source.contains('咖啡') ||
        source.contains('店员') ||
        source.contains('服务员') ||
        source.contains('barista') ||
        source.contains('drink') ||
        source.contains('order') ||
        source.contains('cafe') ||
        source.contains('restaurant');
  }

  bool _isProductInquiryScene() {
    final String source = _hintSceneSource().toLowerCase();
    return source.contains('咖啡机') ||
        source.contains('coffee machine') ||
        ((source.contains('machine') || source.contains('产品')) &&
            (source.contains('优点') ||
                source.contains('优势') ||
                source.contains('推荐') ||
                source.contains('区别') ||
                source.contains('适合') ||
                source.contains('benefit') ||
                source.contains('recommend')));
  }

  String _hintBackgroundText() {
    final String role = _draft.userRole.trim();
    final String scene = _draft.title.trim();
    if (role.isNotEmpty && scene.isNotEmpty) {
      return '$role · $scene';
    }
    return role.isNotEmpty ? role : scene;
  }

  _SceneResponseHint _questionAwareServiceHint(
    String latestNpcText,
    _SceneAgendaCue cue, {
    String? coachText,
    List<SceneHistoryTurn>? turns,
  }) {
    if (_isProductInquiryScene() && !_isDrinkOrderScene()) {
      return _SceneResponseHint(
        stageLabel: cue.stageLabel,
        questionFocus: latestNpcText,
        backgroundFocus: _hintBackgroundText(),
        goalHint: (coachText ?? '').trim().isNotEmpty
            ? coachText!.trim()
            : '对方在做接待开场。你不要泛泛回应，直接说你想了解哪款产品，并点出你最在意的优点或需求。',
        keywords: const <String>[
          'I\'m looking for',
          'main advantage',
          'fit my needs',
        ],
        starter:
            'I\'m looking for a coffee machine, and I want to know its main advantages.',
        sampleAnswer:
            'I\'m looking for a coffee machine, and I want to know its main advantages. I care most about ease of use, coffee quality, and whether it is a good fit for daily home use.',
      );
    }
    final _ServicePolicyDecision decision = _servicePolicyDecision(
      turns ?? _hintContextTurns(),
      coachText: coachText,
    );
    return _SceneResponseHint(
      stageLabel: decision.cue.stageLabel,
      questionFocus: decision.questionFocus.isEmpty
          ? latestNpcText
          : decision.questionFocus,
      backgroundFocus: _hintBackgroundText(),
      goalHint: decision.goalHint,
      keywords: decision.keywords,
      starter: decision.starter,
      sampleAnswer: decision.sampleAnswer,
    );
  }

  _SceneResponseHint _questionAwareInterviewHint(
    String latestNpcText,
    _SceneAgendaCue cue,
  ) {
    final String normalized = latestNpcText.toLowerCase();
    final String topic = _hintProjectTopic();
    final String background = _hintBackgroundText();

    if ((normalized.contains('cross-functional') ||
            normalized.contains('cross functional')) &&
        (normalized.contains('led') ||
            normalized.contains('lead') ||
            normalized.contains('collaboration'))) {
      return _SceneResponseHint(
        stageLabel: cue.stageLabel,
        questionFocus: latestNpcText,
        backgroundFocus: background,
        goalHint: '这是行为题。用 STAR 讲一次你主导多团队协作的真实经历，重点说你怎么协调角色和推进落地。',
        keywords: const <String>[
          'situation',
          'ownership',
          'product/design/backend/QA',
        ],
        starter: 'One time I led cross-functional collaboration was during ...',
        sampleAnswer:
            'One time I led cross-functional collaboration was during $topic. I worked closely with product, design, backend, and QA to align scope, timeline, and priorities. I set up regular check-ins, clarified ownership, and resolved trade-offs quickly when blockers came up. As a result, we delivered the project on schedule and improved collaboration across the teams.',
      );
    }

    if (normalized.contains('walk me through') &&
        (normalized.contains('project') ||
            normalized.contains('time you') ||
            normalized.contains('experience'))) {
      return _SceneResponseHint(
        stageLabel: cue.stageLabel,
        questionFocus: latestNpcText,
        backgroundFocus: background,
        goalHint: '先给一句总览，再按 STAR 顺序展开，别一上来就堆细节。',
        keywords: const <String>['situation', 'task', 'action', 'result'],
        starter: 'Sure. One project that stands out was ...',
        sampleAnswer:
            'Sure. One project that stands out was $topic. The situation was that we needed to solve a clear performance problem under time pressure. My task was to drive the solution and align the team on the best approach. I coordinated the implementation, clarified trade-offs, and kept everyone focused on the highest-priority work. In the end, we improved the product performance and delivered the change successfully.',
      );
    }

    if (normalized.contains('why did you choose') ||
        normalized.contains('why did you pick') ||
        normalized.contains('why that') ||
        normalized.contains('approach over') ||
        normalized.contains('solution over')) {
      return _SceneResponseHint(
        stageLabel: cue.stageLabel,
        questionFocus: latestNpcText,
        backgroundFocus: background,
        goalHint: '这是方案选择题。先给结论，再用 2 到 3 个标准解释为什么选这个方案，而不是另一个方案。',
        keywords: const <String>[
          'performance',
          'implementation cost',
          'maintainability',
        ],
        starter: 'I chose that approach because ...',
        sampleAnswer:
            'I chose that approach because it gave us the best balance between performance, implementation cost, and long-term maintainability. It solved the core bottleneck clearly, but it was still practical for the team to implement and support.',
      );
    }

    if (normalized.contains('would you still pick') ||
        normalized.contains('would you still choose') ||
        normalized.contains('if memory') ||
        normalized.contains('top constraint') ||
        normalized.contains('trade-off')) {
      return _SceneResponseHint(
        stageLabel: cue.stageLabel,
        questionFocus: latestNpcText,
        backgroundFocus: background,
        goalHint: '这是追问权衡题。先明确“会/不会”，再说如果约束变化，你会如何调整判断标准。',
        keywords: const <String>['it depends', 'constraint', 'trade-off'],
        starter: 'If memory had been the main constraint, ...',
        sampleAnswer:
            'If memory had been the main constraint, I would have reevaluated the decision more carefully. I might still choose the same solution if it remained the best overall trade-off, but I would put more weight on memory efficiency and implementation overhead before making the final call.',
      );
    }

    if (normalized.contains('one sentence') ||
        normalized.contains('1 sentence') ||
        normalized.contains('in one sentence') ||
        normalized.contains('sum up')) {
      return _SceneResponseHint(
        stageLabel: cue.stageLabel,
        questionFocus: latestNpcText,
        backgroundFocus: background,
        goalHint: '这是总结题。只给一句话，讲清你最后用什么标准做判断。',
        keywords: const <String>[
          'main criterion',
          'best trade-off',
          'clear win',
        ],
        starter: 'My main criterion was ...',
        sampleAnswer:
            'My main criterion was choosing the option that solved the real bottleneck most clearly without adding unnecessary complexity for the team.',
      );
    }

    return _SceneResponseHint(
      stageLabel: cue.stageLabel,
      questionFocus: latestNpcText,
      backgroundFocus: background,
      goalHint: cue.coachHintZh,
      keywords: const <String>['direct answer', 'example', 'result'],
      starter: 'The key point is that ...',
      sampleAnswer:
          'The key point is that I would answer directly first, support it with one concrete example, and then finish with the result or impact.',
    );
  }

  String _genericNpcTurnInstruction(
    _SceneAgendaCue cue, {
    required String latestNpcText,
    required String latestUserText,
  }) {
    final String cleanedUser = latestUserText.trim();
    final String cleanedNpc = latestNpcText.trim();
    if (cleanedNpc.isEmpty) {
      return 'Stay in role and open or continue the scene within the current stage "${cue.stageLabel}". Focus on ${cue.learnerTaskEn}.';
    }
    if (cleanedUser.isEmpty) {
      return 'Repeat the current stage naturally without jumping ahead. Focus only on ${cue.learnerTaskEn}.';
    }
    return 'Respond directly to the learner\'s latest message "$cleanedUser". Stay in role and keep this turn focused on ${cue.learnerTaskEn}. Do not jump ahead to another stage or unrelated topic.';
  }

  _SceneTurnContract _buildSceneTurnContract(
    List<SceneHistoryTurn> turns, {
    String? coachText,
  }) {
    final _SceneAgendaCue cue = _sceneAgendaCueForTurns(turns);
    final String latestNpcText = _latestNpcPromptText(turns);
    final String latestUserText = _latestUserPromptText(turns);
    final String normalizedCoachText = (coachText ?? '').trim();
    final _SceneResponseHint hint = _currentSceneHint(
      coachText: coachText,
      turns: turns,
    );
    final SceneTurnContract? serverContract = _serverTurnContract;
    if (serverContract != null) {
      return _SceneTurnContract(
        stageLabel: serverContract.stageLabel.isNotEmpty
            ? serverContract.stageLabel
            : cue.stageLabel,
        questionFocus: serverContract.questionFocus.isNotEmpty
            ? serverContract.questionFocus
            : hint.questionFocus,
        backgroundFocus: serverContract.backgroundFocus.isNotEmpty
            ? serverContract.backgroundFocus
            : hint.backgroundFocus,
        learnerTaskEn: serverContract.learnerTaskEn.isNotEmpty
            ? serverContract.learnerTaskEn
            : cue.learnerTaskEn,
        learnerGoalZh: normalizedCoachText.isNotEmpty
            ? normalizedCoachText
            : (serverContract.learnerGoalZh.isNotEmpty
                  ? serverContract.learnerGoalZh
                  : hint.goalHint),
        npcTurnSummary: serverContract.npcTurnSummary.isNotEmpty
            ? serverContract.npcTurnSummary
            : 'Current stage: ${cue.stageLabel}. Keep the scene on ${cue.learnerTaskEn}.',
        npcTurnInstruction: serverContract.npcTurnInstruction.isNotEmpty
            ? serverContract.npcTurnInstruction
            : _genericNpcTurnInstruction(
                cue,
                latestNpcText: latestNpcText,
                latestUserText: latestUserText,
              ),
        keywords: serverContract.keywords.isNotEmpty
            ? serverContract.keywords
            : hint.keywords,
        starter: serverContract.starter.isNotEmpty
            ? serverContract.starter
            : hint.starter,
        sampleAnswer: serverContract.sampleAnswer.isNotEmpty
            ? serverContract.sampleAnswer
            : hint.sampleAnswer,
        confirmedFacts: serverContract.confirmedFacts,
        mustAsk: serverContract.mustAsk,
        mustAvoid: serverContract.mustAvoid.isNotEmpty
            ? serverContract.mustAvoid
            : const <String>['unrelated topic', 'coach language'],
      );
    }
    if ((_effectiveSceneSpec.category == 'service' ||
            _isDrinkOrderScene() ||
            _isProductInquiryScene()) &&
        !_isProductInquiryScene()) {
      final _ServicePolicyDecision plan = _servicePolicyDecision(
        turns,
        coachText: coachText,
      );
      return _SceneTurnContract(
        stageLabel: plan.cue.stageLabel,
        questionFocus: plan.questionFocus.isEmpty
            ? latestNpcText
            : plan.questionFocus,
        backgroundFocus: _hintBackgroundText(),
        learnerTaskEn: plan.cue.learnerTaskEn,
        learnerGoalZh: plan.goalHint,
        npcTurnSummary: plan.nextNpcSummary,
        npcTurnInstruction: _serviceNpcTurnContract(plan, latestUserText),
        keywords: plan.keywords,
        starter: plan.starter,
        sampleAnswer: plan.sampleAnswer,
        confirmedFacts: plan.state.confirmedSummary(),
        mustAsk: plan.nextNpcSlot == null
            ? const <String>['close naturally']
            : <String>[_serviceSlotLabelEn(plan.nextNpcSlot!)],
        mustAvoid: plan.missingSlots
            .where((_ServiceSlot slot) => slot != plan.nextNpcSlot)
            .map(_serviceSlotLabelEn)
            .toList(growable: false),
      );
    }
    final String learnerGoal = normalizedCoachText.isNotEmpty
        ? normalizedCoachText
        : hint.goalHint;
    return _SceneTurnContract(
      stageLabel: cue.stageLabel,
      questionFocus: hint.questionFocus,
      backgroundFocus: hint.backgroundFocus,
      learnerTaskEn: cue.learnerTaskEn,
      learnerGoalZh: learnerGoal,
      npcTurnSummary:
          'Current stage: ${cue.stageLabel}. Keep the scene on ${cue.learnerTaskEn}.',
      npcTurnInstruction: _genericNpcTurnInstruction(
        cue,
        latestNpcText: latestNpcText,
        latestUserText: latestUserText,
      ),
      keywords: hint.keywords,
      starter: hint.starter,
      sampleAnswer: hint.sampleAnswer,
      mustAvoid: const <String>['unrelated topic', 'coach language'],
    );
  }

  _SceneResponseHint _currentSceneHint({
    String? coachText,
    List<SceneHistoryTurn>? turns,
  }) {
    final List<SceneHistoryTurn> resolvedTurns = turns ?? _hintContextTurns();
    final _SceneAgendaCue cue = _sceneAgendaCueForTurns(resolvedTurns);
    final int stageIndex = _sceneHintStageIndexForTurns(resolvedTurns);
    final String latestNpcText = _latestNpcPromptText(resolvedTurns);
    final String background = _hintBackgroundText();
    final String normalizedCoachText = (coachText ?? '').trim();

    if ((_isDrinkOrderScene() || _isProductInquiryScene()) &&
        _hintSceneSource().trim().isNotEmpty) {
      final _SceneResponseHint hint = _questionAwareServiceHint(
        latestNpcText,
        cue,
        coachText: normalizedCoachText,
        turns: resolvedTurns,
      );
      return hint;
    }

    if (_effectiveSceneSpec.category == 'interview' &&
        latestNpcText.trim().isNotEmpty) {
      final _SceneResponseHint hint = _questionAwareInterviewHint(
        latestNpcText,
        cue,
      );
      if (normalizedCoachText.isEmpty) {
        return hint;
      }
      return _SceneResponseHint(
        stageLabel: hint.stageLabel,
        questionFocus: hint.questionFocus,
        backgroundFocus: hint.backgroundFocus,
        goalHint: normalizedCoachText,
        keywords: hint.keywords,
        starter: hint.starter,
        sampleAnswer: hint.sampleAnswer,
      );
    }

    final List<_SceneHintTemplate> templates = switch (_effectiveSceneSpec
        .category) {
      'process_review' => const <_SceneHintTemplate>[
        _SceneHintTemplate(
          keywords: <String>['bottleneck', 'slow down', 'handoff'],
          starter: 'The biggest bottleneck right now is ...',
          sample:
              'The biggest bottleneck right now is the review handoff between product and engineering. It slows delivery because we often wait too long for final clarifications.',
        ),
        _SceneHintTemplate(
          keywords: <String>['root cause', 'for example', 'unclear'],
          starter: 'The main reason is that ...',
          sample:
              'The main reason is that ownership is not clear at the review stage. For example, last week two teams waited on each other before anyone made the final decision.',
        ),
        _SceneHintTemplate(
          keywords: <String>['first step', 'priority', 'improve'],
          starter: 'The first change I would make is ...',
          sample:
              'The first change I would make is assigning one clear owner for each review cycle. That should come first because it will remove delays immediately.',
        ),
        _SceneHintTemplate(
          keywords: <String>['owner', 'timeline', 'next step'],
          starter: 'I can take ownership of ...',
          sample:
              'I can take ownership of the first trial this week. We can review the result on Friday and decide whether to scale it to the whole team next Monday.',
        ),
      ],
      'work_review' => const <_SceneHintTemplate>[
        _SceneHintTemplate(
          keywords: <String>['bottom line', 'status', 'currently'],
          starter: 'The short answer is that ...',
          sample:
              'The short answer is that we are slightly behind the original plan, but the core deliverables are still under control.',
        ),
        _SceneHintTemplate(
          keywords: <String>['main issue', 'blocked by', 'cause'],
          starter: 'The main issue was ...',
          sample:
              'The main issue was that the integration testing took longer than expected, which delayed the final validation work.',
        ),
        _SceneHintTemplate(
          keywords: <String>['fix', 'next action', 'this week'],
          starter: 'What I am doing next is ...',
          sample:
              'What I am doing next is narrowing the open issues to the top priority items and closing them one by one with the QA team this week.',
        ),
        _SceneHintTemplate(
          keywords: <String>['owner', 'deadline', 'commitment'],
          starter: 'I will personally make sure ...',
          sample:
              'I will personally make sure the next checkpoint is met, and I will send an updated timeline by tomorrow afternoon.',
        ),
      ],
      'client' => const <_SceneHintTemplate>[
        _SceneHintTemplate(
          keywords: <String>['main concern', 'understand', 'impact'],
          starter: 'I understand your concern, and ...',
          sample:
              'I understand your concern, and the main issue is that the latest changes affected the delivery timeline more than we expected.',
        ),
        _SceneHintTemplate(
          keywords: <String>['reason', 'because', 'unexpected'],
          starter: 'The main reason is that ...',
          sample:
              'The main reason is that we found an issue during the final integration step, and we needed extra time to fix it safely.',
        ),
        _SceneHintTemplate(
          keywords: <String>['solution', 'reduce risk', 'support'],
          starter: 'To reduce the impact, we will ...',
          sample:
              'To reduce the impact, we will deliver the highest-priority part first and keep the remaining items on a shorter follow-up schedule.',
        ),
        _SceneHintTemplate(
          keywords: <String>['next step', 'timeline', 'keep updated'],
          starter: 'Our next step is ...',
          sample:
              'Our next step is to share the revised timeline today and confirm the next review checkpoint with you by Friday.',
        ),
      ],
      'interview' => const <_SceneHintTemplate>[
        _SceneHintTemplate(
          keywords: <String>['direct answer', 'I chose', 'because'],
          starter: 'I chose that approach because ...',
          sample:
              'I chose that approach because it gave us the best balance between performance, implementation cost, and long-term maintainability.',
        ),
        _SceneHintTemplate(
          keywords: <String>['for example', 'in one project', 'I handled'],
          starter: 'For example, in one project ...',
          sample:
              'For example, in one project I used that design when we needed to improve rendering performance without adding too much system complexity.',
        ),
        _SceneHintTemplate(
          keywords: <String>['result', 'impact', 'trade-off'],
          starter: 'As a result, ...',
          sample:
              'As a result, the page became much more responsive, and we reduced the performance bottleneck while keeping the codebase easier to maintain.',
        ),
        _SceneHintTemplate(
          keywords: <String>['standard', 'decision', 'priority'],
          starter: 'The main standard I used was ...',
          sample:
              'The main standard I used was whether the solution solved the real bottleneck clearly enough without introducing unnecessary complexity.',
        ),
      ],
      'service' => const <_SceneHintTemplate>[
        _SceneHintTemplate(
          keywords: <String>['I\'d like', 'please', 'drink'],
          starter: 'I\'d like a ... please.',
          sample: 'I\'d like a medium iced latte, please.',
        ),
        _SceneHintTemplate(
          keywords: <String>['iced / hot', 'less sugar', 'oat milk'],
          starter: 'I\'d like it iced with less sugar.',
          sample:
              'I\'d like it iced with less sugar, and oat milk if possible.',
        ),
        _SceneHintTemplate(
          keywords: <String>['to go', 'for here', 'medium'],
          starter: 'To go, please.',
          sample: 'To go, please. A medium size would be great.',
        ),
        _SceneHintTemplate(
          keywords: <String>['that\'s all', 'thank you', 'for now'],
          starter: 'That\'s all, thank you.',
          sample: 'That\'s all for now, thank you.',
        ),
      ],
      'social' => const <_SceneHintTemplate>[
        _SceneHintTemplate(
          keywords: <String>['respond', 'naturally', 'pick up'],
          starter: 'That makes sense. For me, ...',
          sample:
              'That makes sense. For me, the most interesting part has been learning how different teams work together on the same problem.',
        ),
        _SceneHintTemplate(
          keywords: <String>['personal detail', 'for example', 'experience'],
          starter: 'For example, I recently ...',
          sample:
              'For example, I recently worked on a project where I had to explain technical trade-offs to people outside engineering.',
        ),
        _SceneHintTemplate(
          keywords: <String>['follow up', 'ask back', 'share more'],
          starter: 'What about you?',
          sample:
              'What about you? Have you ever had to make a similar choice under time pressure?',
        ),
        _SceneHintTemplate(
          keywords: <String>['next topic', 'keep going', 'light'],
          starter: 'That reminds me ...',
          sample:
              'That reminds me of another situation where communication mattered more than the technical part itself.',
        ),
      ],
      _ => const <_SceneHintTemplate>[
        _SceneHintTemplate(
          keywords: <String>['main point', 'short answer', 'clearly'],
          starter: 'The main point is that ...',
          sample:
              'The main point is that this issue comes from one key cause, and I want to focus on that first.',
        ),
        _SceneHintTemplate(
          keywords: <String>['reason', 'because', 'key factor'],
          starter: 'The main reason is ...',
          sample:
              'The main reason is that one part of the process took longer than expected, and that affected the rest of the timeline.',
        ),
        _SceneHintTemplate(
          keywords: <String>['next step', 'action', 'solve'],
          starter: 'The next thing I will do is ...',
          sample:
              'The next thing I will do is focus on the highest-priority fix first and keep the rest of the work tightly scoped.',
        ),
        _SceneHintTemplate(
          keywords: <String>['timeline', 'owner', 'commitment'],
          starter: 'I will make sure ...',
          sample:
              'I will make sure the next update is clear, and I will confirm the owner and timing before the end of the day.',
        ),
      ],
    };
    final _SceneHintTemplate template =
        templates[stageIndex.clamp(0, templates.length - 1)];
    final _SceneResponseHint hint = _SceneResponseHint(
      stageLabel: cue.stageLabel,
      questionFocus: latestNpcText,
      backgroundFocus: background,
      goalHint: normalizedCoachText.isNotEmpty
          ? normalizedCoachText
          : cue.coachHintZh,
      keywords: template.keywords,
      starter: template.starter,
      sampleAnswer: template.sample,
    );
    return hint;
  }

  String _hintCacheKey({String? coachText}) {
    final List<SceneHistoryTurn> turns = _hintContextTurns();
    final Iterable<SceneHistoryTurn> window = turns.length > 6
        ? turns.skip(turns.length - 6)
        : turns;
    return [
      _draft.title.trim(),
      _draft.goal.trim(),
      (coachText ?? '').trim(),
      for (final SceneHistoryTurn turn in window)
        '${turn.role}:${_stripSceneMetadataSuffix(turn.text).trim()}',
    ].join('|');
  }

  Future<void> _ensureLlmHint({String? coachText, bool force = false}) async {
    final String cacheKey = _hintCacheKey(coachText: coachText);
    if (!force &&
        (_llmHintCache.containsKey(cacheKey) ||
            _llmHintLoadingKeys.contains(cacheKey))) {
      return;
    }
    final _SceneTurnContract contract = _buildSceneTurnContract(
      _hintContextTurns(),
      coachText: coachText,
    );
    final _SceneResponseHint fallbackHint = contract.toHint();
    final List<SceneHistoryTurn> turns = _hintContextTurns();
    final List<SceneHistoryTurn> recentTurns = turns.length > 6
        ? turns.sublist(turns.length - 6)
        : turns;
    if (mounted) {
      setState(() {
        _llmHintLoadingKeys.add(cacheKey);
      });
    } else {
      _llmHintLoadingKeys.add(cacheKey);
    }
    try {
      final List<SceneHistoryTurn> sanitizedRecentTurns = recentTurns
          .map(
            (SceneHistoryTurn turn) => SceneHistoryTurn(
              role: turn.role,
              text: _stripSceneMetadataSuffix(turn.text).trim(),
            ),
          )
          .toList(growable: false);
      final _SceneResponseHint? refinedHint = await _sceneHintCoordinator
          .generateHint(
            SceneHintRequest(
              draft: _draft,
              contract: contract,
              fallbackHint: fallbackHint,
              recentTurns: sanitizedRecentTurns,
            ),
          );
      if (refinedHint == null) {
        return;
      }
      if (!mounted) {
        _llmHintCache[cacheKey] = refinedHint;
        return;
      }
      setState(() {
        _llmHintCache[cacheKey] = refinedHint;
      });
    } catch (error) {
      debugPrint('[Scene] LLM hint generation failed: $error');
    } finally {
      if (!mounted) {
        _llmHintLoadingKeys.remove(cacheKey);
      } else {
        setState(() {
          _llmHintLoadingKeys.remove(cacheKey);
        });
      }
    }
  }

  _SceneResponseHint _displayedSceneHint({String? coachText}) {
    final _SceneResponseHint fallback = _currentSceneHint(coachText: coachText);
    return _llmHintCache[_hintCacheKey(coachText: coachText)] ?? fallback;
  }

  /// 当前正在使用的 hint 是否正在被 LLM 生成中。
  bool _isCurrentHintLoading({String? coachText}) {
    return _llmHintLoadingKeys.contains(_hintCacheKey(coachText: coachText));
  }

  // ignore: unused_element
  Future<void> _startTurnBasedVoiceRequest(
    List<Uint8List> audioChunks, {
    required int voiceDuration,
  }) async {
    if (audioChunks.isEmpty) {
      return;
    }
    if (_hasActiveVoiceSession) {
      await _disposeVoiceChatSession();
    }

    final String? token = await _sceneRuntimeSupportCoordinator.loadToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录'), duration: Duration(seconds: 2)),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }

    _realtimeAudioService = AudioServiceScope.of(context);
    _hasRealtimeAudioService = true;
    _isAiSpeaking = false;
    _pendingVoiceMessageDuration = voiceDuration;
    _queuedTurnVoiceChunks = List<Uint8List>.unmodifiable(audioChunks);

    setState(() {
      _voiceChatConnecting = true;
      _isNpcThinking = true;
      _showTextComposer = false;
    });

    final (:service, :callGeneration) = _beginVoiceChatSession(
      mode: _VoiceSessionMode.turnBased,
    );

    final SceneVoiceSessionBinding binding =
        _sceneVoiceSessionBindingCoordinator.bind(
          service: service,
          plannerModeAware: false,
          isActive: () =>
              mounted &&
              _voiceChatService == service &&
              _realtimeCallGeneration == callGeneration,
          shouldHandleDisconnected: () =>
              mounted &&
              _voiceChatService == service &&
              _realtimeCallGeneration == callGeneration &&
              !_isFinalizingAiTurn,
          onConnected: () async {
            if (_voiceChatConnecting) {
              setState(() {
                _voiceChatConnecting = false;
              });
            }
            final List<Uint8List>? queuedAudioChunks = _queuedTurnVoiceChunks;
            _queuedTurnVoiceChunks = null;
            if (queuedAudioChunks == null || queuedAudioChunks.isEmpty) {
              return;
            }
            try {
              await _sendBufferedTurnVoice(service, queuedAudioChunks);
            } catch (error) {
              if (!mounted ||
                  _voiceChatService != service ||
                  _realtimeCallGeneration != callGeneration) {
                return;
              }
              await _handleTurnBasedVoiceError('语音发送失败: $error');
            }
          },
          onError: (String message) => _handleTurnBasedVoiceError(message),
          onDisconnected: () => _handleTurnBasedVoiceError('语音对话已断开'),
          onUserFinal: (String text) => _handleVoiceUserFinalEvent(
            service: service,
            callGeneration: callGeneration,
            text: text,
            plannerModeAware: false,
          ),
          onAssistantEvent: (VoiceChatTurnEvent event) =>
              _handleVoiceAssistantEvent(
                service: service,
                callGeneration: callGeneration,
                event: event,
                realtimeAudioStreaming: false,
              ),
        );
    _voiceChatConnSub = binding.connectionSubscription;
    _voiceChatTurnEventSub = binding.turnEventSubscription;

    try {
      final List<SceneHistoryTurn> historyTurns = _currentSceneHistoryTurns();
      await _sceneVoiceRuntimeCoordinator.connect(
        service: service,
        request: SceneVoiceConnectRequest(
          token: token,
          config: SceneVoiceSessionConfig(
            sessionId: _sessionId,
            systemPrompt: _buildTurnBasedSystemPrompt(),
            manualTurnDetection: true,
            sceneContext: _buildVoiceSceneContext(historyTurns: historyTurns),
          ),
        ),
      );
    } catch (error) {
      await _handleTurnBasedVoiceError('$error');
    }
  }

  Future<void> _sendBufferedTurnVoice(
    VoiceChatService service,
    List<Uint8List> audioChunks,
  ) async {
    for (final Uint8List chunk in audioChunks) {
      service.sendAudio(chunk);
    }
    service.commitTurn();
  }

  ({VoiceChatService service, int callGeneration}) _beginVoiceChatSession({
    required _VoiceSessionMode mode,
  }) {
    final VoiceChatService service = _sceneVoiceRuntimeCoordinator
        .createService();
    final int callGeneration = ++_realtimeCallGeneration;
    _voiceChatService = service;
    _voiceSessionMode = mode;
    _voiceTurnOrchestrator.startSession(
      sessionKey: callGeneration,
      mode: mode == _VoiceSessionMode.realtime
          ? VoiceTurnMode.realtime
          : VoiceTurnMode.turnBased,
    );
    return (service: service, callGeneration: callGeneration);
  }

  Future<void> _handleVoiceAssistantEvent({
    required VoiceChatService service,
    required int callGeneration,
    required VoiceChatTurnEvent event,
    required bool realtimeAudioStreaming,
  }) async {
    if (_voiceChatService != service ||
        _realtimeCallGeneration != callGeneration) {
      return;
    }
    switch (event.type) {
      case VoiceChatTurnEventType.assistantStarted:
        _voiceTurnOrchestrator.beginAssistantTurn();
        if (!_isAiSpeaking) {
          _isAiSpeaking = true;
          if (realtimeAudioStreaming) {
            try {
              await _stopRealtimeStreamRecording();
            } catch (error) {
              debugPrint('[Realtime] Stop stream recording error: $error');
            }
          }
        }
        break;
      case VoiceChatTurnEventType.assistantTextDelta:
        final String bufferedText = _voiceTurnOrchestrator.appendAssistantText(
          event.text,
        );
        _upsertRealtimeNpcStreamingMessage(bufferedText);
        break;
      case VoiceChatTurnEventType.assistantAudioChunk:
        final RealtimeAudioChunk? audioChunk = event.audioChunk;
        if (audioChunk == null) {
          break;
        }
        _isAiSpeaking = true;
        try {
          if (realtimeAudioStreaming) {
            debugPrint(
              '[Realtime] Audio chunk received, format=${audioChunk.format}, size=${audioChunk.bytes.length}',
            );
            if (_voiceSessionMode == _VoiceSessionMode.realtime) {
              _realtimeAudioService.enqueueRealtimeAudioChunk(audioChunk);
            } else {
              _realtimeAudioService.addRealtimeAudioChunk(audioChunk);
            }
          } else {
            _realtimeAudioService.addRealtimeAudioChunk(audioChunk);
          }
          _voiceTurnOrchestrator.noteAssistantAudio();
        } catch (error) {
          debugPrint('[VoiceTurn] Audio buffer error: $error');
        }
        break;
      case VoiceChatTurnEventType.assistantSpeaking:
        final bool speaking = event.speaking ?? false;
        if (_sceneVoiceTurnRulesCoordinator.shouldIgnoreAssistantSpeakingEvent(
          realtimeAudioStreaming: realtimeAudioStreaming,
          isAiSpeaking: _isAiSpeaking,
          speaking: speaking,
          hasBufferedAssistantTurn:
              _voiceTurnOrchestrator.hasBufferedAssistantTurn,
        )) {
          break;
        }
        if (speaking) {
          _isAiSpeaking = true;
        }
        _voiceTurnOrchestrator.noteSpeaking(speaking);
        break;
      case VoiceChatTurnEventType.assistantDone:
        _voiceTurnOrchestrator.noteAssistantDone(
          event.assistantMeta ?? service.consumeLastAssistantTurnMeta(),
        );
        break;
      case VoiceChatTurnEventType.userPreview:
      case VoiceChatTurnEventType.userFinal:
        break;
    }
  }

  Future<void> _handleVoiceUserFinalEvent({
    required VoiceChatService service,
    required int callGeneration,
    required String text,
    required bool plannerModeAware,
  }) async {
    if (!mounted ||
        _voiceChatService != service ||
        _realtimeCallGeneration != callGeneration ||
        text.trim().isEmpty) {
      return;
    }

    final PreparedSceneVoiceUserTurn? preparedTurn =
        _sceneVoiceUserTurnCoordinator.prepareUserFinalTurn(
          text: text,
          plannerModeAware: plannerModeAware,
          plannerModeActive: service.plannerModeActive,
          pendingVoiceChunks: _pendingRealtimeUserVoiceChunks,
          pendingVoiceMessageDuration: _pendingVoiceMessageDuration,
        );
    _pendingRealtimeUserVoiceChunks.clear();
    if (preparedTurn == null) {
      return;
    }
    if (plannerModeAware) {
      debugPrint(
        '[Realtime] Trusted upload not routed; user final transcript dropped',
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('实时语音提交暂未接入可信上传流程，请改用文字输入'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleVoiceAssistantTurnReady(
    VoiceAssistantTurnReady ready,
  ) async {
    if (!mounted ||
        _isFinalizingAiTurn ||
        _realtimeCallGeneration != ready.sessionKey) {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      return;
    }
    switch (ready.mode) {
      case VoiceTurnMode.turnBased:
        await _finalizeTurnBasedVoiceTurn(ready);
        break;
      case VoiceTurnMode.realtime:
        await _finalizeRealtimeVoiceTurn(ready);
        break;
    }
  }

  Future<void> _finalizeTurnBasedVoiceTurn(
    VoiceAssistantTurnReady ready,
  ) async {
    if (_voiceSessionMode != _VoiceSessionMode.turnBased) {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      return;
    }
    final VoiceChatService? service = _voiceChatService;
    if (service == null) {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      return;
    }
    final String bufferedText = ready.bufferedText.trim();
    if (bufferedText.isEmpty &&
        !_realtimeAudioService.hasRealtimeAudioBuffered) {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      return;
    }

    _isFinalizingAiTurn = true;
    try {
      final AssistantTurnMeta? assistantMeta =
          ready.assistantMeta ?? service.consumeLastAssistantTurnMeta();
      await _disposeVoiceChatSession(
        stopPlayback: false,
        stopStreamRecording: false,
        disconnectService: true,
      );
      String? replayAudioPath;
      if (_realtimeAudioService.hasRealtimeAudioBuffered) {
        replayAudioPath = await _realtimeAudioService.flushRealtimeAudio();
      }
      if (bufferedText.isNotEmpty) {
        final int resolvedVoiceDuration = await _resolveVoiceDurationSeconds(
          audioPath: replayAudioPath,
          fallbackText: bufferedText,
          fallback: 6,
        );
        _appendRealtimeNpcMessage(
          bufferedText,
          audioPath: replayAudioPath,
          voiceDuration: resolvedVoiceDuration,
        );
        if (!_applyAssistantTurnMeta(assistantMeta)) {
          unawaited(_applyRealtimeTurnMeta(bufferedText));
        }
        if (replayAudioPath == null || replayAudioPath.trim().isEmpty) {
          unawaited(
            _realtimeAudioService.playTts(
              bufferedText,
              allowSystemFallback: false,
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _isNpcThinking = false;
          _voiceChatConnecting = false;
        });
      }
    } finally {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      _isFinalizingAiTurn = false;
    }
  }

  Future<void> _finalizeRealtimeVoiceTurn(VoiceAssistantTurnReady ready) async {
    if (_voiceSessionMode != _VoiceSessionMode.realtime) {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      return;
    }
    final VoiceChatService? service = _voiceChatService;
    final String bufferedText = ready.bufferedText.trim();
    if (bufferedText.isEmpty &&
        !_realtimeAudioService.hasRealtimeAudioBuffered) {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      return;
    }

    _isFinalizingAiTurn = true;
    try {
      debugPrint('[Realtime] Finalizing assistant turn');
      String? replayAudioPath;
      if (_realtimeAudioService.hasRealtimeAudioBuffered) {
        replayAudioPath = _voiceSessionMode == _VoiceSessionMode.realtime
            ? await _realtimeAudioService.finalizeRealtimeStreamingAudio()
            : await _realtimeAudioService.flushRealtimeAudio();
      }
      if (bufferedText.isNotEmpty) {
        final int resolvedVoiceDuration = await _resolveVoiceDurationSeconds(
          audioPath: replayAudioPath,
          fallbackText: bufferedText,
          fallback: 6,
        );
        _appendRealtimeNpcMessage(
          bufferedText,
          audioPath: replayAudioPath,
          voiceDuration: resolvedVoiceDuration,
        );
        if (!_applyAssistantTurnMeta(
          ready.assistantMeta ?? service?.consumeLastAssistantTurnMeta(),
        )) {
          unawaited(_applyRealtimeTurnMeta(bufferedText));
        }
      }
      if (!mounted ||
          _voiceChatService != service ||
          _realtimeCallGeneration != ready.sessionKey ||
          _voiceSessionMode != _VoiceSessionMode.realtime) {
        return;
      }
      try {
        await _startRealtimeStreamRecording();
      } catch (error) {
        debugPrint('[Realtime] Restart stream recording error: $error');
      }
    } finally {
      _voiceTurnOrchestrator.completeFinalize(ready.sessionKey);
      _isFinalizingAiTurn = false;
    }
  }

  Future<void> _handleTurnBasedVoiceError(String message) async {
    await _finishVoiceChatSession(
      mode: _VoiceSessionMode.turnBased,
      disconnectService: true,
      stopStreamRecording: false,
      snackBarMessage: message,
    );
  }

  Future<void> _finishVoiceChatSession({
    required _VoiceSessionMode mode,
    bool disconnectService = false,
    bool stopPlayback = true,
    bool stopStreamRecording = true,
    bool preserveBufferedAssistantText = false,
    String? snackBarMessage,
  }) async {
    final String bufferedText = preserveBufferedAssistantText
        ? _voiceTurnOrchestrator.bufferedAssistantText.trim()
        : '';

    _isAiSpeaking = false;
    await _disposeVoiceChatSession(
      stopPlayback: stopPlayback,
      stopStreamRecording: stopStreamRecording,
      disconnectService: disconnectService,
    );
    if (!mounted) {
      return;
    }

    if (preserveBufferedAssistantText && bufferedText.isNotEmpty) {
      final int resolvedVoiceDuration = _fallbackVoiceDurationFromText(
        bufferedText,
        fallback: 6,
      );
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _MessageRole.npc,
            text: bufferedText,
            inputType: _ChatInputType.voice,
            voiceDuration: resolvedVoiceDuration,
          ),
        );
      });
      _scrollChatToLatest();
    }

    setState(() {
      _voiceChatConnecting = false;
      _isRecording = false;
      if (mode == _VoiceSessionMode.turnBased) {
        _isNpcThinking = false;
      }
    });

    if (snackBarMessage != null && snackBarMessage.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackBarMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startRealtimeStreamRecording() async {
    if (!_hasRealtimeAudioService || _realtimeAudioService.isStreamRecording) {
      return;
    }

    await _realtimeAudioService.startStreamRecording((Uint8List pcmData) {
      if (_isAiSpeaking) {
        return;
      }
      if (pcmData.isNotEmpty) {
        _pendingRealtimeUserVoiceChunks.add(Uint8List.fromList(pcmData));
      }
      _voiceChatService?.sendAudio(pcmData);
    });
  }

  Future<void> _stopRealtimeStreamRecording() async {
    if (!_hasRealtimeAudioService || !_realtimeAudioService.isStreamRecording) {
      return;
    }
    await _realtimeAudioService.stopStreamRecording();
  }

  /// 开始实时语音通话（WebSocket）
  Future<void> _startRealtimeCall() async {
    if (_voiceChatService != null && _voiceChatService!.isConnected) return;
    if (_voiceChatService != null ||
        _voiceChatConnSub != null ||
        _voiceChatTurnEventSub != null) {
      _cleanupVoiceChatSession();
    }

    final String? token = await _sceneRuntimeSupportCoordinator.loadToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录'), duration: Duration(seconds: 2)),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }

    _realtimeAudioService = AudioServiceScope.of(context);
    _hasRealtimeAudioService = true;
    _isAiSpeaking = false;
    _pendingVoiceMessageDuration = 3;

    setState(() {
      _voiceChatConnecting = true;
    });

    final (:service, :callGeneration) = _beginVoiceChatSession(
      mode: _VoiceSessionMode.realtime,
    );

    final SceneVoiceSessionBinding binding =
        _sceneVoiceSessionBindingCoordinator.bind(
          service: service,
          plannerModeAware: true,
          isActive: () =>
              mounted &&
              _voiceChatService == service &&
              _realtimeCallGeneration == callGeneration,
          shouldHandleDisconnected: () =>
              mounted &&
              _voiceChatService == service &&
              _realtimeCallGeneration == callGeneration &&
              !_isFinalizingAiTurn,
          onConnected: () async {
            setState(() {
              _voiceChatConnecting = false;
              _isRecording = true;
            });
            try {
              await _startRealtimeStreamRecording();
            } catch (e) {
              await _finishVoiceChatSession(
                mode: _VoiceSessionMode.realtime,
                disconnectService: true,
                snackBarMessage: '实时录音启动失败: ${e.toString()}',
              );
            }
          },
          onError: (String _) => _finishVoiceChatSession(
            mode: _VoiceSessionMode.realtime,
            disconnectService: true,
            snackBarMessage: '实时通话连接失败',
          ),
          onDisconnected: () =>
              _finishVoiceChatSession(mode: _VoiceSessionMode.realtime),
          onUserFinal: (String text) => _handleVoiceUserFinalEvent(
            service: service,
            callGeneration: callGeneration,
            text: text,
            plannerModeAware: true,
          ),
          onAssistantEvent: (VoiceChatTurnEvent event) =>
              _handleVoiceAssistantEvent(
                service: service,
                callGeneration: callGeneration,
                event: event,
                realtimeAudioStreaming: true,
              ),
        );
    _voiceChatConnSub = binding.connectionSubscription;
    _voiceChatTurnEventSub = binding.turnEventSubscription;

    try {
      await _sceneVoiceRuntimeCoordinator.connect(
        service: service,
        request: SceneVoiceConnectRequest(
          token: token,
          config: SceneVoiceSessionConfig(
            sessionId: _sessionId,
            systemPrompt: _buildRealtimeSystemPrompt(),
            plannerMode: true,
            sceneContext: _buildVoiceSceneContext(
              historyTurns: _currentSceneHistoryTurns(),
            ),
          ),
        ),
      );
    } catch (e) {
      await _finishVoiceChatSession(
        mode: _VoiceSessionMode.realtime,
        disconnectService: true,
        snackBarMessage: '连接失败: ${e.toString()}',
      );
    }
  }

  /// 清理 VoiceChatService 资源（不更新 UI）
  void _cleanupVoiceChatSession() {
    unawaited(_disposeVoiceChatSession());
  }

  Future<void> _disposeVoiceChatSession({
    bool stopPlayback = true,
    bool stopStreamRecording = true,
    bool disconnectService = false,
  }) async {
    final VoiceChatService? service = _voiceChatService;
    final StreamSubscription<String>? connSub = _voiceChatConnSub;
    final StreamSubscription<VoiceChatTurnEvent>? turnEventSub =
        _voiceChatTurnEventSub;

    _realtimeCallGeneration++;
    _isAiSpeaking = false;
    _isFinalizingAiTurn = false;
    _voiceTurnOrchestrator.clearSession();
    _awaitingUserReplyForLastNpc = false;
    _voiceSessionMode = _VoiceSessionMode.none;
    _queuedTurnVoiceChunks = null;
    _voiceChatConnSub = null;
    _voiceChatTurnEventSub = null;
    _voiceChatService = null;
    await _sceneVoiceSessionLifecycleCoordinator.disposeSession(
      service: service,
      connectionSubscription: connSub,
      turnEventSubscription: turnEventSub,
      stopPlayback: stopPlayback ? _stopScenarioAudioPlayback : null,
      stopStreamRecording: stopStreamRecording
          ? _stopRealtimeStreamRecording
          : null,
      disconnectService: disconnectService,
    );
  }

  /// 停止实时语音通话
  Future<void> _stopRealtimeCall() async {
    await _finishVoiceChatSession(
      mode: _VoiceSessionMode.realtime,
      disconnectService: true,
      preserveBufferedAssistantText: true,
    );
  }

  Future<void> _stopScenarioAudioPlayback() async {
    if (!mounted && !_hasRealtimeAudioService) {
      return;
    }
    final AudioService audioService = _hasRealtimeAudioService
        ? _realtimeAudioService
        : AudioServiceScope.of(context);
    await audioService.stopPlayback();
  }

  void _appendRealtimeNpcMessage(
    String text, {
    String? audioPath,
    int? voiceDuration,
  }) {
    final String cleanedText = _stripSceneMetadataSuffix(text);
    if (!mounted || cleanedText.trim().isEmpty) {
      return;
    }
    if (_awaitingUserReplyForLastNpc && cleanedText == _lastRealtimeNpcText) {
      return;
    }
    _lastRealtimeNpcText = cleanedText;
    _awaitingUserReplyForLastNpc = true;
    setState(() {
      final int lastIndex = _messages.length - 1;
      if (lastIndex >= 0 &&
          _messages[lastIndex].role == _MessageRole.npc &&
          _messages[lastIndex].isStreaming) {
        final _ChatMessage current = _messages[lastIndex];
        _messages[lastIndex] = _ChatMessage(
          role: _MessageRole.npc,
          text: cleanedText,
          inputType: _ChatInputType.voice,
          voiceDuration: voiceDuration ?? current.voiceDuration ?? 6,
          audioPath: audioPath ?? current.audioPath,
          mood: current.mood,
          isStreaming: false,
        );
      } else if (lastIndex >= 0 &&
          _messages[lastIndex].role == _MessageRole.npc &&
          _messages[lastIndex].text.trim() == cleanedText) {
        final _ChatMessage current = _messages[lastIndex];
        _messages[lastIndex] = _ChatMessage(
          role: _MessageRole.npc,
          text: current.text,
          inputType: current.inputType,
          voiceDuration: voiceDuration ?? current.voiceDuration,
          audioPath: audioPath ?? current.audioPath,
          mood: current.mood,
          isStreaming: false,
        );
      } else {
        _messages.add(
          _ChatMessage(
            role: _MessageRole.npc,
            text: cleanedText,
            inputType: _ChatInputType.voice,
            voiceDuration:
                voiceDuration ??
                _fallbackVoiceDurationFromText(cleanedText, fallback: 6),
            audioPath: audioPath,
          ),
        );
      }
      _expandedCoachMessageIndex = null;
      _showHintReferenceAnswer = false;
    });
    _scrollChatToLatest();
    _persistConversationHistory();
    if (_effectiveSceneSpec.category == 'service') {
      _recordServiceTurnTrace(
        _servicePolicyDecision(_currentSceneHistoryTurns()),
        source: _voiceSessionMode == _VoiceSessionMode.realtime
            ? 'realtime_reply'
            : 'turn_based_reply',
        assistantReplyText: cleanedText,
      );
    }
    _refreshVoiceSessionGuidance();
    unawaited(_ensureLlmHint());
  }

  void _appendCoachHintMessage(String hint, {String? note}) {
    final String cleanedHint = hint.trim();
    if (cleanedHint.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(
        _ChatMessage(role: _MessageRole.coach, text: cleanedHint, note: note),
      );
      _expandedCoachMessageIndex = null;
      _showHintReferenceAnswer = false;
    });
    _scrollChatToLatest(animated: false);
    _persistConversationHistory();
    unawaited(_ensureLlmHint(coachText: cleanedHint));
  }

  void _appendEventMessage(String label, {Color? accent}) {
    final String cleanedLabel = label.trim();
    if (cleanedLabel.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(
        _ChatMessage(
          role: _MessageRole.event,
          text: cleanedLabel,
          accent: accent ?? const Color(0xFF8BA8E0),
        ),
      );
      _expandedCoachMessageIndex = null;
      _showHintReferenceAnswer = false;
    });
    _scrollChatToLatest(animated: false);
    _persistConversationHistory();
  }

  void _updateLastNpcSummaryLabel(String summary) {
    final String cleanedSummary = summary.trim();
    if (cleanedSummary.isEmpty || !mounted) {
      return;
    }
    setState(() {
      for (int index = _messages.length - 1; index >= 0; index--) {
        final _ChatMessage current = _messages[index];
        if (current.role != _MessageRole.npc) {
          continue;
        }
        _messages[index] = _ChatMessage(
          role: current.role,
          text: current.text,
          note: current.note,
          mood: cleanedSummary,
          inputType: current.inputType,
          voiceDuration: current.voiceDuration,
          audioPath: current.audioPath,
          isStreaming: current.isStreaming,
          accent: current.accent,
        );
        break;
      }
    });
    _persistConversationHistory();
  }

  bool _applyAssistantTurnMeta(AssistantTurnMeta? assistantMeta) {
    if (assistantMeta == null) {
      return false;
    }
    return _applyResolvedAssistantTurnMeta(
      summary: assistantMeta.summary,
      coach: assistantMeta.coach,
      event: assistantMeta.event,
      turnContract: assistantMeta.turnContract,
      sceneState: assistantMeta.sceneState,
    );
  }

  bool _applyResolvedAssistantTurnMeta({
    required String summary,
    required String coach,
    required String event,
    required SceneTurnContract? turnContract,
    required SceneStateSnapshot? sceneState,
  }) {
    final String cleanedSummary = summary.trim();
    final String cleanedCoach = coach.trim();
    final String cleanedEvent = event.trim();
    final bool hasMeta =
        cleanedSummary.isNotEmpty ||
        cleanedCoach.isNotEmpty ||
        cleanedEvent.isNotEmpty ||
        turnContract != null ||
        sceneState != null;
    if (!hasMeta || !mounted) {
      return false;
    }
    if (cleanedSummary.isNotEmpty) {
      _updateLastNpcSummaryLabel(cleanedSummary);
    }
    if (turnContract != null || sceneState != null) {
      setState(() {
        _serverTurnContract = turnContract ?? _serverTurnContract;
        _serverSceneState = sceneState ?? _serverSceneState;
      });
    }
    if (cleanedEvent.isNotEmpty) {
      _appendEventMessage(cleanedEvent);
    }
    final String fallbackCoach = _resolvedCoachHintFallback(
      _currentSceneHistoryTurns(),
    );
    final String resolvedCoach = cleanedCoach.isNotEmpty
        ? cleanedCoach
        : fallbackCoach;
    if (resolvedCoach.isNotEmpty) {
      _appendCoachHintMessage(resolvedCoach);
    }
    return true;
  }

  Future<void> _applyRealtimeTurnMeta(String assistantText) async {
    final String cleanedAssistantText = assistantText.trim();
    if (cleanedAssistantText.isEmpty || !mounted) {
      return;
    }
    final List<Map<String, dynamic>> history = _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => <String, dynamic>{
            'role': m.role == _MessageRole.user ? 'user' : 'npc',
            'text': _stripSceneMetadataSuffix(m.text),
          },
        )
        .toList(growable: false);
    try {
      final SceneTurnMetaResult meta = await _sceneConversationCoordinator
          .generateTurnMeta(
            draft: _draft,
            history: history,
            assistantText: cleanedAssistantText,
            sceneState: _serverSceneState == null
                ? null
                : <String, dynamic>{
                    'currentStageId': _serverSceneState!.currentStageId,
                    'currentStageLabel': _serverSceneState!.currentStageLabel,
                    'currentStageIndex': _serverSceneState!.currentStageIndex,
                    'totalStages': _serverSceneState!.totalStages,
                    'userTurnCount': _serverSceneState!.userTurnCount,
                    'topic': _serverSceneState!.topic,
                    'filledFacts': _serverSceneState!.filledFacts,
                    'missingFacts': _serverSceneState!.missingFacts,
                    'repairCount': _serverSceneState!.repairCount,
                    'offTopicCount': _serverSceneState!.offTopicCount,
                    'lastUserIntent': _serverSceneState!.lastUserIntent,
                    'stageSatisfied': _serverSceneState!.stageSatisfied,
                    'confidence': _serverSceneState!.confidence,
                  },
          );
      if (!mounted) {
        return;
      }
      _applyResolvedAssistantTurnMeta(
        summary: meta.summary,
        coach: meta.coach,
        event: meta.event,
        turnContract: meta.turnContract,
        sceneState: meta.sceneState,
      );
    } catch (error) {
      debugPrint('[Scene] Realtime turn meta failed: $error');
      final String fallbackCoach = _resolvedCoachHintFallback(
        _currentSceneHistoryTurns(),
      );
      if (fallbackCoach.isNotEmpty) {
        _appendCoachHintMessage(fallbackCoach);
      }
    }
  }

  void _upsertRealtimeNpcStreamingMessage(String text) {
    final String cleanedText = _stripSceneMetadataSuffix(text).trim();
    if (!mounted || cleanedText.isEmpty) {
      return;
    }

    setState(() {
      if (_voiceSessionMode == _VoiceSessionMode.turnBased && _isNpcThinking) {
        _isNpcThinking = false;
        _voiceChatConnecting = false;
      }
      final int lastIndex = _messages.length - 1;
      if (lastIndex >= 0 &&
          _messages[lastIndex].role == _MessageRole.npc &&
          _messages[lastIndex].isStreaming) {
        final _ChatMessage current = _messages[lastIndex];
        _messages[lastIndex] = _ChatMessage(
          role: _MessageRole.npc,
          text: cleanedText,
          inputType: _ChatInputType.voice,
          voiceDuration:
              current.voiceDuration ??
              _fallbackVoiceDurationFromText(cleanedText, fallback: 6),
          audioPath: current.audioPath,
          mood: current.mood,
          isStreaming: true,
        );
        return;
      }
      if (lastIndex >= 0 &&
          _messages[lastIndex].role == _MessageRole.npc &&
          _messages[lastIndex].text.trim() == cleanedText) {
        return;
      }

      _messages.add(
        _ChatMessage(
          role: _MessageRole.npc,
          text: cleanedText,
          inputType: _ChatInputType.voice,
          voiceDuration: _fallbackVoiceDurationFromText(
            cleanedText,
            fallback: 6,
          ),
          isStreaming: true,
        ),
      );
    });
    _scrollChatToLatest(animated: false);
  }

  String _stripSceneMetadataSuffix(String rawText) {
    return _sceneVoiceTurnRulesCoordinator.stripSceneMetadataSuffix(rawText);
  }

  void _toggleCoachHintAt(int index) {
    final bool expanding = _expandedCoachMessageIndex != index;
    final String coachText = expanding ? _messages[index].text : '';
    setState(() {
      _expandedCoachMessageIndex = _expandedCoachMessageIndex == index
          ? null
          : index;
      _showHintReferenceAnswer = false;
      _showTextComposer = false;
    });
    if (expanding && coachText.trim().isNotEmpty) {
      unawaited(_ensureLlmHint(coachText: coachText));
    }
    if (_expandedCoachMessageIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scrollChatToLatest(animated: false);
      });
    }
  }

  void _toggleHintReferenceAnswer() {
    setState(() {
      _showHintReferenceAnswer = !_showHintReferenceAnswer;
    });
  }

  Future<void> _sendMessage({
    bool asVoice = false,
    int? voiceDuration,
    String? overrideText,
  }) async {
    final input = (overrideText ?? _controller.text).trim();
    if (input.isEmpty || _isNpcThinking) return;

    final List<SceneHistoryTurn> history = _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => SceneHistoryTurn(
            role: m.role == _MessageRole.user ? 'user' : 'npc',
            text: m.text,
          ),
        )
        .toList();
    final List<SceneHistoryTurn> requestTurns = <SceneHistoryTurn>[
      ...history,
      SceneHistoryTurn(role: 'user', text: input),
    ];
    final SceneDraft requestDraft = _draftForAssistantTurn(requestTurns);
    if (_effectiveSceneSpec.category == 'service') {
      _recordServiceTurnTrace(
        _servicePolicyDecision(requestTurns),
        source: 'text_request',
        turns: requestTurns,
      );
    }

    setState(() {
      _feedback = null;
      _feedbackCacheKey = null;
      _feedbackPendingKey = null;
      _feedbackStartedAt = null;
      _feedbackCompletionAnnouncedKey = null;
      _feedbackTaskGeneration += 1;
      _isFeedbackLoading = false;
      _messages.add(
        _ChatMessage(
          role: _MessageRole.user,
          text: input,
          inputType: asVoice ? _ChatInputType.voice : _ChatInputType.text,
          voiceDuration: asVoice
              ? (voiceDuration ?? (input.length / 14).ceil())
              : null,
        ),
      );
      _isNpcThinking = true;
      _controller.clear();
      _showTextComposer = false;
      _isRecording = false;
      _expandedCoachMessageIndex = null;
      _showHintReferenceAnswer = false;
    });
    _scrollChatToLatest();
    _persistConversationHistory();
    unawaited(_refreshConversationSummary());

    final AppSession session = AppSessionScope.of(context);
    try {
      final SceneReply rawReply = await _sendSceneMessageWithRecovery(
        session: session,
        userText: input,
        draft: requestDraft,
        history: history,
      );
      final SceneReply reply = _sanitizeSceneReplyForScene(
        reply: rawReply,
        requestTurns: requestTurns,
      );
      final String? audioPath = await _prepareNpcAudioPath(reply.npcText);
      final int resolvedVoiceDuration = await _resolveVoiceDurationSeconds(
        audioPath: audioPath,
        fallbackText: reply.npcText,
        fallback: 6,
      );
      final String fallbackCoachHint = _resolvedCoachHintFallback(
        <SceneHistoryTurn>[
          ...history,
          SceneHistoryTurn(role: 'user', text: input),
        ],
      );
      if (!mounted) return;
      setState(() {
        _serverTurnContract = reply.turnContract ?? _serverTurnContract;
        _serverSceneState = reply.sceneState ?? _serverSceneState;
        if (reply.roleMemoryHints.isNotEmpty) {
          _sceneRoleMemoryHints = reply.roleMemoryHints;
        }
        if (reply.learningProfileHints.isNotEmpty) {
          _sceneLearningProfileHints = reply.learningProfileHints;
        }
        _isNpcThinking = false;
        if (reply.eventLabel != null && reply.eventColor != null) {
          _messages.add(
            _ChatMessage(
              role: _MessageRole.event,
              text: reply.eventLabel!,
              accent: reply.eventColor!,
            ),
          );
        }
        _messages.add(
          _ChatMessage(
            role: _MessageRole.npc,
            text: reply.npcText,
            inputType: _ChatInputType.voice,
            voiceDuration: resolvedVoiceDuration,
            mood: reply.summary ?? reply.mood,
            audioPath: audioPath,
          ),
        );
        final String resolvedCoachHint =
            (reply.coachHint ?? '').trim().isNotEmpty
            ? reply.coachHint!.trim()
            : fallbackCoachHint;
        if (resolvedCoachHint.isNotEmpty) {
          _messages.add(
            _ChatMessage(role: _MessageRole.coach, text: resolvedCoachHint),
          );
        }
      });
      _scrollChatToLatest();
      _persistConversationHistory();
      if (_effectiveSceneSpec.category == 'service') {
        _recordServiceTurnTrace(
          _servicePolicyDecision(_currentSceneHistoryTurns()),
          source: 'text_reply',
          assistantReplyText: reply.npcText,
        );
      }
      unawaited(_ensureLlmHint());

      final AudioService audioService = AudioServiceScope.of(context);
      if (audioPath != null && audioPath.trim().isNotEmpty) {
        await audioService.playFile(audioPath);
      } else {
        await audioService.playTts(reply.npcText, allowSystemFallback: false);
      }
    } catch (error) {
      if (!mounted) return;
      final String message = _friendlyErrorMessage(error);
      setState(() {
        _isNpcThinking = false;
        _messages.add(
          _ChatMessage(
            role: _MessageRole.event,
            text: message,
            accent: Color(0xFFE8855A),
          ),
        );
      });
      _persistConversationHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: switch (_view) {
        SceneFlowView.home => _buildVirtualFriendHome(),
        SceneFlowView.create => _buildSceneCreateHome(),
        SceneFlowView.draft => _buildDraft(),
        SceneFlowView.edit => _buildEdit(),
        SceneFlowView.chat => _buildChatReferenceUi(),
        SceneFlowView.feedback => _buildFeedback(),
      },
    );
  }

  Widget _buildVirtualFriendHome() {
    final List<_VirtualFriend> friends = _filteredVirtualFriends;
    return Container(
      key: const ValueKey('scene-home'),
      color: Colors.white,
      child: Column(
        children: [
          _SceneFriendHomeHeader(
            searchController: _friendSearchController,
            onAddFriend: () => _showVirtualFriendEditor(),
          ),
          Expanded(
            child: _isLoadingVirtualFriends
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1AAD19)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: friends.length + 1,
                    separatorBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return const SizedBox.shrink();
                      }
                      return const Divider(
                        height: 1,
                        indent: 76,
                        endIndent: 16,
                        color: Color(0xFFF0F0F0),
                      );
                    },
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            _SceneCreateEntryTile(
                              onTap: () => _openSceneCreate(),
                            ),
                            const Divider(
                              height: 1,
                              indent: 76,
                              endIndent: 16,
                              color: Color(0xFFF0F0F0),
                            ),
                            if (friends.isEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  38,
                                  16,
                                  18,
                                ),
                                child: _VirtualFriendsEmptyState(
                                  onCreateFriend: () =>
                                      _showVirtualFriendEditor(),
                                ),
                              ),
                          ],
                        );
                      }
                      final _VirtualFriend friend = friends[index - 1];
                      return _VirtualFriendTile(
                        friend: friend,
                        timeLabel: _friendLastActiveLabel(friend.updatedAt),
                        selected: friend.id == _activeFriendId,
                        onTap: () => _openSceneCreate(friend: friend),
                        onEdit: () => _showVirtualFriendEditor(friend: friend),
                        onDelete: friend.isCustom
                            ? () => _deleteVirtualFriend(friend)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneCreateHome() {
    final AppSession session = AppSessionScope.of(context);
    final List<_RecentScene> recentScenes = _recentScenes(session);
    final _VirtualFriend? activeFriend = _activeFriend;
    if (activeFriend != null) {
      final List<PracticeHistoryModel> friendPractices =
          _recentPracticesForFriend(session, activeFriend);
      final List<({String label, String prompt})> recommendations =
          _friendQuickRecommendations(activeFriend);
      return _buildVirtualFriendDetailPage(
        activeFriend,
        recommendations,
        friendPractices,
      );
    }
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Container(
        key: const ValueKey('scene-create-home'),
        color: appBackground,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.85, -1),
                  end: Alignment(0.92, 1),
                  colors: [
                    Color(0xFF1A3530),
                    Color(0xFF2E6058),
                    Color(0xFF72B4A8),
                    appBackground,
                  ],
                  stops: [0, 0.42, 0.78, 1],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 54, 22, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _setView(SceneFlowView.home),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0x1AFFFFFF),
                                side: const BorderSide(
                                  color: Color(0x2EFFFFFF),
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _activeFriend == null
                                        ? '从聊天列表进入的二级创建页'
                                        : '为 ${_activeFriend!.name} 定制场景',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0x99FFFFFF),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    '场景创建',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.6,
                                      height: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Color(0x2E000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showVirtualFriendEditor(
                                friend: _activeFriend,
                              ),
                              child: _VirtualFriendAvatarBadge(
                                emoji: _activeFriend?.avatarEmoji ?? '✨',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_activeFriend == null)
                          Row(
                            children: const [
                              _SceneTopPill(
                                icon: Icons.local_fire_department_rounded,
                                iconColor: Color(0xFFFFB83C),
                                value: '7天',
                                suffix: '连续',
                              ),
                              SizedBox(width: 8),
                              _SceneTopPill(
                                icon: Icons.bar_chart_rounded,
                                iconColor: Color(0xFFA8E6D8),
                                value: '2 / 3',
                                suffix: '今日目标',
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _SceneProgressPill(progress: 0.67),
                              ),
                            ],
                          )
                        else
                          _SelectedFriendSummaryCard(
                            friend: _activeFriend!,
                            onClear: () {
                              setState(() {
                                _activeFriendId = null;
                                _controller.clear();
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 82),
                children: [
                  if (_activeFriend != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _SelectedFriendPromptCard(friend: _activeFriend!),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: _buildSceneGeneratorCard(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '快速选场景',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18160F),
                          ),
                        ),
                        Text(
                          '点击直接生成',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFABA39A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      itemCount: quickScenes.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final item = quickScenes[index];
                        return GestureDetector(
                          onTap: _isDraftGenerating
                              ? null
                              : () => _generateDraft(
                                  _activeFriend == null
                                      ? '${item.label}相关的英文对话练习'
                                      : _promptForVirtualFriend(
                                          _activeFriend!,
                                          sceneFocus: item.label,
                                        ),
                                ),
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFEAE6E0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0F000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: item.bg,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3A3530),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: Color(0xFF8A8078),
                            ),
                            SizedBox(width: 7),
                            Text(
                              '最近练过的',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18160F),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            '查看全部',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A7C6F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recentScenes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _RecentSceneEmptyCard(),
                    )
                  else
                    ...recentScenes.map(
                      (scene) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Dismissible(
                          key: ValueKey<String>(
                            'recent-scene-${scene.title}-${scene.practice.id ?? scene.lastTime}',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB94E4E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '删除',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('删除这个场景？'),
                                      content: Text(
                                        '会删除“${scene.title}”在最近练过中的记录和已保存总结。',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('取消'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;
                          },
                          onDismissed: (_) {
                            AppSessionScope.of(
                              context,
                            ).deleteRecentPracticeGroup(scene.title);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已删除该场景记录'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: _RecentSceneCard(
                            scene: scene,
                            onSummary: () {
                              final SceneFeedback? storedFeedback =
                                  _sceneFeedbackFromStoredPractice(
                                    scene.practice,
                                  );
                              final bool isPending =
                                  scene.practice.feedbackStatus == 'pending';
                              if (storedFeedback == null && !isPending) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('这条练习记录还没有可查看的复盘总结'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              final _SceneFeedbackRequestData?
                              restoredFeedbackData =
                                  _feedbackRequestDataFromStoredPractice(
                                    scene.practice,
                                  );
                              if (storedFeedback == null &&
                                  isPending &&
                                  restoredFeedbackData == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('这条后台复盘缺少上下文，请重新生成'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              final SceneDraft restoredDraft =
                                  _sceneDraftFromStoredPractice(
                                    scene.practice,
                                  ) ??
                                  _withSceneSpec(
                                    SceneDraft(
                                      title: scene.title,
                                      emoji: scene.emoji,
                                      tags: scene.tags,
                                      userRole: '沟通发起方',
                                      relationship: '与对方已有工作接触，需要继续推进当前议题',
                                      goal: '保持表达清晰，并能承接对方追问。',
                                      npcName: 'Alex',
                                      npcRole: '对话对象',
                                      environment: '真实工作语境',
                                      challenge: '回答不能太模糊，需要给出明确动作。',
                                      plotDesign:
                                          '先说明当前情况；再回应对方追问；接着给出明确动作；最后补充下一步安排。',
                                    ),
                                  );
                              setState(() {
                                _draft = restoredDraft;
                                _controller.text =
                                    scene.practice.promptText
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? scene.practice.promptText!.trim()
                                    : _editablePromptFromDraft(restoredDraft);
                                _restoredFeedbackRequestData =
                                    restoredFeedbackData;
                                _feedback = storedFeedback;
                                _feedbackCacheKey = storedFeedback == null
                                    ? null
                                    : (scene.practice.id ??
                                          '${scene.title}|${scene.practice.practicedAt?.toIso8601String() ?? ''}');
                                _feedbackPendingKey = null;
                                _feedbackStartedAt = null;
                                _feedbackCompletionAnnouncedKey = null;
                                _feedbackTaskGeneration += 1;
                                _isFeedbackLoading = false;
                                _scenePracticeRecorded = storedFeedback != null;
                                _scenePracticePendingRecorded = isPending;
                                _feedbackOpenedFromRecentSummary = true;
                              });
                              _setView(SceneFlowView.feedback);
                            },
                            onContinue: () {
                              final SceneDraft restoredDraft =
                                  _sceneDraftFromStoredPractice(
                                    scene.practice,
                                  ) ??
                                  _withSceneSpec(
                                    SceneDraft(
                                      title: scene.title,
                                      emoji: scene.emoji,
                                      tags: scene.tags,
                                      userRole: '沟通发起方',
                                      relationship: '与对方延续上一轮沟通，需要把话题继续推进',
                                      goal: '用英文重新组织你的表达节奏。',
                                      npcName: 'Alex',
                                      npcRole: '对话对象',
                                      environment: '延续之前的场景',
                                      challenge: '对方会继续往下追问。',
                                      plotDesign:
                                          '先承接上一轮话题；再回应新的追问；接着推进一个动作；最后把对话带到下一步。',
                                    ),
                                  );
                              final String restoredPrompt =
                                  scene.practice.promptText
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? scene.practice.promptText!.trim()
                                  : _editablePromptFromDraft(restoredDraft);
                              setState(() {
                                _controller.text = restoredPrompt;
                                _draft = restoredDraft;
                                _feedback = null;
                                _feedbackCacheKey = null;
                                _feedbackPendingKey = null;
                                _feedbackStartedAt = null;
                                _feedbackCompletionAnnouncedKey = null;
                                _feedbackTaskGeneration += 1;
                                _isFeedbackLoading = false;
                                _scenePracticeRecorded = false;
                                _scenePracticePendingRecorded = false;
                                _restoredFeedbackRequestData = null;
                                _feedbackOpenedFromRecentSummary = false;
                              });
                              _setView(SceneFlowView.draft);
                            },
                          ),
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Color(0x728A8078),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '已练完的场景会自动归档',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0x728A8078),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualFriendDetailPage(
    _VirtualFriend friend,
    List<({String label, String prompt})> recommendations,
    List<PracticeHistoryModel> recentPractices,
  ) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Container(
        key: ValueKey<String>('friend-detail-${friend.id}'),
        color: const Color(0xFFF8F5EF),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _VirtualFriendDetailHero(
                    friend: friend,
                    onBack: () => _setView(SceneFlowView.home),
                    onEdit: () => _showVirtualFriendEditor(friend: friend),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _VirtualFriendRecommendationSection(
                      items: recommendations,
                      onTapItem: _openRecommendedScene,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                    child: _VirtualFriendCustomSceneComposer(
                      friendName: friend.name,
                      controller: _controller,
                      isLoading: _isDraftGenerating,
                      onGenerate: () => _generateDraft(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
                    child: _VirtualFriendRecentPracticeSection(
                      practices: recentPractices,
                      onTapPractice: (PracticeHistoryModel practice) {
                        final SceneDraft restoredDraft =
                            _sceneDraftFromStoredPractice(practice) ??
                            _draftFromVirtualFriend(friend);
                        final String restoredPrompt =
                            practice.promptText?.trim().isNotEmpty == true
                            ? practice.promptText!.trim()
                            : _editablePromptFromDraft(restoredDraft);
                        setState(() {
                          _controller.text = restoredPrompt;
                          _draft = restoredDraft;
                          _feedback = null;
                          _feedbackCacheKey = null;
                          _feedbackPendingKey = null;
                          _feedbackStartedAt = null;
                          _feedbackCompletionAnnouncedKey = null;
                          _feedbackTaskGeneration += 1;
                          _isFeedbackLoading = false;
                          _scenePracticeRecorded = false;
                          _scenePracticePendingRecorded = false;
                          _restoredFeedbackRequestData = null;
                          _feedbackOpenedFromRecentSummary = false;
                        });
                        _setView(SceneFlowView.draft);
                      },
                    ),
                  ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneGeneratorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 40,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _inputFocused ? const Color(0x664A7C6F) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0x144A7C6F),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: Color(0xFF4A7C6F),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '智能场景生成',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A7C6F),
                  ),
                ),
                const Spacer(),
                const Row(
                  children: [
                    SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF4DB87A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '准备就绪',
                      style: TextStyle(fontSize: 10, color: Color(0xFF8A8078)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 2),
            child: TextField(
              controller: _controller,
              focusNode: _scenePromptFocusNode,
              maxLines: null,
              onTapOutside: (_) => _dismissKeyboard(),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF18160F),
                height: 1.75,
              ),
              decoration: InputDecoration(
                hintText: examplePrompts[_activePromptIndex],
                hintStyle: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFB0A89F),
                  height: 1.75,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEAE6DF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isHomeSpeechRecording)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0x224A7C6F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: _isDraftGenerating
                          ? null
                          : (_) => unawaited(_startHomeSpeechInput()),
                      onLongPressEnd: _isDraftGenerating
                          ? null
                          : (_) => unawaited(_stopHomeSpeechInput()),
                      onLongPressCancel: _isDraftGenerating
                          ? null
                          : () => unawaited(_stopHomeSpeechInput()),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isHomeSpeechRecording
                              ? const Color(0xFF2E6058)
                              : const Color(0xFFF2EFE9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isHomeSpeechRecording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          size: 15,
                          color: _isHomeSpeechRecording
                              ? Colors.white
                              : const Color(0xFF8A8078),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isDraftGenerating
                        ? '正在生成场景草稿'
                        : _isHomeSpeechRecording
                        ? '松开停止，识别结果会实时显示'
                        : _controller.text.isNotEmpty
                        ? '${_controller.text.length} 字'
                        : '按住说话，松开停止',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isDraftGenerating
                          ? const Color(0xFF4A7C6F)
                          : _isHomeSpeechRecording
                          ? const Color(0xFF4A7C6F)
                          : const Color(0xFFB0A89F),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      _controller.text.trim().isEmpty || _isDraftGenerating
                      ? null
                      : () => _generateDraft(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6058),
                    disabledBackgroundColor: const Color(0xFFEAE6DF),
                    foregroundColor: _controller.text.trim().isEmpty
                        ? const Color(0xFFC0B8B0)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: _isDraftGenerating
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _controller.text.trim().isEmpty
                                  ? const Color(0xFFC0B8B0)
                                  : Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: _controller.text.trim().isEmpty
                              ? const Color(0xFFC0B8B0)
                              : Colors.white,
                        ),
                  label: Text(
                    _isDraftGenerating ? '生成中' : '生成场景',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _controller.text.trim().isEmpty
                          ? const Color(0xFFC0B8B0)
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraft() {
    const int confidence = 94;
    const double draftHeaderBackgroundHeight = 112;
    final EdgeInsets mediaPadding = MediaQuery.paddingOf(context);
    final double bottomInset = mediaPadding.bottom;
    final double topInset = mediaPadding.top;

    return Container(
      key: const ValueKey('scene-draft'),
      color: appBackground,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: draftHeaderBackgroundHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A3530),
                    Color(0xFF2E6058),
                    Color(0xFF6DA89A),
                    appBackground,
                  ],
                  stops: [0, 0.5, 0.84, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: draftHeaderBackgroundHeight,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.72, -1),
                  radius: 0.95,
                  colors: [Color(0x3882DCCD), Color(0x0082DCCD)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: draftHeaderBackgroundHeight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, topInset, 20, 0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _setView(SceneFlowView.create),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x2EFFFFFF),
                            side: const BorderSide(color: Color(0x40FFFFFF)),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '场景草稿',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '确认内容，随时调整',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xCC82DCCD),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x2AFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x40FFFFFF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4DF0AA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '理解度 $confidence%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    34,
                    16,
                    bottomInset > 0 ? bottomInset + 110 : 110,
                  ),
                  child: Column(
                    children: [
                      _buildDraftOverviewCard(),
                      const SizedBox(height: 10),
                      _buildFeedbackStatusBanner(),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _continueAdjustDraftPrompt,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F2EC),
                            foregroundColor: const Color(0xFF5A5248),
                            side: const BorderSide(
                              color: Color(0xFFE4E0D8),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: Color(0xFF7A7268),
                          ),
                          label: const Text(
                            '继续调整',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5A5248),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                bottomInset > 0 ? bottomInset + 30 : 30,
              ),
              decoration: BoxDecoration(
                color: appBackground.withValues(alpha: 0.97),
                border: const Border(
                  top: BorderSide(color: Color(0x80DDD9D0), width: 0.5),
                ),
              ),
              child: FilledButton(
                onPressed: _isStartingConversation ? null : _startConversation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6058),
                  minimumSize: const Size.fromHeight(52),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E4E47),
                        Color(0xFF2E6058),
                        Color(0xFF4A7C6F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x6B2E6058),
                        blurRadius: 26,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isStartingConversation) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '进入对话中...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 9),
                          const Text(
                            '开始练习',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdit() {
    return _SceneScaffold(
      key: const ValueKey('scene-edit'),
      title: '调整草稿',
      subtitle: '对应导出仓库里的 SceneEditPage',
      onBack: () => _setView(SceneFlowView.draft),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          const _EditSectionHeader(
            icon: Icons.person_outline_rounded,
            title: '角色设定',
            color: Color(0xFF5A6FA8),
          ),
          const SizedBox(height: 10),
          _EditableCard(
            title: '对方风格',
            value:
                '${_traitSelectionForChallenge()}、${_toneSelectionForChallenge()}、${_draft.challenge}',
            icon: Icons.record_voice_over_rounded,
            color: const Color(0xFF5A6FA8),
          ),
          const SizedBox(height: 4),
          const _EditSectionHeader(
            icon: Icons.flag_rounded,
            title: '对话目标',
            color: Color(0xFF4A7C6F),
          ),
          const SizedBox(height: 10),
          _EditableCard(
            title: '剧情介绍',
            value: _draftOverviewPlotSteps().isNotEmpty
                ? _draftOverviewPlotSteps()
                      .asMap()
                      .entries
                      .map(
                        (MapEntry<int, String> entry) =>
                            '${entry.key + 1}. ${entry.value}',
                      )
                      .join('\n')
                : _draftOverviewPlotSummary(),
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF4A7C6F),
          ),
          const SizedBox(height: 4),
          const _EditSectionHeader(
            icon: Icons.stacked_bar_chart_rounded,
            title: '难度控制',
            color: Color(0xFFA0622A),
          ),
          const SizedBox(height: 10),
          _EditableCard(
            title: '难度等级',
            value: '中等偏上，对方会要求明确时间和责任。',
            icon: Icons.stacked_bar_chart_rounded,
            color: const Color(0xFFA0622A),
          ),
          const SizedBox(height: 4),
          const _EditSectionHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'AI 提醒',
            color: Color(0xFF7B4EA0),
          ),
          const SizedBox(height: 10),
          _EditableCard(
            title: '关键提醒',
            value: '避免过度道歉，重点放在补救动作和下一步承诺。',
            icon: Icons.tips_and_updates_outlined,
            color: const Color(0xFF7B4EA0),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5EF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEDE7DC)),
            ),
            child: const Text(
              '这一页对应原稿里的 SceneEditPage。当前已经补进主要模块层级，后续继续收口时可以再把 pills、开关和滑条做得更完整。',
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _startConversation,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E6058),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('保存并进入对话'),
          ),
        ],
      ),
    );
  }

  String _agentConversationStatusLabel() {
    if (_voiceChatConnecting) {
      return 'Connecting';
    }
    if (_isAiSpeaking) {
      return 'Speaking';
    }
    if (_isFinalizingAiTurn || _isNpcThinking) {
      return 'Thinking';
    }
    if (_isRecording) {
      return _realtimeMode ? 'Listening' : 'Recording';
    }
    if (_hasActiveVoiceSession) {
      return 'Ready';
    }
    return 'Standby';
  }

  String _agentConversationStatusDetail(_SceneResponseHint currentHint) {
    if (_voiceChatConnecting) {
      return 'Agent 正在连线，马上进入当前场景。';
    }
    if (_isAiSpeaking) {
      return 'Agent 正在回应，你可以先看当前阶段和下一句提示。';
    }
    if (_isFinalizingAiTurn || _isNpcThinking) {
      return 'Agent 正在整理这一轮回复和提示。';
    }
    if (_isRecording) {
      return _realtimeMode ? '正在实时听你说话，随时按当前任务继续。' : '正在录音，松开后会按当前阶段发送。';
    }
    if (currentHint.goalHint.trim().isNotEmpty) {
      return currentHint.goalHint.trim();
    }
    return '围绕当前场景目标继续，不要一下说太多。';
  }

  List<SceneBlueprintStage> _resolvedBlueprintStages() {
    final List<SceneBlueprintStage> stages =
        _draft.sceneBlueprint?.stages ?? const <SceneBlueprintStage>[];
    if (stages.isNotEmpty) {
      return stages;
    }
    final int totalStages = _serverSceneState?.totalStages ?? 0;
    if (totalStages <= 0) {
      return const <SceneBlueprintStage>[];
    }
    return List<SceneBlueprintStage>.generate(totalStages, (int index) {
      return SceneBlueprintStage(
        key: 'stage_${index + 1}',
        label: '阶段 ${index + 1}',
        objective: '',
      );
    }, growable: false);
  }

  int _resolvedCurrentStageIndex(_SceneResponseHint currentHint) {
    final int serverIndex = _serverSceneState?.currentStageIndex ?? -1;
    if (serverIndex >= 0) {
      return serverIndex;
    }
    final List<SceneBlueprintStage> stages = _resolvedBlueprintStages();
    if (stages.isEmpty) {
      return 0;
    }
    final int matchedIndex = stages.indexWhere(
      (SceneBlueprintStage stage) =>
          stage.label.trim() == currentHint.stageLabel.trim(),
    );
    return matchedIndex >= 0 ? matchedIndex : 0;
  }

  List<String> _agentConfirmedFactPreview() {
    final LinkedHashSet<String> values = LinkedHashSet<String>();
    final Map<String, String> filledFacts =
        _serverSceneState?.filledFacts ?? const <String, String>{};
    for (final MapEntry<String, String> entry in filledFacts.entries) {
      final String label = entry.key.trim();
      final String value = entry.value.trim();
      if (label.isEmpty || value.isEmpty) {
        continue;
      }
      values.add('$label: $value');
    }
    for (final String fact
        in _serverTurnContract?.confirmedFacts ?? const <String>[]) {
      final String normalized = fact.trim();
      if (normalized.isNotEmpty) {
        values.add(normalized);
      }
    }
    return values.take(5).toList(growable: false);
  }

  List<String> _agentPendingFocusPreview(_SceneResponseHint currentHint) {
    final LinkedHashSet<String> values = LinkedHashSet<String>();
    for (final String item
        in _serverSceneState?.missingFacts ?? const <String>[]) {
      final String normalized = item.trim();
      if (normalized.isNotEmpty) {
        values.add(normalized);
      }
    }
    if (values.isEmpty) {
      for (final String item
          in _draft.sceneBlueprint?.mustCover ?? const <String>[]) {
        final String normalized = item.trim();
        if (normalized.isNotEmpty) {
          values.add(normalized);
        }
      }
    }
    if (values.isEmpty && currentHint.questionFocus.trim().isNotEmpty) {
      values.add(currentHint.questionFocus.trim());
    }
    return values.take(4).toList(growable: false);
  }

  List<String> _agentContinuityPreview() {
    final List<String> items = <String>[
      ..._sceneLearningProfileHints.take(2),
      ..._sceneRoleMemoryHints.take(1),
    ];
    return items
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  Widget _buildAgentConsoleCard({
    required Color backgroundColor,
    required Color borderColor,
    required Color titleColor,
    required Color bodyColor,
    required Color accentColor,
    required IconData icon,
    required String eyebrow,
    required String title,
    required Widget child,
    double width = 248,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: bodyColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentConsolePanel({
    required bool isDark,
    required _SceneResponseHint currentHint,
    required Color panelColor,
    required Color panelBorderColor,
    required Color inputTextColor,
    required Color coachSubtitleColor,
  }) {
    final List<SceneBlueprintStage> stages = _resolvedBlueprintStages();
    final int currentStageIndex = _resolvedCurrentStageIndex(currentHint);
    final int totalStages = stages.isNotEmpty
        ? stages.length
        : (_serverSceneState?.totalStages ?? 1).clamp(1, 12).toInt();
    final double progress = totalStages <= 0
        ? 0
        : ((currentStageIndex + 1) / totalStages).clamp(0, 1).toDouble();
    final List<String> confirmedFacts = _agentConfirmedFactPreview();
    final List<String> pendingFocus = _agentPendingFocusPreview(currentHint);
    final List<String> continuity = _agentContinuityPreview();
    final String stageTitle =
        (_serverSceneState?.currentStageLabel ?? '').trim().isNotEmpty
        ? _serverSceneState!.currentStageLabel.trim()
        : currentHint.stageLabel.trim();
    final String missionText =
        (_draft.sceneBlueprint?.goal ?? _draft.goal).trim().isNotEmpty
        ? (_draft.sceneBlueprint?.goal ?? _draft.goal).trim()
        : 'Keep the conversation moving toward the current task.';
    final Color missionAccent = const Color(0xFF2E6058);
    final Color factAccent = const Color(0xFF9A6B2F);
    final Color continuityAccent = const Color(0xFF5A6FA8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111E19) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: panelBorderColor),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF2E6058))
                      .withValues(alpha: isDark ? 0.16 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E4E47), Color(0xFF6AB7A4)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _realtimeMode ? '🎧' : '🎙️',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_draft.npcName} · ${_draft.npcRole}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: inputTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _agentConversationStatusDetail(currentHint),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: coachSubtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: missionAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _agentConversationStatusLabel(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E6058),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Current Mission',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: coachSubtitleColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  missionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: inputTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: missionAccent.withValues(
                            alpha: 0.12,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2E6058),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: coachSubtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: missionAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stageTitle.isEmpty ? '当前阶段' : stageTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E6058),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: continuityAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _realtimeMode ? 'Realtime Agent' : 'Push-to-talk Agent',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A6FA8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 182,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildAgentConsoleCard(
                  backgroundColor: panelColor,
                  borderColor: panelBorderColor,
                  titleColor: inputTextColor,
                  bodyColor: coachSubtitleColor,
                  accentColor: missionAccent,
                  icon: Icons.track_changes_rounded,
                  eyebrow: 'STAGE',
                  title:
                      '${currentStageIndex + 1}/$totalStages · ${stageTitle.isEmpty ? currentHint.stageLabel : stageTitle}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentHint.questionFocus.trim().isNotEmpty
                            ? currentHint.questionFocus.trim()
                            : currentHint.goalHint,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: inputTextColor,
                        ),
                      ),
                      if (stages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: stages
                              .asMap()
                              .entries
                              .map((MapEntry<int, SceneBlueprintStage> entry) {
                                final bool active =
                                    entry.key == currentStageIndex;
                                final bool done = entry.key < currentStageIndex;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? missionAccent.withValues(alpha: 0.12)
                                        : done
                                        ? continuityAccent.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: active
                                          ? missionAccent.withValues(
                                              alpha: 0.35,
                                            )
                                          : panelBorderColor,
                                    ),
                                  ),
                                  child: Text(
                                    entry.value.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? missionAccent
                                          : done
                                          ? continuityAccent
                                          : coachSubtitleColor,
                                    ),
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildAgentConsoleCard(
                  backgroundColor: panelColor,
                  borderColor: panelBorderColor,
                  titleColor: inputTextColor,
                  bodyColor: coachSubtitleColor,
                  accentColor: factAccent,
                  icon: Icons.fact_check_rounded,
                  eyebrow: 'FACTS & GAPS',
                  title: confirmedFacts.isEmpty ? '待补充的信息' : '已经确认的关键信息',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (confirmedFacts.isNotEmpty
                                ? confirmedFacts
                                : pendingFocus)
                            .map(
                              (String item) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: factAccent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: factAccent.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.35,
                                    color: inputTextColor,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                  ),
                ),
                const SizedBox(width: 10),
                _buildAgentConsoleCard(
                  backgroundColor: panelColor,
                  borderColor: panelBorderColor,
                  titleColor: inputTextColor,
                  bodyColor: coachSubtitleColor,
                  accentColor: continuityAccent,
                  icon: Icons.history_rounded,
                  eyebrow: 'CONTINUITY',
                  title: continuity.isEmpty ? '还没有历史连续性卡片' : '相似场景和用户偏好',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (continuity.isEmpty)
                        Text(
                          '当你继续练习后，这里会显示相似历史会话和对你有用的长期提示。',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.55,
                            color: coachSubtitleColor,
                          ),
                        )
                      else
                        ...continuity.map(
                          (String item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    color: continuityAccent.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.subdirectory_arrow_right_rounded,
                                    size: 11,
                                    color: Color(0xFF5A6FA8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.45,
                                      color: inputTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatReferenceUi() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);
    final _VirtualFriend? activeFriend = _activeFriend;
    final String npcName = activeFriend?.name ?? _draft.npcName;
    final String npcAvatarEmoji =
        (activeFriend?.avatarEmoji.trim().isNotEmpty ?? false)
        ? activeFriend!.avatarEmoji.trim()
        : (_draft.emoji.trim().isNotEmpty ? _draft.emoji.trim() : '👔');
    final String subtitleTitle = _draft.title.trim().isEmpty
        ? '模拟对话'
        : _draft.title.trim();
    final _SceneResponseHint currentHint = _displayedSceneHint();

    int latestCoachMessageIndex = -1;
    for (int i = _messages.length - 1; i >= 0; i -= 1) {
      if (_messages[i].role == _MessageRole.coach) {
        latestCoachMessageIndex = i;
        break;
      }
    }

    final Color pageBackground = isDark
        ? const Color(0xFF121416)
        : const Color(0xFFF3F3F3);
    final Color headerBackground = isDark
        ? const Color(0xFF181A1D)
        : Colors.white;
    final Color headerBorderColor = isDark
        ? const Color(0x1AFFFFFF)
        : const Color(0xFFE2E2E2);
    final Color bodyBackground = isDark
        ? const Color(0xFF141618)
        : const Color(0xFFF5F5F5);
    final Color iconBackground = isDark
        ? const Color(0x14FFFFFF)
        : const Color(0xFFF7F7F7);
    final Color iconColor = isDark ? Colors.white : const Color(0xFF202020);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF171717);
    final Color subtitleColor = isDark
        ? const Color(0x8AFFFFFF)
        : const Color(0xFF9E9E9E);
    final Color panelColor = isDark ? const Color(0xFF1C1E21) : Colors.white;
    final Color panelBorderColor = isDark
        ? const Color(0x1AFFFFFF)
        : const Color(0xFFE7E7E7);
    final Color inputTextColor = isDark
        ? Colors.white
        : const Color(0xFF1A1A1A);
    final Color inputHintColor = isDark
        ? const Color(0x66FFFFFF)
        : const Color(0xFFADADAD);
    final Color pillBackground = _chatRecordingWillCancel
        ? const Color(0xFFF7D9D5)
        : (_isRecording
              ? const Color(0xFFB1F06C)
              : (_voiceChatConnecting || _realtimeMode)
              ? const Color(0xFFE8F6E0)
              : (isDark ? const Color(0xFF222528) : Colors.white));
    final Color pillBorderColor = _chatRecordingWillCancel
        ? const Color(0xFFE39A90)
        : (_isRecording
              ? const Color(0xFF8ED444)
              : (_voiceChatConnecting || _realtimeMode)
              ? const Color(0xFFC8E6B5)
              : panelBorderColor);
    final Color pillTextColor = (_isRecording || _chatRecordingWillCancel)
        ? const Color(0xFF244418)
        : inputTextColor;
    final Color recordingPreviewBackground = isDark
        ? const Color(0xFF263328)
        : const Color(0xFF92EA5F);
    final Color recordingPreviewTextColor = isDark
        ? const Color(0xFFF5FFF0)
        : const Color(0xFF1C3D12);
    final SystemUiOverlayStyle overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: pageBackground,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: pageBackground,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    Widget buildHeaderButton({
      required Widget child,
      required VoidCallback? onPressed,
    }) {
      return Material(
        color: iconBackground,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(width: 36, height: 36, child: Center(child: child)),
        ),
      );
    }

    Widget buildThinkingBubble() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDDEEE3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(npcAvatarEmoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  24,
                ).copyWith(topLeft: const Radius.circular(8)),
                border: Border.all(color: panelBorderColor),
              ),
              child: const SizedBox(
                width: 48,
                height: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ThinkingDot(delay: Duration.zero),
                    _ThinkingDot(delay: Duration(milliseconds: 200)),
                    _ThinkingDot(delay: Duration(milliseconds: 400)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildRecordingPreview() {
      final String previewText = _chatRecordingPreviewText.trim().isNotEmpty
          ? _chatRecordingPreviewText.trim()
          : (_chatSpeechPreviewUnavailable ? '正在录音，松手后会转写' : '正在听写你的英文…');
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 260),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  color: recordingPreviewBackground,
                  borderRadius: BorderRadius.circular(
                    24,
                  ).copyWith(topRight: const Radius.circular(8)),
                ),
                child: Text(
                  previewText,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: recordingPreviewTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDDEEE3),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('🙂', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        key: const ValueKey('scene-chat-reference'),
        color: pageBackground,
        child: Column(
          children: [
            Container(
              color: headerBackground,
              padding: EdgeInsets.fromLTRB(16, viewPadding.top + 10, 16, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      buildHeaderButton(
                        onPressed: _hasPracticeContent
                            ? () => _endPracticeAndReview()
                            : () => _setView(SceneFlowView.draft),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 24,
                          color: iconColor,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        tooltip: '更多操作',
                        color: headerBackground,
                        surfaceTintColor: headerBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (String value) async {
                          switch (value) {
                            case 'mode':
                              if (_hasActiveVoiceSession) {
                                await _stopRealtimeCall();
                              }
                              if (!mounted) {
                                return;
                              }
                              setState(() => _realtimeMode = !_realtimeMode);
                              break;
                            case 'text':
                              setState(() {
                                _showTextComposer = !_showTextComposer;
                                if (_showTextComposer) {
                                  _showCoachAssistant = false;
                                }
                              });
                              break;
                            case 'coach':
                              setState(() {
                                _showCoachAssistant = !_showCoachAssistant;
                                if (_showCoachAssistant) {
                                  _showTextComposer = false;
                                }
                              });
                              break;
                            case 'scene':
                              _setView(SceneFlowView.draft);
                              break;
                            case 'end':
                              if (_hasPracticeContent) {
                                _endPracticeAndReview();
                              }
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'mode',
                                child: Text(
                                  _realtimeMode ? '切回按住说话' : '切到实时通话',
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'text',
                                child: Text(
                                  _showTextComposer ? '收起文本输入' : '打开文本输入',
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'coach',
                                child: Text(
                                  _showCoachAssistant ? '收起提示' : '查看提示',
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'scene',
                                child: Text('返回场景'),
                              ),
                              if (_hasPracticeContent)
                                const PopupMenuItem<String>(
                                  value: 'end',
                                  child: Text('结束练习'),
                                ),
                            ],
                        child: buildHeaderButton(
                          onPressed: null,
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 24,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            npcName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 124,
                                child: Text(
                                  subtitleTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: subtitleColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.schedule_rounded,
                                size: 15,
                                color: subtitleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _chatElapsedLabel(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: headerBorderColor),
            Expanded(
              child: Container(
                color: bodyBackground,
                child: ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  itemCount:
                      _messages.length +
                      (_isNpcThinking ? 1 : 0) +
                      (_isRecording ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (_isNpcThinking && index == _messages.length) {
                      return buildThinkingBubble();
                    }

                    final int recordingIndex =
                        _messages.length + (_isNpcThinking ? 1 : 0);
                    if (_isRecording && index == recordingIndex) {
                      return buildRecordingPreview();
                    }

                    final _ChatMessage message = _messages[index];
                    final bool canToggleCoachHint =
                        message.role == _MessageRole.coach &&
                        index == latestCoachMessageIndex;
                    final bool isCoachHintExpanded =
                        _expandedCoachMessageIndex == index;
                    final String coachText = message.text;
                    final _SceneResponseHint inlineHint = isCoachHintExpanded
                        ? _displayedSceneHint(coachText: coachText)
                        : currentHint;

                    return Column(
                      children: [
                        _ConversationBubble(
                          message: message,
                          npcName: npcName,
                          npcAvatarEmoji: npcAvatarEmoji,
                          userAvatarEmoji: '🙂',
                          transcriptExpanded: _expandedVoiceMessageIndexes
                              .contains(index),
                          transcriptTranslated: _translatedVoiceMessageIndexes
                              .contains(index),
                          transcriptTranslating: _translatingVoiceMessageIndexes
                              .contains(index),
                          transcriptTranslation:
                              _voiceMessageTranslations[index],
                          onVoiceLongPress:
                              message.inputType == _ChatInputType.voice
                              ? () => _toggleVoiceMessageTranscript(index)
                              : null,
                          onVoiceTap: message.inputType == _ChatInputType.voice
                              ? () => unawaited(_playVoiceMessage(message))
                              : null,
                          onTranscriptTranslateTap:
                              message.inputType == _ChatInputType.voice
                              ? () => _toggleVoiceMessageTranslation(index)
                              : null,
                          onCoachTap: canToggleCoachHint
                              ? () => _toggleCoachHintAt(index)
                              : null,
                          coachExpanded: isCoachHintExpanded,
                        ),
                        if (isCoachHintExpanded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 284,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    16,
                                    14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: panelColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: panelBorderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inlineHint.questionFocus.isNotEmpty
                                            ? inlineHint.questionFocus
                                            : coachText,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.55,
                                          color: inputTextColor,
                                        ),
                                      ),
                                      if (inlineHint
                                          .sampleAnswer
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0x142D6A4F)
                                                : const Color(0xFFF3FAEE),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            inlineHint.sampleAnswer,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.6,
                                              color: isDark
                                                  ? const Color(0xFFE3F7D8)
                                                  : const Color(0xFF305B24),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Container(
              color: headerBackground,
              padding: EdgeInsets.fromLTRB(16, 10, 16, viewPadding.bottom + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _showTextComposer && !_isRecording
                        ? Container(
                            key: const ValueKey('chat-text-composer'),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: panelBorderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    minLines: 1,
                                    maxLines: 4,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: inputTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      isCollapsed: true,
                                      hintText: '输入你想对 $npcName 说的话…',
                                      hintStyle: TextStyle(
                                        color: inputHintColor,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Material(
                                  color: const Color(0xFF97E95F),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: () => _sendMessage(),
                                    borderRadius: BorderRadius.circular(16),
                                    child: const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Icon(
                                        Icons.send_rounded,
                                        size: 20,
                                        color: Color(0xFF214117),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _showCoachAssistant
                        ? Container(
                            key: const ValueKey('chat-coach-panel'),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: panelBorderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF7EA),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 16,
                                        color: Color(0xFF5E9150),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        currentHint.questionFocus.isNotEmpty
                                            ? currentHint.questionFocus
                                            : '这里会根据当前对话给你一句即时提示',
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.45,
                                          color: inputTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (currentHint.sampleAnswer.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    currentHint.sampleAnswer,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.55,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : const SizedBox(key: ValueKey('chat-panel-empty')),
                  ),
                  Row(
                    children: [
                      Material(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showTextComposer = !_showTextComposer;
                              if (_showTextComposer) {
                                _showCoachAssistant = false;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              _showTextComposer
                                  ? Icons.mic_none_rounded
                                  : Icons.keyboard_alt_outlined,
                              size: 24,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _realtimeMode ? _toggleChatRecording : null,
                          onLongPressStart: _realtimeMode
                              ? null
                              : (_) => _startChatRecording(),
                          onLongPressMoveUpdate: _realtimeMode
                              ? null
                              : _updateChatRecordingDrag,
                          onLongPressEnd: _realtimeMode
                              ? null
                              : (_) => _finishChatRecording(
                                  send: !_chatRecordingWillCancel,
                                ),
                          onLongPressCancel: _realtimeMode
                              ? null
                              : () => _finishChatRecording(send: false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 58,
                            decoration: BoxDecoration(
                              color: pillBackground,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: pillBorderColor),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _realtimeMode
                                      ? (_isRecording
                                            ? Icons.call_end_rounded
                                            : Icons.call_rounded)
                                      : (_chatRecordingWillCancel
                                            ? Icons.close_rounded
                                            : Icons.mic_none_rounded),
                                  size: 22,
                                  color: pillTextColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _realtimeMode
                                      ? (_voiceChatConnecting
                                            ? '连接中'
                                            : (_isRecording ? '点击挂断' : '点击通话'))
                                      : (_chatRecordingWillCancel
                                            ? '松开 取消'
                                            : (_isRecording
                                                  ? '松开 发送'
                                                  : '按住 说话')),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: pillTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showCoachAssistant = !_showCoachAssistant;
                              if (_showCoachAssistant) {
                                _showTextComposer = false;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              _showCoachAssistant
                                  ? Icons.close_rounded
                                  : Icons.add_rounded,
                              size: 28,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildChat() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double topInset = MediaQuery.paddingOf(context).top;
    const double maxBottomPanelHeight = 150;
    final _SceneResponseHint currentHint = _displayedSceneHint();
    final bool currentHintLlmLoading = _isCurrentHintLoading();
    int latestCoachMessageIndex = -1;
    for (int i = _messages.length - 1; i >= 0; i -= 1) {
      if (_messages[i].role == _MessageRole.coach) {
        latestCoachMessageIndex = i;
        break;
      }
    }
    final Color pageBackground = isDark
        ? const Color(0xFF0E1915)
        : appBackground;
    final Color headerTopColor = isDark
        ? const Color(0xFF0C1613)
        : const Color(0xFFF8F5EE);
    final Color headerBottomColor = isDark
        ? const Color(0xF20C1613)
        : const Color(0xF2F8F5EE);
    final Color headerBorderColor = isDark
        ? const Color(0x1FFFFFFF)
        : borderColor;
    final Color headerShadowColor = isDark
        ? const Color(0x4D000000)
        : const Color(0x14000000);
    final Color chromeButtonBackground = isDark
        ? const Color(0x12FFFFFF)
        : Colors.white;
    final Color chromeButtonIconColor = isDark ? Colors.white : textPrimary;
    final Color secondaryTextColor = isDark
        ? const Color(0x73FFFFFF)
        : textSecondary;
    final Color subtleTextColor = isDark
        ? const Color(0x47FFFFFF)
        : textSecondary;
    final Color statusChipBackground = isDark
        ? const Color(0x0DFFFFFF)
        : const Color(0xFFF4F1EA);
    final Color statusChipBorder = isDark
        ? const Color(0x12FFFFFF)
        : borderColor;
    final Color statusChipForeground = isDark
        ? const Color(0x80FFFFFF)
        : textSecondary;
    final Color thinkingBubbleColor = isDark
        ? const Color(0xFFEFEBE4)
        : Colors.white;
    final Color thinkingBubbleBorder = isDark
        ? Colors.transparent
        : borderColor;
    final Color draftingBubbleColor = isDark
        ? const Color(0x124A7C6F)
        : const Color(0xFFF1F8F5);
    final Color draftingBubbleBorder = isDark
        ? const Color(0x594A7C6F)
        : const Color(0x334A7C6F);
    final Color draftingTextColor = isDark
        ? const Color(0x80FFFFFF)
        : const Color(0xFF49635D);
    final Color bottomBarColor = isDark
        ? const Color(0xFF0D1714)
        : appBackground;
    final Color bottomBarBorderColor = isDark
        ? const Color(0x1FFFFFFF)
        : borderColor;
    final Color panelColor = isDark ? const Color(0x0FFFFFFF) : Colors.white;
    final Color panelBorderColor = isDark
        ? const Color(0x14FFFFFF)
        : borderColor;
    final Color inputTextColor = isDark ? const Color(0xFFEAE7E2) : textPrimary;
    final Color inputHintColor = isDark
        ? const Color(0x66FFFFFF)
        : textSecondary;
    final Color coachSubtitleColor = isDark
        ? const Color(0x73FFFFFF)
        : textSecondary;
    final Color coachCloseColor = isDark
        ? const Color(0x80FFFFFF)
        : textSecondary;
    final Color coachInnerPanelColor = isDark
        ? const Color(0x12000000)
        : const Color(0xFFF7F2EA);
    final Color coachAnswerColor = isDark
        ? const Color(0x144A7C6F)
        : const Color(0xFFF1F8F5);
    final Color coachAnswerBorderColor = isDark
        ? const Color(0x334A7C6F)
        : const Color(0x224A7C6F);
    final Color coachQuestionColor = isDark
        ? const Color(0xFFCDEAE3)
        : const Color(0xFF2E6058);
    final Color coachAnswerTextColor = isDark
        ? const Color(0xFFF1EEE8)
        : textPrimary;
    final Color hintKeywordBackground = isDark
        ? const Color(0x124A7C6F)
        : const Color(0xFFF3F7F4);
    final Color hintKeywordBorder = isDark
        ? const Color(0x334A7C6F)
        : const Color(0x224A7C6F);
    final Color hintKeywordTextColor = isDark
        ? const Color(0xFFD5EEE8)
        : const Color(0xFF2E6058);
    final SystemUiOverlayStyle overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: pageBackground,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: pageBackground,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        key: const ValueKey('scene-chat'),
        color: pageBackground,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [headerTopColor, headerBottomColor],
                ),
                border: Border(
                  bottom: BorderSide(color: headerBorderColor, width: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: headerShadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: _hasPracticeContent
                            ? () => _endPracticeAndReview()
                            : () => _setView(SceneFlowView.draft),
                        style: IconButton.styleFrom(
                          backgroundColor: chromeButtonBackground,
                          minimumSize: const Size(38, 38),
                          padding: EdgeInsets.zero,
                        ),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: chromeButtonIconColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(11),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0x334A7C6F),
                                        Color(0x557ACFBD),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0x667ACFBD),
                                      width: 1.4,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '👔',
                                    style: TextStyle(fontSize: 17),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _draft.npcName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF7ACFBD),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _draft.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusChipBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusChipBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 9,
                                  color: statusChipForeground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _agentConversationStatusLabel(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: statusChipForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () async {
                              if (_hasActiveVoiceSession) {
                                await _stopRealtimeCall();
                              }
                              if (!mounted) {
                                return;
                              }
                              setState(() => _realtimeMode = !_realtimeMode);
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: chromeButtonBackground,
                              minimumSize: const Size(34, 34),
                              padding: EdgeInsets.zero,
                            ),
                            icon: Icon(
                              _realtimeMode
                                  ? Icons.call_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              size: 17,
                              color: const Color(0xFF7ACFBD),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildAgentConsolePanel(
              isDark: isDark,
              currentHint: currentHint,
              panelColor: panelColor,
              panelBorderColor: panelBorderColor,
              inputTextColor: inputTextColor,
              coachSubtitleColor: coachSubtitleColor,
            ),
            Expanded(
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                itemCount:
                    _messages.length +
                    (_isNpcThinking ? 1 : 0) +
                    (_isRecording ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isNpcThinking && index == _messages.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: thinkingBubbleColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: thinkingBubbleBorder),
                            ),
                            child: const SizedBox(
                              width: 36,
                              height: 16,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ThinkingDot(delay: Duration.zero),
                                  _ThinkingDot(
                                    delay: Duration(milliseconds: 200),
                                  ),
                                  _ThinkingDot(
                                    delay: Duration(milliseconds: 400),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final int recordingIndex =
                      _messages.length + (_isNpcThinking ? 1 : 0);
                  if (_isRecording && index == recordingIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 282),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: draftingBubbleColor,
                              borderRadius: BorderRadius.circular(
                                18,
                              ).copyWith(topRight: const Radius.circular(6)),
                              border: Border.all(
                                color: draftingBubbleBorder,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Text(
                              _chatRecordingPreviewText.trim().isNotEmpty
                                  ? '${_chatRecordingPreviewText.trim()} •'
                                  : _chatSpeechPreviewUnavailable
                                  ? '正在录音，松手后会转写'
                                  : '正在听写你的英文…',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.65,
                                fontStyle: FontStyle.italic,
                                color: draftingTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final message = _messages[index];
                  final bool canToggleCoachHint =
                      message.role == _MessageRole.coach &&
                      index == latestCoachMessageIndex;
                  final bool isCoachHintExpanded =
                      _expandedCoachMessageIndex == index;
                  final String coachText = message.text;
                  final String hintCacheKey = _hintCacheKey(
                    coachText: coachText,
                  );
                  final bool llmHintLoading = _llmHintLoadingKeys.contains(
                    hintCacheKey,
                  );
                  final _SceneResponseHint inlineHint = isCoachHintExpanded
                      ? _displayedSceneHint(coachText: coachText)
                      : currentHint;
                  return Column(
                    children: [
                      _ConversationBubble(
                        message: message,
                        npcName: _draft.npcName,
                        npcAvatarEmoji:
                            _activeFriend?.avatarEmoji.trim().isNotEmpty == true
                            ? _activeFriend!.avatarEmoji.trim()
                            : (_draft.emoji.trim().isNotEmpty
                                  ? _draft.emoji.trim()
                                  : '👔'),
                        userAvatarEmoji: '🙂',
                        transcriptExpanded: _expandedVoiceMessageIndexes
                            .contains(index),
                        transcriptTranslated: _translatedVoiceMessageIndexes
                            .contains(index),
                        transcriptTranslating: _translatingVoiceMessageIndexes
                            .contains(index),
                        transcriptTranslation: _voiceMessageTranslations[index],
                        onVoiceLongPress:
                            message.inputType == _ChatInputType.voice
                            ? () => _toggleVoiceMessageTranscript(index)
                            : null,
                        onVoiceTap: message.inputType == _ChatInputType.voice
                            ? () => unawaited(_playVoiceMessage(message))
                            : null,
                        onTranscriptTranslateTap:
                            message.inputType == _ChatInputType.voice
                            ? () => _toggleVoiceMessageTranslation(index)
                            : null,
                        onCoachTap: canToggleCoachHint
                            ? () => _toggleCoachHintAt(index)
                            : null,
                        coachExpanded: isCoachHintExpanded,
                      ),
                      if (isCoachHintExpanded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color: panelColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: panelBorderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: const Color(0x144A7C6F),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 15,
                                            color: Color(0xFF7ACFBD),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '英文回复提示',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: inputTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                llmHintLoading
                                                    ? '正在用模型润色英文提示'
                                                    : '基于当前上下文和这条中文提示生成',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: coachSubtitleColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: coachInnerPanelColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: panelBorderColor,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '当前回合',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: coachQuestionColor,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            inlineHint.goalHint,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.55,
                                              color: coachAnswerTextColor,
                                            ),
                                          ),
                                          if (inlineHint.questionFocus
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Text(
                                              '对方在问',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: coachQuestionColor,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              inlineHint.questionFocus,
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.55,
                                                color: coachAnswerTextColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '起手句',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: coachQuestionColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: coachAnswerColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: coachAnswerBorderColor,
                                        ),
                                      ),
                                      child: Text(
                                        inlineHint.starter,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.6,
                                          color: coachAnswerTextColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: _toggleHintReferenceAnswer,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: panelColor,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: panelBorderColor,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.menu_book_rounded,
                                              size: 14,
                                              color: coachQuestionColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '收起参考回答',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: coachQuestionColor,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              _showHintReferenceAnswer
                                                  ? Icons.expand_less_rounded
                                                  : Icons.expand_more_rounded,
                                              size: 18,
                                              color: coachCloseColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_showHintReferenceAnswer) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          12,
                                          12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: coachAnswerColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: coachAnswerBorderColor,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '参考回答',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: coachQuestionColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              inlineHint.sampleAnswer,
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.6,
                                                color: coachAnswerTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              decoration: BoxDecoration(
                color: bottomBarColor,
                border: Border(
                  top: BorderSide(color: bottomBarBorderColor, width: 0.5),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBottomPanelHeight),
                child: _showCoachAssistant
                    ? SizedBox(
                        height: maxBottomPanelHeight,
                        child: Column(
                          children: [
                            if (_showTextComposer && !_isRecording) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: panelColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: panelBorderColor),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        minLines: 1,
                                        maxLines: 4,
                                        style: TextStyle(
                                          color: inputTextColor,
                                          fontSize: 13,
                                          height: 1.55,
                                        ),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          hintText: '用英文输入你的回应…',
                                          hintStyle: TextStyle(
                                            color: inputHintColor,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _sendMessage(),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2E6058),
                                              Color(0xFF4A7C6F),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            17,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.send_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child: SingleChildScrollView(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    14,
                                    14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: panelColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: panelBorderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: const Color(0x144A7C6F),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 16,
                                              color: Color(0xFF7ACFBD),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '回答提示',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: inputTextColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  currentHintLlmLoading
                                                      ? '正在用 AI 生成更精准的回答提示…'
                                                      : '先看这一轮要说什么，再决定要不要展开参考回答',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: coachSubtitleColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _showCoachAssistant = false;
                                                _showHintReferenceAnswer =
                                                    false;
                                              });
                                            },
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: coachCloseColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          12,
                                          12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: coachInnerPanelColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: panelBorderColor,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '对方在问',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: coachQuestionColor,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              currentHint.questionFocus.isEmpty
                                                  ? '还没进入具体追问，先按当前阶段准备回答'
                                                  : currentHint.questionFocus,
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.55,
                                                color: coachAnswerTextColor,
                                              ),
                                            ),
                                            if (currentHint.backgroundFocus
                                                .trim()
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                '场景背景',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: coachQuestionColor,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                currentHint.backgroundFocus,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 1.5,
                                                  color: coachSubtitleColor,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0x144A7C6F,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    currentHint.stageLabel,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF2E6058),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              '当前回合',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: coachQuestionColor,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              currentHint.goalHint,
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.55,
                                                color: coachAnswerTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '关键词',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: coachQuestionColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: currentHint.keywords
                                            .map(
                                              (String keyword) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 7,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: hintKeywordBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  border: Border.all(
                                                    color: hintKeywordBorder,
                                                  ),
                                                ),
                                                child: Text(
                                                  keyword,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: hintKeywordTextColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          12,
                                          12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: coachAnswerColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: coachAnswerBorderColor,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '起手句',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: coachQuestionColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (currentHintLlmLoading)
                                              const Row(
                                                children: [
                                                  SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Color(0xFF7ACFBD)),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    '正在生成…',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF9A9289),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Text(
                                                currentHint.starter,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.6,
                                                  color: coachAnswerTextColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: _toggleHintReferenceAnswer,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            color: panelColor,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: panelBorderColor,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.menu_book_rounded,
                                                size: 15,
                                                color: coachQuestionColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _showHintReferenceAnswer
                                                      ? '收起参考回答'
                                                      : '查看参考回答',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: inputTextColor,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                _showHintReferenceAnswer
                                                    ? Icons
                                                          .keyboard_arrow_up_rounded
                                                    : Icons
                                                          .keyboard_arrow_down_rounded,
                                                size: 18,
                                                color: coachCloseColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_showHintReferenceAnswer) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            12,
                                            12,
                                            12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: coachAnswerColor,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: coachAnswerBorderColor,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '参考回答',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: coachQuestionColor,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                currentHint.sampleAnswer,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 1.65,
                                                  color: coachAnswerTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: _realtimeMode
                                            ? _toggleChatRecording
                                            : null,
                                        onLongPressStart: _realtimeMode
                                            ? null
                                            : (_) => _startChatRecording(),
                                        onLongPressMoveUpdate: _realtimeMode
                                            ? null
                                            : _updateChatRecordingDrag,
                                        onLongPressEnd: _realtimeMode
                                            ? null
                                            : (_) => _finishChatRecording(
                                                send: !_chatRecordingWillCancel,
                                              ),
                                        onLongPressCancel: _realtimeMode
                                            ? null
                                            : () => _finishChatRecording(
                                                send: false,
                                              ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          width: 78,
                                          height: 78,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: _chatRecordingWillCancel
                                                  ? const [
                                                      Color(0xFF7E3A33),
                                                      Color(0xFFC95D52),
                                                    ]
                                                  : _isRecording
                                                  ? const [
                                                      Color(0xFFE8855A),
                                                      Color(0xFFF39966),
                                                    ]
                                                  : _voiceChatConnecting
                                                  ? const [
                                                      Color(0xFF5ECE92),
                                                      Color(0xFF6FE89E),
                                                    ]
                                                  : _realtimeMode
                                                  ? const [
                                                      Color(0xFF5ECE92),
                                                      Color(0xFF6FE89E),
                                                    ]
                                                  : const [
                                                      Color(0xFF2E6058),
                                                      Color(0xFF4A7C6F),
                                                      Color(0xFF5A9E90),
                                                    ],
                                            ),
                                            border: Border.all(
                                              color: _chatRecordingWillCancel
                                                  ? const Color(0xFFF2AAA2)
                                                  : _isRecording
                                                  ? const Color(0xFFF7A37F)
                                                  : _voiceChatConnecting
                                                  ? const Color(0xFF7CF2AE)
                                                  : _realtimeMode
                                                  ? const Color(0xFF7CF2AE)
                                                  : const Color(0xFF7ACFBD),
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (_chatRecordingWillCancel
                                                            ? const Color(
                                                                0xFFC95D52,
                                                              )
                                                            : _isRecording
                                                            ? const Color(
                                                                0xFFE8855A,
                                                              )
                                                            : _voiceChatConnecting
                                                            ? const Color(
                                                                0xFF5ECE92,
                                                              )
                                                            : _realtimeMode
                                                            ? const Color(
                                                                0xFF5ECE92,
                                                              )
                                                            : const Color(
                                                                0xFF4A7C6F,
                                                              ))
                                                        .withValues(alpha: 0.4),
                                                blurRadius: 28,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            _realtimeMode
                                                ? (_voiceChatConnecting
                                                      ? Icons.call_rounded
                                                      : _isRecording
                                                      ? Icons.call_end_rounded
                                                      : Icons.call_rounded)
                                                : (_chatRecordingWillCancel
                                                      ? Icons.close_rounded
                                                      : _isRecording
                                                      ? Icons
                                                            .arrow_upward_rounded
                                                      : Icons.mic_rounded),
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _realtimeMode
                                            ? (_voiceChatConnecting
                                                  ? '连接中...'
                                                  : _isRecording
                                                  ? '点击挂断'
                                                  : '点击接通')
                                            : (_chatRecordingWillCancel
                                                  ? '松开取消'
                                                  : _isRecording
                                                  ? '松开发送，上滑取消'
                                                  : '长按说话'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                          color: subtleTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_showTextComposer && !_isRecording) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: panelColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: panelBorderColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      minLines: 1,
                                      maxLines: 4,
                                      style: TextStyle(
                                        color: inputTextColor,
                                        fontSize: 13,
                                        height: 1.55,
                                      ),
                                      decoration: InputDecoration(
                                        isCollapsed: true,
                                        hintText: '用英文输入你的回应…',
                                        hintStyle: TextStyle(
                                          color: inputHintColor,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _sendMessage(),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF2E6058),
                                            Color(0xFF4A7C6F),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.send_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: _realtimeMode
                                          ? _toggleChatRecording
                                          : null,
                                      onLongPressStart: _realtimeMode
                                          ? null
                                          : (_) => _startChatRecording(),
                                      onLongPressMoveUpdate: _realtimeMode
                                          ? null
                                          : _updateChatRecordingDrag,
                                      onLongPressEnd: _realtimeMode
                                          ? null
                                          : (_) => _finishChatRecording(
                                              send: !_chatRecordingWillCancel,
                                            ),
                                      onLongPressCancel: _realtimeMode
                                          ? null
                                          : () => _finishChatRecording(
                                              send: false,
                                            ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: 78,
                                        height: 78,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: _chatRecordingWillCancel
                                                ? const [
                                                    Color(0xFF7E3A33),
                                                    Color(0xFFC95D52),
                                                  ]
                                                : _isRecording
                                                ? const [
                                                    Color(0xFFE8855A),
                                                    Color(0xFFF39966),
                                                  ]
                                                : _voiceChatConnecting
                                                ? const [
                                                    Color(0xFF5ECE92),
                                                    Color(0xFF6FE89E),
                                                  ]
                                                : _realtimeMode
                                                ? const [
                                                    Color(0xFF5ECE92),
                                                    Color(0xFF6FE89E),
                                                  ]
                                                : const [
                                                    Color(0xFF2E6058),
                                                    Color(0xFF4A7C6F),
                                                    Color(0xFF5A9E90),
                                                  ],
                                          ),
                                          border: Border.all(
                                            color: _chatRecordingWillCancel
                                                ? const Color(0xFFF2AAA2)
                                                : _isRecording
                                                ? const Color(0xFFF7A37F)
                                                : _voiceChatConnecting
                                                ? const Color(0xFF7CF2AE)
                                                : _realtimeMode
                                                ? const Color(0xFF7CF2AE)
                                                : const Color(0xFF7ACFBD),
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  (_chatRecordingWillCancel
                                                          ? const Color(
                                                              0xFFC95D52,
                                                            )
                                                          : _isRecording
                                                          ? const Color(
                                                              0xFFE8855A,
                                                            )
                                                          : _voiceChatConnecting
                                                          ? const Color(
                                                              0xFF5ECE92,
                                                            )
                                                          : _realtimeMode
                                                          ? const Color(
                                                              0xFF5ECE92,
                                                            )
                                                          : const Color(
                                                              0xFF4A7C6F,
                                                            ))
                                                      .withValues(alpha: 0.4),
                                              blurRadius: 28,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          _realtimeMode
                                              ? (_voiceChatConnecting
                                                    ? Icons.call_rounded
                                                    : _isRecording
                                                    ? Icons.call_end_rounded
                                                    : Icons.call_rounded)
                                              : (_chatRecordingWillCancel
                                                    ? Icons.close_rounded
                                                    : _isRecording
                                                    ? Icons.arrow_upward_rounded
                                                    : Icons.mic_rounded),
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _realtimeMode
                                          ? (_voiceChatConnecting
                                                ? '连接中...'
                                                : _isRecording
                                                ? '点击挂断'
                                                : '点击接通')
                                          : (_chatRecordingWillCancel
                                                ? '松开取消'
                                                : _isRecording
                                                ? '松开发送，上滑取消'
                                                : '长按说话'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                        color: subtleTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final AppLocalizations l10n = context.l10n;
    final int rounds = _messages
        .where((m) => m.role == _MessageRole.user)
        .length;
    if (_isFeedbackLoading) {
      final int elapsedSeconds = _feedbackStartedAt == null
          ? 0
          : DateTime.now().difference(_feedbackStartedAt!).inSeconds;
      return _SceneScaffold(
        key: const ValueKey('scene-feedback-loading'),
        title: l10n.practiceFeedback,
        subtitle: l10n.generatingAnalysis,
        onBack: () => _setView(
          _feedbackOpenedFromRecentSummary
              ? SceneFlowView.create
              : SceneFlowView.draft,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDFCF8), Color(0xFFF7F5EE)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8E1D5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EEE4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE6DFD1)),
                    ),
                    child: const Text(
                      '复盘正在整理中',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D7A57),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F5F0),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD2E9E0)),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF7ACFBD),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '正在生成高质量复盘',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2A24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    elapsedSeconds > 0
                        ? '已生成 ${elapsedSeconds}s，通常还需要 10-15 秒'
                        : '通常需要 10-15 秒，正在后台整理逐条点评',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: Color(0xFF756B5C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ThinkingDot(delay: Duration.zero),
                      SizedBox(width: 8),
                      _ThinkingDot(delay: Duration(milliseconds: 160)),
                      SizedBox(width: 8),
                      _ThinkingDot(delay: Duration(milliseconds: 320)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F2E8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9E0CF)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: Color(0xFFB28C42),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '你可以先离开这个界面，复盘会继续在后台生成。完成后会在草稿页显示状态，并提示你回来查看。',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.55,
                              color: Color(0xFF7A6750),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _setView(SceneFlowView.draft),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E6058),
                        backgroundColor: const Color(0xFFFDFBF6),
                        side: const BorderSide(color: Color(0xFFD8D1C2)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('先离开，后台继续生成'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_feedback == null) {
      return _SceneScaffold(
        key: const ValueKey('scene-feedback-error'),
        title: l10n.practiceFeedback,
        subtitle: '复盘暂时不可用',
        onBack: () => _setView(
          _feedbackOpenedFromRecentSummary
              ? SceneFlowView.create
              : SceneFlowView.chat,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 34,
                  color: Color(0xFFE8C46A),
                ),
                const SizedBox(height: 12),
                const Text(
                  '复盘总结生成失败',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _lastFeedbackError?.isNotEmpty ?? false
                      ? '错误信息：$_lastFeedbackError'
                      : '你可以重试一次，或者先返回继续对话。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xB3FFFFFF),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _isFeedbackLoading = true;
                    });
                    _generateFeedback();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6058),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('重新生成'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final SceneFeedback fb = _feedback!;

    return _SceneScaffold(
      key: const ValueKey('scene-feedback'),
      title: l10n.practiceFeedback,
      subtitle: l10n.feedbackPageSubtitle,
      onBack: () => _setView(
        _feedbackOpenedFromRecentSummary
            ? SceneFlowView.create
            : SceneFlowView.chat,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13302A), Color(0xFF2E6058)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sceneFeedbackHeadline(fb.headline),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${fb.overallScore}',
                  style: const TextStyle(
                    fontSize: 46,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.sceneFeedbackSummary(rounds, _draft.npcName),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD2EEE7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...fb.metrics.map(
            (m) => _FeedbackMetric(
              label: l10n.sceneFeedbackMetric(m.label),
              score: m.score,
              color: m.color,
            ),
          ),
          const SizedBox(height: 12),
          _CoachCard(
            title: l10n.coachAdvice,
            body: l10n.sceneFeedbackCoach(fb.coachTip),
          ),
          const SizedBox(height: 12),
          if (fb.turnReviews.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '逐条语音点评',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '每条语音都会看发音、语法、表达方式，并给出更自然的英文替换说法。',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...fb.turnReviews.indexed.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.$1 == fb.turnReviews.length - 1 ? 0 : 12,
                ),
                child: _FeedbackTurnReviewCard(review: entry.$2),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.feedbackTopFixes,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fb.improvements.indexed.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.$1 == fb.improvements.length - 1 ? 0 : 12,
                      ),
                      child: _ImprovementCard(
                        index: entry.$1 + 1,
                        emoji: entry.$2.$1,
                        title: l10n.sceneFeedbackImprovementTitle(entry.$2.$2),
                        detail: l10n.sceneFeedbackImprovementDetail(
                          entry.$2.$3,
                        ),
                        color: const <Color>[
                          Color(0xFFC4743A),
                          Color(0xFF8BA8E0),
                          Color(0xFF4A7C6F),
                        ][entry.$1 % 3],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setView(SceneFlowView.chat),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.practiceAgain),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _setView(SceneFlowView.create),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6058),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.backToHome),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
