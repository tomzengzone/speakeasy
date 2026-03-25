import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/utils/error_handler.dart';

class MockErrorReporter extends Mock implements ErrorReporter {}

void main() {
  late MockErrorReporter reporter;

  setUp(() {
    reporter = MockErrorReporter();
    ErrorHandler.resetForTesting();
    ErrorHandler.reporter = reporter;
  });

  tearDown(ErrorHandler.resetForTesting);

  test('debug 模式会输出上下文和错误信息', () {
    final List<String?> logs = <String?>[];

    ErrorHandler.isDebugMode = () => true;
    ErrorHandler.debugLogger = (String? message, {int? wrapWidth}) {
      logs.add(message);
    };

    ErrorHandler.handleError(Exception('boom'), context: 'Auth login failed');

    expect(logs, <String?>['[Auth login failed] Exception: boom']);
    verifyZeroInteractions(reporter);
  });

  test('debug 模式在存在堆栈时会输出堆栈信息', () {
    final List<String?> logs = <String?>[];
    StackTrace? capturedStack;
    String? capturedLabel;
    final StackTrace stackTrace = StackTrace.current;

    ErrorHandler.isDebugMode = () => true;
    ErrorHandler.debugLogger = (String? message, {int? wrapWidth}) {
      logs.add(message);
    };
    ErrorHandler.debugStackLogger =
        ({StackTrace? stackTrace, String? label, int? maxFrames}) {
          capturedStack = stackTrace;
          capturedLabel = label;
        };

    ErrorHandler.handleError(
      Exception('boom'),
      stackTrace: stackTrace,
      context: 'Stats refresh failed',
    );

    expect(logs.single, '[Stats refresh failed] Exception: boom');
    expect(capturedStack, stackTrace);
    expect(capturedLabel, '[Stats refresh failed]');
  });

  test('debug 模式在没有堆栈时不会调用堆栈输出', () {
    bool stackPrinted = false;

    ErrorHandler.isDebugMode = () => true;
    ErrorHandler.debugLogger = (String? message, {int? wrapWidth}) {};
    ErrorHandler.debugStackLogger =
        ({StackTrace? stackTrace, String? label, int? maxFrames}) {
          stackPrinted = true;
        };

    ErrorHandler.handleError(Exception('boom'), context: 'Profile save failed');

    expect(stackPrinted, isFalse);
  });

  test('release 模式会捕获异常并写入日志', () async {
    final Exception error = Exception('boom');
    final StackTrace stackTrace = StackTrace.current;
    final List<String?> logs = <String?>[];

    when(
      () => reporter.captureException(error, stackTrace: stackTrace),
    ).thenAnswer((_) async {});
    when(
      () => reporter.log(
        'Auth login failed',
        name: 'SpeakEasy',
        error: error,
        stackTrace: stackTrace,
      ),
    ).thenReturn(null);

    ErrorHandler.isDebugMode = () => false;
    ErrorHandler.debugLogger = (String? message, {int? wrapWidth}) {
      logs.add(message);
    };

    ErrorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: 'Auth login failed',
    );

    await Future<void>.delayed(Duration.zero);

    expect(logs, isEmpty);
    verify(
      () => reporter.captureException(error, stackTrace: stackTrace),
    ).called(1);
    verify(
      () => reporter.log(
        'Auth login failed',
        name: 'SpeakEasy',
        error: error,
        stackTrace: stackTrace,
      ),
    ).called(1);
  });

  test('release 模式没有堆栈时也会记录异常', () async {
    final Exception error = Exception('boom');

    when(
      () => reporter.captureException(error, stackTrace: null),
    ).thenAnswer((_) async {});
    when(
      () => reporter.log(
        'Membership upgrade failed',
        name: 'SpeakEasy',
        error: error,
        stackTrace: null,
      ),
    ).thenReturn(null);

    ErrorHandler.isDebugMode = () => false;

    ErrorHandler.handleError(error, context: 'Membership upgrade failed');

    await Future<void>.delayed(Duration.zero);

    verify(() => reporter.captureException(error, stackTrace: null)).called(1);
    verify(
      () => reporter.log(
        'Membership upgrade failed',
        name: 'SpeakEasy',
        error: error,
        stackTrace: null,
      ),
    ).called(1);
  });
}
