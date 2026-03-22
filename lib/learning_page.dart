import 'package:flutter/material.dart';

import 'app_models.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({super.key, required this.card, required this.onBack});

  final ExpressionCardData card;
  final VoidCallback onBack;

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  int _step = 0;
  int? _playingPhrase;
  int? _recordingPhrase;
  int _selectedVariation = 0;

  static const List<String> _titles = <String>[
    '先理解场景',
    '先学这 3 句',
    '跟我一起说',
    '换一种说法并自己输出',
  ];

  static const List<String> _bodies = <String>[
    '先理解为什么这类场景容易卡住，再建立“自然开场”的直觉。',
    '先拿走 3 句最顺手的表达，知道它们分别适合什么语气。',
    '先跟着说，稳住语调和节奏，再慢慢提高自然度。',
    '把固定结构换词，最后完成一次你自己的表达。',
  ];

  static const List<({String en, String cn, String note})> _phrases =
      <({String en, String cn, String note})>[
        (
          en: 'Good morning, everyone. Thanks for joining.',
          cn: '大家早上好，感谢加入。',
          note: '适合会议开场',
        ),
        (en: 'Let\'s get started.', cn: '我们开始吧。', note: '推进节奏最自然'),
        (
          en: 'Today, we\'re here to discuss this week\'s priorities.',
          cn: '今天我们来聊一下本周的优先事项。',
          note: '说明目的更清楚',
        ),
      ];

  static const List<String> _variations = <String>[
    'Thanks for joining on short notice.',
    'I\'d like to start with a quick update.',
    'Let me walk you through the current timeline.',
    'First, here is the recovery plan.',
  ];

  void _handleBack() {
    if (_step == 0) {
      widget.onBack();
      return;
    }
    setState(() {
      _step -= 1;
    });
  }

  void _handleNext() {
    if (_step == _titles.length - 1) {
      widget.onBack();
      return;
    }
    setState(() {
      _step += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.card.color;

    return Material(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 18),
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
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
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
                            widget.card.title,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '步骤 ${_step + 1} / ${_titles.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xCFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LearningProgress(current: _step + 1, total: _titles.length),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
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
                      Text(
                        'STEP ${_step + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _titles[_step],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bodies[_step],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildStepContent(color),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            decoration: BoxDecoration(
              color: appBackground.withValues(alpha: 0.97),
              border: const Border(top: BorderSide(color: Color(0xFFF0ECE6))),
            ),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleBack,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('上一步'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _step == _titles.length - 1 ? '完成本课' : '下一步',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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

  Widget _buildStepContent(Color color) {
    return switch (_step) {
      0 => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5EF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE7DC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '真实场景',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.card.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.card.pattern,
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '先把场景理解清楚，再进入表达和跟读，后面会更顺。',
              style: TextStyle(fontSize: 13, height: 1.6, color: textSecondary),
            ),
          ],
        ),
      ),
      1 => Column(
        children: List<Widget>.generate(_phrases.length, (int index) {
          final item = _phrases[index];
          final bool playing = _playingPhrase == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.en,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.cn,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.note,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () =>
                        setState(() => _playingPhrase = playing ? null : index),
                    style: IconButton.styleFrom(
                      backgroundColor: playing
                          ? color
                          : color.withValues(alpha: 0.12),
                    ),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: 16,
                      color: playing ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
      2 => Column(
        children: List<Widget>.generate(_phrases.length, (int index) {
          final item = _phrases[index];
          final bool recording = _recordingPhrase == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () =>
                  setState(() => _recordingPhrase = recording ? null : index),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: recording ? color : borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.en,
                        style: const TextStyle(
                          fontSize: 15,
                          color: textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: recording ? color : const Color(0xFFF3F0EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        recording
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_none_rounded,
                        size: 18,
                        color: recording ? Colors.white : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
      _ => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '现在轮到你了',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nice to finally ___ you.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(_variations.length, (int index) {
                final bool active = _selectedVariation == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedVariation = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? color.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? color.withValues(alpha: 0.22)
                            : borderColor,
                      ),
                    ),
                    child: Text(
                      _variations[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: active ? color : textPrimary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            const Text(
              '选一个最顺口的版本，大声说一遍，然后用它完成你自己的场景开口。',
              style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    };
  }
}

class _LearningProgress extends StatelessWidget {
  const _LearningProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP $current OF $total',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List<Widget>.generate(
              total,
              (int index) => Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: index < current
                        ? Colors.white
                        : const Color(0x3DFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
