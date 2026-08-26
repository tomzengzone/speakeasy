import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/secure_token_store.dart';

abstract interface class TokenProvider {
  Future<AuthCredentials?> getCredentials();
}

class SecureTokenProvider implements TokenProvider {
  SecureTokenProvider(this._tokenStore);

  final SecureTokenStore _tokenStore;

  @override
  Future<AuthCredentials?> getCredentials() => _tokenStore.read();
}
