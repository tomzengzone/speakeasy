part of 'scene_page.dart';

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
