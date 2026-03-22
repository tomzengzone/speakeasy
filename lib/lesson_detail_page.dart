import 'package:flutter/material.dart';

import 'app_models.dart';

class LessonDetailPage extends StatelessWidget {
  const LessonDetailPage({
    super.key,
    required this.card,
    required this.onBack,
    required this.onStart,
  });

  final ExpressionCardData card;
  final VoidCallback onBack;
  final VoidCallback onStart;

  List<String> _masterGoals() {
    return <String>['1 个可直接套用的开口框架', '2 个自然不僵硬的变体表达', '1 次完整的场景开口输出'];
  }

  String _sceneSummary() {
    return switch (card.category) {
      '不会开口' => '你知道大概要说什么，但第一句总是卡住。这节课先帮你理解什么样的开场更自然、更安全。',
      '不会表达' => '你脑子里有想法，但说出来时不够清楚。这节课会先给你一个更顺的表达路径。',
      '说不下去' => '你能开头，但一两句之后就接不下去。这里会先帮你建立继续往下说的结构感。',
      '一慌就乱' => '你不是不会，而是一紧张就丢掉顺序。这节课会先帮你把稳定表达的骨架搭起来。',
      _ => '这节课会先给你一个能马上用起来的场景表达方式，再带你完成一次完整练习。',
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color color = card.color;
    final List<String> tags = <String>[
      card.category,
      '场景理解',
      'Lv.${card.difficultyLevel}',
    ];

    return Material(
      color: appBackground,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 54, 20, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                    IconButton(
                      onPressed: onBack,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x1FFFFFFF),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '课程介绍',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xD9FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F5F0),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withValues(alpha: 0.92),
                                  color.withValues(alpha: 0.68),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.pattern,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.35,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _sceneSummary(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xE8FFFFFF),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '这节课你会拿走',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._masterGoals().map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: textPrimary,
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              decoration: BoxDecoration(
                color: appBackground.withValues(alpha: 0.97),
                border: const Border(top: BorderSide(color: Color(0xFFF0ECE6))),
              ),
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '开始学习',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
