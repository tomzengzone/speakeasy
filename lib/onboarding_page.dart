import 'package:flutter/material.dart';

import 'app_models.dart';
import 'l10n/l10n.dart';

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
  static const Map<String, String> _goalDescriptions = <String, String>{
    '不会开口': '第一句话总是说不出口',
    '不会表达': '脑子里有想法但说不出来',
    '说不下去': '开口了但很快就卡住',
    '一慌就乱': '一紧张就什么都忘了',
    '说得更好': '想让表达更地道自然',
  };

  static const List<_LevelOption> _levelOptions = <_LevelOption>[
    _LevelOption(
      label: '入门',
      description: '日常单词认识，但很难开口说',
      level: 1,
      color: Color(0xFF7A5C3A),
    ),
    _LevelOption(
      label: '初级',
      description: '能说简单句子，但不够流利',
      level: 2,
      color: Color(0xFF4A607A),
    ),
    _LevelOption(
      label: '中级',
      description: '可以日常交流，但表达不自然',
      level: 3,
      color: Color(0xFF4A6741),
    ),
    _LevelOption(
      label: '高级',
      description: '表达流利，想进一步提升地道度',
      level: 4,
      color: Color(0xFF7B4EA0),
    ),
  ];

  static const List<_DailyGoalOption> _dailyGoalOptions = <_DailyGoalOption>[
    _DailyGoalOption(label: '5 分钟', description: '随手练练', minutes: 5),
    _DailyGoalOption(
      label: '15 分钟',
      description: '稳步提升',
      minutes: 15,
      badge: '最受欢迎',
    ),
    _DailyGoalOption(label: '30 分钟', description: '快速突破', minutes: 30),
  ];

  final PageController _pageController = PageController();
  final Set<int> _selectedGoalIndexes = <int>{};

  int _currentPage = 0;
  int? _selectedLevel;
  int? _selectedDailyMinutes;

  bool get _canContinue {
    return switch (_currentPage) {
      0 => _selectedGoalIndexes.isNotEmpty,
      1 => _selectedLevel != null,
      _ => _selectedDailyMinutes != null,
    };
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
    if (_currentPage < 2) {
      await _goToPage(_currentPage + 1);
      return;
    }
    widget.onComplete(
      goals: intents
          .asMap()
          .entries
          .where((MapEntry<int, IntentData> entry) {
            return _selectedGoalIndexes.contains(entry.key);
          })
          .map((MapEntry<int, IntentData> entry) => entry.value.label)
          .toList(),
      level: _selectedLevel!,
      dailyMinutes: _selectedDailyMinutes!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      backgroundColor: appBackground,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 260,
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
                    stops: [0, 0.36, 0.74, 1],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.82, -0.92),
                    radius: 0.94,
                    colors: [Color(0x52D8F1B9), Color(0x00D8F1B9)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: _currentPage == 0
                            ? null
                            : IconButton(
                                onPressed: () => _goToPage(_currentPage - 1),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0x14FFFFFF),
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List<Widget>.generate(3, (int index) {
                                final bool active = index == _currentPage;
                                final bool passed = index < _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin: EdgeInsets.only(
                                    right: index == 2 ? 0 : 8,
                                  ),
                                  width: active ? 28 : 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: active || passed
                                        ? Colors.white
                                        : const Color(0x52FFFFFF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.stepProgress(_currentPage + 1, 3),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xD9FFFFFF),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44, height: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int value) {
                      setState(() {
                        _currentPage = value;
                      });
                    },
                    children: [
                      _buildGoalStep(l10n),
                      _buildLevelStep(l10n),
                      _buildDailyGoalStep(l10n),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canContinue ? _handlePrimaryAction : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: const Color(0xFFD9D3CB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 2 ? l10n.startLearning : l10n.nextStep,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildGoalStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        _StepHeader(title: l10n.goalStepTitle, subtitle: l10n.goalStepSubtitle),
        const SizedBox(height: 24),
        ...intents.asMap().entries.map((MapEntry<int, IntentData> entry) {
          final bool selected = _selectedGoalIndexes.contains(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _GoalCard(
              data: entry.value,
              description: l10n.onboardingGoalDescription(
                _goalDescriptions[entry.value.label] ?? '',
              ),
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedGoalIndexes.remove(entry.key);
                  } else {
                    _selectedGoalIndexes.add(entry.key);
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLevelStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        _StepHeader(
          title: l10n.levelStepTitle,
          subtitle: l10n.levelStepSubtitle,
        ),
        const SizedBox(height: 24),
        ..._levelOptions.map((_LevelOption option) {
          final bool selected = _selectedLevel == option.level;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _LevelCard(
              option: option,
              selected: selected,
              onTap: () {
                setState(() {
                  _selectedLevel = option.level;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDailyGoalStep(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        _StepHeader(
          title: l10n.dailyGoalStepTitle,
          subtitle: l10n.dailyGoalStepSubtitle,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(_dailyGoalOptions.length, (
            int index,
          ) {
            final _DailyGoalOption option = _dailyGoalOptions[index];
            final bool selected = _selectedDailyMinutes == option.minutes;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == _dailyGoalOptions.length - 1 ? 0 : 12,
                ),
                child: _DailyGoalCard(
                  option: option,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedDailyMinutes = option.minutes;
                    });
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.9,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.data,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IntentData data;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? data.color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? data.color : borderColor,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.08 : 0.04),
                blurRadius: selected ? 28 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.intentLabel(data.label),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? data.color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? data.color : const Color(0xFFD0CBC4),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LevelOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected
                ? option.color.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? option.color : borderColor,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.08 : 0.04),
                blurRadius: selected ? 26 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    l10n.difficultyLabel(option.label),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: option.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.difficultyLabel(option.label),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.levelDescription(option.description),
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? option.color : const Color(0xFFD0CBC4),
                    width: 1.6,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: selected ? 12 : 0,
                    height: selected ? 12 : 0,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final AppLocalizations l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
          decoration: BoxDecoration(
            color: selected
                ? primaryGreen.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? primaryGreen : borderColor,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.08 : 0.04),
                blurRadius: selected ? 26 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            height: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (option.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7E8B3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.dailyGoalBadge(option.badge!),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B6128),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 26),
                const Spacer(),
                Text(
                  l10n.dailyGoalLabel(option.label),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: selected ? primaryGreen : textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.dailyGoalDescription(option.description),
                  style: const TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? primaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? primaryGreen : const Color(0xFFD0CBC4),
                      width: 1.6,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelOption {
  const _LevelOption({
    required this.label,
    required this.description,
    required this.level,
    required this.color,
  });

  final String label;
  final String description;
  final int level;
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
