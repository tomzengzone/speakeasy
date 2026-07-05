import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-MVP-E2E-006: scene catalog, join scene and listening warmup path',
    (WidgetTester tester) async {
      await launchAndCompleteOnboarding(tester);

      final Finder introSceneCard = find.byKey(
        const ValueKey<String>('home_scene_grid_card_onboarding_introduction'),
      );
      await scrollUntilFound(
        tester,
        introSceneCard,
        direction: E2eScrollDirection.down,
        scrollable: find.byKey(const ValueKey<String>('home_learn_scroll')),
        timeout: const Duration(seconds: 20),
      );
      await tapAndPump(tester, introSceneCard);

      await pumpUntilFound(tester, find.text('入职介绍'));
      expect(find.text('下一步'), findsWidgets);
      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('home_scene_intro_join_button')),
      );
      await pumpUntilFound(tester, find.text('已加入学习'));

      await tapAndPump(tester, find.text('返回'));
      await waitForHome(tester);

      final Finder listeningButton = find.byKey(
        const ValueKey<String>('home_hero_listen_button'),
      );
      await scrollUntilFound(
        tester,
        listeningButton,
        direction: E2eScrollDirection.up,
        scrollable: find.byKey(const ValueKey<String>('home_learn_scroll')),
        timeout: const Duration(seconds: 20),
      );
      await tapAndPump(tester, listeningButton);

      await pumpUntilFound(
        tester,
        find.text('开始热身'),
        timeout: const Duration(seconds: 30),
      );
      expect(find.textContaining('听完整对话'), findsWidgets);

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('listening_mode_toggle')),
      );
      await pumpUntilFound(tester, find.textContaining('跟读目标表达'));
    },
  );
}
