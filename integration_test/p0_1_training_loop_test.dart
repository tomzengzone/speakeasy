import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-P01-013: P0.1 training route runs fallback, feedback and recap loop',
    (WidgetTester tester) async {
      await launchAndCompleteOnboarding(tester);

      final Finder trainingButton = find.byKey(
        const ValueKey<String>('home_hero_training_button'),
      );
      await pumpUntilFound(tester, trainingButton);
      await tapAndPump(tester, trainingButton);

      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('interview_training_session_view')),
        timeout: const Duration(seconds: 30),
      );
      expect(find.text('Opening'), findsOneWidget);
      expect(find.text('SayOne'), findsOneWidget);

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('interview_training_record_button')),
      );
      await tapAndPump(
        tester,
        find.byKey(
          const ValueKey<String>('interview_training_submit_recording_button'),
        ),
      );

      await pumpUntilFound(
        tester,
        find.byKey(
          const ValueKey<String>('interview_training_text_fallback_field'),
        ),
      );
      expect(find.textContaining('ASR unavailable'), findsOneWidget);
      await tester.enterText(
        find.byKey(
          const ValueKey<String>('interview_training_text_fallback_field'),
        ),
        'I am excited to talk about my background.',
      );
      await tapAndPump(
        tester,
        find.byKey(
          const ValueKey<String>('interview_training_text_fallback_button'),
        ),
      );

      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('interview_training_feedback_panel')),
      );
      expect(find.text('Explain purpose'), findsOneWidget);
      expect(find.text('FillOne'), findsOneWidget);

      for (int attempt = 0; attempt < 16; attempt += 1) {
        if (find
            .byKey(const ValueKey<String>('interview_training_recap_panel'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
        await scrollUntilFound(
          tester,
          find.byKey(
            const ValueKey<String>('interview_training_continue_button'),
          ),
          direction: E2eScrollDirection.down,
          scrollable: find.byKey(
            const ValueKey<String>('interview_training_session_view'),
          ),
          timeout: const Duration(seconds: 8),
        );
        await tapAndPump(
          tester,
          find.byKey(
            const ValueKey<String>('interview_training_continue_button'),
          ),
        );
      }

      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('interview_training_recap_panel')),
        timeout: const Duration(seconds: 12),
      );
      expect(
        find.textContaining('Training recap for job_interview'),
        findsOneWidget,
      );
      expect(find.text('pending_local_write'), findsOneWidget);
      expect(find.textContaining('entitlement'), findsNothing);
      expect(find.textContaining('billing'), findsNothing);
      expect(find.textContaining('final mastery'), findsNothing);

      await tapAndPump(
        tester,
        find.byKey(const ValueKey<String>('interview_training_finish_button')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('home_hero_training_button')),
      );
    },
  );
}
