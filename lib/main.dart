import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/core/bootstrap/app_bootstrapper.dart';
import 'package:speakeasy/core/bootstrap/app_root.dart';
import 'package:speakeasy/utils/error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('SPEAKEASY_DISABLE_GLOBAL_ERROR_HOOKS')) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
      if (details.stack != null) {
        debugPrintStack(stackTrace: details.stack);
      }
    };
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _BootErrorView(
        title: '界面加载失败',
        detail: details.exceptionAsString(),
      );
    };
  }

  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  static const AppBootstrapper _bootstrapper = AppBootstrapper();

  Widget? _app;
  String _status = '正在启动…';
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _error = null;
      _status = '正在启动…';
    });
    try {
      final AppBootstrapBundle bundle = await _bootstrapper.bootstrap(
        onStatus: (String status) {
          if (!mounted) {
            return;
          }
          setState(() => _status = status);
        },
      );
      final Widget app = SpeakEasyAppRoot(
        session: bundle.createSession(),
        audioService: bundle.createAudioService(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _app = app;
      });
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'App bootstrap failed',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget? app = _app;
    if (app != null) {
      return app;
    }
    final String? error = _error;
    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _BootErrorView(
          title: '应用启动失败',
          detail: error,
          onRetry: () => unawaited(_bootstrap()),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BootLoadingView(status: _status),
    );
  }
}

class _BootLoadingView extends StatelessWidget {
  const _BootLoadingView({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              const Text(
                'SpeakEasy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF7B7B7B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootErrorView extends StatelessWidget {
  const _BootErrorView({
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 34,
                  color: Color(0xFFB25555),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF7A6F67),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('重试')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
