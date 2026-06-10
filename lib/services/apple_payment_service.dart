import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:speakeasy/config/payment_config.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';
import 'package:speakeasy/services/api_client.dart';
import 'payment_service.dart';

class ApplePaymentService implements PaymentService {
  ApplePaymentService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  Future<PaymentResult> purchasePlan(String planId) async {
    await _ensureStoreAvailable();

    final String appAccountToken = await ApiClient.currentUserId();
    final ProductDetails product = await _loadProduct(planId);
    final Completer<PaymentResult> completer = Completer<PaymentResult>();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        _listenToFlow(
          completer: completer,
          expectedPlanId: planId,
          appAccountToken: appAccountToken,
        );

    try {
      final bool started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: appAccountToken,
        ),
      );
      if (!started) {
        return PaymentResult(
          success: false,
          status: PaymentStatus.error,
          planId: planId,
          errorMessage: '无法发起 App Store 购买请求',
        );
      }

      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => PaymentResult(
          success: false,
          status: PaymentStatus.pending,
          planId: planId,
          message: '购买请求已提交，等待 App Store 完成确认',
        ),
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<PaymentResult> restorePurchases() async {
    final PaymentResult storeResult = await _runRestoreFlow(
      emptyResult: const PaymentResult(
        success: false,
        status: PaymentStatus.inactive,
        message: '未找到可恢复的购买记录',
      ),
    );
    if (storeResult.success) {
      return storeResult;
    }

    final Map<String, dynamic> response = await ApiClient.restoreSubscription(
      platform: 'apple',
    );
    final CommercialEntitlementProjection entitlement =
        CommercialEntitlementProjection.fromJson(
          _asMap(response['entitlement']),
        );
    if (!entitlement.isFreshActivePaid(now: DateTime.now())) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.inactive,
        entitlement: entitlement,
        message: '未找到可恢复的购买记录',
        rawData: response,
      );
    }
    return PaymentResult(
      success: true,
      status: PaymentStatus.restored,
      entitlement: entitlement,
      message: '已恢复有效订阅',
      rawData: response,
    );
  }

  @override
  Future<PaymentResult> checkSubscriptionStatus() async {
    final Map<String, dynamic> entitlementData =
        await ApiClient.refreshEntitlements();
    final CommercialEntitlementProjection entitlement =
        CommercialEntitlementProjection.fromJson(entitlementData);
    if (!entitlement.isFreshActivePaid(now: DateTime.now())) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.inactive,
        entitlement: entitlement,
        message: '当前没有有效订阅',
        rawData: entitlementData,
      );
    }
    return PaymentResult(
      success: true,
      status: PaymentStatus.success,
      entitlement: entitlement,
      message: '订阅有效',
      rawData: entitlementData,
    );
  }

  Future<PaymentResult> _runRestoreFlow({
    required PaymentResult emptyResult,
  }) async {
    await _ensureStoreAvailable();

    final String appAccountToken = await ApiClient.currentUserId();
    final Completer<PaymentResult> completer = Completer<PaymentResult>();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        _listenToFlow(completer: completer, appAccountToken: appAccountToken);

    try {
      await _inAppPurchase.restorePurchases();
      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => emptyResult,
      );
    } finally {
      await subscription.cancel();
    }
  }

  StreamSubscription<List<PurchaseDetails>> _listenToFlow({
    required Completer<PaymentResult> completer,
    required String appAccountToken,
    String? expectedPlanId,
  }) {
    return _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchases) {
        unawaited(
          _handlePurchaseUpdates(
            purchases,
            completer: completer,
            expectedPlanId: expectedPlanId,
            appAccountToken: appAccountToken,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.complete(
            PaymentResult(
              success: false,
              status: PaymentStatus.error,
              planId: expectedPlanId,
              errorMessage: error.toString(),
            ),
          );
        }
      },
    );
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases, {
    required Completer<PaymentResult> completer,
    required String appAccountToken,
    String? expectedPlanId,
  }) async {
    if (purchases.isEmpty) {
      return;
    }

    for (final PurchaseDetails purchase in purchases) {
      final String? matchedPlanId = PaymentConfig.planIdForProduct(
        purchase.productID,
      );
      if (expectedPlanId != null && matchedPlanId != expectedPlanId) {
        continue;
      }

      final PaymentResult result = await _buildResultForPurchase(
        purchase,
        matchedPlanId: matchedPlanId,
        appAccountToken: appAccountToken,
      );
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return;
    }
  }

  Future<PaymentResult> _buildResultForPurchase(
    PurchaseDetails purchase, {
    required String? matchedPlanId,
    required String appAccountToken,
  }) async {
    try {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          return PaymentResult(
            success: false,
            status: PaymentStatus.pending,
            planId: matchedPlanId,
            productId: purchase.productID,
            message: '支付处理中，请等待 App Store 完成确认',
          );
        case PurchaseStatus.canceled:
          return PaymentResult(
            success: false,
            status: PaymentStatus.cancelled,
            planId: matchedPlanId,
            productId: purchase.productID,
            message: '你已取消购买',
          );
        case PurchaseStatus.error:
          return PaymentResult(
            success: false,
            status: PaymentStatus.error,
            planId: matchedPlanId,
            productId: purchase.productID,
            errorMessage: _errorMessageFromPurchase(purchase),
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final _AppleEntitlementVerification? verification =
              await _verifyReceipt(purchase, appAccountToken: appAccountToken);
          if (verification == null || !verification.isUsable) {
            return PaymentResult(
              success: false,
              status: PaymentStatus.error,
              planId: matchedPlanId,
              entitlement: verification?.entitlement,
              productId: purchase.productID,
              errorMessage: '收据校验失败，请稍后重试',
              rawData: _paymentRawData(
                purchase,
                backendResponse: verification?.rawData,
              ),
            );
          }
          return PaymentResult(
            success: true,
            status: purchase.status == PurchaseStatus.restored
                ? PaymentStatus.restored
                : PaymentStatus.success,
            planId: matchedPlanId,
            entitlement: verification.entitlement,
            productId: purchase.productID,
            transactionId: purchase.purchaseID,
            message: purchase.status == PurchaseStatus.restored
                ? '已恢复有效订阅'
                : '购买成功',
            rawData: _paymentRawData(
              purchase,
              backendResponse: verification.rawData,
            ),
          );
      }
    } finally {
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _ensureStoreAvailable() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw Exception('当前设备无法连接 App Store');
    }
  }

  Future<ProductDetails> _loadProduct(String planId) async {
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(<String>{PaymentConfig.productIdForPlan(planId)});

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    if (response.productDetails.isEmpty) {
      throw Exception('未找到对应的订阅商品，请检查 App Store Connect 配置');
    }

    return response.productDetails.first;
  }

  Future<_AppleEntitlementVerification?> _verifyReceipt(
    PurchaseDetails purchase, {
    required String appAccountToken,
  }) async {
    final String transactionId = (purchase.purchaseID ?? '').trim();
    if (transactionId.isEmpty || appAccountToken.trim().isEmpty) {
      return null;
    }

    final Map<String, dynamic> data = await ApiClient.verifyAppleSubscription(
      productId: purchase.productID,
      transactionId: transactionId,
      originalTransactionId: transactionId,
      appAccountToken: appAccountToken,
    );
    final String verificationStatus =
        (data['verification_status'] as String? ??
                data['verificationStatus'] as String? ??
                '')
            .trim();
    final Map<String, dynamic> entitlement = _asMap(data['entitlement']);
    final CommercialEntitlementProjection projection =
        CommercialEntitlementProjection.fromJson(entitlement);
    return _AppleEntitlementVerification(
      verified: verificationStatus == 'verified',
      entitlement: projection,
      rawData: data,
    );
  }

  String _errorMessageFromPurchase(PurchaseDetails purchase) {
    final IAPError? error = purchase.error;
    final String message = error?.message.trim() ?? '';
    return message.isEmpty ? 'App Store 支付失败，请稍后重试' : message;
  }

  Map<String, dynamic> _rawPurchaseData(PurchaseDetails purchase) {
    return <String, dynamic>{
      'purchaseId': purchase.purchaseID,
      'productId': purchase.productID,
      'transactionDate': purchase.transactionDate,
      'status': purchase.status.name,
      'source': purchase.verificationData.source,
    };
  }

  Map<String, dynamic> _paymentRawData(
    PurchaseDetails purchase, {
    Map<String, dynamic>? backendResponse,
  }) {
    final Map<String, dynamic> data = <String, dynamic>{
      'purchase': _rawPurchaseData(purchase),
    };
    if (backendResponse != null) {
      data['backend'] = backendResponse;
    }
    return data;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}

class _AppleEntitlementVerification {
  const _AppleEntitlementVerification({
    required this.verified,
    required this.entitlement,
    required this.rawData,
  });

  final bool verified;
  final CommercialEntitlementProjection entitlement;
  final Map<String, dynamic> rawData;

  bool get isUsable =>
      verified && entitlement.isFreshActivePaid(now: DateTime.now());
}
