import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/credential_repository.dart';
import 'package:speakeasy/core/auth/token_provider.dart';

typedef RefreshCredentials =
    Future<AuthCredentials> Function(String refreshToken);

abstract interface class RefreshRateLimitSignal {
  Duration get retryAfter;
}

class CredentialContextChanged implements Exception {
  const CredentialContextChanged();

  @override
  String toString() {
    return 'CredentialContextChanged('
        'credentials changed while refresh was in flight)';
  }
}

DateTime _utcNow() => DateTime.now().toUtc();

class RefreshCoordinator {
  RefreshCoordinator({
    required TokenProvider tokenProvider,
    required CredentialRepository credentialRepository,
    required RefreshCredentials refreshCredentials,
    DateTime Function()? now,
  }) : _tokenProvider = tokenProvider,
       _credentialRepository = credentialRepository,
       _refreshCredentials = refreshCredentials,
       _now = now ?? _utcNow;

  final TokenProvider _tokenProvider;
  final CredentialRepository _credentialRepository;
  final RefreshCredentials _refreshCredentials;
  final DateTime Function() _now;

  Future<AuthCredentials>? _inFlightRefresh;
  DateTime? _cooldownUntil;
  String? _cooldownRefreshToken;
  Object? _cooldownFailure;
  StackTrace? _cooldownStackTrace;

  Future<AuthCredentials> refreshIfNeeded({
    String? failedAccessToken,
    bool force = false,
  }) async {
    final AuthCredentials? current = await _tokenProvider.getCredentials();
    if (current == null) {
      throw StateError('Complete authentication credentials are required');
    }

    final String failedToken = failedAccessToken?.trim() ?? '';
    if (failedToken.isNotEmpty && failedToken != current.accessToken) {
      return current;
    }

    _throwIfCoolingDown(current);

    final Future<AuthCredentials>? inFlight = _inFlightRefresh;
    if (inFlight != null) {
      return inFlight;
    }

    final bool reactiveRefresh = failedToken.isNotEmpty;
    if (!force && !reactiveRefresh && !current.needsRefreshAt(_now())) {
      return current;
    }

    final Future<AuthCredentials> refresh = _refresh(current);
    _inFlightRefresh = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_inFlightRefresh, refresh)) {
        _inFlightRefresh = null;
      }
    }
  }

  Future<AuthCredentials> _refresh(AuthCredentials current) async {
    late final AuthCredentials refreshed;
    try {
      refreshed = await _refreshCredentials(current.refreshToken);
    } on RefreshRateLimitSignal catch (failure, stackTrace) {
      _cooldownUntil = _now().add(failure.retryAfter);
      _cooldownRefreshToken = current.refreshToken;
      _cooldownFailure = failure;
      _cooldownStackTrace = stackTrace;
      Error.throwWithStackTrace(failure, stackTrace);
    }
    final bool replaced = await _credentialRepository.replaceIfCurrent(
      expected: current,
      replacement: refreshed,
    );
    if (!replaced) {
      throw const CredentialContextChanged();
    }
    _clearCooldown();
    return refreshed;
  }

  void _throwIfCoolingDown(AuthCredentials current) {
    final DateTime? until = _cooldownUntil;
    if (until == null ||
        _cooldownRefreshToken != current.refreshToken ||
        !_now().isBefore(until)) {
      _clearCooldown();
      return;
    }
    final Object? failure = _cooldownFailure;
    if (failure != null) {
      Error.throwWithStackTrace(
        failure,
        _cooldownStackTrace ?? StackTrace.current,
      );
    }
  }

  void _clearCooldown() {
    _cooldownUntil = null;
    _cooldownRefreshToken = null;
    _cooldownFailure = null;
    _cooldownStackTrace = null;
  }
}
