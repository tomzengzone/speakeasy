import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/services/storage_service.dart';

const String _boxName = 'speakeasy_storage';
const String _migrationVersionKey = '_storage_migration_version';
const List<String> _legacyInterviewKeys = <String>[
  'favorite_expressions',
  'interview_personal_wiki_expressions',
  'interview_compiled_wiki',
  'interview_user_growth_wiki',
  'interview_active_session',
  'interview_active_session_onboarding_introduction',
  'interview_dismissed_wiki_items',
  'interview_useful_wiki_items',
  'interview_expression_learning_progress',
  'interview_scene_level_preferences',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'speakeasy_cefr_storage_migration_',
    );
    Hive.init(hiveDirectory.path);
    final Box<dynamic> seedBox = await Hive.openBox<dynamic>(_boxName);
    await seedBox.put(_migrationVersionKey, 1);
    for (final String key in _legacyInterviewKeys) {
      await seedBox.put(key, <String, dynamic>{
        'targetLevel': 'L1',
        'nodeId': 'L1_01',
      });
    }
    await seedBox.put('unrelated_key', 'preserved');
    await Hive.close();

    await StorageService.instance.init(
      hivePath: hiveDirectory.path,
      migrateFromSharedPreferences: false,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('migration v2 clears all level- and node-dependent local data', () {
    final Box<dynamic> box = Hive.box<dynamic>(_boxName);

    expect(box.get(_migrationVersionKey), 2);
    for (final String key in _legacyInterviewKeys) {
      expect(box.containsKey(key), isFalse, reason: key);
    }
    expect(box.get('unrelated_key'), 'preserved');
  });

  test('strict preference reader never converts legacy values to A2', () async {
    for (final String legacyLevel in <String>[
      'L1',
      'L2',
      'L3',
      'beginner',
      'intermediate',
      'advanced',
    ]) {
      await StorageService.instance.saveObject<Map<String, String>>(
        'interview_scene_level_preferences',
        <String, String>{'job_interview': legacyLevel},
        (Map<String, String> value) => <String, dynamic>{...value},
      );

      expect(
        () => const InterviewWikiStore().loadSelectedTargetLevel(),
        throwsFormatException,
        reason: '$legacyLevel must not become A2',
      );
    }
  });
}
