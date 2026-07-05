import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MVP system smoke: login, onboarding and home use the real backend',
    (WidgetTester tester) async {
      await launchAndCompleteOnboarding(tester);

      expect(find.text('学习场景'), findsWidgets);
      expect(find.text('英语面试'), findsWidgets);
    },
  );
}
