import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:speakeasy/services/storage_service.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-MVP-E2E-009: profile, settings, session persistence and relogin',
    (WidgetTester tester) async {
      const String updatedNickname = 'MVP E2E User';

      await launchAndCompleteOnboarding(tester);

      await tapBottomTab(tester, 2);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('profile_header')),
      );

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('profile_edit_button')),
      );
      await scrollUntilFound(
        tester,
        find.byKey(const ValueKey<String>('edit_profile_nickname_input')),
        direction: E2eScrollDirection.down,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('edit_profile_nickname_input')),
        updatedNickname,
      );
      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('edit_profile_save_button')),
      );
      await pumpUntilFound(tester, find.text(updatedNickname));

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('profile_settings_button')),
      );
      await scrollUntilFound(
        tester,
        find.byKey(const ValueKey<String>('profile_dark_mode_switch')),
        direction: E2eScrollDirection.down,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('profile_dark_mode_switch')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final Switch darkModeSwitch = tester.widget<Switch>(
        find.byKey(const ValueKey<String>('profile_dark_mode_switch')),
      );
      expect(darkModeSwitch.value, isTrue);

      await tester.pump(const Duration(seconds: 2));
      await scrollUntilFound(
        tester,
        find.byKey(const ValueKey<String>('profile_logout_button')),
        direction: E2eScrollDirection.down,
        timeout: const Duration(seconds: 20),
      );
      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('profile_logout_button')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('login_phone_method')),
        timeout: const Duration(seconds: 30),
      );
      await _waitForClearedAuthSession(tester);

      await loginWithTestPhone(tester);
      final int reloginDestination = await pumpUntilAny(tester, <Finder>[
        find.byKey(const ValueKey<String>('home_bottom_tab_0')),
        find.text('先选最需要突破的英语场景'),
      ], timeout: const Duration(seconds: 45));
      expect(
        reloginDestination,
        0,
        reason: 'Re-login should restore backend onboarding/session state.',
      );

      await tapBottomTab(tester, 2);
      await pumpUntilFound(
        tester,
        find.text(updatedNickname),
        timeout: const Duration(seconds: 45),
      );
    },
  );
}

Future<void> _waitForClearedAuthSession(WidgetTester tester) async {
  for (int attempt = 0; attempt < 30; attempt += 1) {
    if (StorageService.instance.getAuthSession() == null) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Auth session was not cleared after logout');
}
