import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';
import 'package:speakeasy/features/commercial/commercial_scenario_gate.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/pages/home_page.dart';

const Set<String> _cefrLevels = <String>{'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
const Set<String> _authoredLevels = <String>{'A2', 'B1', 'B2'};
const Set<String> _hintLevels = <String>{'L1', 'L2', 'L3', 'L4'};
final RegExp _legacyLevelToken = RegExp(
  r'(^|[^A-Za-z0-9])(L1|L2|L3|beginner|intermediate|advanced)(?=$|[^A-Za-z0-9])',
  caseSensitive: false,
);

void main() {
  group('CONTENT-CEFR-API-001', () {
    test('bundled scene catalog resolves only strict CEFR scene assets', () {
      final Map<String, dynamic> catalog = _readJson(
        'assets/data/interview_scene_catalog.json',
      );
      final List<Map<String, dynamic>> scenes = _mapList(catalog['scenes']);

      expect(scenes, isNotEmpty);
      for (final Map<String, dynamic> scene in scenes) {
        final String assetPath = scene['assetPath'] as String;
        expect(File(assetPath).existsSync(), isTrue, reason: assetPath);
        expect(
          _legacyLevelToken.hasMatch(jsonEncode(scene)),
          isFalse,
          reason: 'Legacy level metadata remains in $assetPath',
        );
        _expectSceneAssetIsReferenceSafe(assetPath, scene['id'] as String);
      }
    });

    test('legacy bundled job-interview entry remains CEFR reference-safe', () {
      _expectSceneAssetIsReferenceSafe(
        'assets/data/interview_scene_wiki.json',
        'job_interview',
      );
    });

    test(
      'scene runtime rejects legacy and unknown levels without fallback',
      () {
        final InterviewSceneGraph graph = InterviewSceneGraph.fromJson(
          _readJson('assets/data/interview_scene_wikis/job_interview.json'),
        );

        expect(graph.flowNodeIdsForLevel('A1'), isEmpty);
        expect(graph.flowNodeIdsForLevel('C1'), isEmpty);
        expect(graph.flowNodeIdsForLevel('C2'), isEmpty);
        expect(() => graph.flowNodeIdsForLevel('L1'), throwsFormatException);
        expect(
          () => graph.flowNodeIdsForLevel('beginner'),
          throwsFormatException,
        );
        expect(
          () => graph.flowNodeIdsForLevel('unknown'),
          throwsFormatException,
        );
      },
    );

    test('home preserves valid CEFR selections without authored content', () {
      final InterviewSceneGraph graph = InterviewSceneGraph.fromJson(
        _readJson('assets/data/interview_scene_wikis/job_interview.json'),
      );

      for (final String level in <String>['A1', 'C1', 'C2']) {
        expect(
          resolveInterviewHomeTargetLevel(graph, level),
          level,
          reason: '$level must not be replaced by the first authored track',
        );
      }
      expect(
        () => resolveInterviewHomeTargetLevel(graph, 'L1'),
        throwsFormatException,
        reason: 'A legacy stored value must not become A2',
      );
    });

    test('commercial gate preserves only the migrated B2 track gate', () {
      expect(CommercialScenarioGate.requiresPro('B2'), isTrue);
      for (final String level in <String>['A1', 'A2', 'B1', 'C1', 'C2']) {
        expect(
          CommercialScenarioGate.requiresPro(level),
          isFalse,
          reason: '$level must not inherit the B2 entitlement gate',
        );
      }
      expect(
        () => CommercialScenarioGate.requiresPro('L3'),
        throwsArgumentError,
      );
      expect(
        () => CommercialScenarioGate.requiresPro('advanced'),
        throwsArgumentError,
      );

      final CommercialEntitlementProjection free =
          CommercialEntitlementProjection.unknown();
      expect(
        CommercialScenarioGate.decisionFor(
          targetLevel: 'C1',
          entitlement: free,
        ).allowed,
        isTrue,
      );
    });
  });
}

void _expectSceneAssetIsReferenceSafe(String path, String expectedSceneId) {
  final Map<String, dynamic> asset = _readJson(path);
  final Map<String, dynamic> meta = (asset['meta'] as Map)
      .cast<String, dynamic>();
  final List<Map<String, dynamic>> nodes = _mapList(asset['nodes']);
  final Set<String> nodeIds = nodes
      .map((Map<String, dynamic> node) => node['id'] as String)
      .toSet();

  expect(meta['id'], expectedSceneId, reason: path);
  expect(
    nodeIds,
    hasLength(nodes.length),
    reason: 'Duplicate node IDs in $path',
  );
  expect(
    _mapList(
      asset['tracks'],
    ).map((Map<String, dynamic> track) => track['targetLevel']).toSet(),
    _authoredLevels,
    reason: path,
  );

  for (final Map<String, dynamic> track in _mapList(asset['tracks'])) {
    final String level = track['targetLevel'] as String;
    expect(_cefrLevels, contains(level), reason: path);
    expect(track['id'], level, reason: path);
    _expectReferencesExist(track['nodeIds'], nodeIds, '$path track $level');
  }

  for (final Map<String, dynamic> phase in _mapList(asset['phases'])) {
    _expectReferencesExist(
      phase['nodeIds'],
      nodeIds,
      '$path phase ${phase['id']}',
    );
  }
  _expectReferencesExist(asset['flow'], nodeIds, '$path flow');

  for (final Map<String, dynamic> slot in _mapList(asset['levelMap'])) {
    final Map<String, dynamic> levels = (slot['levels'] as Map)
        .cast<String, dynamic>();
    expect(levels.keys.toSet(), _authoredLevels, reason: '$path levelMap');
    _expectReferencesExist(levels.values, nodeIds, '$path levelMap');
  }

  for (final Map<String, dynamic> node in nodes) {
    final String id = node['id'] as String;
    final String level = node['level'] as String;
    expect(_cefrLevels, contains(level), reason: '$path node $id');
    expect(node['targetLevel'], level, reason: '$path node $id');
    final String expectedPrefix = expectedSceneId == 'onboarding_introduction'
        ? 'ONB_${level}_'
        : '${level}_';
    expect(id, startsWith(expectedPrefix), reason: '$path node $id');
    for (final String key in <String>[
      'dependencies',
      'previousIds',
      'nextIds',
      'equivalentIds',
    ]) {
      _expectReferencesExist(node[key], nodeIds, '$path node $id $key');
    }

    final Map<String, dynamic> hintTree = (node['hintTree'] as Map)
        .cast<String, dynamic>();
    expect(
      hintTree.keys.toSet(),
      _hintLevels,
      reason: '$path node $id hintTree must remain L1-L4',
    );
  }

  _expectNoLegacyLevelsOutsideHintOrMastery(asset, path: path);
}

void _expectReferencesExist(
  Object? rawReferences,
  Set<String> nodeIds,
  String source,
) {
  final Iterable<Object?> references = rawReferences is Iterable
      ? rawReferences.cast<Object?>()
      : const <Object?>[];
  for (final Object? rawReference in references) {
    expect(rawReference, isA<String>(), reason: source);
    expect(nodeIds, contains(rawReference), reason: '$source -> $rawReference');
  }
}

void _expectNoLegacyLevelsOutsideHintOrMastery(
  Object? value, {
  required String path,
  String field = r'$',
  bool excludedNamespace = false,
}) {
  if (value is Map) {
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final String key = entry.key.toString();
      final String lowerKey = key.toLowerCase();
      final bool excluded =
          excludedNamespace ||
          lowerKey.contains('hint') ||
          lowerKey.contains('scaffold') ||
          lowerKey.contains('mastery');
      if (!excluded) {
        expect(
          _legacyLevelToken.hasMatch(key),
          isFalse,
          reason: '$path $field key $key',
        );
      }
      _expectNoLegacyLevelsOutsideHintOrMastery(
        entry.value,
        path: path,
        field: '$field.$key',
        excludedNamespace: excluded,
      );
    }
    return;
  }
  if (value is Iterable) {
    int index = 0;
    for (final Object? item in value) {
      _expectNoLegacyLevelsOutsideHintOrMastery(
        item,
        path: path,
        field: '$field[$index]',
        excludedNamespace: excludedNamespace,
      );
      index += 1;
    }
    return;
  }
  if (value is String && !excludedNamespace) {
    expect(
      _legacyLevelToken.hasMatch(value),
      isFalse,
      reason: '$path $field: $value',
    );
  }
}

Map<String, dynamic> _readJson(String path) {
  return (jsonDecode(File(path).readAsStringSync()) as Map)
      .cast<String, dynamic>();
}

List<Map<String, dynamic>> _mapList(Object? value) {
  return (value as List<dynamic>)
      .map((dynamic item) => (item as Map).cast<String, dynamic>())
      .toList(growable: false);
}
