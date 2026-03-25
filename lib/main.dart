import 'package:flutter/material.dart';

import 'audio_service.dart';
import 'app_session.dart';
import 'content_repository.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'notification_service.dart';
import 'onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // 通知初始化失败不影响主流程
  }
  runApp(SpeakEasyApp(session: AppSession(), audioService: AudioService()));
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
                title: 'SpeakEasy',
                themeMode: session.themeMode,
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
                            onComplete: ({
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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onSubmit: (submission) async {
        // WeChat / Apple 登录尚未接入 SDK，给友好提示
        if (submission.provider == LoginProvider.wechat ||
            submission.provider == LoginProvider.apple) {
          setState(() {
            _errorMessage = submission.provider == LoginProvider.wechat
                ? '微信登录正在接入中，请使用手机号登录'
                : 'Apple 登录正在接入中，请使用手机号登录';
          });
          return;
        }
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        try {
          await widget.session.signInWithCode(
            phone: submission.phone ?? '',
            code: submission.password ?? '',
          );
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = e.toString().replaceFirst('Exception: ', '');
            });
          }
        }
      },
    );
  }
}
