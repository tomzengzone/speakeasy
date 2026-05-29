import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/application/profile/notification_preferences_coordinator.dart';
import 'package:speakeasy/core/routing/app_routes.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/pages/login_page.dart';
import 'package:speakeasy/pages/membership_page.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/storage_service.dart';
import 'package:speakeasy/utils/app_cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.completedSceneCount = 0,
    this.onOpenCompletedScenes,
  });

  final int completedSceneCount;
  final VoidCallback? onOpenCompletedScenes;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const NotificationPreferencesCoordinator
  _notificationPreferencesCoordinator = NotificationPreferencesCoordinator();

  bool _showMembership = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _darkMode = false;
  bool _soundEnabled = true;
  int _activeSection = 0;
  List<FavoriteExpressionStorageModel> _favoriteItems =
      const <FavoriteExpressionStorageModel>[];

  @override
  void initState() {
    super.initState();
    final NotificationPreferencesSnapshot reminderSettings =
        _notificationPreferencesCoordinator.loadSettings();
    _reminderEnabled = reminderSettings.enabled;
    _reminderTime = TimeOfDay(
      hour: reminderSettings.hour,
      minute: reminderSettings.minute,
    );
    _favoriteItems = _loadFavoriteItems();
  }

  Future<void> _openMembership(AppSession session) async {
    setState(() => _showMembership = true);
    await session.refreshMembershipStatus();
  }

  Future<void> _openFavorites() async {
    await Navigator.of(context).pushNamed(AppRoutes.favorites);
    if (!mounted) {
      return;
    }
    setState(() {
      _favoriteItems = _loadFavoriteItems();
    });
  }

  List<FavoriteExpressionStorageModel> _loadFavoriteItems() {
    final List<FavoriteExpressionStorageModel> items = StorageService.instance
        .getFavoriteExpressions()
        .where(
          (FavoriteExpressionStorageModel item) =>
              item.practiceText.trim().isNotEmpty,
        )
        .toList(growable: false);
    return items.toList()..sort(
      (FavoriteExpressionStorageModel a, FavoriteExpressionStorageModel b) =>
          b.savedAt.compareTo(a.savedAt),
    );
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
        .map((MapEntry<int, SkillLevelModel> entry) {
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

  String _formatMinutesValue(
    int value, {
    required bool isStatsLoading,
    required bool hasStats,
  }) {
    if (isStatsLoading && !hasStats) {
      return '...';
    }
    if (!hasStats && value == 0) {
      return '--';
    }
    if (value < 60) {
      return '$value 分钟';
    }
    final double hours = value / 60;
    return '${hours.toStringAsFixed(value % 60 == 0 ? 0 : 1)} 小时';
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
    final DateTime local = practicedAt.toLocal();
    final Duration diff = now.difference(local);
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    if (diff.inDays == 0) {
      return l10n.todayTime('$hh:$mm');
    }
    if (diff.inDays == 1) {
      return l10n.yesterdayTime('$hh:$mm');
    }
    return l10n.monthDayTime(local.month, local.day, '$hh:$mm');
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

  void _showPracticeDetails(
    PracticeHistoryModel practice,
    AppSession session,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: appBackground,
      builder: (BuildContext sheetContext) {
        return _PracticeDetailSheet(
          practice: practice,
          timeLabel: _formatPracticeTime(practice, l10n),
          onDelete: () async {
            Navigator.of(sheetContext).pop();
            await session.deleteRecentPracticeGroup(practice.title);
          },
        );
      },
    );
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

    final List<_ProfileMetric> headerMetrics = <_ProfileMetric>[
      _ProfileMetric(
        label: '练习',
        value: _formatCountValue(
          stats.totalSessions,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
      ),
      _ProfileMetric(
        label: '连续',
        value: _formatCountValue(
          stats.currentStreak,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
      ),
      _ProfileMetric(label: '收藏', value: '${_favoriteItems.length}'),
    ];

    return ColoredBox(
      color: appBackground,
      child: Column(
        children: [
          _ProfileHeader(
            nickname: session.nickname,
            avatarUrl: session.avatarUrl,
            levelLabel: _levelChipLabel(stats, l10n),
            planLabel: isPro ? l10n.proActivated : l10n.freeUser,
            isPro: isPro,
            metrics: headerMetrics,
            onEditProfile: () =>
                Navigator.of(context).pushNamed(AppRoutes.editProfile),
            onOpenSettings: () => setState(() => _activeSection = 2),
            onOpenMembership: () => _openMembership(session),
          ),
          _ProfileSectionTabs(
            activeIndex: _activeSection,
            onChanged: (int index) => setState(() => _activeSection = index),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: switch (_activeSection) {
                0 => _buildOverview(
                  session: session,
                  l10n: l10n,
                  isPro: isPro,
                  isStatsLoading: isStatsLoading,
                  hasStats: hasStats,
                  skillLevels: skillLevels,
                ),
                1 => _buildHistory(
                  session: session,
                  l10n: l10n,
                  isStatsLoading: isStatsLoading,
                  hasStats: hasStats,
                ),
                _ => _buildSettings(session),
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOverview({
    required AppSession session,
    required AppLocalizations l10n,
    required bool isPro,
    required bool isStatsLoading,
    required bool hasStats,
    required List<_SkillLevel> skillLevels,
  }) {
    final LearningStatsModel stats = session.stats;
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
        label: '学习时长',
        value: _formatMinutesValue(
          stats.totalMinutes,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
        color: const Color(0xFF7B4EA0),
        icon: Icons.timer_rounded,
      ),
    ];

    return <Widget>[
      _SubscriptionPanel(
        key: const ValueKey<String>('profile_subscription_panel'),
        isPro: isPro,
        planLabel: isPro ? l10n.proActivated : l10n.freeUser,
        onTap: () => _openMembership(session),
      ),
      const SizedBox(height: 20),
      _SectionLabel(title: l10n.learningOverview),
      if (isStatsLoading && !hasStats)
        _StatsPanelState(
          icon: Icons.sync_rounded,
          title: l10n.learningStatsLoading,
          subtitle: l10n.syncingLearningData,
        )
      else if (!hasStats)
        _StatsPanelState(
          icon: session.statsErrorMessage == null
              ? Icons.insights_outlined
              : Icons.cloud_off_rounded,
          title: session.statsErrorMessage == null
              ? l10n.noLearningStats
              : l10n.learningStatsUnavailable,
          subtitle:
              session.statsErrorMessage ?? l10n.learningStatsAfterPracticeHint,
        )
      else
        _MetricGrid(items: learningStats),
      const SizedBox(height: 20),
      _WeeklyRhythmPanel(
        stats: stats,
        isStatsLoading: isStatsLoading,
        hasStats: hasStats,
      ),
      const SizedBox(height: 20),
      _FavoritesSnapshot(
        key: const ValueKey<String>('profile_favorites_snapshot'),
        items: _favoriteItems,
        onOpenFavorites: () => unawaited(_openFavorites()),
      ),
      const SizedBox(height: 20),
      _SectionLabel(title: l10n.skillDistribution),
      if (skillLevels.isEmpty)
        _StatsPanelState(
          icon: isStatsLoading && !hasStats
              ? Icons.sync_rounded
              : Icons.bar_chart_rounded,
          title: isStatsLoading && !hasStats
              ? l10n.skillDistributionLoading
              : l10n.noSkillDistribution,
          subtitle: l10n.skillDistributionHint,
        )
      else
        _SkillDistributionPanel(skillLevels: skillLevels),
      const SizedBox(height: 20),
      _MenuGroup(
        title: '学习资产',
        children: [
          _MenuTile(
            key: const ValueKey<String>('profile_learning_report_tile'),
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF4A7244),
            label: l10n.learningReport,
            subtitle: l10n.viewDetailedLearningData,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.learningReport);
            },
          ),
          _MenuTile(
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFFC8955A),
            label: '已完成场景',
            subtitle: '查看已完成课程，进入简介页巩固复习',
            badge: '${widget.completedSceneCount}',
            badgeColor: const Color(0xFFC8955A),
            onTap: widget.onOpenCompletedScenes,
          ),
          _MenuTile(
            key: const ValueKey<String>('profile_offline_content_tile'),
            icon: Icons.download_rounded,
            color: const Color(0xFF5A6FA8),
            label: l10n.offlineContent,
            subtitle: l10n.manageOfflineScenePacks,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.offlineContent);
            },
          ),
          _MenuTile(
            key: const ValueKey<String>('profile_achievements_tile'),
            icon: Icons.military_tech_rounded,
            color: const Color(0xFFA0622A),
            label: l10n.achievements,
            subtitle: l10n.viewUnlockedAchievements,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.achievements);
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildHistory({
    required AppSession session,
    required AppLocalizations l10n,
    required bool isStatsLoading,
    required bool hasStats,
  }) {
    final LearningStatsModel stats = session.stats;
    final List<PracticeHistoryModel> practices = stats.recentPractices;

    return <Widget>[
      _SectionLabel(title: '学习历史'),
      _HistorySummary(
        totalSessions: _formatCountValue(
          stats.totalSessions,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
        totalMinutes: _formatMinutesValue(
          stats.totalMinutes,
          isStatsLoading: isStatsLoading,
          hasStats: hasStats,
        ),
        completedSceneCount: widget.completedSceneCount,
      ),
      const SizedBox(height: 18),
      _MenuGroup(
        title: '历史入口',
        children: [
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF4A7244),
            label: l10n.learningReport,
            subtitle: '查看阶段总结、优势和薄弱点',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.learningReport);
            },
          ),
          _MenuTile(
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFFC8955A),
            label: '已完成场景',
            subtitle: '回看完成过的情景任务',
            badge: '${widget.completedSceneCount}',
            badgeColor: const Color(0xFFC8955A),
            onTap: widget.onOpenCompletedScenes,
          ),
        ],
      ),
      _SectionLabel(title: l10n.recentPractice),
      if (practices.isEmpty)
        _StatsPanelState(
          icon: isStatsLoading && !hasStats
              ? Icons.sync_rounded
              : Icons.history_rounded,
          title: isStatsLoading && !hasStats
              ? l10n.recentPracticeLoading
              : l10n.noPracticeRecords,
          subtitle: l10n.recentPracticeHint,
        )
      else
        Column(
          children: practices
              .map(
                (PracticeHistoryModel practice) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryPracticeCard(
                    practice: practice,
                    timeLabel: _formatPracticeTime(practice, l10n),
                    onTap: () => _showPracticeDetails(practice, session, l10n),
                  ),
                ),
              )
              .toList(growable: false),
        ),
    ];
  }

  Future<void> _confirmDeleteAccount(AppSession session) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('注销账号'),
          content: const Text('注销后会删除你的账号与云端学习数据，本地登录状态也会清除。此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD46B6B),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('确认注销'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      await session.deleteAccount();
      if (!mounted) {
        return;
      }
      setState(() {
        _activeSection = 0;
        _showMembership = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('账号已注销')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('注销失败：${error.toString()}')));
    }
  }

  List<Widget> _buildSettings(AppSession session) {
    return <Widget>[
      _MenuGroup(
        title: context.l10n.accountAndMembership,
        children: [
          _MenuTile(
            key: const ValueKey<String>('profile_settings_edit_profile_tile'),
            icon: Icons.person_outline_rounded,
            color: const Color(0xFF4A7244),
            label: context.l10n.editProfile,
            subtitle: context.l10n.editAvatarNickname,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.editProfile);
            },
          ),
          _MenuTile(
            key: const ValueKey<String>('profile_settings_membership_tile'),
            icon: Icons.workspace_premium_rounded,
            color: session.isPro
                ? const Color(0xFFC8955A)
                : const Color(0xFF5A6FA8),
            label: context.l10n.subscriptionManagement,
            subtitle: session.isPro
                ? context.l10n.manageSubscriptionBilling
                : context.l10n.viewSubscriptionPlans,
            badge: session.isPro
                ? context.l10n.proActivated
                : context.l10n.upgrade,
            badgeColor: session.isPro ? const Color(0xFFC8955A) : primaryGreen,
            onTap: () => _openMembership(session),
          ),
          _MenuTile(
            key: const ValueKey<String>('profile_settings_favorites_tile'),
            icon: Icons.favorite_border_rounded,
            color: const Color(0xFFE06B6B),
            label: context.l10n.myFavorites,
            subtitle: '已收藏 ${_favoriteItems.length} 条表达',
            onTap: () => unawaited(_openFavorites()),
          ),
        ],
      ),
      _MenuGroup(
        title: context.l10n.preferences,
        children: [
          _MenuTile(
            key: const ValueKey<String>('profile_daily_reminder_tile'),
            icon: Icons.notifications_none_rounded,
            color: const Color(0xFF4A7244),
            label: context.l10n.dailyReminder,
            trailing: Switch.adaptive(
              key: const ValueKey<String>('profile_daily_reminder_switch'),
              value: _reminderEnabled,
              activeThumbColor: primaryGreen,
              onChanged: (bool value) async {
                final NotificationPreferencesSnapshot reminderSettings =
                    await _notificationPreferencesCoordinator
                        .setReminderEnabled(value: value);
                if (!mounted) {
                  return;
                }
                setState(() {
                  _reminderEnabled = reminderSettings.enabled;
                  _reminderTime = TimeOfDay(
                    hour: reminderSettings.hour,
                    minute: reminderSettings.minute,
                  );
                });
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
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime,
                );
                if (picked == null) {
                  return;
                }
                final NotificationPreferencesSnapshot reminderSettings =
                    await _notificationPreferencesCoordinator.setReminderTime(
                      hour: picked.hour,
                      minute: picked.minute,
                    );
                if (!mounted) {
                  return;
                }
                setState(() {
                  _reminderEnabled = reminderSettings.enabled;
                  _reminderTime = TimeOfDay(
                    hour: reminderSettings.hour,
                    minute: reminderSettings.minute,
                  );
                });
              },
            ),
          _MenuTile(
            key: const ValueKey<String>('profile_dark_mode_tile'),
            icon: Icons.dark_mode_outlined,
            color: const Color(0xFF7B4EA0),
            label: context.l10n.darkMode,
            trailing: Switch(
              key: const ValueKey<String>('profile_dark_mode_switch'),
              value: _darkMode,
              onChanged: (bool value) async {
                await session.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
                if (!mounted) {
                  return;
                }
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
            color: const Color(0xFFA0622A),
            label: context.l10n.interfaceLanguage,
            value: context.l10n.simplifiedChinese,
          ),
        ],
      ),
      _MenuGroup(
        title: context.l10n.helpAndSupport,
        children: [
          _MenuTile(
            icon: Icons.shield_outlined,
            color: const Color(0xFF5A6FA8),
            label: context.l10n.privacySettings,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
            },
          ),
          _MenuTile(
            icon: Icons.description_outlined,
            color: const Color(0xFF9A9289),
            label: '服务条款',
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.termsOfService);
            },
          ),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            color: const Color(0xFF9A9289),
            label: context.l10n.helpFeedback,
          ),
          _MenuTile(
            icon: Icons.message_outlined,
            color: const Color(0xFF9A9289),
            label: context.l10n.contactUs,
          ),
          _MenuTile(
            icon: Icons.delete_forever_outlined,
            color: const Color(0xFFD46B6B),
            label: '注销账号',
            subtitle: '删除账号与云端学习数据',
            danger: true,
            onTap: () => unawaited(_confirmDeleteAccount(session)),
          ),
          _MenuTile(
            key: const ValueKey<String>('profile_logout_button'),
            icon: Icons.logout_rounded,
            color: const Color(0xFFD46B6B),
            label: context.l10n.logout,
            danger: true,
            onTap: () {
              session.logout();
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
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nickname,
    required this.avatarUrl,
    required this.levelLabel,
    required this.planLabel,
    required this.isPro,
    required this.metrics,
    required this.onEditProfile,
    required this.onOpenSettings,
    required this.onOpenMembership,
  });

  final String nickname;
  final String avatarUrl;
  final String levelLabel;
  final String planLabel;
  final bool isPro;
  final List<_ProfileMetric> metrics;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenMembership;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile_header'),
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF263F28), Color(0xFF4A7244), Color(0xFF7FA66A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x263D5C3A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x66FFFFFF)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AppCachedNetworkImage(
                    imageUrl: avatarUrl,
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
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderChip(
                          label: levelLabel,
                          icon: Icons.auto_awesome_rounded,
                        ),
                        GestureDetector(
                          key: const ValueKey<String>(
                            'profile_header_membership_button',
                          ),
                          onTap: onOpenMembership,
                          child: _HeaderChip(
                            label: planLabel,
                            icon: isPro
                                ? Icons.workspace_premium_rounded
                                : Icons.lock_open_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                buttonKey: const ValueKey<String>('profile_edit_button'),
                icon: Icons.edit_outlined,
                tooltip: '编辑资料',
                onTap: onEditProfile,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                buttonKey: const ValueKey<String>('profile_settings_button'),
                icon: Icons.settings_outlined,
                tooltip: '设置',
                onTap: onOpenSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x1F000000),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              children: metrics
                  .map(
                    (_ProfileMetric metric) => Expanded(
                      child: _HeaderMetric(
                        value: metric.value,
                        label: metric.label,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        key: buttonKey,
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0x1FFFFFFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x26FFFFFF)),
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
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
        color: const Color(0x26000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFFFFF)),
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
              fontWeight: FontWeight.w800,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xDFFFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionTabs extends StatelessWidget {
  const _ProfileSectionTabs({
    required this.activeIndex,
    required this.onChanged,
  });

  final int activeIndex;
  final ValueChanged<int> onChanged;

  static const List<({String label, IconData icon})> _tabs =
      <({String label, IconData icon})>[
        (label: '总览', icon: Icons.space_dashboard_rounded),
        (label: '历史', icon: Icons.history_rounded),
        (label: '设置', icon: Icons.tune_rounded),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Row(
        children: List<Widget>.generate(_tabs.length, (int index) {
          final ({String label, IconData icon}) tab = _tabs[index];
          final bool active = activeIndex == index;
          return Expanded(
            child: InkWell(
              key: ValueKey<String>('profile_section_tab_$index'),
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color: active ? darkGreen : textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                        color: active ? textPrimary : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SubscriptionPanel extends StatelessWidget {
  const _SubscriptionPanel({
    super.key,
    required this.isPro,
    required this.planLabel,
    required this.onTap,
  });

  final bool isPro;
  final String planLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = isPro ? const Color(0xFFC8955A) : primaryGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: isPro ? const Color(0xFFFFFAEA) : const Color(0xFFF1F7EF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPro
                    ? Icons.workspace_premium_rounded
                    : Icons.workspace_premium_outlined,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPro ? '订阅已生效' : '升级 SpeakEasy Pro',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isPro
                        ? '$planLabel · 查看权益与账单'
                        : '解锁 L3 高级场景、完整句型库和更高 AI 练习额度',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0ECE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyRhythmPanel extends StatelessWidget {
  const _WeeklyRhythmPanel({
    required this.stats,
    required this.isStatsLoading,
    required this.hasStats,
  });

  final LearningStatsModel stats;
  final bool isStatsLoading;
  final bool hasStats;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<({String label, bool active, bool today})> weekDays =
        List<({String label, bool active, bool today})>.generate(7, (int i) {
          return (
            label: l10n.weekdayShort(i),
            active: hasStats && stats.weekActivity[i],
            today: DateTime.now().weekday - 1 == i,
          );
        });

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_view_week_rounded,
                color: darkGreen,
                size: 18,
              ),
              const SizedBox(width: 7),
              const Text(
                '学习节奏',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                isStatsLoading && !hasStats
                    ? '同步中'
                    : '${stats.currentStreak} 天连续',
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays
                .map(
                  (day) => _WeekDayDot(
                    label: day.label,
                    active: day.active,
                    today: day.today,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _WeekDayDot extends StatelessWidget {
  const _WeekDayDot({
    required this.label,
    required this.active,
    required this.today,
  });

  final String label;
  final bool active;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final Color fill = active
        ? darkGreen
        : today
        ? const Color(0xFFEAF4E4)
        : const Color(0xFFF2EFEA);
    final Color foreground = active
        ? Colors.white
        : today
        ? darkGreen
        : textTertiary;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: today ? darkGreen : Colors.transparent,
              width: today ? 1.2 : 0,
            ),
          ),
          child: Icon(
            active ? Icons.check_rounded : Icons.remove_rounded,
            size: 15,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _FavoritesSnapshot extends StatelessWidget {
  const _FavoritesSnapshot({
    super.key,
    required this.items,
    required this.onOpenFavorites,
  });

  final List<FavoriteExpressionStorageModel> items;
  final VoidCallback onOpenFavorites;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          InkWell(
            key: const ValueKey<String>('profile_favorites_entry'),
            onTap: onOpenFavorites,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE06B6B).withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFE06B6B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '我的收藏',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items.isEmpty
                              ? '收藏表达后会在这里快速回看'
                              : '已收藏 ${items.length} 条表达',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (items.isNotEmpty) ...[
            const Divider(height: 1, color: separatorColor),
            for (final FavoriteExpressionStorageModel item in items.take(2))
              _FavoritePreviewRow(item: item),
          ],
        ],
      ),
    );
  }
}

class _FavoritePreviewRow extends StatelessWidget {
  const _FavoritePreviewRow({required this.item});

  final FavoriteExpressionStorageModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Color(0xFFE06B6B),
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.practiceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                if (item.translation.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.translation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillDistributionPanel extends StatelessWidget {
  const _SkillDistributionPanel({required this.skillLevels});

  final List<_SkillLevel> skillLevels;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: skillLevels.map((item) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${item.level}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.totalSessions,
    required this.totalMinutes,
    required this.completedSceneCount,
  });

  final String totalSessions;
  final String totalMinutes;
  final int completedSceneCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _HistorySummaryItem(
            label: '累计练习',
            value: totalSessions,
            icon: Icons.mic_rounded,
            color: const Color(0xFF5A6FA8),
          ),
          _HistorySummaryItem(
            label: '学习时长',
            value: totalMinutes,
            icon: Icons.timer_rounded,
            color: const Color(0xFF7B4EA0),
          ),
          _HistorySummaryItem(
            label: '完成场景',
            value: '$completedSceneCount',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFFC8955A),
          ),
        ],
      ),
    );
  }
}

class _HistorySummaryItem extends StatelessWidget {
  const _HistorySummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPracticeCard extends StatelessWidget {
  const _HistoryPracticeCard({
    required this.practice,
    required this.timeLabel,
    required this.onTap,
  });

  final PracticeHistoryModel practice;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String scoreLabel = practice.score == null
        ? '--'
        : '${practice.score}';
    final String statusLabel = switch (practice.feedbackStatus) {
      'ready' => '已反馈',
      'pending' => '待反馈',
      _ => '记录',
    };
    final Color statusColor = switch (practice.feedbackStatus) {
      'ready' => primaryGreen,
      'pending' => const Color(0xFFA0622A),
      _ => textTertiary,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        decoration: _panelDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  practice.emoji.isEmpty ? '🎯' : practice.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          practice.title.isEmpty ? '练习记录' : practice.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      _TinyBadge(label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  if (practice.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: practice.tags
                          .take(3)
                          .map(
                            (String tag) => _TinyBadge(
                              label: tag,
                              color: const Color(0xFF5A6FA8),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text(
                  scoreLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
                const Text(
                  '分',
                  style: TextStyle(
                    fontSize: 10,
                    color: textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeDetailSheet extends StatelessWidget {
  const _PracticeDetailSheet({
    required this.practice,
    required this.timeLabel,
    required this.onDelete,
  });

  final PracticeHistoryModel practice;
  final String timeLabel;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final String summary = _feedbackValue('summary');
    final String headline = _feedbackValue('headline');
    final String coachTip = _feedbackValue('coachTip');
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    practice.title.isEmpty ? '练习记录' : practice.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (practice.score != null)
                  _TinyBadge(label: '${practice.score} 分', color: primaryGreen),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (practice.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: practice.tags
                    .map(
                      (String tag) => _TinyBadge(
                        label: tag,
                        color: const Color(0xFF5A6FA8),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (practice.promptText?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 18),
              _DetailBlock(title: '练习输入', body: practice.promptText!.trim()),
            ],
            if (headline.isNotEmpty ||
                summary.isNotEmpty ||
                coachTip.isNotEmpty)
              const SizedBox(height: 14),
            if (headline.isNotEmpty)
              _DetailBlock(title: '反馈标题', body: headline),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DetailBlock(title: '反馈总结', body: summary),
            ],
            if (coachTip.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DetailBlock(title: '下一步建议', body: coachTip),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => unawaited(onDelete()),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除这组记录'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD46B6B),
                  side: const BorderSide(color: Color(0x33D46B6B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _feedbackValue(String key) {
    final Object? value = practice.feedbackData?[key];
    if (value is String) {
      return value.trim();
    }
    return '';
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.42,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: _panelDecoration(),
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
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
          decoration: _panelDecoration(),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
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
                      fontWeight: FontWeight.w700,
                      color: danger ? const Color(0xFFD46B6B) : textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    fontWeight: FontWeight.w900,
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
          fontWeight: FontWeight.w900,
          color: textTertiary,
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFF0ECE6)),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 2)),
    ],
  );
}

class _ProfileMetric {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;
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
