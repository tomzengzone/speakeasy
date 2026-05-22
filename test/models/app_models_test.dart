import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/models/app_models.dart';

void main() {
  test('bottom tabs only expose learning, expression and profile modules', () {
    expect(
      bottomTabs.map((item) => item.label).toList(growable: false),
      <String>['情景学习', '推荐表达', '我的'],
    );
  });
}
