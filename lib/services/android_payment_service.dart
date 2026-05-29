import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:speakeasy/config/payment_config.dart';
import 'package:speakeasy/services/api_client.dart';
import 'payment_service.dart';

class AndroidPaymentService implements PaymentService {
  AndroidPaymentService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

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

    await _ensureStoreAvailable();
    final ProductDetails product = await _loadProduct(planId);
    final Completer<PaymentResult> completer = Completer<PaymentResult>();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        _listenToFlow(completer: completer, expectedPlanId: planId);

    try {
      final bool started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        return PaymentResult(
          success: false,
          status: PaymentStatus.error,
          planId: planId,
          productId: product.id,
          errorMessage: '无法发起 Google Play 购买请求',
        );
      }

      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => PaymentResult(
          success: false,
          status: PaymentStatus.pending,
          planId: planId,
          productId: product.id,
          message: '购买请求已提交，等待 Google Play 完成确认',
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
        message: '未找到可恢复的 Google Play 订阅',
      ),
    );
    if (storeResult.success) {
      return storeResult;
    }

    final Map<String, dynamic> response = await ApiClient.restoreSubscription(
      platform: 'google',
    );
    final Map<String, dynamic> entitlement = _asMap(response['entitlement']);
    if (!_hasActiveProEntitlement(entitlement)) {
      return const PaymentResult(
        success: false,
        status: PaymentStatus.inactive,
        message: '未找到可恢复的 Google Play 订阅',
      );
    }
    return PaymentResult(
      success: true,
      status: PaymentStatus.restored,
      planId: PaymentConfig.yearlyPlanId,
      message: '已恢复有效 Google Play 订阅',
      rawData: response,
    );
  }

  @override
  Future<PaymentResult> checkSubscriptionStatus() async {
    final Map<String, dynamic> entitlement =
        await ApiClient.refreshEntitlements();
    if (!_hasActiveProEntitlement(entitlement)) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.inactive,
        message: '当前没有有效 Google Play 订阅',
        rawData: entitlement,
      );
    }
    return PaymentResult(
      success: true,
      status: PaymentStatus.success,
      planId: PaymentConfig.yearlyPlanId,
      message: 'Google Play 订阅有效',
      rawData: entitlement,
    );
  }

  Future<PaymentResult> _runRestoreFlow({
    required PaymentResult emptyResult,
  }) async {
    await _ensureStoreAvailable();

    final Completer<PaymentResult> completer = Completer<PaymentResult>();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        _listenToFlow(completer: completer);

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
    String? expectedPlanId,
  }) {
    return _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchases) {
        unawaited(
          _handlePurchaseUpdates(
            purchases,
            completer: completer,
            expectedPlanId: expectedPlanId,
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
  }) async {
    try {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          return PaymentResult(
            success: false,
            status: PaymentStatus.pending,
            planId: matchedPlanId,
            productId: purchase.productID,
            message: '支付处理中，请等待 Google Play 完成确认',
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
          final bool verified = await _validatePurchase(purchase);
          if (!verified) {
            return PaymentResult(
              success: false,
              status: PaymentStatus.error,
              planId: matchedPlanId,
              productId: purchase.productID,
              errorMessage: 'Google Play 购买凭证校验失败，请稍后重试',
              rawData: _rawPurchaseData(purchase),
            );
          }
          return PaymentResult(
            success: true,
            status: purchase.status == PurchaseStatus.restored
                ? PaymentStatus.restored
                : PaymentStatus.success,
            planId: matchedPlanId,
            productId: purchase.productID,
            transactionId: purchase.purchaseID,
            message: purchase.status == PurchaseStatus.restored
                ? '已恢复有效 Google Play 订阅'
                : 'Google Play 购买成功',
            rawData: _rawPurchaseData(purchase),
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
      throw Exception('当前设备无法连接 Google Play');
    }
  }

  Future<ProductDetails> _loadProduct(String planId) async {
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(<String>{PaymentConfig.productIdForPlan(planId)});

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    if (response.productDetails.isEmpty) {
      throw Exception('未找到对应的订阅商品，请检查 Google Play Console 配置');
    }

    return response.productDetails.first;
  }

  Future<bool> _validatePurchase(PurchaseDetails purchase) async {
    final String purchaseToken = purchase
        .verificationData
        .serverVerificationData
        .trim();
    if (purchaseToken.isEmpty) {
      return false;
    }

    final Map<String, dynamic> data = await ApiClient.verifyGoogleSubscription(
      purchaseToken: purchaseToken,
      productId: purchase.productID,
    );
    final String verificationStatus =
        (data['verification_status'] as String? ??
                data['verificationStatus'] as String? ??
                '')
            .trim();
    final String subscriptionStatus =
        (data['subscription_status'] as String? ??
                data['subscriptionStatus'] as String? ??
                '')
            .trim();
    final Map<String, dynamic> entitlement = _asMap(data['entitlement']);
    final String entitlementStatus = (entitlement['status'] as String? ?? '')
        .trim();
    return verificationStatus == 'verified' &&
        (subscriptionStatus == 'active' || entitlementStatus == 'active');
  }

  bool _hasActiveProEntitlement(Map<String, dynamic> entitlement) {
    final String plan = (entitlement['plan'] as String? ?? '').trim();
    final String status = (entitlement['status'] as String? ?? '').trim();
    return plan == 'pro' && status == 'active';
  }

  String _errorMessageFromPurchase(PurchaseDetails purchase) {
    final IAPError? error = purchase.error;
    final String message = error?.message.trim() ?? '';
    return message.isEmpty ? 'Google Play 支付失败，请稍后重试' : message;
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
