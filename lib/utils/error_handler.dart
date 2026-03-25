import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef DebugPrintStackCallback =
    void Function({StackTrace? stackTrace, String? label, int? maxFrames});

abstract class ErrorReporter {
  Future<void> captureException(Object error, {StackTrace? stackTrace});

  void log(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  });
}

class SentryErrorReporter implements ErrorReporter {
  const SentryErrorReporter();

  @override
  Future<void> captureException(Object error, {StackTrace? stackTrace}) async {
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  @override
  void log(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }
}

class ErrorHandler {
  const ErrorHandler._();

  static ErrorReporter reporter = const SentryErrorReporter();
  static bool Function() isDebugMode = _defaultIsDebugMode;
  static DebugPrintCallback debugLogger = debugPrint;
  static DebugPrintStackCallback debugStackLogger = debugPrintStack;

  static void handleError(
    Object error, {
    StackTrace? stackTrace,
    required String context,
  }) {
    if (isDebugMode()) {
      debugLogger('[$context] $error');
      if (stackTrace != null) {
        debugStackLogger(stackTrace: stackTrace, label: '[$context]');
      }
      return;
    }

    unawaited(reporter.captureException(error, stackTrace: stackTrace));
    reporter.log(
      context,
      name: 'SpeakEasy',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @visibleForTesting
  static void resetForTesting() {
    reporter = const SentryErrorReporter();
    isDebugMode = _defaultIsDebugMode;
    debugLogger = debugPrint;
    debugStackLogger = debugPrintStack;
  }

  static bool _defaultIsDebugMode() => kDebugMode;
}
