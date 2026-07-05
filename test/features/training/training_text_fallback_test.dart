import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/training/training_session_view.dart';

import 'training_test_helpers.dart';

void main() {
  testWidgets('TC-P01-007 text fallback is visible only as fallback path', (
    WidgetTester tester,
  ) async {
    String typed = '';
    int fallbackCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainingSessionView(
            session: p01TrainingSession(textFallbackAvailable: true),
            onTextChanged: (String value) => typed = value,
            onTextFallback: () => fallbackCount += 1,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('training_text_fallback_field')),
      'I am excited to discuss the role.',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('training_text_fallback_button')),
    );

    expect(typed, 'I am excited to discuss the role.');
    expect(fallbackCount, 1);
    expect(find.textContaining('Fallback path'), findsOneWidget);
  });

  testWidgets('TC-P01-007 default voice path hides text fallback field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainingSessionView(session: p01TrainingSession()),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('training_text_fallback_field')),
      findsNothing,
    );
  });
}
