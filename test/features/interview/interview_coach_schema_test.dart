import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_coach_schema.dart';
import 'package:speakeasy/features/interview/interview_models.dart';

void main() {
  const List<String> sceneWikiPaths = <String>[
    'assets/data/interview_scene_wikis/job_interview.json',
    'assets/data/interview_scene_wikis/onboarding_introduction.json',
  ];

  test('scene capability wikis use registry and global move library', () {
    final File capabilityFile = File('assets/data/capability_registry.json');
    final File moveLibraryFile = File('assets/data/coach_move_library.json');
    final Map<String, dynamic> capabilityRegistry =
        jsonDecode(capabilityFile.readAsStringSync()) as Map<String, dynamic>;
    final Map<String, dynamic> moveLibrary =
        jsonDecode(moveLibraryFile.readAsStringSync()) as Map<String, dynamic>;
    final Set<String> capabilityIds =
        (capabilityRegistry['capabilities'] as List<dynamic>)
            .map(
              (dynamic item) => (item as Map<String, dynamic>)['id'] as String,
            )
            .toSet();
    final Set<String> moveIds = (moveLibrary['moves'] as List<dynamic>)
        .map(
          (dynamic item) => (item as Map<String, dynamic>)['moveId'] as String,
        )
        .toSet();

    for (final String wikiPath in sceneWikiPaths) {
      final File wikiFile = File(wikiPath);
      final Map<String, dynamic> wiki =
          jsonDecode(wikiFile.readAsStringSync()) as Map<String, dynamic>;
      final List<dynamic> nodes = wiki['nodes'] as List<dynamic>;
      for (final dynamic rawNode in nodes) {
        final Map<String, dynamic> node = rawNode as Map<String, dynamic>;
        final String nodeId =
            '${wiki['meta']?['id'] ?? wikiPath}/${node['id']}';
        final Map<String, dynamic> capability =
            node['capability'] as Map<String, dynamic>;
        final String primaryIntent = capability['primaryIntent'] as String;
        expect(
          capabilityIds,
          contains(primaryIntent),
          reason: '$nodeId uses unknown capability $primaryIntent',
        );
        expect(
          capability['subSkills'] as List<dynamic>,
          isNotEmpty,
          reason: '$nodeId must define capability subSkills',
        );
        final Map<String, dynamic> communicativeIntent =
            node['communicativeIntent'] as Map<String, dynamic>;
        expect(
          communicativeIntent['id'],
          primaryIntent,
          reason: '$nodeId communicativeIntent must match capability',
        );
        expect(
          communicativeIntent['requiredCapabilities'] as List<dynamic>,
          isNotEmpty,
          reason: '$nodeId must define required capability coverage',
        );
        expect(node['narrative'], isA<Map<String, dynamic>>());
        expect(node['teachingVisibility'], isA<Map<String, dynamic>>());
        expect(node['correctionPolicy'], isA<Map<String, dynamic>>());
        expect(
          (node['correctionPolicy'] as Map<String, dynamic>)['grammar'],
          'delayed',
          reason: '$nodeId grammar correction should not interrupt flow',
        );
        final List<dynamic> allowedMoves =
            node['allowedMoves'] as List<dynamic>;
        expect(allowedMoves, isNotEmpty, reason: '$nodeId must define moves');
        for (final dynamic rawMoveId in allowedMoves) {
          final String moveId = rawMoveId as String;
          expect(
            moveIds,
            contains(moveId),
            reason: '$nodeId uses move outside global library: $moveId',
          );
          expect(
            InterviewCoachSchema.isCoachMoveId(moveId),
            isTrue,
            reason: '$nodeId has invalid move id $moveId',
          );
        }

        final Map<String, dynamic> coachMoves =
            node['coachMoves'] as Map<String, dynamic>;
        final Map<String, dynamic> rubric =
            coachMoves['masteryRubric'] as Map<String, dynamic>;
        final List<dynamic> requiredSignals =
            rubric['requiredSignals'] as List<dynamic>;
        expect(
          requiredSignals,
          isNotEmpty,
          reason: '$nodeId must define structured requiredSignals',
        );
        for (final dynamic rawSignal in requiredSignals) {
          final Map<String, dynamic> signal = rawSignal as Map<String, dynamic>;
          expect(signal['id'] as String, isNotEmpty);
          expect(
            signal['examples'] as List<dynamic>,
            isNotEmpty,
            reason: '$nodeId signal ${signal['id']} needs examples',
          );
        }
      }
    }
  });

  test(
    'runtime coach payload is compressed and excludes full node move logic',
    () {
      for (final String wikiPath in sceneWikiPaths) {
        final File wikiFile = File(wikiPath);
        final Map<String, dynamic> wiki =
            jsonDecode(wikiFile.readAsStringSync()) as Map<String, dynamic>;
        final InterviewSceneGraph graph = InterviewSceneGraph.fromJson(wiki);

        for (final InterviewExpressionNode node in graph.nodes.take(5)) {
          final Map<String, dynamic> runtimeJson = node.coachMoves
              .toRuntimeJson(
                targetText: node.targetText,
                capability: node.capability,
                communicativeIntent: node.communicativeIntent,
                narrative: node.narrative,
                teachingVisibility: node.teachingVisibility,
                correctionPolicy: node.correctionPolicy,
                delayedFeedback: node.delayedFeedback,
                allowedMoves: node.allowedMoves,
                nodeInputs: node.nodeInputs,
                adaptivePolicy: node.adaptivePolicy,
                expectedVariants: node.expectedVariants,
                fallbackRubric: node.coachRubric,
                speechFocus: node.speechFocus,
                contextVariants: node.contextVariants,
              );

          expect(runtimeJson.containsKey('moveSet'), isFalse);
          expect(runtimeJson.containsKey('hintTree'), isFalse);
          expect(runtimeJson.containsKey('transferTasks'), isFalse);
          expect(runtimeJson['capability'], isA<Map<String, dynamic>>());
          expect(
            runtimeJson['communicativeIntent'],
            isA<Map<String, dynamic>>(),
          );
          expect(runtimeJson['narrative'], isA<Map<String, dynamic>>());
          expect(
            runtimeJson['teachingVisibility'],
            isA<Map<String, dynamic>>(),
          );
          expect(runtimeJson['correctionPolicy'], isA<Map<String, dynamic>>());
          expect(runtimeJson['allowedMoves'], isA<List<dynamic>>());
          final Map<String, dynamic> rubric =
              runtimeJson['masteryRubric'] as Map<String, dynamic>;
          final List<dynamic> signals =
              rubric['requiredSignals'] as List<dynamic>;
          expect(signals.first, isA<Map<String, dynamic>>());
        }
      }
    },
  );

  test(
    'legacy moveSet still uses stable enum values while compatibility lasts',
    () {
      for (final String wikiPath in sceneWikiPaths) {
        final File wikiFile = File(wikiPath);
        final Map<String, dynamic> wiki =
            jsonDecode(wikiFile.readAsStringSync()) as Map<String, dynamic>;
        final List<dynamic> nodes = wiki['nodes'] as List<dynamic>;

        for (final dynamic rawNode in nodes) {
          final Map<String, dynamic> node = rawNode as Map<String, dynamic>;
          final String nodeId =
              '${wiki['meta']?['id'] ?? wikiPath}/${node['id']}';
          final Map<String, dynamic> coachMoves =
              node['coachMoves'] as Map<String, dynamic>;
          final List<dynamic> moveSet =
              coachMoves['moveSet'] as List<dynamic>? ?? const <dynamic>[];

          for (final dynamic rawMove in moveSet) {
            final Map<String, dynamic> move = rawMove as Map<String, dynamic>;
            expect(
              InterviewCoachSchema.isCoachMoveId(move['id'] as String),
              isTrue,
              reason: '$nodeId has invalid move id ${move['id']}',
            );
            expect(
              InterviewCoachSchema.isTeachingStage(move['stage'] as String),
              isTrue,
              reason: '$nodeId has invalid stage ${move['stage']}',
            );
            for (final dynamic trigger in move['when'] as List<dynamic>) {
              expect(
                InterviewCoachSchema.isTriggerCode(trigger as String),
                isTrue,
                reason: '$nodeId has invalid trigger $trigger',
              );
            }
            final Map<String, dynamic> policy =
                move['plannerPolicy'] as Map<String, dynamic>;
            expect(
              InterviewCoachSchema.isNextAction(
                policy['afterSuccess'] as String,
              ),
              isTrue,
              reason: '$nodeId has invalid afterSuccess',
            );
            expect(
              InterviewCoachSchema.isNextAction(policy['afterFail'] as String),
              isTrue,
              reason: '$nodeId has invalid afterFail',
            );
          }
        }
      }
    },
  );
}
