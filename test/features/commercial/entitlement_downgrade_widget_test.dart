import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/membership_page.dart';

void main() {
  testWidgets('TC-COM-007 免费权益降级状态展示且不承诺未上线权益', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: 'free',
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
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: MembershipPage(
          currentPlan: 'yearly',
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
  });
}
