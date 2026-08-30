import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/login_page.dart';

void main() {
  setUp(() {
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://api.test.local
ENABLE_ACCOUNT_RECOVERY=true
''',
    );
  });

  testWidgets('phone login exposes the account recovery entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: LoginPage(isLoading: false, onSubmit: (_) async {}),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('login_phone_method')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('login_account_recovery_entry')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('login_account_recovery_entry')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('account_recovery_privacy_notice')),
      findsOneWidget,
    );
  });

  testWidgets('account recovery entry stays closed unless explicitly enabled', (
    WidgetTester tester,
  ) async {
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://api.test.local
ENABLE_ACCOUNT_RECOVERY=false
''',
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: LoginPage(isLoading: false, onSubmit: (_) async {}),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('login_phone_method')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('login_account_recovery_entry')),
      findsNothing,
    );
  });
}
