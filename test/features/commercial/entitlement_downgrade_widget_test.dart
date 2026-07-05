import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/membership_page.dart';

void main() {
  testWidgets('TC-COM-007 免费权益降级状态展示且不承诺未上线权益', (WidgetTester tester) async {
    await _setMembershipSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: 'free',
          entitlementProjection: _freeEntitlement(),
          isLoading: false,
          onBack: () {},
          onSubscribe: (_) async {},
          onRestorePurchases: () async {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('membership_page')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('membership_free_gate_banner')),
      findsOneWidget,
    );
    expect(find.text('当前为免费版'), findsOneWidget);
    expect(find.textContaining('L3 高级场景'), findsOneWidget);
    expect(find.text('离线学习包'), findsNothing);
    expect(find.text('专属学习报告'), findsNothing);
  });

  testWidgets('TC-COM-007 付费状态不展示免费降级提示', (WidgetTester tester) async {
    await _setMembershipSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: 'yearly',
          entitlementProjection: _proEntitlement(),
          isLoading: false,
          onBack: () {},
          onSubscribe: (_) async {},
          onRestorePurchases: () async {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('membership_free_gate_banner')),
      findsNothing,
    );
    await _scrollToSubscribeButton(tester);
    final FilledButton button = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('membership_subscribe_button')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('当前方案'), findsOneWidget);
  });

  testWidgets('TC-COM-007 本地付费方案没有后端权益时仍展示降级提示', (WidgetTester tester) async {
    await _setMembershipSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: 'yearly',
          entitlementProjection: _freeEntitlement(),
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
    await _scrollToSubscribeButton(tester);
    final FilledButton button = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('membership_subscribe_button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('TC-COM-007 后端付费权益但商品方案未知时禁用重复订阅', (WidgetTester tester) async {
    await _setMembershipSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: 'free',
          entitlementProjection: _proEntitlement(),
          isLoading: false,
          onBack: () {},
          onSubscribe: (_) async {},
          onRestorePurchases: () async {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('membership_free_gate_banner')),
      findsNothing,
    );
    await _scrollToSubscribeButton(tester);
    final FilledButton button = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('membership_subscribe_button')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('订阅已生效'), findsOneWidget);
  });
}

Future<void> _setMembershipSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _scrollToSubscribeButton(WidgetTester tester) async {
  final Finder button = find.byKey(
    const ValueKey<String>('membership_subscribe_button'),
  );
  for (int i = 0; i < 8 && button.evaluate().isEmpty; i += 1) {
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pumpAndSettle();
  }
  expect(button, findsOneWidget);
}

CommercialEntitlementProjection _freeEntitlement() {
  return CommercialEntitlementProjection.fromJson(<String, dynamic>{
    'plan': 'free',
    'status': 'active',
    'features': <String, dynamic>{'advanced_scenarios': false},
    'validUntil': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    'generatedAt': DateTime.now().toIso8601String(),
  });
}

CommercialEntitlementProjection _proEntitlement() {
  return CommercialEntitlementProjection.fromJson(<String, dynamic>{
    'plan': 'pro',
    'status': 'active',
    'features': <String, dynamic>{'advanced_scenarios': true},
    'validUntil': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    'generatedAt': DateTime.now().toIso8601String(),
  });
}
