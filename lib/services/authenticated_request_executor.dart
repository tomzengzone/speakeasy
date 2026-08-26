import 'package:http/http.dart' as http;

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/refresh_coordinator.dart';
import 'package:speakeasy/core/auth/token_provider.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';

enum AuthPolicy { none, required }

abstract final class AuthEndpointPolicy {
  static const Set<String> _unauthenticatedPaths = <String>{
    SpeakeasyApiPaths.authLoginPhone,
    SpeakeasyApiPaths.authLoginApple,
    SpeakeasyApiPaths.authLoginWechat,
    SpeakeasyApiPaths.authRefresh,
  };

  static AuthPolicy forPath(String path) {
    return _unauthenticatedPaths.contains(path)
        ? AuthPolicy.none
        : AuthPolicy.required;
  }
}

typedef AuthenticatedRequestSender =
    Future<http.Response> Function(Map<String, String> headers);

class AuthenticatedRequestExecutor {
  AuthenticatedRequestExecutor({
    required TokenProvider tokenProvider,
    required RefreshCoordinator refreshCoordinator,
    Future<String?> Function()? legacyAccessToken,
  }) : _tokenProvider = tokenProvider,
       _refreshCoordinator = refreshCoordinator,
       _legacyAccessToken = legacyAccessToken;

  final TokenProvider _tokenProvider;
  final RefreshCoordinator _refreshCoordinator;
  final Future<String?> Function()? _legacyAccessToken;

  Future<http.Response> execute({
    required AuthPolicy authPolicy,
    required AuthenticatedRequestSender send,
    Map<String, String> headers = const <String, String>{},
  }) async {
    if (authPolicy == AuthPolicy.none) {
      return send(_withoutAuthorization(headers));
    }

    AuthCredentials? credentials = await _tokenProvider.getCredentials();
    String? accessToken;
    if (credentials != null) {
      credentials = await _refreshCoordinator.refreshIfNeeded();
      accessToken = credentials.accessToken;
    } else {
      accessToken = await _legacyAccessToken?.call();
    }

    int authRetryCount = 0;
    while (true) {
      final http.Response response = await send(
        _authenticatedHeaders(headers, accessToken),
      );
      if (response.statusCode != 401 ||
          credentials == null ||
          authRetryCount >= 1) {
        return response;
      }

      credentials = await _refreshCoordinator.refreshIfNeeded(
        failedAccessToken: accessToken,
      );
      accessToken = credentials.accessToken;
      authRetryCount += 1;
    }
  }

  Map<String, String> _authenticatedHeaders(
    Map<String, String> headers,
    String? accessToken,
  ) {
    return <String, String>{
      ..._withoutAuthorization(headers),
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  Map<String, String> _withoutAuthorization(Map<String, String> headers) {
    return Map<String, String>.of(headers)
      ..removeWhere(
        (String name, String value) => name.toLowerCase() == 'authorization',
      );
  }
}
