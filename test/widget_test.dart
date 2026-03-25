import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/app_session.dart';
import 'package:speakeasy/audio_service.dart';
import 'package:speakeasy/main.dart';

void main() {
  testWidgets('renders the static home UI', (tester) async {
    await tester.pumpWidget(SpeakEasyApp(session: AppSession(), audioService: AudioService()));

    expect(find.text('学习者'), findsOneWidget);
    expect(find.text('搜索表达 / 场景'), findsOneWidget);
    expect(find.text('学习'), findsOneWidget);
  });
}
