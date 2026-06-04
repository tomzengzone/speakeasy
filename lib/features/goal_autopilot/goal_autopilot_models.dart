class GoalAutopilotSummary {
  const GoalAutopilotSummary({
    required this.goalProfileId,
    required this.goalType,
    required this.supportStatus,
    required this.goalStatus,
    required this.confidenceBand,
    required this.diagnosticStatus,
    required this.sampleCount,
    required this.gapSummary,
    required this.riskLevel,
    required this.riskReason,
    required this.officialScoreEquivalence,
    required this.goalCompletionClaimAllowed,
    required this.allowedClaim,
    required this.revision,
    required this.dailyMinutes,
    required this.intensityPreference,
    required this.supportReasonCode,
    required this.limitationMessage,
    required this.rubricAvailable,
    required this.contentCoverage,
    this.targetScore,
    this.targetAbility = '',
    this.deadline,
    this.etaDate,
    this.etaWindow = '',
    this.nextCheckpointDate,
    this.dailyPlan,
    this.nextAction,
  });

  final String goalProfileId;
  final String goalType;
  final String supportStatus;
  final String goalStatus;
  final String confidenceBand;
  final String diagnosticStatus;
  final int sampleCount;
  final String gapSummary;
  final String riskLevel;
  final String riskReason;
  final bool officialScoreEquivalence;
  final bool goalCompletionClaimAllowed;
  final String allowedClaim;
  final int revision;
  final int dailyMinutes;
  final String intensityPreference;
  final String supportReasonCode;
  final String limitationMessage;
  final bool rubricAvailable;
  final String contentCoverage;
  final double? targetScore;
  final String targetAbility;
  final DateTime? deadline;
  final DateTime? etaDate;
  final String etaWindow;
  final DateTime? nextCheckpointDate;
  final GoalDailyPlan? dailyPlan;
  final GoalAutopilotAction? nextAction;

  bool get hasPlan => dailyPlan != null && nextAction != null;

  bool get isUnsupported =>
      supportStatus == 'unsupported' || diagnosticStatus == 'unsupported';

  bool get isPartialOrLowConfidence =>
      supportStatus == 'partial' ||
      confidenceBand == 'low' ||
      diagnosticStatus == 'low_confidence';

  bool get hasExecutableAction =>
      nextAction != null &&
      !isUnsupported &&
      !isPlanStale &&
      nextAction!.status == 'ready';

  bool get isPlanStale =>
      dailyPlan?.status == 'stale' ||
      nextAction?.status == 'stale' ||
      nextAction?.status == 'blocked';

  bool get canGeneratePlan => !isUnsupported && !hasExecutableAction;

  bool get shouldForceReplan => isPlanStale || (revision > 1 && !hasPlan);

  bool get canShowPreciseEta =>
      !isUnsupported &&
      !isPartialOrLowConfidence &&
      goalCompletionClaimAllowed &&
      etaDate != null;

  factory GoalAutopilotSummary.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> goal = _map(json['goal_profile']);
    final Map<String, dynamic> support = _map(json['support_decision']);
    final Map<String, dynamic> diagnostic = _map(json['diagnostic']);
    final Map<String, dynamic> diagnosticClaimGuard = _map(
      diagnostic['claim_guard'],
    );
    final Map<String, dynamic> forecast = _map(json['forecast']);
    final Map<String, dynamic> forecastClaimGuard = _map(
      forecast['claim_guard'],
    );
    final String goalSupport = _string(
      goal['support_status'],
      fallback: 'partial',
    );
    final String decisionSupport = _string(
      support['support_status'],
      fallback: goalSupport,
    );
    final String supportStatus = _restrictiveSupport(
      goalSupport,
      decisionSupport,
    );
    final bool diagnosticOfficialScore = _bool(
      diagnosticClaimGuard['official_score_equivalence'],
    );
    final bool forecastOfficialScore = forecastClaimGuard.isEmpty
        ? diagnosticOfficialScore
        : _bool(forecastClaimGuard['official_score_equivalence']);
    final bool diagnosticCompletion = _bool(
      diagnosticClaimGuard['goal_completion_claim_allowed'],
    );
    final bool forecastCompletion = forecastClaimGuard.isEmpty
        ? diagnosticCompletion
        : _bool(forecastClaimGuard['goal_completion_claim_allowed']);
    return GoalAutopilotSummary(
      goalProfileId: _string(goal['goal_profile_id']),
      goalType: _string(goal['goal_type'], fallback: 'business_meeting'),
      supportStatus: supportStatus,
      goalStatus: _string(goal['status'], fallback: supportStatus),
      targetScore: _doubleOrNull(goal['target_score']),
      targetAbility: _string(goal['target_ability']),
      deadline: _dateOrNull(goal['deadline']),
      dailyMinutes: _int(goal['daily_minutes']),
      intensityPreference: _string(
        goal['intensity_preference'],
        fallback: 'standard',
      ),
      revision: _int(goal['revision'], fallback: 1),
      supportReasonCode: _string(support['reason_code']),
      limitationMessage: _string(support['limitation_message']),
      rubricAvailable: _bool(support['rubric_available']),
      contentCoverage: _string(support['content_coverage']),
      diagnosticStatus: _string(diagnostic['status'], fallback: 'complete'),
      confidenceBand: _string(diagnostic['confidence_band'], fallback: 'low'),
      sampleCount: _int(diagnostic['sample_count']),
      gapSummary: _string(forecast['gap_summary']),
      etaDate: _dateOrNull(forecast['eta_date']),
      etaWindow: _string(forecast['eta_window']),
      riskLevel: _string(forecast['risk_level'], fallback: 'medium'),
      riskReason: _string(forecast['risk_reason']),
      nextCheckpointDate: _dateOrNull(forecast['next_checkpoint_date']),
      officialScoreEquivalence:
          diagnosticOfficialScore && forecastOfficialScore,
      goalCompletionClaimAllowed: diagnosticCompletion && forecastCompletion,
      allowedClaim: _string(
        forecastClaimGuard['allowed_claim'],
        fallback: _string(
          diagnosticClaimGuard['allowed_claim'],
          fallback: 'product_internal_progress_only',
        ),
      ),
      dailyPlan: json['daily_plan'] is Map
          ? GoalDailyPlan.fromJson(_map(json['daily_plan']))
          : null,
      nextAction: json['next_action'] is Map
          ? GoalAutopilotAction.fromJson(_map(json['next_action']))
          : null,
    );
  }
}

class GoalDailyPlan {
  const GoalDailyPlan({
    required this.dailyPlanId,
    required this.totalMinutes,
    required this.status,
    required this.items,
    required this.memoryPolicy,
    this.limitationMessage = '',
  });

  final String dailyPlanId;
  final int totalMinutes;
  final String status;
  final String limitationMessage;
  final List<GoalPlanItem> items;
  final GoalMemoryPolicy memoryPolicy;

  factory GoalDailyPlan.fromJson(Map<String, dynamic> json) {
    return GoalDailyPlan(
      dailyPlanId: _string(json['daily_plan_id']),
      totalMinutes: _int(json['total_minutes']),
      status: _string(json['status'], fallback: 'ready'),
      limitationMessage: _string(json['limitation_message']),
      items: _list(json['items'])
          .map((Object? item) => GoalPlanItem.fromJson(_map(item)))
          .toList(growable: false),
      memoryPolicy: GoalMemoryPolicy.fromJson(_map(json['memory_policy'])),
    );
  }
}

class GoalPlanItem {
  const GoalPlanItem({
    required this.planItemId,
    required this.itemType,
    required this.title,
    required this.reasonCode,
    required this.durationMinutes,
    required this.status,
    required this.memoryRisk,
  });

  final String planItemId;
  final String itemType;
  final String title;
  final String reasonCode;
  final int durationMinutes;
  final String status;
  final String memoryRisk;

  factory GoalPlanItem.fromJson(Map<String, dynamic> json) {
    return GoalPlanItem(
      planItemId: _string(json['plan_item_id']),
      itemType: _string(json['item_type'], fallback: 'training'),
      title: _string(json['title']),
      reasonCode: _string(json['reason_code']),
      durationMinutes: _int(json['duration_minutes']),
      status: _string(json['status'], fallback: 'pending'),
      memoryRisk: _string(json['memory_risk'], fallback: 'medium'),
    );
  }
}

class GoalMemoryPolicy {
  const GoalMemoryPolicy({
    required this.policyVersion,
    required this.forgettingRisk,
    required this.nextReviewIntervalDays,
    required this.interleavingRule,
  });

  final String policyVersion;
  final String forgettingRisk;
  final int nextReviewIntervalDays;
  final String interleavingRule;

  factory GoalMemoryPolicy.fromJson(Map<String, dynamic> json) {
    return GoalMemoryPolicy(
      policyVersion: _string(
        json['policy_version'],
        fallback: 'memory-curve-v1',
      ),
      forgettingRisk: _string(json['forgetting_risk'], fallback: 'medium'),
      nextReviewIntervalDays: _int(json['next_review_interval_days']),
      interleavingRule: _string(json['interleaving_rule']),
    );
  }
}

class GoalAutopilotAction {
  const GoalAutopilotAction({
    required this.planItemId,
    required this.actionType,
    required this.title,
    required this.reasonCode,
    required this.expectedDurationMinutes,
    required this.status,
  });

  final String planItemId;
  final String actionType;
  final String title;
  final String reasonCode;
  final int expectedDurationMinutes;
  final String status;

  factory GoalAutopilotAction.fromJson(Map<String, dynamic> json) {
    return GoalAutopilotAction(
      planItemId: _string(json['plan_item_id']),
      actionType: _string(json['action_type'], fallback: 'start_training'),
      title: _string(json['title']),
      reasonCode: _string(json['reason_code']),
      expectedDurationMinutes: _int(json['expected_duration_minutes']),
      status: _string(json['status'], fallback: 'ready'),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

List<Object?> _list(Object? value) {
  if (value is List) {
    return value;
  }
  return const <Object?>[];
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value) {
  if (value is bool) {
    return value;
  }
  return value?.toString() == 'true';
}

double? _doubleOrNull(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _dateOrNull(Object? value) {
  final String text = value?.toString() ?? '';
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

String _restrictiveSupport(String first, String second) {
  const Map<String, int> rank = <String, int>{
    'supported': 0,
    'partial': 1,
    'unsupported': 2,
  };
  final int firstRank = rank[first] ?? 1;
  final int secondRank = rank[second] ?? 1;
  return firstRank >= secondRank ? first : second;
}
