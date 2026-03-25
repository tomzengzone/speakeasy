import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/config/sentry_config.dart';
import 'package:speakeasy/services/content_repository.dart';
import 'package:speakeasy/pages/home_page.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/login_page.dart';
import 'package:speakeasy/services/notification_service.dart';
import 'package:speakeasy/pages/onboarding_page.dart';
import 'package:speakeasy/services/storage_service.dart';
import 'package:speakeasy/utils/error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await dotenv.load(fileName: kDebugMode ? '.env.dev' : '.env');
  final SentryConfig sentryConfig = await SentryConfig.load();

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryConfig.dsn;
      options.environment = sentryConfig.environment;
      options.release = sentryConfig.release;
    },
    appRunner: () async {
      try {
        await NotificationService.instance.init();
      } catch (error, stackTrace) {
        ErrorHandler.handleError(
          error,
          stackTrace: stackTrace,
          context: 'Notification service initialization failed',
        );
        // 通知初始化失败不影响主流程
      }

      runApp(SpeakEasyApp(session: AppSession(), audioService: AudioService()));
    },
  );
}

class SpeakEasyApp extends StatelessWidget {
  const SpeakEasyApp({
    super.key,
    required this.session,
    required this.audioService,
  });

  final AppSession session;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return ContentRepositoryScope(
      repository: const AssetContentRepository(),
      child: AudioServiceScope(
        service: audioService,
        child: AppSessionScope(
          session: session,
          child: ListenableBuilder(
            listenable: session,
            builder: (BuildContext context, Widget? _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                onGenerateTitle: (BuildContext context) => context.l10n.appName,
                themeMode: session.themeMode,
                localizationsDelegates: L10n.localizationsDelegates,
                supportedLocales: L10n.supportedLocales,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF4A6B57),
                    brightness: Brightness.light,
                  ),
                  scaffoldBackgroundColor: const Color(0xFFF3EFE8),
                  textTheme: ThemeData.light().textTheme.apply(
                    bodyColor: const Color(0xFF241F1A),
                    displayColor: const Color(0xFF241F1A),
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF4A6B57),
                    brightness: Brightness.dark,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF1A1A1A),
                  textTheme: ThemeData.dark().textTheme.apply(
                    bodyColor: const Color(0xFFEDEAE3),
                    displayColor: const Color(0xFFEDEAE3),
                  ),
                ),
                home: !session.isLoggedIn
                    ? _LoginGate(session: session)
                    : !session.onboardingDone
                    ? OnboardingPage(
                        onComplete:
                            ({
                              required List<String> goals,
                              required int level,
                              required int dailyMinutes,
                            }) {
                              session.completeOnboarding(
                                goals: goals,
                                level: level,
                                dailyMinutes: dailyMinutes,
                              );
                            },
                      )
                    : const SpeakEasyHomePage(),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 登录页包装器：管理 loading 状态和错误信息，调用 AppSession.signInWithCode
class _LoginGate extends StatefulWidget {
  const _LoginGate({required this.session});
  final AppSession session;

  @override
  State<_LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<_LoginGate> {
  String? _localErrorMessage;

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      isLoading: widget.session.isAuthenticating,
      errorMessage: _localErrorMessage ?? widget.session.authErrorMessage,
      onSubmit: (submission) async {
        setState(() {
          _localErrorMessage = null;
        });
        await widget.session.signIn(submission);
      },
    );
  }
}
