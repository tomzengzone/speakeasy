import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/authenticated_request_executor.dart';

enum PhoneAccountRecoveryViewState {
  idle,
  requestingCode,
  codeRequested,
  submitting,
  rateLimited,
  error,
  resultUnknown,
  cleanupInProgress,
  cleanupPending,
  succeeded,
}

class PhoneAccountRecoveryPage extends StatefulWidget {
  const PhoneAccountRecoveryPage({
    super.key,
    this.initialPhone = '',
    this.api = const ApiClientAccountRecoveryApi(),
    this.onRecovered,
  });

  final String initialPhone;
  final AccountRecoveryApi api;
  final Future<void> Function()? onRecovered;

  @override
  State<PhoneAccountRecoveryPage> createState() =>
      _PhoneAccountRecoveryPageState();
}

class _PhoneAccountRecoveryPageState extends State<PhoneAccountRecoveryPage> {
  late final TextEditingController _phoneController;
  final TextEditingController _codeController = TextEditingController();
  PhoneAccountRecoveryViewState _state = PhoneAccountRecoveryViewState.idle;
  String? _statusMessage;
  bool _codeRequested = false;
  int _retrySeconds = 0;
  Timer? _retryTimer;
  RequestCancellationToken? _codeRequestCancellation;
  RequestCancellationToken? _recoveryCancellation;

  bool get _requestInFlight =>
      _state == PhoneAccountRecoveryViewState.requestingCode ||
      _state == PhoneAccountRecoveryViewState.submitting ||
      _state == PhoneAccountRecoveryViewState.cleanupInProgress;

  bool get _flowLocked =>
      _state == PhoneAccountRecoveryViewState.resultUnknown ||
      _state == PhoneAccountRecoveryViewState.cleanupInProgress ||
      _state == PhoneAccountRecoveryViewState.cleanupPending ||
      _state == PhoneAccountRecoveryViewState.succeeded;

  bool get _canSubmit =>
      _codeRequested &&
      !_requestInFlight &&
      !_flowLocked &&
      _phoneController.text.trim().length >= 11 &&
      _codeController.text.trim().length >= 4;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _phoneController.addListener(_refreshForm);
    _codeController.addListener(_refreshForm);
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _codeRequestCancellation?.cancel();
    _recoveryCancellation?.cancel();
    _phoneController
      ..removeListener(_refreshForm)
      ..dispose();
    _codeController
      ..removeListener(_refreshForm)
      ..dispose();
    super.dispose();
  }

  void _refreshForm() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _requestCode() async {
    final String phone = _phoneController.text.trim();
    if (phone.length < 11 || _requestInFlight || _retrySeconds > 0) {
      if (phone.length < 11) {
        setState(() {
          _state = PhoneAccountRecoveryViewState.error;
          _statusMessage = '请输入正确的手机号。';
        });
      }
      return;
    }
    setState(() {
      _state = PhoneAccountRecoveryViewState.requestingCode;
      _statusMessage = null;
      _codeController.clear();
    });
    final RequestCancellationToken cancellation = RequestCancellationToken();
    _codeRequestCancellation?.cancel();
    _codeRequestCancellation = cancellation;
    try {
      await widget.api.requestPhoneRecoveryCode(
        phone,
        cancellation: cancellation,
      );
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _state = PhoneAccountRecoveryViewState.codeRequested;
        _statusMessage = '请求已受理。如果该手机号可用于账号恢复，请留意可能收到的验证码短信；收到后继续。';
      });
      _startRetryCountdown(const Duration(seconds: 60));
    } on RequestCancelledException {
      if (!mounted) return;
      setState(() {
        _state = PhoneAccountRecoveryViewState.idle;
        _statusMessage = '验证码请求已取消，请重试。';
      });
      return;
    } on AccountRecoveryFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure, forCodeRequest: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = PhoneAccountRecoveryViewState.error;
        _statusMessage = '网络连接失败，请检查网络后重试。';
      });
    } finally {
      if (identical(_codeRequestCancellation, cancellation)) {
        _codeRequestCancellation = null;
      }
    }
  }

  Future<void> _submitRecovery() async {
    if (!_canSubmit) return;
    setState(() {
      _state = PhoneAccountRecoveryViewState.submitting;
      _statusMessage = null;
    });
    final RequestCancellationToken cancellation = RequestCancellationToken();
    _recoveryCancellation?.cancel();
    _recoveryCancellation = cancellation;
    try {
      await widget.api.recoverPhoneAccount(
        phone: _phoneController.text.trim(),
        verificationCode: _codeController.text.trim(),
        cancellation: cancellation,
      );
    } on RequestCancelledException {
      if (!mounted) return;
      setState(() {
        _state = PhoneAccountRecoveryViewState.resultUnknown;
        _statusMessage = '暂时无法确认恢复结果。为避免误建新账号，请在本页重新获取恢复验证码并再次完成恢复。';
      });
      return;
    } on AccountRecoveryFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure, forCodeRequest: false);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = PhoneAccountRecoveryViewState.resultUnknown;
        _statusMessage = '暂时无法确认恢复结果。为避免误建新账号，请在本页重新获取恢复验证码并再次完成恢复。';
      });
      return;
    } finally {
      if (identical(_recoveryCancellation, cancellation)) {
        _recoveryCancellation = null;
      }
    }
    if (!mounted) return;
    await _completeLocalCleanupAfterKnownRecovery();
  }

  Future<void> _completeLocalCleanupAfterKnownRecovery() async {
    if (!mounted) return;
    setState(() {
      _state = PhoneAccountRecoveryViewState.cleanupInProgress;
      _statusMessage = '账号已恢复并退出所有设备，正在清理本机登录数据…';
    });
    try {
      final Future<void> Function()? callback = widget.onRecovered;
      if (callback != null) {
        await callback();
      } else {
        await AppSessionScope.of(context).clearSessionAfterAccountRecovery();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = PhoneAccountRecoveryViewState.cleanupPending;
        _statusMessage = '账号已恢复并退出所有设备，但本机登录数据尚未清理完成。请重试本机清理后再登录。';
      });
      return;
    }
    if (!mounted) return;
    _retryTimer?.cancel();
    _codeController.clear();
    setState(() {
      _codeRequested = false;
      _retrySeconds = 0;
      _state = PhoneAccountRecoveryViewState.succeeded;
      _statusMessage = '账号已恢复。已安全退出所有设备，请重新登录。';
    });
  }

  void _showFailure(
    AccountRecoveryFailure failure, {
    required bool forCodeRequest,
  }) {
    switch (failure.kind) {
      case AccountRecoveryFailureKind.invalidInput:
        setState(() {
          _state = PhoneAccountRecoveryViewState.error;
          _statusMessage = '请输入正确的手机号和验证码。';
        });
      case AccountRecoveryFailureKind.verificationFailed:
        setState(() {
          _state = PhoneAccountRecoveryViewState.error;
          _statusMessage = '无法验证账号恢复信息。验证码可能无效或已过期，请重试或重新获取验证码。';
        });
      case AccountRecoveryFailureKind.rateLimited:
        final Duration retryAfter =
            failure.retryAfter ?? const Duration(seconds: 5);
        setState(() {
          _state = PhoneAccountRecoveryViewState.rateLimited;
          _statusMessage = '请求过于频繁，请稍后重试。';
        });
        _startRetryCountdown(retryAfter);
      case AccountRecoveryFailureKind.serviceUnavailable:
        setState(() {
          _state = PhoneAccountRecoveryViewState.error;
          _statusMessage = forCodeRequest
              ? '暂时无法请求验证码，请稍后重试。'
              : '账号恢复服务暂时不可用，请稍后重试。';
        });
      case AccountRecoveryFailureKind.unknownResult:
        setState(() {
          _state = forCodeRequest
              ? PhoneAccountRecoveryViewState.error
              : PhoneAccountRecoveryViewState.resultUnknown;
          _statusMessage = forCodeRequest
              ? '网络连接失败，请检查网络后重试。'
              : '暂时无法确认恢复结果。为避免误建新账号，请在本页重新获取恢复验证码并再次完成恢复。';
        });
    }
  }

  void _startRetryCountdown(Duration duration) {
    _retryTimer?.cancel();
    _retrySeconds = duration.inSeconds.clamp(1, 300);
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _retrySeconds -= 1;
        if (_retrySeconds <= 0) {
          timer.cancel();
          _retrySeconds = 0;
          if (_state == PhoneAccountRecoveryViewState.rateLimited) {
            _state = _codeRequested
                ? PhoneAccountRecoveryViewState.codeRequested
                : PhoneAccountRecoveryViewState.idle;
          }
        }
      });
    });
  }

  void _returnToLogin() {
    _codeRequestCancellation?.cancel();
    _codeController.clear();
    Navigator.of(context).pop(_phoneController.text.trim());
  }

  Future<void> _retryRecoveryAfterUnknownResult() async {
    _retryTimer?.cancel();
    _codeController.clear();
    setState(() {
      _codeRequested = false;
      _retrySeconds = 0;
      _state = PhoneAccountRecoveryViewState.idle;
      _statusMessage = null;
    });
    await _requestCode();
  }

  @override
  Widget build(BuildContext context) {
    final bool submitting = _state == PhoneAccountRecoveryViewState.submitting;
    final bool resultUnknown =
        _state == PhoneAccountRecoveryViewState.resultUnknown;
    final bool cleanupPending =
        _state == PhoneAccountRecoveryViewState.cleanupPending;
    final bool cleanupInProgress =
        _state == PhoneAccountRecoveryViewState.cleanupInProgress;
    return PopScope(
      canPop:
          !submitting &&
          !resultUnknown &&
          !cleanupInProgress &&
          !cleanupPending,
      child: Scaffold(
        key: const ValueKey<String>('phone_account_recovery_screen'),
        appBar: AppBar(
          leading: IconButton(
            key: const ValueKey<String>('account_recovery_back'),
            onPressed:
                submitting ||
                    resultUnknown ||
                    cleanupInProgress ||
                    cleanupPending
                ? null
                : _returnToLogin,
            tooltip: '返回手机号登录',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            '恢复账号',
            key: ValueKey<String>('account_recovery_heading'),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const Text(
                '使用账号已绑定且仍可接收短信的手机号验证。恢复成功后，所有设备都会退出登录。',
                style: TextStyle(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 12),
              const Text(
                '为了保护账号安全，无论手机号是否存在或已绑定，页面都不会显示相关信息。',
                key: ValueKey<String>('account_recovery_privacy_notice'),
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const ValueKey<String>('account_recovery_phone_input'),
                controller: _phoneController,
                enabled: !_requestInFlight && !_flowLocked,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: const ValueKey<String>('account_recovery_send_code'),
                onPressed: _requestInFlight || _flowLocked || _retrySeconds > 0
                    ? null
                    : _requestCode,
                child: Text(
                  _state == PhoneAccountRecoveryViewState.requestingCode
                      ? '正在请求…'
                      : _retrySeconds > 0
                      ? '${_retrySeconds}s 后可重新获取'
                      : '获取恢复验证码',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('account_recovery_code_input'),
                controller: _codeController,
                enabled: _codeRequested && !_requestInFlight && !_flowLocked,
                keyboardType: TextInputType.number,
                autofillHints: const <String>[AutofillHints.oneTimeCode],
                decoration: const InputDecoration(
                  labelText: '恢复验证码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey<String>('account_recovery_submit'),
                onPressed: _canSubmit ? _submitRecovery : null,
                child: Text(submitting ? '正在安全恢复账号…' : '确认恢复账号'),
              ),
              if (_statusMessage != null) ...<Widget>[
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _statusMessage!,
                    key: ValueKey<String>(
                      _state == PhoneAccountRecoveryViewState.succeeded
                          ? 'account_recovery_success'
                          : _state ==
                                PhoneAccountRecoveryViewState.cleanupInProgress
                          ? 'account_recovery_local_cleanup_progress'
                          : _state ==
                                PhoneAccountRecoveryViewState.cleanupPending
                          ? 'account_recovery_local_cleanup_error'
                          : _state ==
                                PhoneAccountRecoveryViewState.codeRequested
                          ? 'account_recovery_code_request_accepted'
                          : _state == PhoneAccountRecoveryViewState.rateLimited
                          ? 'account_recovery_rate_limit'
                          : 'account_recovery_error',
                    ),
                    style: TextStyle(
                      color: _state == PhoneAccountRecoveryViewState.succeeded
                          ? Colors.green.shade800
                          : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (_state ==
                  PhoneAccountRecoveryViewState.succeeded) ...<Widget>[
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const ValueKey<String>(
                    'account_recovery_return_to_phone_login',
                  ),
                  onPressed: _returnToLogin,
                  child: const Text('返回手机号登录'),
                ),
              ],
              if (resultUnknown) ...<Widget>[
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const ValueKey<String>(
                    'account_recovery_retry_after_unknown',
                  ),
                  onPressed: _retryRecoveryAfterUnknownResult,
                  child: const Text('重新获取恢复验证码'),
                ),
              ],
              if (cleanupPending) ...<Widget>[
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const ValueKey<String>(
                    'account_recovery_retry_local_cleanup',
                  ),
                  onPressed: _completeLocalCleanupAfterKnownRecovery,
                  child: const Text('重试本机清理'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
