import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/secure_token_store.dart';

abstract interface class CredentialRepository {
  Future<AuthCredentials?> read();

  Future<void> replace(AuthCredentials credentials);

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

  @override
  Future<AuthCredentials?> read() => _tokenStore.read();

  @override
  Future<void> replace(AuthCredentials credentials) async {
    await _tokenStore.replace(credentials);
    await _clearLegacyAuthSession?.call();
  }

  @override
  Future<void> clear() async {
    await _tokenStore.clear();
    await _clearLegacyAuthSession?.call();
  }
}
