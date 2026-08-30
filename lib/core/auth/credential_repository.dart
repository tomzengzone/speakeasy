import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/secure_token_store.dart';

abstract interface class CredentialRepository {
  Future<AuthCredentials?> read();

  Future<void> replace(AuthCredentials credentials);

  Future<bool> replaceIfCurrent({
    required AuthCredentials expected,
    required AuthCredentials replacement,
  });

  Future<void> clear();
}

class SecureCredentialRepository implements CredentialRepository {
  SecureCredentialRepository({
    required SecureTokenStore tokenStore,
    Future<void> Function()? clearLegacyAuthSession,
  }) : _tokenStore = tokenStore,
       _clearLegacyAuthSession = clearLegacyAuthSession;

  final SecureTokenStore _tokenStore;
  final Future<void> Function()? _clearLegacyAuthSession;
  Future<void> _pendingOperation = Future<void>.value();
  bool _legacyAuthSessionCleared = false;

  @override
  Future<AuthCredentials?> read() {
    return _serialized(() async {
      final AuthCredentials? credentials = await _tokenStore.read();
      await _clearLegacyOnce();
      return credentials;
    });
  }

  @override
  Future<void> replace(AuthCredentials credentials) {
    return _serialized(() => _replace(credentials));
  }

  @override
  Future<bool> replaceIfCurrent({
    required AuthCredentials expected,
    required AuthCredentials replacement,
  }) {
    return _serialized(() async {
      final AuthCredentials? latest = await _tokenStore.read();
      if (!_sameCredentialGeneration(expected, latest)) {
        return false;
      }
      await _replace(replacement);
      return true;
    });
  }

  @override
  Future<void> clear() {
    return _serialized(_clear);
  }

  Future<void> _replace(AuthCredentials credentials) async {
    await _tokenStore.replace(credentials);
    await _clearLegacyNow();
  }

  Future<void> _clear() async {
    await _tokenStore.clear();
    await _clearLegacyNow();
  }

  Future<void> _clearLegacyOnce() async {
    if (_legacyAuthSessionCleared) {
      return;
    }
    await _clearLegacyNow();
  }

  Future<void> _clearLegacyNow() async {
    await _clearLegacyAuthSession?.call();
    _legacyAuthSessionCleared = true;
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final Future<T> result = _pendingOperation.then((_) => operation());
    _pendingOperation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  bool _sameCredentialGeneration(
    AuthCredentials expected,
    AuthCredentials? actual,
  ) {
    return actual != null &&
        expected.accessToken == actual.accessToken &&
        expected.refreshToken == actual.refreshToken;
  }
}
