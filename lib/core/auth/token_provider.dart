import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/credential_repository.dart';

abstract interface class TokenProvider {
  Future<AuthCredentials?> getCredentials();
}

class SecureTokenProvider implements TokenProvider {
  SecureTokenProvider(this._credentialRepository);

  final CredentialRepository _credentialRepository;

  @override
  Future<AuthCredentials?> getCredentials() => _credentialRepository.read();
}
