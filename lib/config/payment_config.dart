class PaymentPlanConfig {
  const PaymentPlanConfig({
    required this.planId,
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    required this.billingNote,
    this.originalPrice,
    this.badge,
    this.popular = false,
  });

  final String planId;
  final String productId;
  final String name;
  final double price;
  final double? originalPrice;
  final String unit;
  final String billingNote;
  final String? badge;
  final bool popular;

  String get displayPrice {
    return price.truncateToDouble() == price
        ? '¥${price.toStringAsFixed(0)}'
        : '¥${price.toStringAsFixed(2)}';
  }

  String? get displayOriginalPrice {
    final double? value = originalPrice;
    if (value == null) {
      return null;
    }
    return value.truncateToDouble() == value
        ? '¥${value.toStringAsFixed(0)}'
        : '¥${value.toStringAsFixed(2)}';
  }
}

class PaymentConfig {
  PaymentConfig._();

  static const String freePlanId = 'free';
  static const String weeklyPlanId = 'weekly';
  static const String monthlyPlanId = 'monthly';
  static const String yearlyPlanId = 'yearly';

  static const PaymentPlanConfig weekly = PaymentPlanConfig(
    planId: weeklyPlanId,
    productId: 'com.speakeasy.plan.weekly',
    name: '周度会员',
    price: 18,
    unit: '周',
    billingNote: '短期体验，自动续费，可随时取消',
    badge: '入门',
  );

  static const PaymentPlanConfig monthly = PaymentPlanConfig(
    planId: monthlyPlanId,
    productId: 'com.speakeasy.plan.monthly',
    name: '月度会员',
    price: 48,
    originalPrice: 68,
    unit: '月',
    billingNote: '稳定进阶，自动续费，可随时取消',
  );

  static const PaymentPlanConfig yearly = PaymentPlanConfig(
    planId: yearlyPlanId,
    productId: 'com.speakeasy.plan.yearly',
    name: '年度会员',
    price: 298,
    originalPrice: 576,
    unit: '年',
    billingNote: '最推荐，自动续费，相当于 ¥24.8/月',
    badge: '省更多',
    popular: true,
  );

  static const List<PaymentPlanConfig> plans = <PaymentPlanConfig>[
    weekly,
    monthly,
    yearly,
  ];

  static const Set<String> validPlanIds = <String>{
    freePlanId,
    weeklyPlanId,
    monthlyPlanId,
    yearlyPlanId,
  };

  static const Set<String> productIds = <String>{
    'com.speakeasy.plan.weekly',
    'com.speakeasy.plan.monthly',
    'com.speakeasy.plan.yearly',
  };

  static PaymentPlanConfig planById(String planId) {
    final String normalizedPlanId = normalizePlanId(planId);
    return plans.firstWhere(
      (PaymentPlanConfig plan) => plan.planId == normalizedPlanId,
    );
  }

  static String productIdForPlan(String planId) {
    return planById(planId).productId;
  }

  static String? planIdForProduct(String productId) {
    for (final PaymentPlanConfig plan in plans) {
      if (plan.productId == productId) {
        return plan.planId;
      }
    }
    return null;
  }

  static String normalizePlanId(String? planId) {
    return switch (planId) {
      weeklyPlanId => weeklyPlanId,
      monthlyPlanId => monthlyPlanId,
      yearlyPlanId => yearlyPlanId,
      'lifetime' => yearlyPlanId,
      _ => freePlanId,
    };
  }
}
