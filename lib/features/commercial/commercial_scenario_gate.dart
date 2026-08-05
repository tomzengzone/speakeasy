import 'commercial_entitlement_projection.dart';
import 'package:speakeasy/models/cefr_level.dart';

class CommercialScenarioGate {
  const CommercialScenarioGate._();

  static const String proTargetLevel = 'B2';
  static const String advancedScenariosFeature = 'advanced_scenarios';
  static const String lockedMessage = 'B2 场景需要 Pro 权益。请先升级或恢复订阅。';
  static const String lockedBadge = 'Pro';

  static bool requiresPro(String targetLevel) {
    if (!isCefrLevel(targetLevel)) {
      throw ArgumentError.value(
        targetLevel,
        'targetLevel',
        'Invalid CEFR level',
      );
    }
    return targetLevel == proTargetLevel;
  }

  static CommercialEntitlementDecision decisionFor({
    required String targetLevel,
    required CommercialEntitlementProjection entitlement,
  }) {
    if (!requiresPro(targetLevel)) {
      return const CommercialEntitlementDecision(
        allowed: true,
        code: CommercialEntitlementDecisionCode.allowed,
        message: '场景可用',
      );
    }
    return entitlement.requireFeature(advancedScenariosFeature);
  }

  static bool canAccess({
    required String targetLevel,
    required CommercialEntitlementProjection entitlement,
  }) {
    return decisionFor(
      targetLevel: targetLevel,
      entitlement: entitlement,
    ).allowed;
  }
}
