import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/models/storage_models.dart';

void main() {
  test('InterviewHomeSceneSelectionStorageModel round-trips json', () {
    const InterviewHomeSceneSelectionStorageModel model =
        InterviewHomeSceneSelectionStorageModel(
          selectedSceneIds: <String>['job_interview', 'small_talk'],
          activeSceneId: 'small_talk',
        );

    final InterviewHomeSceneSelectionStorageModel restored =
        InterviewHomeSceneSelectionStorageModel.fromJson(model.toJson());

    expect(restored.selectedSceneIds, <String>['job_interview', 'small_talk']);
    expect(restored.activeSceneId, 'small_talk');
  });

  test('InterviewHomeSceneSelectionStorageModel trims empty active id', () {
    final InterviewHomeSceneSelectionStorageModel restored =
        InterviewHomeSceneSelectionStorageModel.fromJson(<String, dynamic>{
          'selectedSceneIds': <String>[' job_interview ', '', 'job_interview'],
          'activeSceneId': '  ',
        });

    expect(restored.selectedSceneIds, <String>[
      'job_interview',
      'job_interview',
    ]);
    expect(restored.activeSceneId, isNull);
  });
}
