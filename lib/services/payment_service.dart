import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';

class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.status,
    this.planId,
    this.entitlement,
    this.message,
    this.errorMessage,
    this.transactionId,
    this.productId,
    this.rawData,
  });

  final bool success;
  final PaymentStatus status;
  final String? planId;
  final CommercialEntitlementProjection? entitlement;
  final String? message;
  final String? errorMessage;
  final String? transactionId;
  final String? productId;
  final Map<String, dynamic>? rawData;

  String get displayMessage {
    return errorMessage ?? message ?? '支付未完成';
  }
}

enum PaymentStatus { success, restored, pending, cancelled, inactive, error }

abstract class PaymentService {
  Future<PaymentResult> purchasePlan(String planId);

  Future<PaymentResult> restorePurchases();

  Future<PaymentResult> checkSubscriptionStatus();
}

class UnsupportedPaymentService implements PaymentService {
  const UnsupportedPaymentService();

  @override
  Future<PaymentResult> purchasePlan(String planId) async {
    return const PaymentResult(
      success: false,
      status: PaymentStatus.error,
      errorMessage: '当前平台暂不支持应用内支付',
    );
  }

  @override
  Future<PaymentResult> restorePurchases() async {
    return const PaymentResult(
      success: false,
      status: PaymentStatus.error,
      errorMessage: '当前平台暂不支持恢复购买',
    );
  }

  @override
  Future<PaymentResult> checkSubscriptionStatus() async {
    return const PaymentResult(
      success: false,
      status: PaymentStatus.inactive,
      message: '当前平台暂不支持订阅状态检查',
    );
  }
}
