import 'dart:async';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_models.dart';
import 'app_session.dart';

enum SceneFlowView { home, draft, edit, chat, feedback }

enum _DraftDetailSection {
  persona,
  relationship,
  goals,
  difficulty,
  language,
  globalEdit,
}

class ScenePage extends StatefulWidget {
  const ScenePage({super.key, this.onBottomBarVisibilityChanged});

  final ValueChanged<bool>? onBottomBarVisibilityChanged;

  @override
  State<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<ScenePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _coachQuestionController =
      TextEditingController();
  final FocusNode _scenePromptFocusNode = FocusNode();
  final FocusNode _coachQuestionFocusNode = FocusNode();
  final ScrollController _chatScrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  SceneFlowView _view = SceneFlowView.home;
  int _activePromptIndex = 0;
  bool _inputFocused = false;
  bool _isRecording = false;
  bool _isNpcThinking = false;
  SceneFeedback? _feedback;
  bool _isFeedbackLoading = false;
  bool _chatRecordingWillCancel = false;
  bool _showTextComposer = false;
  bool _showCoachAssistant = false;
  bool _realtimeMode = false;
  String _sessionId = '';
  final Set<_DraftDetailSection> _expandedDraftSections =
      <_DraftDetailSection>{};
  final Set<int> _expandedVoiceMessageIndexes = <int>{};
  SceneDraft _draft = sampleSceneDraft;
  String? _lastCoachQuestion;
  String? _coachAnswer;
  Timer? _promptTimer;
  Timer? _mockInputTimer;

  static const _recentScenes = <_RecentScene>[
    _RecentScene(
      title: '解释项目延期',
      emoji: '📊',
      tags: ['高压沟通', '周会汇报'],
      color: Color(0xFF4A7C6F),
      practiceCount: 18,
      lastTime: '今天',
      progress: 78,
    ),
    _RecentScene(
      title: '第一次客户寒暄',
      emoji: '🤝',
      tags: ['商务社交', '破冰'],
      color: Color(0xFF5A6FA8),
      practiceCount: 9,
      lastTime: '昨天',
      progress: 56,
    ),
    _RecentScene(
      title: '英文电话面试',
      emoji: '☎️',
      tags: ['求职', '高频追问'],
      color: Color(0xFFA0622A),
      practiceCount: 6,
      lastTime: '2 天前',
      progress: 42,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _resetChatSession();
    _controller.addListener(_handleControllerChanged);
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
    _controller.removeListener(_handleControllerChanged);
    _scenePromptFocusNode.removeListener(_handleScenePromptFocusChanged);
    _chatScrollController.dispose();
    _coachQuestionFocusNode.dispose();
    _scenePromptFocusNode.dispose();
    _coachQuestionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
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
      _coachQuestionFocusNode.unfocus();
      return;
    }
    _scenePromptFocusNode.unfocus();
    _coachQuestionFocusNode.unfocus();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _mockInputTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
      return;
    }

    final String target = examplePrompts[_activePromptIndex];
    int cursor = 0;
    _mockInputTimer?.cancel();
    setState(() {
      _isRecording = true;
      _showTextComposer = false;
      _controller.clear();
    });
    _mockInputTimer = Timer.periodic(const Duration(milliseconds: 55), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      cursor += 1;
      setState(() {
        _controller.text = target.substring(0, cursor.clamp(0, target.length));
      });
      if (cursor >= target.length) {
        timer.cancel();
        setState(() {
          _isRecording = false;
        });
      }
    });
  }

  List<_ChatMessage> _initialMessagesForDraft() {
    return <_ChatMessage>[
      _ChatMessage(
        role: _MessageRole.event,
        text: '对话已接通 · ${_draft.npcName} 正在等待',
        accent: const Color(0xFF7ACFBD),
      ),
      const _ChatMessage(
        role: _MessageRole.npc,
        text:
            'Thanks for joining on short notice. I need a clear summary of the situation and your next step.',
        inputType: _ChatInputType.voice,
        voiceDuration: 8,
        mood: '冷静施压中',
      ),
      const _ChatMessage(
        role: _MessageRole.coach,
        text: '先说结论',
        note: '再补原因和补救动作',
      ),
    ];
  }

  void _resetChatSession() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages
      ..clear()
      ..addAll(_initialMessagesForDraft());
    _feedback = null;
    _isFeedbackLoading = false;
  }

  void _generateDraft([String? prompt]) {
    final input = (prompt ?? _controller.text).trim();
    if (input.isEmpty) {
      return;
    }
    setState(() {
      _draft = SceneDraft(
        title: input,
        emoji: _inferEmoji(input),
        tags: const ['AI 定制', '口语练习', '沉浸式'],
        goal: '在真实语境里表达核心信息，并稳住对方情绪。',
        npcName: 'Maya',
        npcRole: '项目经理',
        environment: '工作会议',
        challenge: '对方会继续追问具体影响、下一步动作和承诺时间。',
      );
      _feedback = null;
      _isFeedbackLoading = false;
    });
    _setView(SceneFlowView.draft);
  }

  Future<void> _startConversation() async {
    setState(() {
      _resetChatSession();
    });
    try {
      _sessionId = await ApiClient.createAiSession(
        sceneTitle: _draft.title,
        sceneGoal: _draft.goal,
        npcName: _draft.npcName,
        npcRole: _draft.npcRole,
        environment: _draft.environment,
        challenge: _draft.challenge,
      );
    } catch (_) {
      _sessionId = '';
    }
    if (!mounted) {
      return;
    }
    _setView(SceneFlowView.chat);
  }

  bool _isDraftSectionExpanded(_DraftDetailSection section) {
    return _expandedDraftSections.contains(section);
  }

  void _toggleDraftSection(_DraftDetailSection section) {
    setState(() {
      if (_expandedDraftSections.contains(section)) {
        _expandedDraftSections.remove(section);
      } else {
        _expandedDraftSections.add(section);
      }
    });
  }

  void _notifyBottomBarVisibility() {
    widget.onBottomBarVisibilityChanged?.call(_view == SceneFlowView.home);
  }

  void _setView(SceneFlowView view) {
    if (_view == view) {
      _notifyBottomBarVisibility();
      return;
    }
    setState(() {
      _view = view;
      if (view == SceneFlowView.feedback && _feedback == null) {
        _isFeedbackLoading = true;
        _generateFeedback();
      }
    });
    _notifyBottomBarVisibility();
    if (view == SceneFlowView.chat) {
      _scrollChatToLatest(animated: false);
    }
  }

  void _generateFeedback() {
    final AppSession session = AppSessionScope.of(context);
    final List<SceneHistoryTurn> history = _messages
        .where((m) => m.role == _MessageRole.user || m.role == _MessageRole.npc)
        .map(
          (m) => SceneHistoryTurn(
            role: m.role == _MessageRole.user ? 'user' : 'npc',
            text: m.text,
          ),
        )
        .toList();
    session
        .generateSceneFeedback(draft: _draft, history: history)
        .then((SceneFeedback f) {
          if (!mounted || !_isFeedbackLoading) {
            return;
          }
          setState(() {
            _feedback = f;
            _isFeedbackLoading = false;
          });
        })
        .catchError((Object _) {
          if (!mounted || !_isFeedbackLoading) {
            return;
          }
          setState(() => _isFeedbackLoading = false);
        });
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

  Widget _buildDraftOverviewCard(List<String> summaryTags) {
    const Color accentColor = Color(0xFF2E6058);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9E3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.10),
                  accentColor.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF0EDE6)),
              ),
            ),
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
                        color: accentColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.14),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _draft.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _draft.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Color(0xFF18160F),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _draft.challenge,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: Color(0xFF7A7268),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: summaryTags
                        .map(
                          (tag) => Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x0D000000),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x12000000),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6A6258),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.92,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              const _DraftSummaryCell(
                title: '你的角色',
                value: '项目负责人',
                rightBorder: true,
                bottomBorder: true,
              ),
              _DraftSummaryCell(
                title: '对方角色',
                value: '${_draft.npcName} · ${_draft.npcRole}',
                bottomBorder: true,
              ),
              const _DraftSummaryCell(
                title: '对方风格',
                chips: [
                  ('直接', Color(0xFFC4743A)),
                  ('强势', Color(0xFF8A6F5A)),
                  ('追问多', Color(0xFF5A6FA8)),
                ],
                rightBorder: true,
              ),
              const _DraftSummaryCell(
                title: '你的目标',
                bullets: ['稳住节奏', '给恢复方案'],
                footnote: '+1 个目标',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startChatRecording() {
    if (_isRecording) {
      return;
    }
    final List<String> voiceReplies = <String>[
      'We slipped by three days, but the revised QA plan is already locked and I will send the updated timeline before 6 PM.',
      'The main risk is already contained, and the client will get a concrete recovery schedule from me today.',
      'I should have raised the dependency risk earlier, and I am now owning the recovery plan with two checkpoints.',
    ];
    final String target = voiceReplies[_messages.length % voiceReplies.length];
    int cursor = 0;
    _mockInputTimer?.cancel();
    setState(() {
      _isRecording = true;
      _chatRecordingWillCancel = false;
      _showCoachAssistant = false;
      _controller.clear();
    });
    _coachQuestionFocusNode.unfocus();
    _scrollChatToLatest(animated: false);
    _mockInputTimer = Timer.periodic(const Duration(milliseconds: 32), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      cursor += 1;
      setState(() {
        _controller.text = target.substring(0, cursor.clamp(0, target.length));
      });
      _scrollChatToLatest(animated: false);
      if (cursor >= target.length) {
        timer.cancel();
      }
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
    final String captured = _controller.text.trim();
    setState(() {
      _isRecording = false;
      _chatRecordingWillCancel = false;
    });
    if (send && captured.isNotEmpty) {
      _sendMessage(asVoice: true, voiceDuration: 7);
      return;
    }
    _controller.clear();
  }

  void _toggleChatRecording() {
    if (_isRecording) {
      _finishChatRecording(send: true);
      return;
    }
    _startChatRecording();
  }

  void _toggleCoachAssistant() {
    setState(() {
      _showCoachAssistant = !_showCoachAssistant;
      _showTextComposer = false;
    });
    if (_showCoachAssistant) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _coachQuestionFocusNode.requestFocus();
        _scrollChatToLatest(animated: false);
      });
      return;
    }
    _coachQuestionFocusNode.unfocus();
  }

  void _askCoachQuestion([String? question]) {
    final String input = (question ?? _coachQuestionController.text).trim();
    if (input.isEmpty) {
      return;
    }
    setState(() {
      _lastCoachQuestion = input;
      _coachAnswer = _buildCoachAnswer(input);
      _coachQuestionController.clear();
      _showCoachAssistant = true;
    });
    _scrollChatToLatest();
  }

  String _buildCoachAnswer(String question) {
    final String normalized = question.toLowerCase();

    if (normalized.contains('语法') ||
        normalized.contains('grammar') ||
        normalized.contains('because') ||
        normalized.contains('due to')) {
      return '语法上这里更适合先给完整结论，再补原因。你可以说：'
          '\n“We slipped by three days because the final QA fixes took longer than expected.”'
          '\n如果想更书面一点，再换成：'
          '\n“The three-day delay was due to longer-than-expected QA fixes.”';
    }

    if (normalized.contains('单词') ||
        normalized.contains('word') ||
        normalized.contains('vocab') ||
        normalized.contains('delay') ||
        normalized.contains('postpone')) {
      return '这组词可以这样分：'
          '\n`delay` 更像“延期/耽搁”，常用于项目、进度、航班。'
          '\n`postpone` 更像“把原定安排往后挪”，语气更主动。'
          '\n在你这个场景里，解释项目延期优先用 `delay` 或 `slip`。';
    }

    if (normalized.contains('表达') ||
        normalized.contains('怎么说') ||
        normalized.contains('how to say') ||
        normalized.contains('polite')) {
      return '这个场景里，常用表达优先记这 3 句：'
          '\n1. “We slipped by three days, but the recovery plan is already in motion.”'
          '\n2. “The client will receive an updated timeline before 6 PM today.”'
          '\n3. “I’m owning the next checkpoint and will keep you posted.”';
    }

    return '如果你现在是想在对话里临时补一句，建议遵循这个顺序：'
        '\n先结论：先说发生了什么。'
        '\n再原因：只补最关键的一个原因。'
        '\n最后动作：明确下一步、负责人和时间点。';
  }

  void _sendMessage({bool asVoice = false, int? voiceDuration}) {
    final input = _controller.text.trim();
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

    setState(() {
      _feedback = null;
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
    });
    _scrollChatToLatest();

    final AppSession session = AppSessionScope.of(context);
    session
        .sendSceneMessage(
          sessionId: _sessionId,
          userText: input,
          draft: _draft,
          history: history,
        )
        .then((SceneReply reply) {
          if (!mounted) return;
          setState(() {
            _isNpcThinking = false;
            if (reply.eventLabel != null && reply.eventColor != null) {
              _messages.add(
                _ChatMessage(
                  role: _MessageRole.event,
                  text: reply.eventLabel!,
                  accent: reply.eventColor!,
                ),
              );
            } else if (reply.coachHint != null) {
              _messages.add(
                _ChatMessage(
                  role: _MessageRole.coach,
                  text: reply.coachHint!,
                  note: '保持一句话一个动作',
                ),
              );
            }
            _messages.add(
              _ChatMessage(
                role: _MessageRole.npc,
                text: reply.npcText,
                inputType: _ChatInputType.voice,
                voiceDuration: 6,
                mood: reply.mood,
              ),
            );
          });
          _scrollChatToLatest();
        })
        .catchError((Object error) {
          if (!mounted) return;
          setState(() {
            _isNpcThinking = false;
            _messages.add(
              const _ChatMessage(
                role: _MessageRole.event,
                text: '网络异常，请重试',
                accent: Color(0xFFE8855A),
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: switch (_view) {
        SceneFlowView.home => _buildHome(),
        SceneFlowView.draft => _buildDraft(),
        SceneFlowView.edit => _buildEdit(),
        SceneFlowView.chat => _buildChat(),
        SceneFlowView.feedback => _buildFeedback(),
      },
    );
  }

  Widget _buildHome() {
    final AppSession session = AppSessionScope.of(context);
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Container(
        key: const ValueKey('scene-home'),
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '今天已练习 2 个场景 🔥',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0x99FFFFFF),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '今天想练什么场景？',
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
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xB3FFFFFF),
                                    Color(0x99A8D48A),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x38000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 44,
                                height: 44,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xE0FFFFFF),
                                    width: 2,
                                  ),
                                ),
                                child: Image.network(
                                  session.avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) {
                                        return const ColoredBox(
                                          color: Color(0xFF87B076),
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                            Expanded(child: _SceneProgressPill(progress: 0.67)),
                          ],
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          onTap: () => _generateDraft('${item.label}相关的英文对话练习'),
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
                  ..._recentScenes.map(
                    (scene) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _RecentSceneCard(
                        scene: scene,
                        onSummary: () {
                          setState(() {
                            _draft = SceneDraft(
                              title: scene.title,
                              emoji: scene.emoji,
                              tags: scene.tags,
                              goal: '保持表达清晰，并能承接对方追问。',
                              npcName: 'Alex',
                              npcRole: '对话对象',
                              environment: '真实工作语境',
                              challenge: '回答不能太模糊，需要给出明确动作。',
                            );
                            _feedback = null;
                            _isFeedbackLoading = false;
                          });
                          _setView(SceneFlowView.feedback);
                        },
                        onContinue: () {
                          setState(() {
                            _controller.text = scene.title;
                            _draft = SceneDraft(
                              title: scene.title,
                              emoji: scene.emoji,
                              tags: scene.tags,
                              goal: '用英文重新组织你的表达节奏。',
                              npcName: 'Alex',
                              npcRole: '对话对象',
                              environment: '延续之前的场景',
                              challenge: '对方会继续往下追问。',
                            );
                            _feedback = null;
                            _isFeedbackLoading = false;
                          });
                          _setView(SceneFlowView.draft);
                        },
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
                    if (_isRecording)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0x224A7C6F),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? const Color(0xFF2E6058)
                              : const Color(0xFFF2EFE9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          size: 15,
                          color: _isRecording
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
                    _isRecording
                        ? '正在聆听…'
                        : _controller.text.isNotEmpty
                        ? '${_controller.text.length} 字'
                        : '描述你真实的沟通场景',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isRecording
                          ? const Color(0xFF4A7C6F)
                          : const Color(0xFFB0A89F),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _controller.text.trim().isEmpty
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
                  icon: Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: _controller.text.trim().isEmpty
                        ? const Color(0xFFC0B8B0)
                        : Colors.white,
                  ),
                  label: Text(
                    '生成场景',
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
    const Color primary = Color(0xFF2E6058);
    const Color pressureColor = Color(0xFFC4743A);
    const int confidence = 94;
    final List<String> summaryTags = <String>[
      _draft.tags.first,
      '职场英语',
      '中高压',
      '直接追问',
      '恢复计划',
    ];
    final List<String> goals = <String>[
      '先给出结论，避免显得在绕背景',
      '明确说明恢复计划和具体时间点',
      '在追问责任时保持专业和稳定',
    ];
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
                          onPressed: () => _setView(SceneFlowView.home),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildDraftOverviewCard(summaryTags),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                  child: Column(
                    children: [
                      const _DraftSectionDivider(label: '快速调整'),
                      const SizedBox(height: 12),
                      _DraftSectionCard(
                        title: '人物设定',
                        accent: const Color(0xFF8A6F5A),
                        trailing: '强势 · 直接',
                        icon: Icons.person_2_outlined,
                        isExpanded: _isDraftSectionExpanded(
                          _DraftDetailSection.persona,
                        ),
                        onToggle: () =>
                            _toggleDraftSection(_DraftDetailSection.persona),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0x082E6058),
                                    Color(0x084A7C6F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEDE9E3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF3A5A54),
                                              Color(0xFF5A8A80),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          '👔',
                                          style: TextStyle(fontSize: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _draft.npcName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF18160F),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _draft.npcRole,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF7A7268),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _setView(SceneFlowView.edit),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 34),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFE4E0D8),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 12,
                                          color: Color(0xFF7A7268),
                                        ),
                                        label: const Text(
                                          '编辑',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7A7268),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const _DraftTraitRow(
                                    label: '性格',
                                    options: ['随和', '中性', '强势', '强硬'],
                                    selected: '强势',
                                    color: Color(0xFF8A6F5A),
                                  ),
                                  const SizedBox(height: 10),
                                  const _DraftTraitRow(
                                    label: '语气',
                                    options: ['温和', '中性', '直接', '咄咄'],
                                    selected: '直接',
                                    color: Color(0xFF8A6F5A),
                                  ),
                                  const SizedBox(height: 10),
                                  const _DraftTraitRow(
                                    label: '容忍度',
                                    options: ['极低', '低', '中', '高'],
                                    selected: '低',
                                    color: Color(0xFF8A6F5A),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const _DraftTextArea(
                              title: '自然语言微调',
                              hint: '让他更不耐烦一点，但不要太凶…',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DraftSectionCard(
                        title: '关系背景',
                        accent: Color(0xFF7B6FA8),
                        trailing: '有过接触',
                        icon: Icons.groups_outlined,
                        isExpanded: _isDraftSectionExpanded(
                          _DraftDetailSection.relationship,
                        ),
                        onToggle: () => _toggleDraftSection(
                          _DraftDetailSection.relationship,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DraftFieldLabel(text: '熟悉程度'),
                            SizedBox(height: 9),
                            _DraftPillWrap(
                              color: Color(0xFF7B6FA8),
                              options: ['初次见面', '有过接触', '比较熟悉', '老同事'],
                              selected: ['有过接触'],
                            ),
                            SizedBox(height: 14),
                            _DraftFieldLabel(text: '信任基础'),
                            SizedBox(height: 9),
                            _DraftPillWrap(
                              color: Color(0xFF7B6FA8),
                              options: ['互相怀疑', '中性观望', '基本信任', '充分信任'],
                              selected: ['中性观望'],
                            ),
                            SizedBox(height: 14),
                            _DraftToggleRow(
                              title: '是否第一次提这件事',
                              subtitle: '影响对方的心理预期和反应模式',
                              active: true,
                              color: Color(0xFF7B6FA8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DraftSectionCard(
                        title: '对话目标',
                        accent: primary,
                        trailing: '3 个已选',
                        icon: Icons.flag_outlined,
                        isExpanded: _isDraftSectionExpanded(
                          _DraftDetailSection.goals,
                        ),
                        onToggle: () =>
                            _toggleDraftSection(_DraftDetailSection.goals),
                        child: Column(
                          children: [
                            ...goals.map(
                              (goal) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _DraftGoalRow(text: goal, active: true),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '可追加目标',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textTertiary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const _DraftPillWrap(
                              color: Color(0xFF2E6058),
                              options: ['表现出自信', '更地道口语', '结构更清晰'],
                              selected: ['表现出自信'],
                              additive: true,
                            ),
                            const SizedBox(height: 12),
                            const _DraftTextArea(
                              hint:
                                  '用自然语言描述你想要的目标，例如：\n• 表现出自信\n• 使用地道口语\n• 结构化表达',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DraftSectionCard(
                        title: '难度与真实度',
                        accent: pressureColor,
                        trailing: '中高压',
                        icon: Icons.tune_rounded,
                        isExpanded: _isDraftSectionExpanded(
                          _DraftDetailSection.difficulty,
                        ),
                        onToggle: () =>
                            _toggleDraftSection(_DraftDetailSection.difficulty),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DraftFieldLabel(text: '压力强度'),
                            SizedBox(height: 10),
                            _DraftPressureScale(
                              labels: ['轻松', '极限'],
                              activeIndex: 4,
                              color: pressureColor,
                            ),
                            SizedBox(height: 16),
                            _DraftFieldLabel(text: '打断频率'),
                            SizedBox(height: 9),
                            _DraftPillWrap(
                              color: Color(0xFF5A6FA8),
                              options: ['无', '低', '中', '高'],
                              selected: ['中'],
                            ),
                            SizedBox(height: 14),
                            _DraftFieldLabel(text: '追问深度'),
                            SizedBox(height: 9),
                            _DraftPillWrap(
                              color: Color(0xFF7B4EA0),
                              options: ['浅', '中', '深', '刁钻'],
                              selected: ['深'],
                            ),
                            SizedBox(height: 14),
                            _DraftToggleRow(
                              title: '意外情况',
                              subtitle: '开启后，对话会有随机突发事件',
                              active: true,
                              color: pressureColor,
                            ),
                            SizedBox(height: 11),
                            _DraftPillWrap(
                              color: pressureColor,
                              options: ['被打断', '要求直接回答', '对方拒绝解释'],
                              selected: ['被打断', '要求直接回答'],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DraftSectionCard(
                        title: '语言要求',
                        accent: Color(0xFF3D7FA8),
                        trailing: 'B1 · 正常',
                        icon: Icons.language_outlined,
                        isExpanded: _isDraftSectionExpanded(
                          _DraftDetailSection.language,
                        ),
                        onToggle: () =>
                            _toggleDraftSection(_DraftDetailSection.language),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DraftFieldLabel(text: '我的英语水平'),
                            SizedBox(height: 9),
                            _DraftPillWrap(
                              color: Color(0xFF3D7FA8),
                              options: ['A2', 'B1', 'B2', 'C1'],
                              selected: ['B1'],
                            ),
                            SizedBox(height: 7),
                            Text(
                              '进阶水平 · 标准日常对话节奏',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFABA39A),
                              ),
                            ),
                            SizedBox(height: 14),
                            _DraftFieldLabel(text: '对方语速'),
                            SizedBox(height: 9),
                            _DraftPillWrap(
                              color: Color(0xFF3D7FA8),
                              options: ['慢', '正常', '快', '母语'],
                              selected: ['正常'],
                            ),
                            SizedBox(height: 14),
                            _DraftFieldLabel(text: '地道口语程度'),
                            SizedBox(height: 9),
                            _DraftPillWrap(
                              color: Color(0xFF5A6FA8),
                              options: ['低', '中', '高'],
                              selected: ['中'],
                            ),
                            SizedBox(height: 14),
                            _DraftToggleRow(
                              title: '允许提示',
                              subtitle: '卡住时可请求 AI 给出表达提示',
                              active: true,
                              color: Color(0xFF2E6058),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DraftSectionCard(
                        title: '场景全局修改',
                        accent: Color(0xFF8A8078),
                        icon: Icons.message_outlined,
                        isExpanded: _isDraftSectionExpanded(
                          _DraftDetailSection.globalEdit,
                        ),
                        onToggle: () =>
                            _toggleDraftSection(_DraftDetailSection.globalEdit),
                        child: _DraftTextArea(
                          hint:
                              '用自然语言描述你想要的改变，例如：\n• 让对话更难一些\n• 让对方更友好\n• 降低语速',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 10,
                            color: Color(0x668A8078),
                          ),
                          SizedBox(width: 5),
                          Text(
                            '由 AI 自动解析，仅供参考',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0x668A8078),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                bottomInset > 0 ? bottomInset + 8 : 10,
              ),
              decoration: BoxDecoration(
                color: appBackground.withValues(alpha: 0.97),
                border: const Border(top: BorderSide(color: Color(0xFFDDD9D0))),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _startConversation,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text(
                  '开始练习',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
            value: '专业、直接、会继续追问',
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
            title: '你的目标',
            value: '先说结论，再解释原因，最后给补救方案。',
            icon: Icons.flag_rounded,
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

  Widget _buildChat() {
    final double topInset = MediaQuery.paddingOf(context).top;
    final double maxBottomPanelHeight = _showCoachAssistant ? 286 : 150;

    return Container(
      key: const ValueKey('scene-chat'),
      color: const Color(0xFF0E1915),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0C1613), Color(0xF20C1613)],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => _setView(SceneFlowView.draft),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x12FFFFFF),
                        minimumSize: const Size(38, 38),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: Colors.white,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _draft.npcName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF7ACFBD),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            _draft.npcRole,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0x66FFFFFF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '等待你的直接回答',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8BA8E0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _draft.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0x66FFFFFF),
                                  ),
                                ),
                              ),
                            ],
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
                            color: const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x12FFFFFF)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 9,
                                color: Color(0x66FFFFFF),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '02:47',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0x80FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => _setView(SceneFlowView.feedback),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x12FFFFFF),
                            minimumSize: const Size(34, 34),
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(
                            Icons.pause_rounded,
                            size: 17,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () =>
                              setState(() => _realtimeMode = !_realtimeMode),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x12FFFFFF),
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
                            color: const Color(0xFFEFEBE4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const SizedBox(
                            width: 36,
                            height: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            color: const Color(0x124A7C6F),
                            borderRadius: BorderRadius.circular(
                              18,
                            ).copyWith(topRight: const Radius.circular(6)),
                            border: Border.all(
                              color: const Color(0x594A7C6F),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Text(
                            _controller.text.isEmpty
                                ? 'I understand the concern...'
                                : '${_controller.text} •',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.65,
                              fontStyle: FontStyle.italic,
                              color: Color(0x80FFFFFF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final message = _messages[index];
                return _ConversationBubble(
                  message: message,
                  npcName: _draft.npcName,
                  transcriptExpanded: _expandedVoiceMessageIndexes.contains(
                    index,
                  ),
                  onVoiceLongPress: message.inputType == _ChatInputType.voice
                      ? () => _toggleVoiceMessageTranscript(index)
                      : null,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1714),
              border: Border(
                top: BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxBottomPanelHeight),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_showTextComposer && !_isRecording) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x14FFFFFF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 4,
                                style: const TextStyle(
                                  color: Color(0xFFEAE7E2),
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  hintText: '用英文输入你的回应…',
                                  hintStyle: TextStyle(
                                    color: Color(0x66FFFFFF),
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
                    if (_showCoachAssistant && !_isRecording) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x14FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(0x144A7C6F),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: Color(0xFF7ACFBD),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '实时提问',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFF3F1EC),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '可以问语法、单词、常用表达',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0x73FFFFFF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _toggleCoachAssistant,
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0x80FFFFFF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  const [
                                    'delay 和 postpone 有什么区别？',
                                    '这里 because 和 due to 怎么选？',
                                    '怎么更礼貌地解释延期？',
                                  ].map((suggestion) {
                                    return _CoachSuggestionChip(
                                      label: suggestion,
                                      onTap: () =>
                                          _askCoachQuestion(suggestion),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x12000000),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0x14FFFFFF),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _coachQuestionController,
                                      focusNode: _coachQuestionFocusNode,
                                      minLines: 1,
                                      maxLines: 4,
                                      onTapOutside: (_) =>
                                          _coachQuestionFocusNode.unfocus(),
                                      onSubmitted: (_) => _askCoachQuestion(),
                                      style: const TextStyle(
                                        color: Color(0xFFEAE7E2),
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                      decoration: const InputDecoration(
                                        isCollapsed: true,
                                        hintText: '比如：这里为什么用 slipped by？',
                                        hintStyle: TextStyle(
                                          color: Color(0x66FFFFFF),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _askCoachQuestion(),
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
                            if (_coachAnswer != null &&
                                _lastCoachQuestion != null) ...[
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
                                  color: const Color(0x144A7C6F),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0x334A7C6F),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Q: $_lastCoachQuestion',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFCDEAE3),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _coachAnswer!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.65,
                                        color: Color(0xFFF1EEE8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                    : () => _finishChatRecording(send: false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
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
                                          : _realtimeMode
                                          ? const Color(0xFF7CF2AE)
                                          : const Color(0xFF7ACFBD),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_chatRecordingWillCancel
                                                    ? const Color(0xFFC95D52)
                                                    : _isRecording
                                                    ? const Color(0xFFE8855A)
                                                    : _realtimeMode
                                                    ? const Color(0xFF5ECE92)
                                                    : const Color(0xFF4A7C6F))
                                                .withValues(alpha: 0.4),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _realtimeMode
                                        ? (_isRecording
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
                                    ? (_isRecording ? '点击挂断' : '点击接通')
                                    : (_chatRecordingWillCancel
                                          ? '松开取消'
                                          : _isRecording
                                          ? '松开发送，上滑取消'
                                          : '长按说话'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                  color: Color(0x47FFFFFF),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 0,
                            bottom: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _toggleCoachAssistant,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _showCoachAssistant
                                          ? const Color(0xFF7ACFBD)
                                          : const Color(0x12FFFFFF),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _showCoachAssistant
                                            ? const Color(0xFFB7F0E3)
                                            : const Color(0x18FFFFFF),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      _showCoachAssistant
                                          ? Icons.close_rounded
                                          : Icons.help_outline_rounded,
                                      size: 20,
                                      color: _showCoachAssistant
                                          ? const Color(0xFF123730)
                                          : const Color(0xFFEAE7E2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '提问',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 0.4,
                                    color: Color(0x47FFFFFF),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    if (_isFeedbackLoading || _feedback == null) {
      return _SceneScaffold(
        key: const ValueKey('scene-feedback-loading'),
        title: '练后反馈',
        subtitle: '正在生成分析...',
        onBack: () => _setView(SceneFlowView.chat),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    final SceneFeedback fb = _feedback!;
    const List<(String, String, String)> suggestions =
        <(String, String, String)>[
          ('🔁', '再练一次同场景', '保留当前难度，再打一轮把节奏练顺。'),
          ('⚡', '提高追问强度', '让对方更强势，专门训练高压追问。'),
          ('🛠️', '调整场景设定', '保留目标，但改成客户电话或周会汇报。'),
        ];
    const List<Color> impColors = <Color>[
      Color(0xFFC4743A),
      Color(0xFF8BA8E0),
      Color(0xFF4A7C6F),
    ];

    return _SceneScaffold(
      key: const ValueKey('scene-feedback'),
      title: '练后反馈',
      subtitle: '对应导出仓库里的 FeedbackPage',
      onBack: () => _setView(SceneFlowView.chat),
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
                  fb.headline,
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
                  fb.summary,
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
            (m) =>
                _FeedbackMetric(label: m.label, score: m.score, color: m.color),
          ),
          const SizedBox(height: 18),
          const _FeedbackTaskCard(
            title: '任务拆解',
            items: [
              ('解释延期原因', '完成', Color(0xFF4A7C6F)),
              ('避免显得推责', '部分完成', Color(0xFFC4743A)),
              ('提出后续方案', '较弱', Color(0xFFA04A4A)),
            ],
          ),
          const SizedBox(height: 12),
          _CoachCard(title: '教练建议', body: fb.coachTip),
          const SizedBox(height: 12),
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
                const Text(
                  '模块 B · 这轮最该改的 3 个点',
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
                      title: entry.$2.$2,
                      detail: entry.$2.$3,
                      color: impColors[entry.$1 % impColors.length],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                const Text(
                  '模块 D · 下一轮建议',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...suggestions.indexed.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.$1 == suggestions.length - 1 ? 0 : 10,
                    ),
                    child: _SuggestionActionCard(
                      emoji: entry.$2.$1,
                      title: entry.$2.$2,
                      body: entry.$2.$3,
                      primary: entry.$1 == 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  child: const Text('再练一次'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _setView(SceneFlowView.home),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6058),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('回到首页'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _inferEmoji(String text) {
    if (text.contains('面试')) return '💼';
    if (text.contains('老板') || text.contains('项目')) return '📊';
    if (text.contains('客户')) return '🤝';
    if (text.contains('电话')) return '☎️';
    return '🗣️';
  }
}

class _SceneScaffold extends StatelessWidget {
  const _SceneScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 54, 18, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF213E3A),
                  Color(0xFF2E6058),
                  Color(0xFF6EA8A0),
                  appBackground,
                ],
                stops: [0, 0.5, 0.82, 1],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x14FFFFFF),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xD5DFF8F2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EditableCard extends StatelessWidget {
  const _EditableCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftSectionDivider extends StatelessWidget {
  const _DraftSectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFEDE9E3), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textTertiary,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFEDE9E3), thickness: 1)),
      ],
    );
  }
}

class _DraftSummaryCell extends StatelessWidget {
  const _DraftSummaryCell({
    required this.title,
    this.value,
    this.chips,
    this.bullets,
    this.footnote,
    this.rightBorder = false,
    this.bottomBorder = false,
  });

  final String title;
  final String? value;
  final List<(String, Color)>? chips;
  final List<String>? bullets;
  final String? footnote;
  final bool rightBorder;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        border: Border(
          right: rightBorder
              ? const BorderSide(color: Color(0xFFF4F1ED))
              : BorderSide.none,
          bottom: bottomBorder
              ? const BorderSide(color: Color(0xFFF4F1ED))
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textTertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18160F),
                height: 1.35,
              ),
            ),
          if (chips != null)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: chips!
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: chip.$2.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: chip.$2.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        chip.$1,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: chip.$2,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (bullets != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...bullets!.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '· $bullet',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3A3530),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (footnote != null)
                  Text(
                    footnote!,
                    style: const TextStyle(fontSize: 9, color: textTertiary),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DraftSectionCard extends StatelessWidget {
  const _DraftSectionCard({
    required this.title,
    required this.accent,
    required this.icon,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    this.trailing,
  });

  final String title;
  final Color accent;
  final IconData icon;
  final String? trailing;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE9E3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                border: isExpanded
                    ? const Border(bottom: BorderSide(color: Color(0xFFF4F1ED)))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 15, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) ...[
                    Text(
                      trailing!,
                      style: const TextStyle(fontSize: 11, color: textTertiary),
                    ),
                    const SizedBox(width: 10),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Color(0xFF9E978E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: child,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _DraftFieldLabel extends StatelessWidget {
  const _DraftFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF3A3530),
      ),
    );
  }
}

class _DraftTraitRow extends StatelessWidget {
  const _DraftTraitRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.color,
  });

  final String label;
  final List<String> options;
  final String selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A3530),
          ),
        ),
        const SizedBox(height: 8),
        _DraftPillWrap(color: color, options: options, selected: [selected]),
      ],
    );
  }
}

class _DraftPillWrap extends StatelessWidget {
  const _DraftPillWrap({
    required this.color,
    required this.options,
    required this.selected,
    this.additive = false,
  });

  final Color color;
  final List<String> options;
  final List<String> selected;
  final bool additive;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: options.map((option) {
        final bool active = selected.contains(option);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.08)
                : const Color(0xFFF4F1EB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.20)
                  : const Color(0xFFEAE6DF),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (additive) ...[
                Icon(
                  active ? Icons.check_rounded : Icons.add_rounded,
                  size: 11,
                  color: active ? color : const Color(0xFF7A7268),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                option,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? color : const Color(0xFF7A7268),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DraftGoalRow extends StatelessWidget {
  const _DraftGoalRow({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: active ? const Color(0x072E6058) : const Color(0xFFF8F5F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(0x382E6058) : const Color(0xFFEAE6DF),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF2E6058) : const Color(0xFFDDD9D3),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 11,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active
                    ? const Color(0xFF18160F)
                    : const Color(0xFF8A8078),
                height: 1.4,
              ),
            ),
          ),
          const Icon(
            Icons.drag_indicator_rounded,
            size: 14,
            color: Color(0x80B0A89F),
          ),
        ],
      ),
    );
  }
}

class _DraftTextArea extends StatelessWidget {
  const _DraftTextArea({this.title, required this.hint});

  final String? title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 7),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F5F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAE6DF), width: 1.5),
          ),
          child: Text(
            hint,
            style: const TextStyle(
              fontSize: 12,
              height: 1.65,
              color: Color(0xFFABA39A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8F3EB), Color(0xFFF2EDE2)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFC8C2B8),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: Color(0xFFABA39A),
              ),
              SizedBox(width: 8),
              Text(
                '应用修改',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFABA39A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DraftToggleRow extends StatelessWidget {
  const _DraftToggleRow({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.color,
  });

  final String title;
  final String subtitle;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3530),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: textTertiary),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? color : const Color(0xFFD9D4CC),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _DraftPressureScale extends StatelessWidget {
  const _DraftPressureScale({
    required this.labels,
    required this.activeIndex,
    required this.color,
  });

  final List<String> labels;
  final int activeIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List<Widget>.generate(
            5,
            (int index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                height: 10,
                decoration: BoxDecoration(
                  color: index < activeIndex ? color : const Color(0xFFE7E2DA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              labels.first,
              style: const TextStyle(fontSize: 9, color: Color(0xFFC0B8B0)),
            ),
            const Spacer(),
            Text(
              labels.last,
              style: const TextStyle(fontSize: 9, color: Color(0xFFC0B8B0)),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditSectionHeader extends StatelessWidget {
  const _EditSectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SceneTopPill extends StatelessWidget {
  const _SceneTopPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.suffix,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0x2E000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            suffix,
            style: const TextStyle(fontSize: 10, color: Color(0x85FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _SceneProgressPill extends StatelessWidget {
  const _SceneProgressPill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2E000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xD8A8E6DC),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(fontSize: 10, color: Color(0xA6FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _RecentSceneCard extends StatelessWidget {
  const _RecentSceneCard({
    required this.scene,
    required this.onSummary,
    required this.onContinue,
  });

  final _RecentScene scene;
  final VoidCallback onSummary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scene.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    scene.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: scene.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scene.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scene.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: scene.progress / 100,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFEDE9E3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scene.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${scene.progress}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: scene.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '练习 ${scene.practiceCount} 次',
                style: const TextStyle(fontSize: 11, color: textSecondary),
              ),
              const SizedBox(width: 8),
              const Text(
                '·',
                style: TextStyle(fontSize: 11, color: textTertiary),
              ),
              const SizedBox(width: 8),
              Text(
                scene.lastTime,
                style: const TextStyle(fontSize: 11, color: textSecondary),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onSummary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scene.color,
                  side: BorderSide(color: scene.color.withValues(alpha: 0.22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('查看总结'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: scene.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('继续练习'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({
    required this.message,
    required this.npcName,
    required this.transcriptExpanded,
    this.onVoiceLongPress,
  });

  final _ChatMessage message;
  final String npcName;
  final bool transcriptExpanded;
  final VoidCallback? onVoiceLongPress;

  @override
  Widget build(BuildContext context) {
    if (message.role == _MessageRole.event) {
      final Color accent = message.accent ?? const Color(0xFF7ACFBD);
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            const Expanded(
              child: Divider(color: Color(0x14FFFFFF), thickness: 1),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0x14FFFFFF), thickness: 1),
            ),
          ],
        ),
      );
    }

    if (message.role == _MessageRole.coach) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 230),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
            decoration: BoxDecoration(
              color: const Color(0x10E8C46A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x22E8C46A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xCCE8C46A),
                    height: 1.4,
                  ),
                ),
                if (message.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message.note!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0x88E8C46A),
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final bool isNpc = message.role == _MessageRole.npc;
    final bool isVoice = message.inputType == _ChatInputType.voice;
    final BorderRadius bubbleRadius = BorderRadius.circular(20).copyWith(
      topLeft: isNpc ? const Radius.circular(6) : null,
      topRight: isNpc ? null : const Radius.circular(6),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isNpc ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isNpc ? 288 : 280),
          child: Column(
            crossAxisAlignment: isNpc
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              if (isNpc) ...[
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: const LinearGradient(
                          colors: [Color(0x334A7C6F), Color(0x447ACFBD)],
                        ),
                        border: Border.all(color: const Color(0x447ACFBD)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('👔', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      npcName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7ACFBD),
                      ),
                    ),
                    if (message.mood != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x128BA8E0),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x2A8BA8E0)),
                        ),
                        child: Text(
                          message.mood!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8BA8E0),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              GestureDetector(
                onLongPress: isVoice ? onVoiceLongPress : null,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: isNpc
                        ? const Color(0x0FFFFFFF)
                        : const Color(0x1F4A7C6F),
                    borderRadius: bubbleRadius,
                    border: Border.all(
                      color: isNpc
                          ? const Color(0x16FFFFFF)
                          : const Color(0x334A7C6F),
                    ),
                  ),
                  child: isVoice
                      ? _VoiceMessageCard(
                          isNpc: isNpc,
                          duration: message.voiceDuration ?? (isNpc ? 5 : 4),
                        )
                      : Text(
                          message.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.6,
                          ),
                        ),
                ),
              ),
              if (isVoice && transcriptExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: isNpc
                        ? const Color(0x12111714)
                        : const Color(0x12324E47),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNpc
                          ? const Color(0x1EFFFFFF)
                          : const Color(0x335A9E90),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xE6FFFFFF),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceMessageCard extends StatelessWidget {
  const _VoiceMessageCard({required this.isNpc, required this.duration});

  final bool isNpc;
  final int duration;

  @override
  Widget build(BuildContext context) {
    if (isNpc) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_arrow_rounded,
            size: 15,
            color: Color(0xFF7ACFBD),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 76,
            child: Row(
              children: List<Widget>.generate(
                10,
                (int index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index == 9 ? 0 : 2),
                    height: index.isEven ? 7 : 11,
                    decoration: BoxDecoration(
                      color: const Color(0x667ACFBD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${duration}s',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0x80FFFFFF),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${duration}s',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0x80FFFFFF),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List<Widget>.generate(
              8,
              (int index) => Container(
                width: 4,
                height: index.isEven ? 6 : 10,
                margin: EdgeInsets.only(left: index == 0 ? 0 : 2),
                decoration: BoxDecoration(
                  color: const Color(0xB2D4F3EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(
          Icons.graphic_eq_rounded,
          size: 13,
          color: Color(0xFFD4F3EB),
        ),
      ],
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({
    required this.index,
    required this.emoji,
    required this.title,
    required this.detail,
    required this.color,
  });

  final int index;
  final String emoji;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE9E3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A6258),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionActionCard extends StatelessWidget {
  const _SuggestionActionCard({
    required this.emoji,
    required this.title,
    required this.body,
    required this.primary,
  });

  final String emoji;
  final String title;
  final String body;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primary ? const Color(0x074A7C6F) : const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary ? const Color(0x384A7C6F) : const Color(0xFFEDE9E3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary
                  ? const Color(0x124A7C6F)
                  : const Color(0xFFF2EFE8),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8078),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: primary ? const Color(0xFF4A7C6F) : const Color(0xFFC0B8B0),
          ),
        ],
      ),
    );
  }
}

class _FeedbackMetric extends StatelessWidget {
  const _FeedbackMetric({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF2EFE9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTaskCard extends StatelessWidget {
  const _FeedbackTaskCard({required this.title, required this.items});

  final String title;
  final List<(String, String, Color)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.$1,
                      style: const TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: item.$3.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.$3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScene {
  const _RecentScene({
    required this.title,
    required this.emoji,
    required this.tags,
    required this.color,
    required this.practiceCount,
    required this.lastTime,
    required this.progress,
  });

  final String title;
  final String emoji;
  final List<String> tags;
  final Color color;
  final int practiceCount;
  final String lastTime;
  final int progress;
}

class _CoachSuggestionChip extends StatelessWidget {
  const _CoachSuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0x124A7C6F),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x334A7C6F)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD5EEE8),
          ),
        ),
      ),
    );
  }
}

enum _ChatInputType { voice, text }

enum _MessageRole { event, npc, user, coach }

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    this.note,
    this.mood,
    this.inputType,
    this.voiceDuration,
    this.accent,
  });

  final _MessageRole role;
  final String text;
  final String? note;
  final String? mood;
  final _ChatInputType? inputType;
  final int? voiceDuration;
  final Color? accent;
}

class _ThinkingDot extends StatefulWidget {
  const _ThinkingDot({required this.delay});

  final Duration delay;

  @override
  State<_ThinkingDot> createState() => _ThinkingDotState();
}

class _ThinkingDotState extends State<_ThinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF9A9289),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
