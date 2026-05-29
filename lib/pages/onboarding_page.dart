import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/storage_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final void Function({
    required List<String> goals,
    required int level,
    required int dailyMinutes,
  })
  onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _stepCount = 4;

  static const List<_AssessmentSceneOption> _sceneOptions =
      <_AssessmentSceneOption>[
        _AssessmentSceneOption(
          title: '英语面试',
          subtitle: '自我介绍、项目经历、优势弱点、压力追问',
          outcome: '优先练面试回答',
          primaryRoute: '情景学习：英语面试',
          expressionRoute: '推荐表达：高频面试句架',
          sceneId: 'job_interview',
          icon: Icons.work_outline_rounded,
          color: Color(0xFF4A6F8F),
        ),
        _AssessmentSceneOption(
          title: '入职介绍',
          subtitle: '新团队自我介绍、职责说明、优先级确认',
          outcome: '优先练入职沟通',
          primaryRoute: '情景学习：入职介绍',
          expressionRoute: '推荐表达：职场开场与说明',
          sceneId: 'onboarding_introduction',
          icon: Icons.badge_outlined,
          color: Color(0xFF4A7244),
        ),
        _AssessmentSceneOption(
          title: '工作沟通',
          subtitle: '会议发言、项目对齐、解释延期、争取支持',
          outcome: '优先练工作沟通',
          primaryRoute: '情景学习：会议与项目协作',
          expressionRoute: '推荐表达：解释、推进、确认',
          sceneId: 'onboarding_introduction',
          icon: Icons.groups_2_outlined,
          color: Color(0xFFA0622A),
        ),
        _AssessmentSceneOption(
          title: '日常服务',
          subtitle: '点单、出行、购物、酒店、问路和求助',
          outcome: '优先练日常服务',
          primaryRoute: '情景学习：生活服务场景',
          expressionRoute: '推荐表达：短句开口与确认',
          icon: Icons.local_cafe_outlined,
          color: Color(0xFF3D7FA8),
        ),
      ];

  static const List<_DiagnosticLevelOption> _diagnosticOptions =
      <_DiagnosticLevelOption>[
        _DiagnosticLevelOption(
          title: '只能蹦关键词',
          subtitle: '知道想表达什么，但还组不成完整句',
          signal: '需要先建立可套用句架',
          level: 1,
          targetLevel: 'L1',
          color: Color(0xFF7A5C3A),
        ),
        _DiagnosticLevelOption(
          title: '能说简单句',
          subtitle: '能回答，但停顿多，遇到追问容易卡住',
          signal: '需要补连续回答结构',
          level: 2,
          targetLevel: 'L2',
          color: Color(0xFF4A607A),
        ),
        _DiagnosticLevelOption(
          title: '能完整说明',
          subtitle: '意思说得清，但语气和连接不够自然',
          signal: '需要练地道连接和追问承接',
          level: 3,
          targetLevel: 'L3',
          color: Color(0xFF4A6741),
        ),
        _DiagnosticLevelOption(
          title: '想更像职场英语',
          subtitle: '表达基本流畅，想提升说服力和细节层次',
          signal: '需要强化高级表达和个性化素材',
          level: 4,
          targetLevel: 'L3+',
          color: Color(0xFF7B4EA0),
        ),
      ];

  static const List<_DailyGoalOption> _dailyGoalOptions = <_DailyGoalOption>[
    _DailyGoalOption(label: '5 分钟', description: '保持手感', minutes: 5),
    _DailyGoalOption(
      label: '15 分钟',
      description: '稳定推进',
      minutes: 15,
      badge: '推荐',
    ),
    _DailyGoalOption(label: '30 分钟', description: '集中突破', minutes: 30),
  ];

  final PageController _pageController = PageController();
  final Set<int> _selectedBlockerIndexes = <int>{};

  int _currentPage = 0;
  int? _selectedSceneIndex;
  int? _selectedDiagnosticIndex;
  int _selectedDailyMinutes = 15;

  bool get _canContinue {
    return switch (_currentPage) {
      0 => _selectedSceneIndex != null,
      1 => _selectedBlockerIndexes.isNotEmpty,
      2 => _selectedDiagnosticIndex != null,
      _ => true,
    };
  }

  _AssessmentSceneOption? get _selectedScene {
    final int? index = _selectedSceneIndex;
    if (index == null) {
      return null;
    }
    return _sceneOptions[index];
  }

  _DiagnosticLevelOption? get _selectedDiagnostic {
    final int? index = _selectedDiagnosticIndex;
    if (index == null) {
      return null;
    }
    return _diagnosticOptions[index];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (!_canContinue) {
      return;
    }
    if (_currentPage < _stepCount - 1) {
      await _goToPage(_currentPage + 1);
      return;
    }

    final _AssessmentSceneOption scene = _selectedScene ?? _sceneOptions.first;
    final _DiagnosticLevelOption diagnostic =
        _selectedDiagnostic ?? _diagnosticOptions[1];
    final List<String> blockers = intents
        .asMap()
        .entries
        .where((MapEntry<int, IntentData> entry) {
          return _selectedBlockerIndexes.contains(entry.key);
        })
        .map((MapEntry<int, IntentData> entry) => entry.value.label)
        .toList(growable: false);
    final List<String> goals = <String>{
      scene.outcome,
      ...blockers,
      diagnostic.signal,
      '首评目标：${scene.title} ${diagnostic.targetLevel}',
    }.toList(growable: false);

    widget.onComplete(
      goals: goals,
      level: diagnostic.level,
      dailyMinutes: _selectedDailyMinutes,
    );
    unawaited(_persistLearningRoute(scene, diagnostic));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          children: [
            _AssessmentTopBar(
              currentPage: _currentPage,
              stepCount: _stepCount,
              onBack: _currentPage == 0
                  ? null
                  : () => _goToPage(_currentPage - 1),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int value) {
                  setState(() => _currentPage = value);
                },
                children: [
                  _buildSceneStep(),
                  _buildBlockerStep(),
                  _buildDiagnosticStep(),
                  _buildPlanStep(),
                ],
              ),
            ),
            _AssessmentFooter(
              enabled: _canContinue,
              label: _currentPage == _stepCount - 1 ? '进入学习路径' : '继续',
              onPressed: _handlePrimaryAction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const _StepIntro(
          eyebrow: '首评 01',
          title: '先选最需要突破的英语场景',
          subtitle: '评测会把你的答案转成一条学习路径：先练场景，再补推荐表达。',
        ),
        const SizedBox(height: 18),
        for (int index = 0; index < _sceneOptions.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SceneOptionTile(
              selectionKey: ValueKey<String>('onboarding_scene_$index'),
              option: _sceneOptions[index],
              selected: _selectedSceneIndex == index,
              onTap: () => setState(() => _selectedSceneIndex = index),
            ),
          ),
      ],
    );
  }

  Widget _buildBlockerStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const _StepIntro(
          eyebrow: '首评 02',
          title: '这类场景里最容易卡在哪里',
          subtitle: '可以多选。系统会据此调整推荐表达的优先级。',
        ),
        const SizedBox(height: 18),
        for (int index = 0; index < intents.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BlockerOptionTile(
              selectionKey: ValueKey<String>('onboarding_blocker_$index'),
              data: intents[index],
              description: _blockerDescription(intents[index].label),
              selected: _selectedBlockerIndexes.contains(index),
              onTap: () {
                setState(() {
                  if (_selectedBlockerIndexes.contains(index)) {
                    _selectedBlockerIndexes.remove(index);
                  } else {
                    _selectedBlockerIndexes.add(index);
                  }
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDiagnosticStep() {
    final _AssessmentSceneOption scene = _selectedScene ?? _sceneOptions.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        _StepIntro(
          eyebrow: '首评 03',
          title: '如果现在进入「${scene.title}」',
          subtitle: '选一个最接近你真实输出状态的描述。',
        ),
        const SizedBox(height: 18),
        for (int index = 0; index < _diagnosticOptions.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DiagnosticOptionTile(
              selectionKey: ValueKey<String>('onboarding_diagnostic_$index'),
              option: _diagnosticOptions[index],
              selected: _selectedDiagnosticIndex == index,
              onTap: () => setState(() => _selectedDiagnosticIndex = index),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanStep() {
    final _AssessmentSceneOption scene = _selectedScene ?? _sceneOptions.first;
    final _DiagnosticLevelOption diagnostic =
        _selectedDiagnostic ?? _diagnosticOptions[1];
    final List<IntentData> selectedBlockers = intents
        .asMap()
        .entries
        .where((MapEntry<int, IntentData> entry) {
          return _selectedBlockerIndexes.contains(entry.key);
        })
        .map((MapEntry<int, IntentData> entry) => entry.value)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const _StepIntro(
          eyebrow: '首评结果',
          title: '你的第一条学习路径已生成',
          subtitle: '进入首页后，会优先从这个路径开始积累学习记录和收藏。',
        ),
        const SizedBox(height: 18),
        _PlanSummary(
          scene: scene,
          diagnostic: diagnostic,
          blockers: selectedBlockers,
        ),
        const SizedBox(height: 18),
        const _SectionTitle(title: '每天练多久'),
        const SizedBox(height: 10),
        _DailyGoalSelector(
          selectedMinutes: _selectedDailyMinutes,
          options: _dailyGoalOptions,
          onChanged: (int minutes) {
            setState(() => _selectedDailyMinutes = minutes);
          },
        ),
      ],
    );
  }

  static String _blockerDescription(String value) {
    return switch (value) {
      '不会开口' => '需要第一句和安全开场',
      '不会表达' => '需要把中文想法转成英文句架',
      '说不下去' => '需要承接追问和延展补充',
      '一慌就乱' => '需要短句兜底和节奏稳定',
      '说得更好' => '需要更自然、更有说服力',
      _ => '用于调整后续推荐',
    };
  }

  Future<void> _persistLearningRoute(
    _AssessmentSceneOption scene,
    _DiagnosticLevelOption diagnostic,
  ) async {
    final String sceneId = scene.sceneId.trim();
    if (sceneId.isEmpty) {
      return;
    }
    final String targetLevel = switch (diagnostic.level) {
      1 => 'beginner',
      2 => 'intermediate',
      _ => 'advanced',
    };
    await InterviewWikiStore(
      sceneId: sceneId,
    ).saveSelectedTargetLevel(targetLevel);
    await StorageService.instance.saveInterviewHomeSceneSelection(
      InterviewHomeSceneSelectionStorageModel(
        selectedSceneIds: <String>[sceneId],
        activeSceneId: sceneId,
      ),
    );
  }
}

class _AssessmentTopBar extends StatelessWidget {
  const _AssessmentTopBar({
    required this.currentPage,
    required this.stepCount,
    required this.onBack,
  });

  final int currentPage;
  final int stepCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : IconButton(
                    tooltip: '返回上一步',
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2EFEA),
                      foregroundColor: textPrimary,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SpeakEasy 首评',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: (currentPage + 1) / stepCount,
                    backgroundColor: const Color(0xFFEDE8DF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              '${currentPage + 1}/$stepCount',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentFooter extends StatelessWidget {
  const _AssessmentFooter({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: const BoxDecoration(
        color: appBackground,
        border: Border(top: BorderSide(color: separatorColor)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey<String>('onboarding_primary_action'),
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: primaryGreen,
            disabledBackgroundColor: const Color(0xFFD9D3CB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          icon: Icon(
            label == '进入学习路径'
                ? Icons.arrow_forward_rounded
                : Icons.check_rounded,
            size: 19,
          ),
          label: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _SceneOptionTile extends StatelessWidget {
  const _SceneOptionTile({
    required this.selectionKey,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final Key selectionKey;
  final _AssessmentSceneOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableSurface(
      selectionKey: selectionKey,
      selected: selected,
      color: option.color,
      onTap: onTap,
      child: Row(
        children: [
          _OptionIcon(icon: option.icon, color: option.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  option.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SelectedMark(selected: selected, color: option.color),
        ],
      ),
    );
  }
}

class _BlockerOptionTile extends StatelessWidget {
  const _BlockerOptionTile({
    required this.selectionKey,
    required this.data,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final Key selectionKey;
  final IntentData data;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableSurface(
      selectionKey: selectionKey,
      selected: selected,
      color: data.color,
      onTap: onTap,
      child: Row(
        children: [
          _OptionIcon(icon: data.icon, color: data.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SelectedMark(selected: selected, color: data.color),
        ],
      ),
    );
  }
}

class _DiagnosticOptionTile extends StatelessWidget {
  const _DiagnosticOptionTile({
    required this.selectionKey,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final Key selectionKey;
  final _DiagnosticLevelOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableSurface(
      selectionKey: selectionKey,
      selected: selected,
      color: option.color,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: option.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              option.targetLevel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: option.color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  option.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SelectedMark(selected: selected, color: option.color),
        ],
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    required this.scene,
    required this.diagnostic,
    required this.blockers,
  });

  final _AssessmentSceneOption scene;
  final _DiagnosticLevelOption diagnostic;
  final List<IntentData> blockers;

  @override
  Widget build(BuildContext context) {
    final List<IntentData> visibleBlockers = blockers.isEmpty
        ? intents.take(1).toList(growable: false)
        : blockers.take(3).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F1F2937),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _OptionIcon(icon: scene.icon, color: scene.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${scene.title} · ${diagnostic.targetLevel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      diagnostic.signal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PlanRouteRow(
            icon: Icons.menu_book_rounded,
            color: scene.color,
            title: scene.primaryRoute,
            subtitle: '先在完整对话里建立语境和回答节奏',
          ),
          const SizedBox(height: 12),
          _PlanRouteRow(
            icon: Icons.record_voice_over_rounded,
            color: primaryGreen,
            title: scene.expressionRoute,
            subtitle: '再把高频句架加入可复用表达库',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final IntentData blocker in visibleBlockers)
                _FocusChip(label: blocker.label, color: blocker.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanRouteRow extends StatelessWidget {
  const _PlanRouteRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyGoalSelector extends StatelessWidget {
  const _DailyGoalSelector({
    required this.selectedMinutes,
    required this.options,
    required this.onChanged,
  });

  final int selectedMinutes;
  final List<_DailyGoalOption> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 360;
        if (compact) {
          return Column(
            children: [
              for (final _DailyGoalOption option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DailyGoalCard(
                    option: option,
                    selected: selectedMinutes == option.minutes,
                    onTap: () => onChanged(option.minutes),
                  ),
                ),
            ],
          );
        }
        return Row(
          children: [
            for (int index = 0; index < options.length; index += 1)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == options.length - 1 ? 0 : 10,
                  ),
                  child: _DailyGoalCard(
                    option: options[index],
                    selected: selectedMinutes == options[index].minutes,
                    onTap: () => onChanged(options[index].minutes),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _DailyGoalOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 118,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEEF5EA) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? primaryGreen : borderColor,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 22,
                  child: option.badge == null
                      ? null
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0CC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              option.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8B6128),
                              ),
                            ),
                          ),
                        ),
                ),
                const Spacer(),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: selected ? primaryGreen : textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  option.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableSurface extends StatelessWidget {
  const _SelectableSurface({
    required this.selectionKey,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  final Key selectionKey;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: selectionKey,
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.10) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : borderColor,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F1F2937),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _OptionIcon extends StatelessWidget {
  const _OptionIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? color : const Color(0xFFD0CBC4),
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: textPrimary,
      ),
    );
  }
}

class _AssessmentSceneOption {
  const _AssessmentSceneOption({
    required this.title,
    required this.subtitle,
    required this.outcome,
    required this.primaryRoute,
    required this.expressionRoute,
    this.sceneId = '',
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String outcome;
  final String primaryRoute;
  final String expressionRoute;
  final String sceneId;
  final IconData icon;
  final Color color;
}

class _DiagnosticLevelOption {
  const _DiagnosticLevelOption({
    required this.title,
    required this.subtitle,
    required this.signal,
    required this.level,
    required this.targetLevel,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String signal;
  final int level;
  final String targetLevel;
  final Color color;
}

class _DailyGoalOption {
  const _DailyGoalOption({
    required this.label,
    required this.description,
    required this.minutes,
    this.badge,
  });

  final String label;
  final String description;
  final int minutes;
  final String? badge;
}
