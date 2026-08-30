import 'package:flutter/material.dart';

import 'package:speakeasy/core/routing/app_router.dart';
import 'package:speakeasy/core/theme/app_theme.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/home_page.dart';
import 'package:speakeasy/pages/login_page.dart';
import 'package:speakeasy/pages/onboarding_page.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/content_repository.dart';

class SpeakEasyAppRoot extends StatelessWidget {
  const SpeakEasyAppRoot({
    super.key,
    required this.session,
    required this.audioService,
    this.courseCatalogApi = const ApiClientCourseCatalogApi(),
  });

  final AppSession session;
  final AudioService audioService;
  final CourseCatalogApi courseCatalogApi;

  @override
  Widget build(BuildContext context) {
    return AppSessionLifecycleObserver(
      session: session,
      child: ContentRepositoryScope(
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
                  onGenerateTitle: (BuildContext context) =>
                      context.l10n.appName,
                  themeMode: session.themeMode,
                  localizationsDelegates: L10n.localizationsDelegates,
                  supportedLocales: L10n.supportedLocales,
                  onGenerateRoute: AppRouter.onGenerateRoute,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  home: _resolveHome(session),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _resolveHome(AppSession session) {
    if (session.authState == SessionAuthState.initializing) {
      return const _SessionInitializingGate();
    }
    if (session.authState == SessionAuthState.offlineDegraded) {
      return _OfflineSessionGate(session: session);
    }
    if (!session.isLoggedIn) {
      return _LoginGate(session: session);
    }
    if (!session.onboardingDone) {
      return OnboardingPage(
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
      );
    }
    return SpeakEasyHomePage(courseCatalogApi: courseCatalogApi);
  }
}

class AppSessionLifecycleObserver extends StatefulWidget {
  const AppSessionLifecycleObserver({
    super.key,
    required this.session,
    required this.child,
  });

  final AppSession session;
  final Widget child;

  @override
  State<AppSessionLifecycleObserver> createState() =>
      _AppSessionLifecycleObserverState();
}

class _AppSessionLifecycleObserverState
    extends State<AppSessionLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.session.handleForegroundResume();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SessionInitializingGate extends StatelessWidget {
  const _SessionInitializingGate();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _OfflineSessionGate extends StatelessWidget {
  const _OfflineSessionGate({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_rounded, size: 42),
              const SizedBox(height: 16),
              const Text('暂时无法确认登录状态'),
              const SizedBox(height: 8),
              const Text('请检查网络后重试，本机登录凭据仍会保留。'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: session.initializeSession,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginGate extends StatelessWidget {
  const _LoginGate({required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      onSubmit: session.signIn,
      isLoading: session.isAuthenticating,
      errorMessage: session.authErrorMessage,
    );
  }
}
