import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'app_models.dart';
import 'app_session.dart';
import 'learning_page.dart';
import 'lesson_detail_page.dart';
import 'profile_page.dart';
import 'scene_page.dart';

class SpeakEasyHomePage extends StatefulWidget {
  const SpeakEasyHomePage({super.key});

  @override
  State<SpeakEasyHomePage> createState() => _SpeakEasyHomePageState();
}

class _SpeakEasyHomePageState extends State<SpeakEasyHomePage> {
  int _activeBottomIndex = 0;
  int _activeIntentIndex = 0;
  int _activeSectionIndex = 0;
  int _activeDifficultyIndex = 0;
  bool _showSceneBottomBar = true;

  Set<int> _savedIds = <int>{};
  Set<int> _dismissedIds = <int>{};
  Set<int> _completedIds = <int>{};
  List<ExpressionCardData> _allCards = expressionCards;

  ExpressionCardData? _activeLessonCard;
  bool _showLessonIntro = false;
  bool _showLearningFlow = false;
  bool _searchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCards());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<int> savedIds = _parseIds(prefs.getString('saved_ids') ?? '');
    final Set<int> dismissedIds = _parseIds(
      prefs.getString('dismissed_ids') ?? '',
    );
    final Set<int> completedIds = _parseIds(
      prefs.getString('completed_ids') ?? '',
    );
    if (!mounted) return;
    setState(() {
      _savedIds
        ..clear()
        ..addAll(savedIds);
      _dismissedIds
        ..clear()
        ..addAll(dismissedIds);
      _completedIds
        ..clear()
        ..addAll(completedIds);
    });
  }

  Future<void> _loadCards() async {
    try {
      final Map<String, dynamic> res = await ApiClient.getCards();
      if (res['code'] != 0 || !mounted) {
        return;
      }
      final List<dynamic> list = res['data'] as List<dynamic>;
      final List<ExpressionCardData> cards = list
          .map(
            (dynamic e) =>
                ExpressionCardData.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      final Set<int> savedIds = <int>{};
      final Set<int> dismissedIds = <int>{};
      final Set<int> completedIds = <int>{};
      for (int i = 0; i < cards.length; i++) {
        final Map<String, dynamic> cardJson = list[i] as Map<String, dynamic>;
        if (cardJson['saved'] == true) {
          savedIds.add(i);
        }
        if (cardJson['dismissed'] == true) {
          dismissedIds.add(i);
        }
        if (cardJson['completed'] == true) {
          completedIds.add(i);
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _allCards = cards;
        _savedIds = savedIds;
        _dismissedIds = dismissedIds;
        _completedIds = completedIds;
      });
    } catch (_) {
      // Keep the local compile-time fallback when the backend is unavailable.
    }
  }

  Future<void> _persistState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_ids', _savedIds.join(','));
    await prefs.setString('dismissed_ids', _dismissedIds.join(','));
    await prefs.setString('completed_ids', _completedIds.join(','));
  }

  Set<int> _parseIds(String value) {
    if (value.isEmpty) return <int>{};
    return value.split(',').map(int.tryParse).whereType<int>().toSet();
  }

  List<ExpressionCardData> get _learnCards {
    final String category = intents[_activeIntentIndex].label;
    var cards = _allCards.where((card) => card.category == category).toList();

    if (_activeDifficultyIndex > 0) {
      final int level = difficultyOptions[_activeDifficultyIndex].level;
      cards = cards.where((card) => card.difficultyLevel == level).toList();
    }

    if (_activeSectionIndex == 2) {
      return cards
          .where((card) => _savedIds.contains(_allCards.indexOf(card)))
          .toList();
    }
    if (_activeSectionIndex == 3) {
      return cards
          .where((card) => _dismissedIds.contains(_allCards.indexOf(card)))
          .toList();
    }
    if (_activeSectionIndex == 4) {
      return cards
          .where((card) => _completedIds.contains(_allCards.indexOf(card)))
          .toList();
    }

    return cards.where((card) {
      final int index = _allCards.indexOf(card);
      return !_savedIds.contains(index) &&
          !_dismissedIds.contains(index) &&
          !_completedIds.contains(index);
    }).toList();
  }

  List<ExpressionCardData> get _searchCards {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return const <ExpressionCardData>[];
    }
    return _allCards.where((card) {
      return card.title.toLowerCase().contains(query) ||
          card.pattern.toLowerCase().contains(query) ||
          card.category.toLowerCase().contains(query);
    }).toList();
  }

  void _openLesson(ExpressionCardData card) {
    setState(() {
      _activeLessonCard = card;
      _showLessonIntro = true;
      _showLearningFlow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hideBottomBar =
        (_activeBottomIndex == 1 && !_showSceneBottomBar) ||
        (_activeBottomIndex == 0 && (_showLessonIntro || _showLearningFlow));

    return Scaffold(
      backgroundColor: appBackground,
      body: Stack(
        children: [
          if (_activeBottomIndex == 0) ...const [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.68, -1),
                      end: Alignment(0.92, 1),
                      colors: [
                        Color(0xFF2E4A2C),
                        Color(0xFF4A7244),
                        Color(0xFF87B076),
                        appBackground,
                      ],
                      stops: [0, 0.38, 0.72, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 220,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.8, -0.92),
                      radius: 0.9,
                      colors: [Color(0x4DBEE6A0), Color(0x00BEE6A0)],
                    ),
                  ),
                ),
              ),
            ),
          ],
          SafeArea(
            bottom: false,
            child: switch (_activeBottomIndex) {
              0 => _buildLearnTab(),
              1 => ScenePage(
                onBottomBarVisibilityChanged: (bool visible) {
                  if (_showSceneBottomBar == visible) {
                    return;
                  }
                  setState(() {
                    _showSceneBottomBar = visible;
                  });
                },
              ),
              _ => const ProfilePage(),
            },
          ),
          if (_showLessonIntro && _activeLessonCard != null)
            Positioned.fill(
              child: LessonDetailPage(
                card: _activeLessonCard!,
                onBack: () => setState(() {
                  _showLessonIntro = false;
                  _activeLessonCard = null;
                }),
                onStart: () => setState(() {
                  _showLessonIntro = false;
                  _showLearningFlow = true;
                }),
              ),
            ),
          if (_showLearningFlow && _activeLessonCard != null)
            Positioned.fill(
              child: LearningPage(
                card: _activeLessonCard!,
                onBack: () => setState(() {
                  _showLearningFlow = false;
                  _showLessonIntro = true;
                }),
                onComplete: () {
                  final ExpressionCardData? card = _activeLessonCard;
                  final int idx = card != null ? _allCards.indexOf(card) : -1;
                  if (idx >= 0) {
                    _completedIds.add(idx);
                    unawaited(
                      ApiClient.updateCardState(
                        _cardIdFor(card!, idx),
                        completed: true,
                      ),
                    );
                  }
                  setState(() {
                    _showLearningFlow = false;
                    _activeLessonCard = null;
                  });
                  _persistState();
                  AppSessionScope.of(
                    context,
                  ).recordPracticeSession(durationSeconds: 300, score: 80);
                },
              ),
            ),
          if (_searchExpanded) Positioned.fill(child: _buildSearchOverlay()),
        ],
      ),
      bottomNavigationBar: hideBottomBar
          ? null
          : _BottomBar(
              currentIndex: _activeBottomIndex,
              onChanged: (int index) {
                setState(() {
                  _activeBottomIndex = index;
                });
              },
            ),
    );
  }

  Widget _buildLearnTab() {
    return Column(
      children: [
        _HomeHeader(
          onSearchTap: () {
            setState(() {
              _searchExpanded = true;
            });
          },
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
          child: SizedBox(
            height: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(intents.length, (int index) {
                final IntentData item = intents[index];
                final bool selected = _activeIntentIndex == index;
                return _IntentTab(
                  label: item.label,
                  icon: item.icon,
                  color: item.color,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _activeIntentIndex = index;
                    });
                  },
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List<Widget>.generate(sections.length, (
                      int index,
                    ) {
                      final bool active = _activeSectionIndex == index;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _activeSectionIndex = index),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: active ? darkGreen : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            sections[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: active ? textPrimary : textTertiary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              PopupMenuButton<int>(
                initialValue: _activeDifficultyIndex,
                onSelected: (int value) =>
                    setState(() => _activeDifficultyIndex = value),
                color: appBackground,
                elevation: 8,
                position: PopupMenuPosition.under,
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: Color(0xFF8E867D),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        difficultyOptions[_activeDifficultyIndex].label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A5550),
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) {
                  return List<PopupMenuEntry<int>>.generate(
                    difficultyOptions.length,
                    (int index) {
                      final DifficultyOption item = difficultyOptions[index];
                      final bool active = _activeDifficultyIndex == index;
                      return PopupMenuItem<int>(
                        value: index,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 29,
                              child: item.level == 0
                                  ? null
                                  : Row(
                                      children: List<Widget>.generate(3, (
                                        int dot,
                                      ) {
                                        return Container(
                                          width: 5,
                                          height: 5,
                                          margin: EdgeInsets.only(
                                            right: dot == 2 ? 0 : 3,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: dot < item.level
                                                ? item.color
                                                : item.color.withValues(
                                                    alpha: 0.14,
                                                  ),
                                          ),
                                        );
                                      }),
                                    ),
                            ),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: active
                                    ? item.color
                                    : const Color(0xFF5A5550),
                              ),
                            ),
                            const Spacer(),
                            if (active)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
            children: [
              _CardMasonry(
                cards: _learnCards,
                allCards: _allCards,
                onTapCard: _openLesson,
                emptyEmoji: _emptyEmoji,
                emptyText: _emptyText,
                savedIds: _savedIds,
                onSaveCard: (ExpressionCardData card) {
                  final int idx = _allCards.indexOf(card);
                  final bool shouldSave = !_savedIds.contains(idx);
                  setState(() {
                    if (shouldSave) {
                      _savedIds.add(idx);
                    } else {
                      _savedIds.remove(idx);
                    }
                  });
                  unawaited(
                    ApiClient.updateCardState(
                      _cardIdFor(card, idx),
                      saved: shouldSave,
                    ),
                  );
                  _persistState();
                },
                onDismissCard: (ExpressionCardData card) {
                  final int idx = _allCards.indexOf(card);
                  setState(() => _dismissedIds.add(idx));
                  unawaited(
                    ApiClient.updateCardState(
                      _cardIdFor(card, idx),
                      dismissed: true,
                    ),
                  );
                  _persistState();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchOverlay() {
    return Container(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.68, -1),
                end: Alignment(0.92, 1),
                colors: [
                  Color(0xFF2E4A2C),
                  Color(0xFF4A7244),
                  Color(0xFF87B076),
                  appBackground,
                ],
                stops: [0, 0.38, 0.72, 1],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchExpanded = false;
                      _searchController.clear();
                    });
                  },
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 14,
                          color: Color(0xFF8EAA80),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              hintText: '搜索表达 / 场景',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB8C0B0),
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _searchController.clear()),
                            child: const Text(
                              '✕',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB8C0B0),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
              children: [
                if (_searchController.text.trim().isEmpty)
                  const _SearchPlaceholder(
                    icon: Icons.search_rounded,
                    title: '输入关键词搜索',
                  )
                else if (_searchCards.isEmpty)
                  const _SearchPlaceholder(emoji: '🔍', title: '未找到相关内容')
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      '找到 ${_searchCards.length} 个结果',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  _CardMasonry(
                    cards: _searchCards,
                    allCards: _allCards,
                    onTapCard: (ExpressionCardData card) {
                      setState(() {
                        _searchExpanded = false;
                        _searchController.clear();
                        _activeLessonCard = card;
                        _showLessonIntro = true;
                        _showLearningFlow = false;
                      });
                    },
                    emptyEmoji: '',
                    emptyText: '',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _emptyEmoji {
    if (_activeSectionIndex == 2) return '🔖';
    if (_activeSectionIndex == 3) return '🙈';
    if (_activeSectionIndex == 4) return '🎉';
    return '🌿';
  }

  String get _emptyText {
    if (_activeSectionIndex == 2) return '还没有收藏的卡片';
    if (_activeSectionIndex == 3) return '没有标记不感兴趣的卡片';
    if (_activeSectionIndex == 4) return '还没有完成的卡片';
    if (_activeDifficultyIndex > 0) {
      return '暂无「${difficultyOptions[_activeDifficultyIndex].label}」难度卡片';
    }
    return '暂无卡片';
  }

  String _cardIdFor(ExpressionCardData card, int index) {
    final String? remoteId = card.id;
    if (remoteId != null && remoteId.isNotEmpty) {
      return remoteId;
    }
    return 'card_${(index + 1).toString().padLeft(3, '0')}';
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSearchTap});

  final VoidCallback onSearchTap;

  static String _timeGreeting() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return '早上好，今天继续学习吧';
    }
    if (hour >= 11 && hour < 18) {
      return '中午好，今天继续学习吧';
    }
    return '晚上好，今天继续学习吧';
  }

  Future<void> _showAvatarPicker(
    BuildContext context,
    AppSession session,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: appBackground,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择头像',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '点击即可立即替换首页和个人页头像',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: defaultAvatarUrls.map((String avatarUrl) {
                    final bool selected = session.avatarUrl == avatarUrl;
                    return GestureDetector(
                      onTap: () {
                        session.updateAvatar(avatarUrl);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? darkGreen : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return const ColoredBox(
                                    color: Color(0xFF87B076),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppSession session = AppSessionScope.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 54, 22, 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_timeGreeting()} 👋',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x9EFFFFFF),
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      session.nickname,
                      style: const TextStyle(
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
                onTap: () => _showAvatarPicker(context, session),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xB3FFFFFF), Color(0x99A8D48A)],
                    ),
                    boxShadow: const [
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
              ),
            ],
          ),
          const SizedBox(height: 11),
          const Row(
            children: [
              _StatPill(
                icon: Icons.local_fire_department_rounded,
                value: '7',
                suffix: '天连续',
                iconColor: Color(0xFFFFB83C),
              ),
              SizedBox(width: 7),
              _StatPill(
                icon: Icons.bolt_rounded,
                value: '248',
                suffix: 'XP',
                iconColor: Color(0xFFE9D48A),
              ),
              SizedBox(width: 7),
              _MiniPill(label: 'Lv.3'),
              Spacer(),
              _MiniPill(label: 'Today'),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xF2FFFFFF),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 14,
                    color: Color(0xFF8EAA80),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '搜索表达 / 场景',
                    style: TextStyle(fontSize: 13, color: Color(0xFFB8C0B0)),
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.suffix,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String suffix;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        color: const Color(0x2E000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            suffix,
            style: const TextStyle(fontSize: 11, color: Color(0xD7FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2E000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x2EFFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IntentTab extends StatelessWidget {
  const _IntentTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : color.withValues(alpha: 0.12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMasonry extends StatelessWidget {
  const _CardMasonry({
    required this.cards,
    required this.allCards,
    required this.onTapCard,
    required this.emptyEmoji,
    required this.emptyText,
    this.onSaveCard,
    this.onDismissCard,
    this.savedIds,
  });

  final List<ExpressionCardData> cards;
  final List<ExpressionCardData> allCards;
  final ValueChanged<ExpressionCardData> onTapCard;
  final ValueChanged<ExpressionCardData>? onSaveCard;
  final ValueChanged<ExpressionCardData>? onDismissCard;
  final Set<int>? savedIds;
  final String emptyEmoji;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Opacity(
        opacity: 0.45,
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Column(
            children: [
              Text(emptyEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                emptyText,
                style: const TextStyle(fontSize: 13, color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final List<ExpressionCardData> leftCards = <ExpressionCardData>[];
    final List<ExpressionCardData> rightCards = <ExpressionCardData>[];
    for (int i = 0; i < cards.length; i++) {
      if (i.isEven) {
        leftCards.add(cards[i]);
      } else {
        rightCards.add(cards[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftCards
                .map(
                  (ExpressionCardData card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExpressionCard(
                      card: card,
                      onTap: onTapCard,
                      onSave: onSaveCard,
                      onDismiss: onDismissCard,
                      isSaved:
                          savedIds?.contains(allCards.indexOf(card)) ?? false,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: rightCards
                .map(
                  (ExpressionCardData card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExpressionCard(
                      card: card,
                      onTap: onTapCard,
                      onSave: onSaveCard,
                      onDismiss: onDismissCard,
                      isSaved:
                          savedIds?.contains(allCards.indexOf(card)) ?? false,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ExpressionCard extends StatelessWidget {
  const _ExpressionCard({
    required this.card,
    required this.onTap,
    this.onSave,
    this.onDismiss,
    this.isSaved = false,
  });

  final ExpressionCardData card;
  final ValueChanged<ExpressionCardData> onTap;
  final ValueChanged<ExpressionCardData>? onSave;
  final ValueChanged<ExpressionCardData>? onDismiss;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(card),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x17000000),
              blurRadius: 14,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
              child: SizedBox(
                height: card.thumbHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              card.color.withValues(alpha: 0.84),
                              card.color.withValues(alpha: 0.56),
                              card.color.withValues(alpha: 0.28),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Image.network(
                        card.image,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) {
                              return const SizedBox.shrink();
                            },
                      ),
                    ),
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0x47000000)),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _previewWords(card.pattern),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0x1FFFFFFF),
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Row(
                        children: List<Widget>.generate(3, (int index) {
                          return Container(
                            width: 4,
                            height: 4,
                            margin: EdgeInsets.only(right: index == 2 ? 0 : 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < card.difficultyLevel
                                  ? const Color(0xBFFFFFFF)
                                  : const Color(0x33FFFFFF),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        height: 36,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0x38000000), Color(0x00000000)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      height: 1.35,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: List<Widget>.generate(card.progress.length, (
                      int index,
                    ) {
                      final ProgressState progress = card.progress[index];
                      final Color color = switch (progress) {
                        ProgressState.done => card.color,
                        ProgressState.current => card.color.withValues(
                          alpha: 0.78,
                        ),
                        ProgressState.locked => const Color(0xFFEAE6E0),
                        ProgressState.idle => card.color.withValues(
                          alpha: 0.22,
                        ),
                      };
                      return Expanded(
                        child: Container(
                          height: 2.5,
                          margin: EdgeInsets.only(
                            right: index == card.progress.length - 1 ? 0 : 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: color,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 10,
                        color: Color(0xFFFF8A20),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${card.learnerCount} 人学习',
                          style: const TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      if (onDismiss != null)
                        GestureDetector(
                          onTap: () => onDismiss!(card),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: textTertiary,
                          ),
                        ),
                      if (onSave != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onSave!(card),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 14,
                            color: isSaved ? card.color : textTertiary,
                          ),
                        ),
                      ],
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

  static String _previewWords(String text) {
    return text.split(' ').take(4).join(' ');
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder({this.icon, this.emoji, required this.title});

  final IconData? icon;
  final String? emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, size: 48, color: const Color(0xFFB8C0B0)),
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 82 + bottomInset,
          padding: EdgeInsets.fromLTRB(
            8,
            10,
            8,
            bottomInset > 0 ? bottomInset : 10,
          ),
          decoration: const BoxDecoration(
            color: Color(0xECFDFCF9),
            border: Border(
              top: BorderSide(color: Color(0xFFDDD9D0), width: 0.5),
            ),
          ),
          child: Row(
            children: List<Widget>.generate(bottomTabs.length, (int index) {
              final ({String label, IconData icon}) item = bottomTabs[index];
              final bool active = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 28,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0x143D5C3A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          size: 21,
                          color: active ? darkGreen : const Color(0xFFB8B0A6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.3,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active ? darkGreen : const Color(0xFFB8B0A6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
