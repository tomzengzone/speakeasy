class CommercialScenarioGate {
  const CommercialScenarioGate._();

  static const String proTargetLevel = 'advanced';
  static const String lockedMessage = 'L3 高级场景需要 Pro 权益。请先升级或恢复订阅。';
  static const String lockedBadge = 'Pro';

  static String normalizeTargetLevel(String targetLevel) {
    final String normalized = targetLevel.trim();
    return switch (normalized) {
      'L2' || 'intermediate' => 'intermediate',
      'L3' || 'advanced' => proTargetLevel,
      _ => 'beginner',
    };
  }

  static bool requiresPro(String targetLevel) {
    return normalizeTargetLevel(targetLevel) == proTargetLevel;
  }

  static bool canAccess({required String targetLevel, required bool isPro}) {
    return isPro || !requiresPro(targetLevel);
  }
}
