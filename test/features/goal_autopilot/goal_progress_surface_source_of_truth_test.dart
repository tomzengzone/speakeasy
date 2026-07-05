import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/goal_autopilot/goal_autopilot_adapter.dart';
import 'package:speakeasy/features/goal_autopilot/goal_progress_surface.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';

import 'goal_progress_projection_fixtures.dart';

void main() {
  test(
    'TC-P02-FUC-016 surfaces consume backend projection as source of truth',
    () async {
      final List<GoalAutopilotRequest> requests = <GoalAutopilotRequest>[];
      final GoalAutopilotAdapter adapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          requests.add(request);
          return goalProgressProjectionResponseFixture();
        },
      );

      final projection = await adapter.loadProgressProjection();

      expect(requests, hasLength(1));
      expect(
        requests.single.operation,
        GoalAutopilotOperation.progressProjection,
      );
      expect(
        requests.single.path,
        SpeakeasyApiPaths.goalAutopilotProgressProjection,
      );
      expect(
        projection.fragmentFor(GoalProgressSurface.home)?.eligible,
        isTrue,
      );
      expect(
        projection.fragmentFor(GoalProgressSurface.queue)?.eligible,
        isTrue,
      );
      expect(
        projection.fragmentFor(GoalProgressSurface.wiki)?.eligible,
        isTrue,
      );
      expect(projection.sourceRefs, contains('forecast:forecast_id_sample'));
      expect(
        projection.sourceRefs,
        contains('checkpoint:checkpoint_id_sample'),
      );

      final List<String> safeFields = projection.surfaceFragments
          .expand((fragment) => fragment.safeFields)
          .toList(growable: false);
      for (final String forbidden in <String>[
        'diagnostic',
        'rubric_scores',
        'target_ability',
        'target_score',
        'transcript',
        'audio_ref',
        'provider_payload',
        'queue_priority',
      ]) {
        expect(safeFields, isNot(contains(forbidden)), reason: forbidden);
      }

      final String homeSource = File(
        'lib/features/goal_autopilot/goal_autopilot_panel.dart',
      ).readAsStringSync();
      final String queueSource = File(
        'lib/features/interview/interview_expression_learning_page.dart',
      ).readAsStringSync();
      final String wikiSource = File(
        'lib/pages/home_page.dart',
      ).readAsStringSync();
      final String coordinatorSource = File(
        'lib/features/interview/expression_daily_queue_coordinator.dart',
      ).readAsStringSync();
      final String surfaceSource = File(
        'lib/features/goal_autopilot/goal_progress_surface.dart',
      ).readAsStringSync();

      expect(homeSource, contains('GoalProgressHomeSurface'));
      expect(queueSource, contains('GoalProgressQueueSurface'));
      expect(wikiSource, contains('GoalProgressWikiSurface'));
      expect(coordinatorSource, isNot(contains('GoalProgressProjection')));
      expect(surfaceSource, isNot(contains('targetScore')));
      expect(surfaceSource, isNot(contains('targetAbility')));
      expect(surfaceSource, isNot(contains('goalCompletionClaimAllowed')));
      expect(surfaceSource, isNot(contains('etaDate')));
    },
  );

  test(
    'TC-P02-FUC-016 optional projection fallback does not hide API failures',
    () async {
      final GoalAutopilotAdapter legacyAdapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async => <String, dynamic>{
          'schema_version': 1,
        },
      );

      expect(await legacyAdapter.loadOptionalProgressProjection(), isNull);

      final GoalAutopilotAdapter failingAdapter = GoalAutopilotAdapter(
        transport: (GoalAutopilotRequest request) async {
          throw Exception('projection unavailable');
        },
      );

      await expectLater(
        failingAdapter.loadOptionalProgressProjection(),
        throwsA(isA<Exception>()),
      );
    },
  );
}
