import 'package:flutter/material.dart';

import 'app_models.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({
    super.key,
    required this.onBack,
    required this.currentPlan,
    required this.onSubscribe,
    required this.isLoading,
    this.errorMessage,
  });

  final VoidCallback onBack;
  final String currentPlan;
  final Future<void> Function(String planId) onSubscribe;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  late String _selectedPlan = widget.currentPlan == 'free'
      ? 'yearly'
      : widget.currentPlan;

  bool get _isPro => widget.currentPlan != 'free';

  @override
  void didUpdateWidget(covariant MembershipPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPlan != widget.currentPlan) {
      _selectedPlan = widget.currentPlan == 'free'
          ? 'yearly'
          : widget.currentPlan;
    }
  }

  static const _plans = <_MemberPlan>[
    _MemberPlan(
      id: 'monthly',
      name: '月度会员',
      price: 28,
      unit: '月',
      billingNote: '按月计费，随时取消',
    ),
    _MemberPlan(
      id: 'yearly',
      name: '年度会员',
      price: 168,
      originalPrice: 336,
      unit: '年',
      billingNote: '相当于 ¥14/月',
      badge: '省 50%',
      popular: true,
    ),
    _MemberPlan(
      id: 'lifetime',
      name: '终身会员',
      price: 398,
      originalPrice: 672,
      unit: '永久',
      billingNote: '一次购买，终身使用',
      badge: '最划算',
    ),
  ];

  static const _proFeatures = <_MemberFeature>[
    _MemberFeature(
      icon: Icons.all_inclusive_rounded,
      title: '无限场景练习',
      desc: '不限次数畅享所有场景',
    ),
    _MemberFeature(
      icon: Icons.menu_book_rounded,
      title: '完整句型库',
      desc: '500+ 地道英语句型',
    ),
    _MemberFeature(
      icon: Icons.mic_rounded,
      title: 'AI 深度反馈',
      desc: '语音分析和发音纠正',
    ),
    _MemberFeature(
      icon: Icons.message_rounded,
      title: '沉浸式对话',
      desc: '无限次沉浸对话练习',
    ),
    _MemberFeature(
      icon: Icons.download_rounded,
      title: '离线学习包',
      desc: '下载场景离线练习',
    ),
    _MemberFeature(
      icon: Icons.shield_outlined,
      title: '专属学习报告',
      desc: '详细能力分析报告',
    ),
  ];

  static const _compareItems = <({String label, bool free, bool pro})>[
    (label: '每日 3 次场景练习', free: true, pro: true),
    (label: '基础句型库（50+）', free: true, pro: true),
    (label: '学习进度追踪', free: true, pro: true),
    (label: '无限场景练习', free: false, pro: true),
    (label: '完整句型库（500+）', free: false, pro: true),
    (label: 'AI 深度对话反馈', free: false, pro: true),
    (label: '离线学习包', free: false, pro: true),
    (label: '专属学习报告', free: false, pro: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A3218),
                  Color(0xFF2E4A2C),
                  Color(0xFF4A7244),
                  Color(0xFF87B076),
                  Color(0xFFC8E4B0),
                ],
                stops: [0, 0.25, 0.55, 0.85, 1],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x26FFD700), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x33A8D48A), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                            Color(0xFFFF8C00),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x59FFA500),
                            blurRadius: 32,
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isPro ? '你已是 Pro 会员' : '升级到 Pro',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPro ? '感谢你的支持，享受所有高级功能' : '解锁全部功能，加速你的口语进步',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xCCFFFFFF),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                _SectionTitle(title: 'Pro 会员权益'),
                Container(
                  decoration: _panelDecoration(),
                  child: Column(
                    children: List<Widget>.generate(_proFeatures.length, (
                      int index,
                    ) {
                      final _MemberFeature feature = _proFeatures[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: index == 0
                                  ? Colors.transparent
                                  : separatorColor,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                feature.icon,
                                color: const Color(0xFFC8955A),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feature.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    feature.desc,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: '选择会员方案'),
                ..._plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan.id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedPlan == plan.id
                              ? const Color(0xFFFFFAF1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPlan == plan.id
                                ? const Color(0xFFC8955A)
                                : const Color(0xFFF0ECE6),
                            width: _selectedPlan == plan.id ? 1.5 : 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        plan.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      if (plan.badge != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: plan.popular
                                                ? const Color(0xFFF8D98C)
                                                : const Color(0xFFE9F3EF),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            plan.badge!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: plan.popular
                                                  ? const Color(0xFF6A4D21)
                                                  : primaryGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    plan.billingNote,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                  if (plan.originalPrice != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '原价 ¥${plan.originalPrice}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textTertiary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '¥${plan.price}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '/${plan.unit}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.errorMessage != null) ...[
                  _InlineMessage(message: widget.errorMessage!),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed:
                      widget.isLoading ||
                          (_isPro && widget.currentPlan == _selectedPlan)
                      ? null
                      : () => widget.onSubscribe(_selectedPlan),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4A2C),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.isLoading
                        ? '处理中...'
                        : (_isPro && widget.currentPlan == _selectedPlan)
                        ? '当前方案'
                        : (_isPro ? '切换方案' : '立即开通'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: '免费版 vs Pro'),
                Container(
                  decoration: _panelDecoration(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: const [
                            Expanded(child: SizedBox()),
                            SizedBox(
                              width: 64,
                              child: Text(
                                '免费版',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 64,
                              child: Text(
                                'Pro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4A7244),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...List<Widget>.generate(_compareItems.length, (
                        int index,
                      ) {
                        final item = _compareItems[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: index == 0
                                    ? Colors.transparent
                                    : separatorColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 64,
                                child: Icon(
                                  item.free
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  size: 16,
                                  color: item.free
                                      ? const Color(0xFF8EAA80)
                                      : const Color(0xFFD6D0C8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 64,
                                child: Icon(
                                  item.pro
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  size: 16,
                                  color: item.pro
                                      ? primaryGreen
                                      : const Color(0xFFD6D0C8),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

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

class _MemberPlan {
  const _MemberPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.billingNote,
    this.originalPrice,
    this.badge,
    this.popular = false,
  });

  final String id;
  final String name;
  final int price;
  final int? originalPrice;
  final String unit;
  final String billingNote;
  final String? badge;
  final bool popular;
}

class _MemberFeature {
  const _MemberFeature({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4C9C2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFD46B6B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9D4C4C),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
