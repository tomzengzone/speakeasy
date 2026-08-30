import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/refresh_coordinator.dart';
import 'package:speakeasy/core/auth/token_provider.dart';

enum AuthPolicy { none, required }

typedef AuthenticatedRequestSender =
    Future<http.Response> Function(Map<String, String> headers);

class AuthenticatedRequestExecutor {
  AuthenticatedRequestExecutor({
    required TokenProvider tokenProvider,
    required RefreshCoordinator refreshCoordinator,
  }) : _tokenProvider = tokenProvider,
       _refreshCoordinator = refreshCoordinator;

  final TokenProvider _tokenProvider;
  final RefreshCoordinator _refreshCoordinator;

  Future<http.Response> execute({
    AuthPolicy authPolicy = AuthPolicy.required,
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
    }

    int authRetryCount = 0;
    while (true) {
      final http.Response response = await send(
        _authenticatedHeaders(headers, accessToken),
      );
      if (!_isAccessTokenExpired(response) ||
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

  bool _isAccessTokenExpired(http.Response response) {
    if (response.statusCode != 401 || response.body.trim().isEmpty) {
      return false;
    }
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return false;
      }
      final Object? rawError = decoded['error'];
      if (rawError is! Map) {
        return false;
      }
      return rawError['code'] == 'ACCESS_TOKEN_EXPIRED';
    } on FormatException {
      return false;
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
    return Map<String, String>.of(headers)..removeWhere(
      (String name, String value) => name.toLowerCase() == 'authorization',
    );
  }
}
