import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speakeasy/config/payment_config.dart';
import 'package:speakeasy/features/commercial/commercial_scenario_gate.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/membership_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-COM-020 首装免费边界展示可恢复会员入口且不承诺未上线权益', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: PaymentConfig.freePlanId,
          isLoading: false,
          onBack: () {},
          onSubscribe: (_) async {},
          onRestorePurchases: () async {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('membership_free_gate_banner')),
      findsOneWidget,
    );
    expect(find.textContaining('L3 高级场景'), findsWidgets);
    expect(find.text('离线学习包'), findsNothing);
    expect(find.text('专属学习报告'), findsNothing);
  });

  test('TC-COM-020 旧会员计划数据不会授予未知权益', () {
    expect(
      PaymentConfig.normalizePlanId('lifetime'),
      PaymentConfig.yearlyPlanId,
    );
    expect(
      PaymentConfig.normalizePlanId('legacy-pro'),
      PaymentConfig.freePlanId,
    );
    expect(PaymentConfig.normalizePlanId(''), PaymentConfig.freePlanId);
  });

  test('TC-COM-020 非付费用户额度/权益耗尽时 L3 场景保持锁定', () {
    expect(
      CommercialScenarioGate.canAccess(
        targetLevel: CommercialScenarioGate.proTargetLevel,
        isPro: false,
      ),
      isFalse,
    );
    expect(
      CommercialScenarioGate.canAccess(
        targetLevel: CommercialScenarioGate.proTargetLevel,
        isPro: true,
      ),
      isTrue,
    );
  });

  testWidgets('TC-COM-020 弱网或 provider 错误保持可恢复操作', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: PaymentConfig.freePlanId,
          isLoading: false,
          errorMessage: '网络不可用，请稍后重试或恢复购买。',
          onBack: () {},
          onSubscribe: (_) async {},
          onRestorePurchases: () async {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('网络不可用，请稍后重试或恢复购买。'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('网络不可用，请稍后重试或恢复购买。'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('membership_restore_purchases_button')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey<String>('membership_restore_purchases_button')),
      findsOneWidget,
    );
  });
}
