import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/home_page.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/content_repository.dart';
import 'package:speakeasy/services/storage_service.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'speakeasy_p01_training_entry_',
    );
    await StorageService.instance.init(
      hivePath: hiveDir.path,
      migrateFromSharedPreferences: false,
    );
    await prepareDefaultLearningRouteFixture();
  });

  tearDownAll(() async {
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  testWidgets(
    'TC-P01-031: P0.1 training entry is blocked when backend training is disabled',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ContentRepositoryScope(
          repository: const AssetContentRepository(),
          child: AudioServiceScope(
            service: AudioService(),
            child: AppSessionScope(
              session: AppSession(
                sessionCoordinator: SessionLifecycleCoordinator(
                  authService: _NoopAuthService(),
                  remoteApi: const _NoopSessionRemoteApi(),
                ),
              ),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                localizationsDelegates: L10n.localizationsDelegates,
                supportedLocales: L10n.supportedLocales,
                home: const SpeakEasyHomePage(),
              ),
            ),
          ),
        ),
      );

      final Finder trainingButton = find.byKey(
        const ValueKey<String>('home_hero_training_button'),
      );
      await pumpUntilFound(tester, trainingButton);
      await tapAndPump(tester, trainingButton);

      expect(find.textContaining('训练服务暂不可用'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('training_session_view')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('training_recap_panel')),
        findsNothing,
      );
    },
  );
}

class _NoopAuthService extends AuthService {
  _NoopAuthService()
    : super(
        signInWithEmail: (_) async => const AppUser(
          nickname: 'E2E learner',
          avatarUrl: '',
          memberPlan: 'free',
          onboardingDone: true,
        ),
      );
}

class _NoopSessionRemoteApi implements SessionRemoteApi {
  const _NoopSessionRemoteApi();

  @override
  Future<void> clearToken() async {}

  @override
  Future<Map<String, dynamic>> getMe() async => const <String, dynamic>{};

  @override
  Future<String?> getToken() async => null;

  @override
  Future<Map<String, dynamic>> refreshToken() async =>
      const <String, dynamic>{};

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<Map<String, dynamic>> testPhoneLogin(String phone) async =>
      const <String, dynamic>{};
}
