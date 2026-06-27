enum CommercialEntitlementRefreshState {
  unknown,
  refreshing,
  fresh,
  stale,
  failed,
}

enum CommercialEntitlementDecisionCode {
  allowed,
  unknown,
  refreshing,
  stale,
  refreshFailed,
  inactive,
  expired,
  revoked,
  entitlementRequired,
  featureNotIncluded,
}

class CommercialEntitlementDecision {
  const CommercialEntitlementDecision({
    required this.allowed,
    required this.code,
    required this.message,
  });

  final bool allowed;
  final CommercialEntitlementDecisionCode code;
  final String message;
}

class CommercialEntitlementProjection {
  CommercialEntitlementProjection({
    required String plan,
    required String status,
    required Map<String, bool> features,
    required this.refreshState,
    DateTime? fetchedAt,
    this.validUntil,
    this.generatedAt,
    this.errorMessage,
  }) : plan = _normalize(plan, fallback: freePlan),
       status = _normalize(status, fallback: inactiveStatus),
       features = Map<String, bool>.unmodifiable(features),
       fetchedAt = fetchedAt ?? DateTime.now();

  factory CommercialEntitlementProjection.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
    CommercialEntitlementRefreshState refreshState =
        CommercialEntitlementRefreshState.fresh,
  }) {
    final String plan = _stringValue(json, 'plan');
    final String status = _stringValue(json, 'status');
    if (plan.trim().isEmpty || status.trim().isEmpty) {
      return CommercialEntitlementProjection.unknown();
    }
    return CommercialEntitlementProjection(
      plan: plan,
      status: status,
      features: _featuresFrom(json),
      validUntil: _dateValue(json, 'validUntil', 'valid_until'),
      generatedAt: _dateValue(json, 'generatedAt', 'generated_at'),
      fetchedAt: fetchedAt,
      refreshState: refreshState,
    );
  }

  factory CommercialEntitlementProjection.unknown() {
    return CommercialEntitlementProjection(
      plan: freePlan,
      status: inactiveStatus,
      features: const <String, bool>{},
      refreshState: CommercialEntitlementRefreshState.unknown,
    );
  }

  factory CommercialEntitlementProjection.refreshing(
    CommercialEntitlementProjection previous,
  ) {
    return previous.copyWith(
      refreshState: CommercialEntitlementRefreshState.refreshing,
    );
  }

  factory CommercialEntitlementProjection.failed(
    CommercialEntitlementProjection previous, {
    String? errorMessage,
  }) {
    return previous.copyWith(
      refreshState: CommercialEntitlementRefreshState.failed,
      errorMessage: errorMessage,
    );
  }

  static const String freePlan = 'free';
  static const String proPlan = 'pro';
  static const String activeStatus = 'active';
  static const String inactiveStatus = 'inactive';
  static const String expiredStatus = 'expired';
  static const String refundedStatus = 'refunded';
  static const String revokedStatus = 'revoked';
  static const Duration paidGateFreshness = Duration(minutes: 15);

  final String plan;
  final String status;
  final Map<String, bool> features;
  final DateTime? validUntil;
  final DateTime? generatedAt;
  final DateTime fetchedAt;
  final CommercialEntitlementRefreshState refreshState;
  final String? errorMessage;

  bool get isKnown => refreshState != CommercialEntitlementRefreshState.unknown;

  bool isFreshDisplayPaidFromBackendProjection({
    DateTime? now,
    Duration maxAge = paidGateFreshness,
  }) {
    return isFreshActivePaid(now: now, maxAge: maxAge);
  }

  bool isExpired({DateTime? now}) {
    final DateTime? until = validUntil;
    if (until == null) {
      return status == expiredStatus;
    }
    return !until.isAfter(now ?? DateTime.now()) || status == expiredStatus;
  }

  bool isPaidGateFresh({DateTime? now, Duration maxAge = paidGateFreshness}) {
    if (refreshState != CommercialEntitlementRefreshState.fresh) {
      return false;
    }
    final DateTime reference = now ?? DateTime.now();
    if (reference.difference(fetchedAt) > maxAge) {
      return false;
    }
    return !isExpired(now: reference);
  }

  bool isBackendUsable({DateTime? now}) {
    return status == activeStatus && !isExpired(now: now);
  }

  bool isFreshActivePaid({DateTime? now, Duration maxAge = paidGateFreshness}) {
    return plan == proPlan &&
        isPaidGateFresh(now: now, maxAge: maxAge) &&
        isBackendUsable(now: now);
  }

  bool hasFeature(String featureKey) {
    return features[featureKey.trim()] == true;
  }

  CommercialEntitlementDecision requireFeature(
    String featureKey, {
    DateTime? now,
    Duration maxAge = paidGateFreshness,
  }) {
    final DateTime reference = now ?? DateTime.now();
    if (refreshState == CommercialEntitlementRefreshState.unknown) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.unknown,
        message: '权益状态未知，请联网刷新后重试',
      );
    }
    if (refreshState == CommercialEntitlementRefreshState.refreshing) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.refreshing,
        message: '正在刷新权益状态，请稍后重试',
      );
    }
    if (refreshState == CommercialEntitlementRefreshState.failed) {
      return CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.refreshFailed,
        message: errorMessage ?? '权益刷新失败，请稍后重试',
      );
    }
    if (reference.difference(fetchedAt) > maxAge ||
        refreshState == CommercialEntitlementRefreshState.stale) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.stale,
        message: '权益状态已过期，请联网刷新后重试',
      );
    }
    if (status == refundedStatus || status == revokedStatus) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.revoked,
        message: '订阅权益已撤销，请恢复购买或重新订阅',
      );
    }
    if (isExpired(now: reference)) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.expired,
        message: '订阅权益已过期，请恢复购买或重新订阅',
      );
    }
    if (!isBackendUsable(now: reference)) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.inactive,
        message: '当前没有有效订阅权益',
      );
    }
    if (plan != proPlan) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.entitlementRequired,
        message: '需要 Pro 权益',
      );
    }
    if (!hasFeature(featureKey)) {
      return const CommercialEntitlementDecision(
        allowed: false,
        code: CommercialEntitlementDecisionCode.featureNotIncluded,
        message: '当前订阅不包含该功能',
      );
    }
    return const CommercialEntitlementDecision(
      allowed: true,
      code: CommercialEntitlementDecisionCode.allowed,
      message: '权益可用',
    );
  }

  CommercialEntitlementProjection copyWith({
    String? plan,
    String? status,
    Map<String, bool>? features,
    DateTime? validUntil,
    DateTime? generatedAt,
    DateTime? fetchedAt,
    CommercialEntitlementRefreshState? refreshState,
    String? errorMessage,
  }) {
    return CommercialEntitlementProjection(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      features: features ?? this.features,
      validUntil: validUntil ?? this.validUntil,
      generatedAt: generatedAt ?? this.generatedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      refreshState: refreshState ?? this.refreshState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static String _normalize(String value, {required String fallback}) {
    final String trimmed = value.trim().toLowerCase();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _stringValue(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    return value is String ? value : '';
  }

  static DateTime? _dateValue(
    Map<String, dynamic> json,
    String camelKey,
    String snakeKey,
  ) {
    final Object? value = json[camelKey] ?? json[snakeKey];
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim())?.toUtc();
    }
    return null;
  }

  static Map<String, bool> _featuresFrom(Map<String, dynamic> json) {
    final Object? raw =
        json['features'] ?? json['featureFlags'] ?? json['feature_flags'];
    if (raw is! Map) {
      return const <String, bool>{};
    }
    final Map<String, bool> features = <String, bool>{};
    raw.forEach((Object? key, Object? value) {
      final String featureKey = (key ?? '').toString().trim();
      if (featureKey.isEmpty) {
        return;
      }
      features[featureKey] = value == true;
    });
    return features;
  }
}
