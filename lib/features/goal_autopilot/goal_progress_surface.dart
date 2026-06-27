import 'package:flutter/material.dart';

import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';

abstract final class GoalProgressSurface {
  static const String home = 'home';
  static const String queue = 'queue';
  static const String wiki = 'wiki';
}

class GoalProgressHomeSurface extends StatelessWidget {
  const GoalProgressHomeSurface({
    super.key,
    required this.projection,
    this.compact = false,
  });

  final GoalProgressProjection projection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GoalProjectionSurfaceCard(
      projection: projection,
      surface: GoalProgressSurface.home,
      title: 'Goal progress',
      icon: Icons.flag_outlined,
      compact: compact,
      dark: true,
    );
  }
}

class GoalProgressQueueSurface extends StatelessWidget {
  const GoalProgressQueueSurface({
    super.key,
    required this.projection,
    this.compact = true,
  });

  final GoalProgressProjection projection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GoalProjectionSurfaceCard(
      projection: projection,
      surface: GoalProgressSurface.queue,
      title: 'Goal reason',
      icon: Icons.format_list_bulleted_rounded,
      compact: compact,
    );
  }
}

class GoalProgressWikiSurface extends StatelessWidget {
  const GoalProgressWikiSurface({
    super.key,
    required this.projection,
    this.compact = true,
  });

  final GoalProgressProjection projection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GoalProjectionSurfaceCard(
      projection: projection,
      surface: GoalProgressSurface.wiki,
      title: 'Goal checkpoint',
      icon: Icons.fact_check_outlined,
      compact: compact,
    );
  }
}

class GoalProjectionSurfaceCard extends StatelessWidget {
  const GoalProjectionSurfaceCard({
    super.key,
    required this.projection,
    required this.surface,
    required this.title,
    required this.icon,
    this.compact = false,
    this.dark = false,
  });

  final GoalProgressProjection projection;
  final String surface;
  final String title;
  final IconData icon;
  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final GoalProgressSurfaceFragment? fragment = projection.fragmentFor(
      surface,
    );
    if (fragment == null) {
      return const SizedBox.shrink();
    }
    final Color background = dark
        ? const Color(0x1AFFFFFF)
        : const Color(0xFFF6F8F1);
    final Color border = dark
        ? const Color(0x33FFFFFF)
        : const Color(0xFFDDE8D6);
    final Color text = dark ? Colors.white : const Color(0xFF20231F);
    final Color muted = dark
        ? const Color(0xFFD5E8DD)
        : const Color(0xFF66715F);
    final Color accent = dark
        ? const Color(0xFFE8F5E9)
        : const Color(0xFF315A3A);
    final List<_ProjectionLine> lines = _projectionLines(fragment);
    if (!fragment.eligible) {
      final String reason = fragment.downgradeReason.isNotEmpty
          ? fragment.downgradeReason
          : projection.downgradeReason;
      return _SurfaceShell(
        key: ValueKey<String>('goal_progress_${surface}_surface'),
        background: background,
        border: border,
        compact: compact,
        child: _SurfaceContent(
          title: title,
          icon: icon,
          accent: accent,
          text: text,
          muted: muted,
          lines: <_ProjectionLine>[
            _ProjectionLine(
              label: 'State',
              value: reason.isEmpty ? fragment.displayState : reason,
            ),
          ],
        ),
      );
    }
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    final String reason = fragment.downgradeReason.isNotEmpty
        ? fragment.downgradeReason
        : projection.downgradeReason;
    final List<_ProjectionLine> displayLines = <_ProjectionLine>[
      if (fragment.displayState != 'ready' || reason.isNotEmpty)
        _ProjectionLine(
          label: 'State',
          value: reason.isEmpty ? fragment.displayState : reason,
        ),
      ...lines,
    ];
    return _SurfaceShell(
      key: ValueKey<String>('goal_progress_${surface}_surface'),
      background: background,
      border: border,
      compact: compact,
      child: _SurfaceContent(
        title: title,
        icon: icon,
        accent: accent,
        text: text,
        muted: muted,
        lines: displayLines,
      ),
    );
  }

  List<_ProjectionLine> _projectionLines(GoalProgressSurfaceFragment fragment) {
    final List<_ProjectionLine> lines = <_ProjectionLine>[];
    final GoalAutopilotAction? nextAction = projection.nextAction;
    final GoalProgressForecastFragment? progress = projection.progress;
    final GoalProgressCheckpointFragment? checkpoint =
        projection.latestCheckpoint;

    if (fragment.allows('next_action') &&
        fragment.nextActionRef.isNotEmpty &&
        nextAction != null &&
        nextAction.title.trim().isNotEmpty) {
      lines.add(
        _ProjectionLine(
          label: 'Next',
          value:
              '${nextAction.title} · ${nextAction.expectedDurationMinutes} min',
        ),
      );
      if (nextAction.reasonCode.trim().isNotEmpty) {
        lines.add(
          _ProjectionLine(label: 'Reason', value: nextAction.reasonCode),
        );
      }
    }
    if (fragment.allows('gap_summary') &&
        fragment.forecastRef.isNotEmpty &&
        progress != null &&
        progress.gapSummary.trim().isNotEmpty) {
      lines.add(_ProjectionLine(label: 'Gap', value: progress.gapSummary));
    }
    if (fragment.allows('risk_reason_code') &&
        fragment.forecastRef.isNotEmpty &&
        progress != null &&
        progress.riskReasonCode.trim().isNotEmpty) {
      lines.add(_ProjectionLine(label: 'Risk', value: progress.riskReasonCode));
    }
    if (fragment.allows('next_checkpoint_date') &&
        fragment.forecastRef.isNotEmpty &&
        progress?.nextCheckpointDate != null) {
      lines.add(
        _ProjectionLine(
          label: 'Next checkpoint',
          value: _formatDate(progress!.nextCheckpointDate!),
        ),
      );
    }
    if (fragment.allows('checkpoint_summary') &&
        fragment.checkpointRef.isNotEmpty &&
        checkpoint != null &&
        checkpoint.summary.trim().isNotEmpty) {
      lines.add(
        _ProjectionLine(label: 'Checkpoint', value: checkpoint.summary),
      );
    }
    return lines;
  }
}

class _SurfaceShell extends StatelessWidget {
  const _SurfaceShell({
    super.key,
    required this.background,
    required this.border,
    required this.compact,
    required this.child,
  });

  final Color background;
  final Color border;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Padding(padding: EdgeInsets.all(compact ? 10 : 12), child: child),
    );
  }
}

class _SurfaceContent extends StatelessWidget {
  const _SurfaceContent({
    required this.title,
    required this.icon,
    required this.accent,
    required this.text,
    required this.muted,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color text;
  final Color muted;
  final List<_ProjectionLine> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ...lines.map(
          (_ProjectionLine line) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: '${line.label}: ',
                    style: TextStyle(color: text, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: line.value),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.25),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectionLine {
  const _ProjectionLine({required this.label, required this.value});

  final String label;
  final String value;
}

String _formatDate(DateTime value) {
  final DateTime local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
