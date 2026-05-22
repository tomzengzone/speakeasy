import 'package:speakeasy/config/payment_config.dart';
import 'payment_service.dart';

class AndroidPaymentService implements PaymentService {
  const AndroidPaymentService();

  @override
  Future<PaymentResult> purchasePlan(String planId) async {
    if (!PaymentConfig.validPlanIds.contains(planId) ||
        planId == PaymentConfig.freePlanId) {
      return const PaymentResult(
        success: false,
        status: PaymentStatus.error,
        errorMessage: '无效的订阅方案',
      );
    }

    return PaymentResult(
      success: false,
      status: PaymentStatus.error,
      planId: planId,
      productId: PaymentConfig.productIdForPlan(planId),
      errorMessage: 'Android 订阅暂未接入，请先完成 Google Play Billing 和服务端权益校验',
      rawData: const <String, dynamic>{
        'googlePlayBilling': 'pending',
        'serverEntitlementVerification': 'pending',
      },
    );
  }

  @override
  Future<PaymentResult> restorePurchases() async {
    return const PaymentResult(
      success: false,
      status: PaymentStatus.error,
      errorMessage: 'Android 恢复购买暂未接入，请在 Google Play Billing 实现后补齐',
    );
  }

  @override
  Future<PaymentResult> checkSubscriptionStatus() async {
    return const PaymentResult(
      success: false,
      status: PaymentStatus.inactive,
      message: 'Android 订阅状态检查暂未接入',
    );
  }
}
