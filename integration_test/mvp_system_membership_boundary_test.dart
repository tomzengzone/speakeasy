import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-MVP-E2E-010: membership boundary UI with external payment gate',
    (WidgetTester tester) async {
      await launchAndCompleteOnboarding(tester);

      await tapBottomTab(tester, 2);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('profile_subscription_panel')),
      );
      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('profile_subscription_panel')),
      );

      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('membership_page')),
      );
      expect(find.text('升级到 Pro'), findsWidgets);
      expect(find.text('AI 深度反馈'), findsWidgets);
      await scrollUntilFound(
        tester,
        find.byKey(const ValueKey<String>('membership_plan_weekly')),
        direction: E2eScrollDirection.down,
      );
      await scrollUntilFound(
        tester,
        find.byKey(const ValueKey<String>('membership_plan_yearly')),
        direction: E2eScrollDirection.down,
      );

      await scrollUntilFound(
        tester,
        find.byKey(const ValueKey<String>('membership_subscribe_button')),
        direction: E2eScrollDirection.down,
        timeout: const Duration(seconds: 20),
      );
      expect(
        find.byKey(const ValueKey<String>('membership_subscribe_button')),
        findsOneWidget,
      );
      await scrollUntilFound(
        tester,
        find.byKey(
          const ValueKey<String>('membership_restore_purchases_button'),
        ),
        direction: E2eScrollDirection.down,
        timeout: const Duration(seconds: 20),
      );
      expect(
        find.byKey(
          const ValueKey<String>('membership_restore_purchases_button'),
        ),
        findsOneWidget,
      );

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('membership_back_button')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('profile_subscription_panel')),
      );
    },
  );
}
