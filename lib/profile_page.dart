import 'package:flutter/material.dart';

import 'app_models.dart';
import 'app_session.dart';
import 'login_page.dart';
import 'membership_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showMembership = false;
  bool _notifyEnabled = true;
  bool _darkMode = false;
  bool _soundEnabled = true;
  int _activeSection = 0;

  static const _weekDays = <({String label, bool active, bool today})>[
    (label: '一', active: true, today: false),
    (label: '二', active: true, today: false),
    (label: '三', active: true, today: false),
    (label: '四', active: true, today: false),
    (label: '五', active: false, today: false),
    (label: '六', active: true, today: false),
    (label: '日', active: false, today: true),
  ];

  static const _learningStats = <_StatItem>[
    _StatItem(
      label: '学习天数',
      value: '42',
      color: Color(0xFF4A7244),
      icon: Icons.calendar_month_rounded,
    ),
    _StatItem(
      label: '总练习数',
      value: '156',
      color: Color(0xFF5A6FA8),
      icon: Icons.mic_rounded,
    ),
    _StatItem(
      label: '总时长',
      value: '18.5h',
      color: Color(0xFFA0622A),
      icon: Icons.schedule_rounded,
    ),
    _StatItem(
      label: '掌握句型',
      value: '89',
      color: Color(0xFFC8955A),
      icon: Icons.star_rounded,
    ),
  ];

  static const _skillLevels = <_SkillLevel>[
    _SkillLevel(label: '开口能力', level: 72, color: Color(0xFF4A7C6F)),
    _SkillLevel(label: '表达能力', level: 58, color: Color(0xFF5A6FA8)),
    _SkillLevel(label: '持续能力', level: 45, color: Color(0xFFA0622A)),
    _SkillLevel(label: '应变能力', level: 63, color: Color(0xFF7B4EA0)),
    _SkillLevel(label: '地道程度', level: 35, color: Color(0xFF3D7FA8)),
  ];

  static const _recentPractices = <_PracticeItem>[
    _PracticeItem(title: '咖啡店点单', time: '今天 09:30', score: 92, emoji: '☕'),
    _PracticeItem(title: '机场值机对话', time: '昨天 20:15', score: 85, emoji: '✈️'),
    _PracticeItem(title: '工作会议发言', time: '昨天 14:00', score: 78, emoji: '💼'),
    _PracticeItem(title: '餐厅预订', time: '3月14日', score: 88, emoji: '🍽️'),
  ];

  @override
  Widget build(BuildContext context) {
    final AppSession session = AppSessionScope.of(context);
    final bool isPro = session.isPro;

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
                                    size: 34,
                                  ),
                                );
                              },
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
                            isPro ? 'SpeakEasy Pro 会员' : '免费版用户',
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
                                label: 'Lv.3',
                                icon: Icons.auto_awesome_rounded,
                              ),
                              _HeaderChip(
                                label: isPro ? '已开通 Pro' : '升级到 Pro',
                                icon: Icons.workspace_premium_rounded,
                              ),
                            ],
                          ),
                        ],
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
                        children: const [
                          Expanded(
                            child: _HeaderMetric(value: '28', label: '总练习'),
                          ),
                          Expanded(
                            child: _HeaderMetric(value: '7', label: '连续天数'),
                          ),
                          Expanded(
                            child: _HeaderMetric(value: '82', label: '最佳分数'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _weekDays.map((day) {
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
                  label: '概览',
                  active: _activeSection == 0,
                  onTap: () => setState(() => _activeSection = 0),
                ),
                _SegmentChip(
                  label: '设置',
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
                  ? _buildOverview(isPro: isPro)
                  : _buildSettings(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOverview({required bool isPro}) {
    return <Widget>[
      _SectionLabel(title: '学习概览'),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: _learningStats.map((item) => _StatCard(item: item)).toList(),
      ),
      const SizedBox(height: 20),
      _SectionLabel(title: '能力分布'),
      Container(
        decoration: _panelDecoration(),
        child: Column(
          children: _skillLevels.map((item) {
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
      _SectionLabel(title: '最近练习'),
      Container(
        decoration: _panelDecoration(),
        child: Column(
          children: List<Widget>.generate(_recentPractices.length, (int index) {
            final item = _recentPractices[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      '${item.score}',
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
        title: '账户与会员',
        children: [
          _MenuTile(
            icon: Icons.workspace_premium_rounded,
            color: isPro ? const Color(0xFFC8955A) : const Color(0xFFABA39A),
            label: isPro ? 'Pro 会员' : '升级到 Pro',
            subtitle: isPro ? '查看会员权益与管理' : '解锁全部功能',
            badge: isPro ? '已开通' : '升级',
            badgeColor: isPro ? const Color(0xFFC8955A) : primaryGreen,
            onTap: () => setState(() => _showMembership = true),
          ),
          _MenuTile(
            icon: Icons.credit_card_rounded,
            color: const Color(0xFF5A6FA8),
            label: '订阅管理',
            subtitle: isPro ? '管理自动续费与账单' : '查看订阅方案',
            onTap: () => setState(() => _showMembership = true),
          ),
          const _MenuTile(
            icon: Icons.person_outline_rounded,
            color: Color(0xFF4A7244),
            label: '编辑资料',
            subtitle: '修改头像、昵称',
          ),
        ],
      ),
      _MenuGroup(
        title: '学习相关',
        children: const [
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            color: Color(0xFF4A7244),
            label: '学习报告',
            subtitle: '查看详细学习数据',
          ),
          _MenuTile(
            icon: Icons.favorite_border_rounded,
            color: Color(0xFFE06B6B),
            label: '我的收藏',
            subtitle: '收藏的句型和场景',
            badge: '12',
            badgeColor: Color(0xFFE06B6B),
          ),
          _MenuTile(
            icon: Icons.download_rounded,
            color: Color(0xFF5A6FA8),
            label: '离线内容',
            subtitle: '已下载 3 个场景包',
          ),
          _MenuTile(
            icon: Icons.emoji_events_outlined,
            color: Color(0xFFC8955A),
            label: '成就徽章',
            subtitle: '已解锁 8 个成就',
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSettings() {
    return <Widget>[
      _MenuGroup(
        title: '偏好设置',
        children: [
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            color: const Color(0xFF4A7244),
            label: '学习提醒',
            trailing: Switch(
              value: _notifyEnabled,
              onChanged: (bool value) => setState(() => _notifyEnabled = value),
              activeThumbColor: primaryGreen,
            ),
          ),
          _MenuTile(
            icon: Icons.dark_mode_outlined,
            color: const Color(0xFF7B4EA0),
            label: '深色模式',
            trailing: Switch(
              value: _darkMode,
              onChanged: (bool value) => setState(() => _darkMode = value),
              activeThumbColor: primaryGreen,
            ),
          ),
          _MenuTile(
            icon: Icons.volume_up_outlined,
            color: const Color(0xFF3D7FA8),
            label: '音效',
            trailing: Switch(
              value: _soundEnabled,
              onChanged: (bool value) => setState(() => _soundEnabled = value),
              activeThumbColor: primaryGreen,
            ),
          ),
          const _MenuTile(
            icon: Icons.language_rounded,
            color: Color(0xFFA0622A),
            label: '界面语言',
            value: '简体中文',
          ),
          const _MenuTile(
            icon: Icons.shield_outlined,
            color: Color(0xFF5A6FA8),
            label: '隐私设置',
          ),
        ],
      ),
      _MenuGroup(
        title: '帮助与支持',
        children: [
          const _MenuTile(
            icon: Icons.help_outline_rounded,
            color: Color(0xFF9A9289),
            label: '帮助与反馈',
          ),
          const _MenuTile(
            icon: Icons.message_outlined,
            color: Color(0xFF9A9289),
            label: '联系我们',
          ),
          const _MenuTile(
            icon: Icons.star_border_rounded,
            color: Color(0xFFFFB83C),
            label: '给个好评',
          ),
          _MenuTile(
            icon: Icons.logout_rounded,
            color: const Color(0xFFD46B6B),
            label: '退出登录',
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
    required this.score,
    required this.emoji,
  });

  final String title;
  final String time;
  final int score;
  final String emoji;
}
