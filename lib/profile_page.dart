import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_session.dart';
import 'edit_profile_page.dart';
import 'l10n/l10n.dart';
import 'login_page.dart';
import 'membership_page.dart';
import 'models/learning_stats_model.dart';
import 'notification_service.dart';
import 'pages/achievements_page.dart';
import 'pages/favorites_page.dart';
import 'pages/learning_report_page.dart';
import 'pages/offline_content_page.dart';
import 'pages/privacy_policy_page.dart';
import 'utils/app_cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showMembership = false;
  bool _reminderEnabled = NotificationService.instance.enabled;
  TimeOfDay _reminderTime = TimeOfDay(
    hour: NotificationService.instance.hour,
    minute: NotificationService.instance.minute,
  );
  bool _darkMode = false;
  bool _soundEnabled = true;
  int _activeSection = 0;

  Future<void> _openMembership(AppSession session) async {
    setState(() => _showMembership = true);
    await session.refreshMembershipStatus();
  }

  static const List<Color> _skillPalette = <Color>[
    Color(0xFF4A7C6F),
    Color(0xFF5A6FA8),
    Color(0xFFA0622A),
    Color(0xFF7B4EA0),
    Color(0xFF3D7FA8),
  ];

  List<_SkillLevel> _buildSkillLevels(LearningStatsModel stats) {
    return stats.skillLevels
        .asMap()
        .entries
        .map((entry) {
          final SkillLevelModel item = entry.value;
          return _SkillLevel(
            label: item.label,
            level: item.level,
            color:
                item.color ?? _skillPalette[entry.key % _skillPalette.length],
          );
        })
        .toList(growable: false);
  }

  List<_PracticeItem> _buildPracticeItems(
    LearningStatsModel stats,
    AppLocalizations l10n,
  ) {
    return stats.recentPractices
        .map((PracticeHistoryModel item) {
          return _PracticeItem(
            title: item.title.isEmpty ? l10n.practiceRecord : item.title,
            time: _formatPracticeTime(item, l10n),
            scoreLabel: item.score == null ? '--' : '${item.score}',
            emoji: item.emoji.isEmpty ? '🎯' : item.emoji,
          );
        })
        .toList(growable: false);
  }

  String _formatCountValue(
    int value, {
    required bool isStatsLoading,
    required bool hasStats,
    String suffix = '',
  }) {
    if (isStatsLoading && !hasStats) {
      return '...';
    }
    if (!hasStats && value == 0) {
      return '--';
    }
    return '$value$suffix';
  }

  String _formatPercentValue(
    int? value, {
    required bool isStatsLoading,
    required bool hasStats,
  }) {
    if (isStatsLoading && !hasStats) {
      return '...';
    }
    if (value == null) {
      return '--';
    }
    return '$value%';
  }

  String _formatPracticeTime(PracticeHistoryModel item, AppLocalizations l10n) {
    if (item.timeLabel != null && item.timeLabel!.trim().isNotEmpty) {
      return item.timeLabel!;
    }
    final DateTime? practicedAt = item.practicedAt;
    if (practicedAt == null) {
      return l10n.unknownTime;
    }

    final DateTime now = DateTime.now();
    final Duration diff = now.difference(practicedAt);
    final String hh = practicedAt.hour.toString().padLeft(2, '0');
    final String mm = practicedAt.minute.toString().padLeft(2, '0');
    if (diff.inDays == 0) {
      return l10n.todayTime('$hh:$mm');
    }
    if (diff.inDays == 1) {
      return l10n.yesterdayTime('$hh:$mm');
    }
    return l10n.monthDayTime(practicedAt.month, practicedAt.day, '$hh:$mm');
  }

  String _levelChipLabel(LearningStatsModel stats, AppLocalizations l10n) {
    final int? level = stats.level;
    if (level != null && level > 0) {
      return 'Lv.$level';
    }
    if (stats.experiencePoints > 0) {
      return '${stats.experiencePoints} XP';
    }
    return l10n.learningStatsTitle;
  }

  @override
  Widget build(BuildContext context) {
    final AppSession session = AppSessionScope.of(context);
    final AppLocalizations l10n = context.l10n;
    final LearningStatsModel stats = session.stats;
    _darkMode = session.themeMode == ThemeMode.dark;
    final bool isPro = session.isPro;
    final bool isStatsLoading = session.isStatsLoading;
    final bool hasStats = stats.hasOverviewData;
    final List<_SkillLevel> skillLevels = _buildSkillLevels(stats);
    final List<_PracticeItem> recentPractices = _buildPracticeItems(
      stats,
      l10n,
    );
    final List<({String label, bool active, bool today})> weekDays =
        List<({String label, bool active, bool today})>.generate(7, (int i) {
          final bool today = DateTime.now().weekday - 1 == i;
          return (
            label: l10n.weekdayShort(i),
            active: hasStats && stats.weekActivity[i],
            today: today,
          );
        });
    final List<_StatItem> learningStats = <_StatItem>[
      _StatItem(
        label: l10n.learningDays,
        value: _formatCountValue(
          stats.displayLearningDays,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
        color: const Color(0xFF4A7244),
        icon: Icons.calendar_month_rounded,
      ),
      _StatItem(
        label: l10n.totalPracticeCount,
        value: _formatCountValue(
          stats.totalSessions,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
        color: const Color(0xFF5A6FA8),
        icon: Icons.mic_rounded,
      ),
      _StatItem(
        label: l10n.accuracyRate,
        value: _formatPercentValue(
          stats.accuracyRate,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
        color: const Color(0xFFA0622A),
        icon: Icons.verified_rounded,
      ),
      _StatItem(
        label: l10n.currentStreak,
        value: _formatCountValue(
          stats.currentStreak,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
          suffix: l10n.dayUnit,
        ),
        color: const Color(0xFFC8955A),
        icon: Icons.local_fire_department_rounded,
      ),
    ];

    if (!session.isLoggedIn) {
      return LoginPage(
        onSubmit: session.signIn,
        isLoading: session.isAuthenticating,
        errorMessage: session.authErrorMessage,
      );
    }

    if (_showMembership) {
      return MembershipPage(
        onBack: () => setState(() => _showMembership = false),
        currentPlan: session.memberPlan,
        onSubscribe: (String planId) async {
          await session.changeMembership(planId);
          if (!mounted || session.membershipErrorMessage != null) {
            return;
          }
          setState(() {
            _showMembership = false;
          });
        },
        onRestorePurchases: session.restoreMembershipPurchases,
        isLoading: session.isUpdatingMembership,
        errorMessage: session.membershipErrorMessage,
      );
    }

    return Container(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 20),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xCCFFFFFF), Color(0x99A8D48A)],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AppCachedNetworkImage(
                          imageUrl: session.avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: const AppImagePlaceholder(
                            color: Color(0xFFDBE7D4),
                            icon: Icons.person_rounded,
                            iconColor: Colors.white,
                            iconSize: 34,
                          ),
                          errorWidget: const AppImagePlaceholder(
                            color: Color(0xFF87B076),
                            icon: Icons.person_rounded,
                            iconColor: Colors.white,
                            iconSize: 34,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.nickname,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPro ? l10n.speakEasyProMember : l10n.freeUser,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xD6FFFFFF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeaderChip(
                                label: _levelChipLabel(stats, l10n),
                                icon: Icons.auto_awesome_rounded,
                              ),
                              _HeaderChip(
                                label: isPro
                                    ? l10n.proActivated
                                    : l10n.upgradeToPro,
                                icon: Icons.workspace_premium_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x1AFFFFFF),
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _activeSection = 1),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x1AFFFFFF),
                      ),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x18000000),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x18FFFFFF)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderMetric(
                              value: _formatCountValue(
                                stats.totalSessions,
                                isStatsLoading: isStatsLoading,
                                hasStats: hasStats,
                              ),
                              label: l10n.totalPracticeShort,
                            ),
                          ),
                          Expanded(
                            child: _HeaderMetric(
                              value: _formatCountValue(
                                stats.currentStreak,
                                isStatsLoading: isStatsLoading,
                                hasStats: hasStats,
                              ),
                              label: l10n.consecutiveDays,
                            ),
                          ),
                          Expanded(
                            child: _HeaderMetric(
                              value: _formatCountValue(
                                stats.bestScore,
                                isStatsLoading: isStatsLoading,
                                hasStats: hasStats,
                              ),
                              label: l10n.bestScore,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: weekDays.map((day) {
                          final Color bg = day.today
                              ? const Color(0xFFFFF0C4)
                              : day.active
                              ? const Color(0xFFCAE4BE)
                              : const Color(0x33FFFFFF);
                          final Color iconColor = day.today
                              ? const Color(0xFF6D511F)
                              : day.active
                              ? const Color(0xFF294423)
                              : const Color(0xD6EFF6E7);
                          return Column(
                            children: [
                              Text(
                                day.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xD6FFFFFF),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: bg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  day.active
                                      ? Icons.check_rounded
                                      : Icons.remove_rounded,
                                  size: 14,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EFE9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _SegmentChip(
                  label: l10n.overview,
                  active: _activeSection == 0,
                  onTap: () => setState(() => _activeSection = 0),
                ),
                _SegmentChip(
                  label: l10n.settings,
                  active: _activeSection == 1,
                  onTap: () => setState(() => _activeSection = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: _activeSection == 0
                  ? _buildOverview(
                      session: session,
                      isPro: isPro,
                      learningStats: learningStats,
                      isStatsLoading: isStatsLoading,
                      hasStats: hasStats,
                      skillLevels: skillLevels,
                      recentPractices: recentPractices,
                    )
                  : _buildSettings(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOverview({
    required AppSession session,
    required bool isPro,
    required List<_StatItem> learningStats,
    required bool isStatsLoading,
    required bool hasStats,
    required List<_SkillLevel> skillLevels,
    required List<_PracticeItem> recentPractices,
  }) {
    return <Widget>[
      _SectionLabel(title: context.l10n.learningOverview),
      if (isStatsLoading && !hasStats)
        _StatsPanelState(
          icon: Icons.sync_rounded,
          title: context.l10n.learningStatsLoading,
          subtitle: context.l10n.syncingLearningData,
        )
      else if (!hasStats)
        _StatsPanelState(
          icon: session.statsErrorMessage == null
              ? Icons.insights_outlined
              : Icons.cloud_off_rounded,
          title: session.statsErrorMessage == null
              ? context.l10n.noLearningStats
              : context.l10n.learningStatsUnavailable,
          subtitle:
              session.statsErrorMessage ??
              context.l10n.learningStatsAfterPracticeHint,
        )
      else
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: learningStats.map((item) => _StatCard(item: item)).toList(),
        ),
      const SizedBox(height: 20),
      _SectionLabel(title: context.l10n.skillDistribution),
      if (skillLevels.isEmpty)
        _StatsPanelState(
          icon: isStatsLoading && !hasStats
              ? Icons.sync_rounded
              : Icons.bar_chart_rounded,
          title: isStatsLoading && !hasStats
              ? context.l10n.skillDistributionLoading
              : context.l10n.noSkillDistribution,
          subtitle: context.l10n.skillDistributionHint,
        )
      else
        Container(
          decoration: _panelDecoration(),
          child: Column(
            children: skillLevels.map((item) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${item.level}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.level / 100,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF2EFEA),
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      const SizedBox(height: 20),
      _SectionLabel(title: context.l10n.recentPractice),
      if (recentPractices.isEmpty)
        _StatsPanelState(
          icon: isStatsLoading && !hasStats
              ? Icons.sync_rounded
              : Icons.history_rounded,
          title: isStatsLoading && !hasStats
              ? context.l10n.recentPracticeLoading
              : context.l10n.noPracticeRecords,
          subtitle: context.l10n.recentPracticeHint,
        )
      else
        Container(
          decoration: _panelDecoration(),
          child: Column(
            children: List<Widget>.generate(recentPractices.length, (
              int index,
            ) {
              final item = recentPractices[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: index == 0 ? Colors.transparent : separatorColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.scoreLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      const SizedBox(height: 20),
      _MenuGroup(
        title: context.l10n.accountAndMembership,
        children: [
          _MenuTile(
            icon: Icons.workspace_premium_rounded,
            color: isPro ? const Color(0xFFC8955A) : const Color(0xFFABA39A),
            label: isPro ? context.l10n.proMember : context.l10n.upgradeToPro,
            subtitle: isPro
                ? context.l10n.viewMembershipBenefits
                : context.l10n.unlockAllFeatures,
            badge: isPro ? context.l10n.proActivated : context.l10n.upgrade,
            badgeColor: isPro ? const Color(0xFFC8955A) : primaryGreen,
            onTap: () => _openMembership(session),
          ),
          _MenuTile(
            icon: Icons.credit_card_rounded,
            color: const Color(0xFF5A6FA8),
            label: context.l10n.subscriptionManagement,
            subtitle: isPro
                ? context.l10n.manageSubscriptionBilling
                : context.l10n.viewSubscriptionPlans,
            onTap: () => _openMembership(session),
          ),
          _MenuTile(
            icon: Icons.person_outline_rounded,
            color: Color(0xFF4A7244),
            label: context.l10n.editProfile,
            subtitle: context.l10n.editAvatarNickname,
          ),
        ],
      ),
      _MenuGroup(
        title: context.l10n.learningRelated,
        children: [
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF4A7244),
            label: context.l10n.learningReport,
            subtitle: context.l10n.viewDetailedLearningData,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const LearningReportPage(),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.favorite_border_rounded,
            color: const Color(0xFFE06B6B),
            label: context.l10n.myFavorites,
            subtitle: context.l10n.favoritePatternsAndScenes,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const FavoritesPage(),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.download_rounded,
            color: const Color(0xFF5A6FA8),
            label: context.l10n.offlineContent,
            subtitle: context.l10n.manageOfflineScenePacks,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const OfflineContentPage(),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFFC8955A),
            label: context.l10n.achievements,
            subtitle: context.l10n.viewUnlockedAchievements,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const AchievementsPage(),
                ),
              );
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSettings() {
    return <Widget>[
      _MenuGroup(
        title: context.l10n.preferences,
        children: [
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            color: const Color(0xFF4A7244),
            label: context.l10n.dailyReminder,
            trailing: Switch.adaptive(
              value: _reminderEnabled,
              activeThumbColor: primaryGreen,
              onChanged: (bool value) async {
                await NotificationService.instance.setEnabled(value: value);
                if (!mounted) {
                  return;
                }
                setState(() => _reminderEnabled = value);
              },
            ),
          ),
          if (_reminderEnabled)
            _MenuTile(
              icon: Icons.access_time_rounded,
              color: const Color(0xFF4A7244),
              label: context.l10n.reminderTime(
                '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textSecondary,
              ),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime,
                );
                if (picked == null) {
                  return;
                }
                await NotificationService.instance.setTime(
                  hour: picked.hour,
                  minute: picked.minute,
                );
                if (!mounted) {
                  return;
                }
                setState(() => _reminderTime = picked);
              },
            ),
          _MenuTile(
            icon: Icons.dark_mode_outlined,
            color: const Color(0xFF7B4EA0),
            label: context.l10n.darkMode,
            trailing: Switch(
              value: _darkMode,
              onChanged: (bool value) async {
                final AppSession session = AppSessionScope.of(context);
                await session.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
                setState(() => _darkMode = value);
              },
              activeThumbColor: primaryGreen,
            ),
          ),
          _MenuTile(
            icon: Icons.volume_up_outlined,
            color: const Color(0xFF3D7FA8),
            label: context.l10n.soundEffects,
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (bool value) => setState(() => _soundEnabled = value),
              activeThumbColor: primaryGreen,
            ),
          ),
          _MenuTile(
            icon: Icons.language_rounded,
            color: Color(0xFFA0622A),
            label: context.l10n.interfaceLanguage,
            value: context.l10n.simplifiedChinese,
          ),
          _MenuTile(
            icon: Icons.shield_outlined,
            color: Color(0xFF5A6FA8),
            label: context.l10n.privacySettings,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
        ],
      ),
      _MenuGroup(
        title: context.l10n.helpAndSupport,
        children: [
          _MenuTile(
            icon: Icons.help_outline_rounded,
            color: Color(0xFF9A9289),
            label: context.l10n.helpFeedback,
          ),
          _MenuTile(
            icon: Icons.message_outlined,
            color: Color(0xFF9A9289),
            label: context.l10n.contactUs,
          ),
          _MenuTile(
            icon: Icons.star_border_rounded,
            color: Color(0xFFFFB83C),
            label: context.l10n.rateUs,
          ),
          _MenuTile(
            icon: Icons.logout_rounded,
            color: const Color(0xFFD46B6B),
            label: context.l10n.logout,
            danger: true,
            onTap: () {
              AppSessionScope.of(context).logout();
              setState(() {
                _activeSection = 0;
                _showMembership = false;
              });
            },
          ),
        ],
      ),
    ];
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0ECE6)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 12,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x24000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xD6FFFFFF)),
        ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? textPrimary : textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textTertiary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const Spacer(),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatsPanelState extends StatelessWidget {
  const _StatsPanelState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: title),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0ECE6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.value,
    this.badge,
    this.badgeColor,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final String? value;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: separatorColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0x15D46B6B)
                    : color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: danger ? const Color(0xFFD46B6B) : color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: danger ? const Color(0xFFD46B6B) : textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 11, color: textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? primaryGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value!,
                  style: const TextStyle(fontSize: 12, color: textTertiary),
                ),
              ),
            trailing ??
                (danger
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFD0CBC3),
                      )),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _SkillLevel {
  const _SkillLevel({
    required this.label,
    required this.level,
    required this.color,
  });

  final String label;
  final int level;
  final Color color;
}

class _PracticeItem {
  const _PracticeItem({
    required this.title,
    required this.time,
    required this.scoreLabel,
    required this.emoji,
  });

  final String title;
  final String time;
  final String scoreLabel;
  final String emoji;
}
