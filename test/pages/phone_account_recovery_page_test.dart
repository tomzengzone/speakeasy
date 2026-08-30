import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/pages/phone_account_recovery_page.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/authenticated_request_executor.dart';

class _FakeAccountRecoveryApi implements AccountRecoveryApi {
  AccountRecoveryFailure? requestFailure;
  AccountRecoveryFailure? recoveryFailure;
  int requestCalls = 0;
  int recoveryCalls = 0;
  Completer<void>? pendingRequest;
  Completer<void>? pendingRecovery;
  RequestCancellationToken? requestCancellation;
  RequestCancellationToken? recoveryCancellation;

  @override
  Future<void> requestPhoneRecoveryCode(
    String phone, {
    RequestCancellationToken? cancellation,
  }) async {
    requestCalls += 1;
    requestCancellation = cancellation;
    if (requestFailure case final AccountRecoveryFailure failure) {
      throw failure;
    }
    final Completer<void>? pending = pendingRequest;
    if (pending != null && cancellation != null) {
      await Future.any<void>(<Future<void>>[
        pending.future,
        cancellation.whenCancelled.then<void>((_) {
          throw const RequestCancelledException();
        }),
      ]);
    }
  }

  @override
  Future<void> recoverPhoneAccount({
    required String phone,
    required String verificationCode,
    RequestCancellationToken? cancellation,
  }) async {
    recoveryCalls += 1;
    recoveryCancellation = cancellation;
    if (recoveryFailure case final AccountRecoveryFailure failure) {
      throw failure;
    }
    final Completer<void>? pending = pendingRecovery;
    if (pending != null && cancellation != null) {
      await Future.any<void>(<Future<void>>[
        pending.future,
        cancellation.whenCancelled.then<void>((_) {
          throw const RequestCancelledException();
        }),
      ]);
    }
  }
}

void main() {
  testWidgets(
    'purpose-bound recovery shows privacy-safe acceptance and requires relogin',
    (WidgetTester tester) async {
      final _FakeAccountRecoveryApi api = _FakeAccountRecoveryApi();
      bool localSessionCleared = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneAccountRecoveryPage(
            api: api,
            onRecovered: () async {
              localSessionCleared = true;
            },
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('account_recovery_privacy_notice')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_phone_input')),
        '+8613800138600',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_send_code')),
      );
      await tester.pump();

      expect(api.requestCalls, 1);
      expect(
        find.byKey(
          const ValueKey<String>('account_recovery_code_request_accepted'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('请求已受理'), findsOneWidget);
      expect(find.textContaining('账号存在'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_code_input')),
        '654321',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey<String>('account_recovery_submit')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      await tester.pump();

      expect(api.recoveryCalls, 1);
      expect(
        tester
            .widget<TextField>(
              find.byKey(
                const ValueKey<String>('account_recovery_phone_input'),
              ),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('account_recovery_code_input')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey<String>('account_recovery_submit')),
            )
            .onPressed,
        isNull,
      );
      expect(localSessionCleared, isTrue);
      expect(
        find.byKey(const ValueKey<String>('account_recovery_success')),
        findsOneWidget,
      );
      expect(find.textContaining('已安全退出所有设备，请重新登录'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('back from a pending code request cancels only that UI caller', (
    WidgetTester tester,
  ) async {
    final _FakeAccountRecoveryApi api = _FakeAccountRecoveryApi()
      ..pendingRequest = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PhoneAccountRecoveryPage(api: api, onRecovered: () async {}),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('account_recovery_phone_input')),
      '+8613800138605',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('account_recovery_send_code')),
    );
    await tester.pump();
    expect(api.requestCancellation?.isCancelled, isFalse);

    await tester.tap(
      find.byKey(const ValueKey<String>('account_recovery_back')),
    );
    await tester.pump();

    expect(api.requestCancellation?.isCancelled, isTrue);
    api.pendingRequest?.complete();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'all recovery verification failures share one privacy-safe copy',
    (WidgetTester tester) async {
      final _FakeAccountRecoveryApi api = _FakeAccountRecoveryApi()
        ..recoveryFailure = const AccountRecoveryFailure(
          kind: AccountRecoveryFailureKind.verificationFailed,
          message: 'backend detail must not be rendered',
        );
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneAccountRecoveryPage(api: api, onRecovered: () async {}),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_phone_input')),
        '+8613800138601',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_send_code')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_code_input')),
        '000000',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey<String>('account_recovery_submit')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('account_recovery_error')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('无法验证账号恢复信息'), findsOneWidget);
      expect(find.textContaining('backend detail'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'explicit verification failure can return only the phone without auth side effects',
    (WidgetTester tester) async {
      final _FakeAccountRecoveryApi api = _FakeAccountRecoveryApi()
        ..recoveryFailure = const AccountRecoveryFailure(
          kind: AccountRecoveryFailureKind.verificationFailed,
          message: 'privacy-safe failure',
        );
      String? returnedPhone;
      int loginOrCreateCalls = 0;
      int localCleanupCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setHostState) {
              return Scaffold(
                body: Builder(
                  builder: (BuildContext navigationContext) {
                    return Column(
                      children: <Widget>[
                        Text(
                          returnedPhone ?? '',
                          key: const ValueKey<String>(
                            'returned_phone_form_value',
                          ),
                        ),
                        FilledButton(
                          key: const ValueKey<String>('open_account_recovery'),
                          onPressed: () async {
                            final String? phone =
                                await Navigator.of(
                                  navigationContext,
                                ).push<String>(
                                  MaterialPageRoute<String>(
                                    builder: (_) => PhoneAccountRecoveryPage(
                                      api: api,
                                      onRecovered: () async {
                                        localCleanupCalls += 1;
                                      },
                                    ),
                                  ),
                                );
                            if (phone != null) {
                              setHostState(() {
                                returnedPhone = phone;
                              });
                            }
                          },
                          child: const Text('打开恢复页'),
                        ),
                        FilledButton(
                          key: const ValueKey<String>('login_or_create_probe'),
                          onPressed: () {
                            loginOrCreateCalls += 1;
                          },
                          child: const Text('手机号登录'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('open_account_recovery')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_phone_input')),
        '+8613800138608',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_send_code')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_code_input')),
        '000000',
      );
      final TextEditingController recoveryCodeController = tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('account_recovery_code_input')),
          )
          .controller!;
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      await tester.pump();

      expect(api.requestCalls, 1);
      expect(api.recoveryCalls, 1);
      expect(find.textContaining('无法验证账号恢复信息'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey<String>('account_recovery_back')),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_back')),
      );

      expect(recoveryCodeController.text, isEmpty);
      await tester.pumpAndSettle();

      expect(returnedPhone, '+8613800138608');
      expect(
        find.byKey(const ValueKey<String>('returned_phone_form_value')),
        findsOneWidget,
      );
      expect(find.text('+8613800138608'), findsOneWidget);
      expect(api.requestCalls, 1);
      expect(api.recoveryCalls, 1);
      expect(loginOrCreateCalls, 0);
      expect(localCleanupCalls, 0);
    },
  );

  testWidgets(
    'unknown completion result stays in recovery and cannot enter auto-create login',
    (WidgetTester tester) async {
      final _FakeAccountRecoveryApi api = _FakeAccountRecoveryApi()
        ..recoveryFailure = const AccountRecoveryFailure(
          kind: AccountRecoveryFailureKind.unknownResult,
          message: 'unknown',
        );
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneAccountRecoveryPage(api: api, onRecovered: () async {}),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_phone_input')),
        '+8613800138600',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_send_code')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_code_input')),
        '654321',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey<String>('account_recovery_submit')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      await tester.pump();

      expect(api.recoveryCalls, 1);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('account_recovery_code_input')),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey<String>('account_recovery_submit')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(
          const ValueKey<String>('account_recovery_return_to_phone_login'),
        ),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        find.byKey(
          const ValueKey<String>('account_recovery_retry_after_unknown'),
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(
          const ValueKey<String>('account_recovery_retry_after_unknown'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('避免误建新账号'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(
          const ValueKey<String>('account_recovery_retry_after_unknown'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('account_recovery_retry_after_unknown'),
        ),
      );
      await tester.pump();

      expect(api.requestCalls, 2);
      expect(api.recoveryCalls, 1);
      expect(
        find.byKey(
          const ValueKey<String>('account_recovery_code_request_accepted'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('completion cancellation while mounted becomes result unknown', (
    WidgetTester tester,
  ) async {
    final _FakeAccountRecoveryApi api = _FakeAccountRecoveryApi()
      ..pendingRecovery = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PhoneAccountRecoveryPage(api: api, onRecovered: () async {}),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('account_recovery_phone_input')),
      '+8613800138600',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('account_recovery_send_code')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('account_recovery_code_input')),
      '654321',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('account_recovery_submit')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('account_recovery_submit')),
    );
    await tester.pump();

    api.recoveryCancellation?.cancel();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();

    expect(api.recoveryCalls, 1);
    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey<String>('account_recovery_retry_after_unknown'),
      ),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('避免误建新账号'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey<String>('account_recovery_submit')),
          )
          .onPressed,
      isNull,
    );
    api.pendingRecovery?.complete();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'known server success remains known while local cleanup is retried',
    (WidgetTester tester) async {
      final _FakeAccountRecoveryApi api = _FakeAccountRecoveryApi();
      int cleanupCalls = 0;
      final Completer<void> firstCleanup = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneAccountRecoveryPage(
            api: api,
            onRecovered: () async {
              cleanupCalls += 1;
              if (cleanupCalls == 1) {
                await firstCleanup.future;
              }
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_phone_input')),
        '+8613800138600',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_send_code')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey<String>('account_recovery_code_input')),
        '654321',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('account_recovery_submit')),
      );
      await tester.pump();

      expect(api.recoveryCalls, 1);
      expect(cleanupCalls, 1);
      expect(
        find.byKey(
          const ValueKey<String>('account_recovery_local_cleanup_progress'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('正在清理本机登录数据'), findsOneWidget);
      firstCleanup.completeError(
        StateError('secure storage temporarily unavailable'),
      );
      await tester.pump();

      expect(find.textContaining('账号已恢复并退出所有设备'), findsOneWidget);
      expect(find.textContaining('无法确认恢复结果'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('account_recovery_return_to_phone_login'),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey<String>('account_recovery_submit')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey<String>('account_recovery_code_input')),
            )
            .enabled,
        isFalse,
      );
      await tester.scrollUntilVisible(
        find.byKey(
          const ValueKey<String>('account_recovery_retry_local_cleanup'),
        ),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('account_recovery_retry_local_cleanup'),
        ),
      );
      await tester.pump();

      expect(api.recoveryCalls, 1);
      expect(cleanupCalls, 2);
      expect(
        find.byKey(const ValueKey<String>('account_recovery_success')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
