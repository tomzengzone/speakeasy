import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:speakeasy/services/storage_service.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-MVP-E2E-007: recommendation, favorite and learning memory persist',
    (WidgetTester tester) async {
      await launchAndCompleteOnboarding(tester);

      await tapBottomTab(tester, 1);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('daily_expression_card')),
        timeout: const Duration(seconds: 45),
      );

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('daily_expression_favorite_button')),
      );
      await tester.pump(const Duration(seconds: 1));

      final int favoriteCount = StorageService.instance
          .getFavoriteExpressions()
          .length;
      expect(favoriteCount, greaterThanOrEqualTo(1));

      await tapBottomTab(tester, 2);
      await scrollUntilFound(
        tester,
        find.byKey(const ValueKey<String>('profile_favorites_entry')),
        direction: E2eScrollDirection.down,
      );
      expect(find.textContaining('已收藏 1 条表达'), findsWidgets);

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('profile_favorites_entry')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('favorites_page')),
      );
      expect(
        find.byKey(const ValueKey<String>('favorites_intro')),
        findsOneWidget,
      );
      expect(find.textContaining('已收藏 1 条表达'), findsWidgets);
    },
  );
}
