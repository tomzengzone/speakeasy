import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/core/bootstrap/app_root.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://47.98.225.160/api
OPENAI_API_KEY=sk-test
ENV=test
''',
    );
    hiveDir = await Directory.systemTemp.createTemp('speakeasy_widget_test_');
    await StorageService.instance.init(hivePath: hiveDir.path);
  });

  tearDownAll(() async {
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  testWidgets('renders the static home UI', (tester) async {
    await tester.pumpWidget(
      SpeakEasyAppRoot(session: AppSession(), audioService: AudioService()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SpeakEasyAppRoot), findsOneWidget);
  });
}
