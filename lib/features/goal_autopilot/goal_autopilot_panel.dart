import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';

class GoalAutopilotPanel extends StatefulWidget {
  const GoalAutopilotPanel({
    super.key,
    this.adapter = const GoalAutopilotAdapter(),
  });

  final GoalAutopilotAdapter adapter;

  @override
  State<GoalAutopilotPanel> createState() => _GoalAutopilotPanelState();
}

class _GoalAutopilotPanelState extends State<GoalAutopilotPanel> {
  Future<GoalAutopilotSummary>? _summaryFuture;
  bool _busy = false;
  bool _creatingGoal = false;
  bool _editing = false;
  bool _exploring = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.adapter.loadSummary();
  }

  void _reload() {
    setState(() {
      _summaryFuture = widget.adapter.loadSummary();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      _reload();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveGoal(_GoalDraft draft) {
    return _run(() async {
      await widget.adapter.createGoal(
        goalType: draft.goalType,
        targetScore: draft.targetScore,
        targetAbility: draft.targetAbility,
        deadline: draft.deadline,
        dailyMinutes: draft.dailyMinutes,
        intensityPreference: draft.intensityPreference,
        diagnosticSamples: draft.samples,
      );
      if (mounted) {
        setState(() {
          _creatingGoal = false;
          _editing = false;
          _exploring = false;
        });
      }
    });
  }

  void _openGoalIntake() {
    setState(() {
      _creatingGoal = true;
      _editing = false;
      _exploring = false;
    });
  }

  void _openExplorePractice() {
    setState(() {
      _creatingGoal = false;
      _editing = false;
      _exploring = true;
    });
  }

  void _closeNoGoalSubflow() {
    setState(() {
      _creatingGoal = false;
      _exploring = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GoalAutopilotSummary>(
      future: _summaryFuture,
      builder:
          (BuildContext context, AsyncSnapshot<GoalAutopilotSummary> snapshot) {
            final GoalAutopilotSummary? summary = snapshot.data;
            final Widget content = switch ((
              snapshot.connectionState,
              snapshot.hasError,
              summary,
              _editing,
            )) {
              (ConnectionState.waiting, _, null, _) => const SizedBox(
                height: 112,
                child: Center(child: CircularProgressIndicator()),
              ),
              (_, _, null, _) when _creatingGoal => _GoalSetup(
                busy: _busy,
                onSubmit: _saveGoal,
                onCancel: _closeNoGoalSubflow,
              ),
              (_, _, null, _) when _exploring => _ExplorePractice(
                onBack: _closeNoGoalSubflow,
                onSetGoal: _openGoalIntake,
              ),
              (_, true, null, _) => _NoActiveGoal(
                busy: _busy,
                onSetGoal: _openGoalIntake,
                onExplore: _openExplorePractice,
              ),
              (_, _, GoalAutopilotSummary value, true) => _GoalSetup(
                busy: _busy,
                initial: value,
                onSubmit: _saveGoal,
                onCancel: () => setState(() => _editing = false),
              ),
              (_, _, GoalAutopilotSummary value, false) => _GoalSummary(
                summary: value,
                busy: _busy,
                onEdit: () => setState(() => _editing = true),
                onGeneratePlan: (bool forceReplan) => _run(
                  () => widget.adapter
                      .generatePlan(forceReplan: forceReplan)
                      .then((_) {}),
                ),
                onCompleteAction: value.hasExecutableAction
                    ? () => _run(
                        () => widget.adapter
                            .completeAction(
                              planItemId: value.nextAction!.planItemId,
                            )
                            .then((_) {}),
                      )
                    : null,
                onCheckpoint: value.isUnsupported
                    ? null
                    : () => _run(widget.adapter.submitCheckpoint),
              ),
              _ => _NoActiveGoal(
                busy: _busy,
                onSetGoal: _openGoalIntake,
                onExplore: _openExplorePractice,
              ),
            };
            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF102820),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(padding: const EdgeInsets.all(16), child: content),
            );
          },
    );
  }
}

class _NoActiveGoal extends StatelessWidget {
  const _NoActiveGoal({
    required this.busy,
    required this.onSetGoal,
    required this.onExplore,
  });

  final bool busy;
  final VoidCallback onSetGoal;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(Icons.flag_outlined, color: Color(0xFFE8F5E9), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No active goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: busy ? null : onSetGoal,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Set a goal'),
              ),
            ),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onExplore,
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('Explore practice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: Color(0xFFE8F5E9)),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onExplore,
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Try a sample drill'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: Color(0xFFE8F5E9)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExplorePractice extends StatelessWidget {
  const _ExplorePractice({required this.onBack, required this.onSetGoal});

  final VoidCallback onBack;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(Icons.play_circle_outline, color: Color(0xFFE8F5E9), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sample drill',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Prompt: explain one recent win in two sentences.',
          style: TextStyle(color: Color(0xFFF5F7F2), fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          'Practice feedback: add one concrete example and keep the second sentence short.',
          style: TextStyle(color: Color(0xFFD5E8DD), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: Color(0xFFE8F5E9)),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: onSetGoal,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Set a goal'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalSetup extends StatefulWidget {
  const _GoalSetup({
    required this.busy,
    required this.onSubmit,
    this.initial,
    this.onCancel,
  });

  final bool busy;
  final GoalAutopilotSummary? initial;
  final Future<void> Function(_GoalDraft draft) onSubmit;
  final VoidCallback? onCancel;

  @override
  State<_GoalSetup> createState() => _GoalSetupState();
}

class _GoalSetupState extends State<_GoalSetup> {
  static const List<String> _goalTypes = <String>[
    'ielts_speaking',
    'toefl_speaking',
    'business_meeting',
    'job_interview',
    'onboarding_introduction',
  ];
  static const List<String> _intensities = <String>[
    'gentle',
    'standard',
    'intensive',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _goalType;
  late String _intensityPreference;
  late final TextEditingController _targetScoreController;
  late final TextEditingController _targetAbilityController;
  late final TextEditingController _deadlineController;
  late final TextEditingController _dailyMinutesController;
  late final List<TextEditingController> _sampleControllers;

  @override
  void initState() {
    super.initState();
    final GoalAutopilotSummary? initial = widget.initial;
    _goalType = _goalTypes.contains(initial?.goalType)
        ? initial!.goalType
        : 'ielts_speaking';
    _intensityPreference = _intensities.contains(initial?.intensityPreference)
        ? initial!.intensityPreference
        : 'standard';
    _targetScoreController = TextEditingController(
      text: initial?.targetScore == null
          ? '8'
          : _formatScore(initial!.targetScore!),
    );
    _targetAbilityController = TextEditingController(
      text:
          initial?.targetAbility ??
          'confident speaking under follow-up pressure',
    );
    _deadlineController = TextEditingController(
      text: _formatDate(
        initial?.deadline ?? DateTime.now().add(const Duration(days: 75)),
      ),
    );
    _dailyMinutesController = TextEditingController(
      text: (initial?.dailyMinutes ?? 30).toString(),
    );
    _sampleControllers = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
  }

  @override
  void dispose() {
    _targetScoreController.dispose();
    _targetAbilityController.dispose();
    _deadlineController.dispose();
    _dailyMinutesController.dispose();
    for (final TextEditingController controller in _sampleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFFE8F5E9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Goal autopilot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.busy ? null : widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE8F5E9),
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey<String>('goal-type-field'),
              initialValue: _goalType,
              dropdownColor: Colors.white,
              decoration: _decoration('Goal type'),
              items: _goalTypes
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(growable: false),
              onChanged: widget.busy
                  ? null
                  : (String? value) {
                      if (value != null) {
                        setState(() => _goalType = value);
                      }
                    },
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: const ValueKey<String>('goal-target-score-field'),
                    controller: _targetScoreController,
                    enabled: !widget.busy,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Target score'),
                    validator: (_) => _scoreAbilityError(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey<String>('goal-daily-minutes-field'),
                    controller: _dailyMinutesController,
                    enabled: !widget.busy,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Daily minutes'),
                    validator: _validateDailyMinutes,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const ValueKey<String>('goal-target-ability-field'),
              controller: _targetAbilityController,
              enabled: !widget.busy,
              decoration: _decoration('Target ability'),
              validator: (_) => _scoreAbilityError(),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: const ValueKey<String>('goal-deadline-field'),
                    controller: _deadlineController,
                    enabled: !widget.busy,
                    keyboardType: TextInputType.datetime,
                    decoration: _decoration('Deadline'),
                    validator: _validateDeadline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey<String>('goal-intensity-field'),
                    initialValue: _intensityPreference,
                    dropdownColor: Colors.white,
                    decoration: _decoration('Intensity'),
                    items: _intensities
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: widget.busy
                        ? null
                        : (String? value) {
                            if (value != null) {
                              setState(() => _intensityPreference = value);
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (
              int index = 0;
              index < _sampleControllers.length;
              index++
            ) ...<Widget>[
              TextFormField(
                key: ValueKey<String>(
                  'goal-diagnostic-sample-${index + 1}-field',
                ),
                controller: _sampleControllers[index],
                enabled: !widget.busy,
                minLines: 2,
                maxLines: 3,
                decoration: _decoration('Diagnostic sample ${index + 1}'),
                validator: index == 0 ? _validateSamples : null,
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: widget.busy ? null : _submit,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start autopilot'),
                  ),
                ),
                const Text(
                  'Product-internal progress only',
                  style: TextStyle(color: Color(0xFFD5E8DD), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FBF7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      isDense: true,
    );
  }

  String? _scoreAbilityError() {
    final bool hasScore = _targetScoreController.text.trim().isNotEmpty;
    final bool hasAbility = _targetAbilityController.text.trim().isNotEmpty;
    if (!hasScore && !hasAbility) {
      return 'Add target score or ability.';
    }
    if (hasScore &&
        double.tryParse(_targetScoreController.text.trim()) == null) {
      return 'Use a number.';
    }
    return null;
  }

  String? _validateDailyMinutes(String? value) {
    final int? minutes = int.tryParse(value?.trim() ?? '');
    if (minutes == null || minutes < 5 || minutes > 240) {
      return 'Use 5-240.';
    }
    return null;
  }

  String? _validateDeadline(String? value) {
    final DateTime? deadline = DateTime.tryParse(value?.trim() ?? '');
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (deadline == null || !deadline.isAfter(today)) {
      return 'Use a future date.';
    }
    return null;
  }

  String? _validateSamples(String? _) {
    final bool hasSample = _sampleControllers.any(
      (TextEditingController controller) => controller.text.trim().isNotEmpty,
    );
    if (!hasSample) {
      return 'Add at least one diagnostic sample.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await widget.onSubmit(
      _GoalDraft(
        goalType: _goalType,
        targetScore: double.tryParse(_targetScoreController.text.trim()),
        targetAbility: _targetAbilityController.text.trim(),
        deadline: DateTime.parse(_deadlineController.text.trim()),
        dailyMinutes: int.parse(_dailyMinutesController.text.trim()),
        intensityPreference: _intensityPreference,
        samples: _sampleControllers
            .asMap()
            .entries
            .where(
              (MapEntry<int, TextEditingController> entry) =>
                  entry.value.text.trim().isNotEmpty,
            )
            .map(
              (MapEntry<int, TextEditingController> entry) =>
                  GoalDiagnosticSampleInput(
                    sampleRef: 'flutter_goal_sample_${entry.key + 1}',
                    transcript: entry.value.text,
                  ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({
    required this.summary,
    required this.busy,
    required this.onEdit,
    required this.onGeneratePlan,
    required this.onCompleteAction,
    required this.onCheckpoint,
  });

  final GoalAutopilotSummary summary;
  final bool busy;
  final VoidCallback onEdit;
  final void Function(bool forceReplan) onGeneratePlan;
  final VoidCallback? onCompleteAction;
  final VoidCallback? onCheckpoint;

  @override
  Widget build(BuildContext context) {
    final GoalAutopilotAction? action = summary.nextAction;
    final GoalDailyPlan? plan = summary.dailyPlan;
    final String limitationMessage = _visibleLimitation(summary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.auto_awesome, color: Color(0xFFE8F5E9), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _goalTitle(summary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.confidenceBand} confidence · ${summary.riskLevel} risk',
                    style: const TextStyle(
                      color: Color(0xFFD5E8DD),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _Metric(
              label: 'Support: ${summary.supportStatus}',
              icon: Icons.rule,
            ),
            _Metric(label: 'Revision ${summary.revision}', icon: Icons.edit),
            _Metric(
              label:
                  'Samples ${summary.sampleCount} · ${summary.diagnosticStatus}',
              icon: Icons.graphic_eq,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (summary.supportReasonCode.isNotEmpty)
          Text(
            summary.supportReasonCode,
            style: const TextStyle(color: Color(0xFFD5E8DD), fontSize: 12),
          ),
        if (limitationMessage.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            limitationMessage,
            style: const TextStyle(color: Color(0xFFF5F7F2), fontSize: 13),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          summary.gapSummary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFF5F7F2), fontSize: 13),
        ),
        if (!summary.officialScoreEquivalence ||
            !summary.goalCompletionClaimAllowed) ...<Widget>[
          const SizedBox(height: 8),
          const Text(
            'Product-internal progress only',
            style: TextStyle(color: Color(0xFFD5E8DD), fontSize: 12),
          ),
        ],
        if (summary.canShowPreciseEta) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'ETA ${_formatDate(summary.etaDate!)}',
            style: const TextStyle(color: Color(0xFFD5E8DD), fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Edit goal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: Color(0xFFE8F5E9)),
                ),
              ),
            ),
            if (summary.hasExecutableAction && action != null)
              _ActionRow(
                action: action,
                busy: busy,
                onComplete: onCompleteAction,
              )
            else if (summary.canGeneratePlan)
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => onGeneratePlan(summary.shouldForceReplan),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    summary.shouldForceReplan
                        ? 'Regenerate plan'
                        : 'Generate plan',
                  ),
                ),
              ),
          ],
        ),
        if (plan != null && !summary.isUnsupported) ...<Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _Metric(
                label: '${plan.totalMinutes} min',
                icon: Icons.timer_outlined,
              ),
              const SizedBox(width: 8),
              _Metric(
                label: '${plan.memoryPolicy.nextReviewIntervalDays}d review',
                icon: Icons.repeat_rounded,
              ),
            ],
          ),
        ],
        if (onCheckpoint != null) ...<Widget>[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: busy ? null : onCheckpoint,
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('Checkpoint'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE8F5E9),
            ),
          ),
        ],
      ],
    );
  }

  String _goalTitle(GoalAutopilotSummary value) {
    final String score = value.targetScore == null
        ? ''
        : ' ${_formatScore(value.targetScore!)}';
    return '${value.goalType.replaceAll('_', ' ')}$score';
  }

  String _visibleLimitation(GoalAutopilotSummary value) {
    final String text = value.limitationMessage.trim();
    if (text.isEmpty) {
      return '';
    }
    final String lowered = text.toLowerCase();
    if (!value.officialScoreEquivalence &&
        (lowered.contains('official score') ||
            lowered.contains('score certification'))) {
      return 'Product-internal progress only; no external certification claim.';
    }
    return text;
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.busy,
    required this.onComplete,
  });

  final GoalAutopilotAction action;
  final bool busy;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${action.expectedDurationMinutes} min · ${action.reasonCode}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFC6DACF), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: busy ? null : onComplete,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: const Color(0xFFD5E8DD)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFD5E8DD), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDraft {
  const _GoalDraft({
    required this.goalType,
    required this.targetScore,
    required this.targetAbility,
    required this.deadline,
    required this.dailyMinutes,
    required this.intensityPreference,
    required this.samples,
  });

  final String goalType;
  final double? targetScore;
  final String targetAbility;
  final DateTime deadline;
  final int dailyMinutes;
  final String intensityPreference;
  final List<GoalDiagnosticSampleInput> samples;
}

String _formatDate(DateTime value) {
  final DateTime local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _formatScore(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
