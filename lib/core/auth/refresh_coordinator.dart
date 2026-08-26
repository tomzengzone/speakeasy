import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/token_provider.dart';

typedef RefreshCredentials =
    Future<AuthCredentials> Function(String refreshToken);
typedef ReplaceCredentials = Future<void> Function(AuthCredentials credentials);

DateTime _utcNow() => DateTime.now().toUtc();

class RefreshCoordinator {
  RefreshCoordinator({
    required TokenProvider tokenProvider,
    required RefreshCredentials refreshCredentials,
    required ReplaceCredentials replaceCredentials,
    DateTime Function()? now,
  }) : _tokenProvider = tokenProvider,
       _refreshCredentials = refreshCredentials,
       _replaceCredentials = replaceCredentials,
       _now = now ?? _utcNow;

  final TokenProvider _tokenProvider;
  final RefreshCredentials _refreshCredentials;
  final ReplaceCredentials _replaceCredentials;
  final DateTime Function() _now;

  Future<AuthCredentials>? _inFlightRefresh;

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
    final AuthCredentials refreshed = await _refreshCredentials(
      current.refreshToken,
    );
    await _replaceCredentials(refreshed);
    return refreshed;
  }
}
