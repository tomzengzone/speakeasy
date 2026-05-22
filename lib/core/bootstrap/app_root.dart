import 'package:flutter/material.dart';

import 'package:speakeasy/core/routing/app_router.dart';
import 'package:speakeasy/core/theme/app_theme.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/home_page.dart';
import 'package:speakeasy/pages/login_page.dart';
import 'package:speakeasy/pages/onboarding_page.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/content_repository.dart';

class SpeakEasyAppRoot extends StatelessWidget {
  const SpeakEasyAppRoot({
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
                onGenerateRoute: AppRouter.onGenerateRoute,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                home: _resolveHome(session),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _resolveHome(AppSession session) {
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
    return const SpeakEasyHomePage();
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
