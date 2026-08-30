import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/storage_service.dart';

import '../support/hive_test_support.dart';

class _RequestRecord {
  const _RequestRecord({required this.method, required this.path});

  final String method;
  final String path;
}

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late HttpServer server;
  final List<_RequestRecord> requests = <_RequestRecord>[];
  String? terminalCode;
  String? refreshTerminalCode;
  bool rejectBusinessRequest = false;

  setUpAll(() async {
    HttpOverrides.global = _RealHttpOverrides();
    hiveDirectory = await Directory.systemTemp.createTemp(
      'speakeasy_device_sessions_',
    );
    await StorageService.instance.init(
      hivePath: hiveDirectory.path,
      migrateFromSharedPreferences: false,
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    dotenv.testLoad(
      fileInput: 'API_BASE_URL=http://${server.address.host}:${server.port}',
    );
    server.listen((HttpRequest request) async {
      await utf8.decoder.bind(request).join();
      requests.add(
        _RequestRecord(method: request.method, path: request.uri.path),
      );

      final String? errorCode = terminalCode;
      if (request.uri.path == SpeakeasyApiPaths.authSessions &&
          errorCode != null) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'error': <String, dynamic>{
              'code': errorCode,
              'message': 'terminal authentication failure',
            },
          }),
        );
      } else if (request.uri.path == SpeakeasyApiPaths.authSessions &&
          rejectBusinessRequest) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'error': <String, dynamic>{
              'code': 'ACCESS_TOKEN_EXPIRED',
              'message': 'access token expired',
            },
          }),
        );
      } else if (request.uri.path == SpeakeasyApiPaths.authRefresh &&
          refreshTerminalCode != null) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'error': <String, dynamic>{
              'code': refreshTerminalCode,
              'message': 'refresh token rejected',
            },
          }),
        );
      } else if (request.method == 'GET' &&
          request.uri.path == SpeakeasyApiPaths.authSessions) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'schema_version': 1,
            'sessions': <Map<String, dynamic>>[],
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.noContent;
      }
      await request.response.close();
    });
  });

  setUp(() async {
    requests.clear();
    terminalCode = null;
    refreshTerminalCode = null;
    rejectBusinessRequest = false;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await StorageService.instance.clearAuthSession();
    await ApiClient.saveCredentials(
      AuthCredentials(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.utc(2099),
      ),
    );
  });

  tearDownAll(() async {
    await server.close(force: true);
    HttpOverrides.global = null;
    await deleteHiveTestDirectory(hiveDirectory);
  });

  test('device session API uses canonical methods and generated paths', () async {
    await ApiClient.listAuthSessions();
    await ApiClient.revokeAuthSession('00000000-0000-0000-0000-000000000002');
    await ApiClient.logoutOtherSessions();
    await ApiClient.logoutAllSessions();
    await ApiClient.logoutCurrentSession();

    expect(
      requests.map(
        (_RequestRecord request) => '${request.method} ${request.path}',
      ),
      <String>[
        'GET ${SpeakeasyApiPaths.authSessions}',
        'DELETE ${SpeakeasyApiPaths.authSession('00000000-0000-0000-0000-000000000002')}',
        'POST ${SpeakeasyApiPaths.authLogoutOthers}',
        'POST ${SpeakeasyApiPaths.authLogoutAll}',
        'POST ${SpeakeasyApiPaths.authLogout}',
      ],
    );
  });

  test(
    'terminal business response clears credentials without refresh retry',
    () async {
      terminalCode = 'SESSION_REVOKED';
      final Future<SessionSecurityFailure> event =
          ApiClient.sessionSecurityFailures.first;

      await expectLater(
        ApiClient.listAuthSessions(),
        throwsA(
          isA<SessionSecurityFailure>().having(
            (SessionSecurityFailure failure) => failure.reason,
            'reason',
            SessionSecurityReason.sessionRevoked,
          ),
        ),
      );

      expect((await event).backendCode, 'SESSION_REVOKED');
      expect(await ApiClient.getCredentials(), isNull);
      expect(requests, hasLength(1));
      expect(requests.single.path, SpeakeasyApiPaths.authSessions);
    },
  );

  test(
    'ACCESS_TOKEN_INVALID clears credentials without refresh retry',
    () async {
      terminalCode = 'ACCESS_TOKEN_INVALID';
      final Future<SessionSecurityFailure> event =
          ApiClient.sessionSecurityFailures.first;

      await expectLater(
        ApiClient.listAuthSessions(),
        throwsA(
          isA<SessionSecurityFailure>().having(
            (SessionSecurityFailure failure) => failure.reason,
            'reason',
            SessionSecurityReason.accessTokenInvalid,
          ),
        ),
      );

      expect((await event).backendCode, 'ACCESS_TOKEN_INVALID');
      expect(await ApiClient.getCredentials(), isNull);
      expect(requests, hasLength(1));
    },
  );

  for (final ({String code, SessionSecurityReason reason}) scenario
      in <({String code, SessionSecurityReason reason})>[
        (
          code: 'REFRESH_TOKEN_EXPIRED',
          reason: SessionSecurityReason.refreshTokenExpired,
        ),
        (
          code: 'REFRESH_TOKEN_INVALID',
          reason: SessionSecurityReason.refreshTokenInvalid,
        ),
      ]) {
    test(
      'business 401 refresh maps ${scenario.code} and clears credentials',
      () async {
        rejectBusinessRequest = true;
        refreshTerminalCode = scenario.code;
        final Future<SessionSecurityFailure> event =
            ApiClient.sessionSecurityFailures.first;

        await expectLater(
          ApiClient.listAuthSessions(),
          throwsA(
            isA<SessionSecurityFailure>().having(
              (SessionSecurityFailure failure) => failure.reason,
              'reason',
              scenario.reason,
            ),
          ),
        );

        expect((await event).backendCode, scenario.code);
        expect(await ApiClient.getCredentials(), isNull);
        expect(
          requests.map(
            (_RequestRecord request) => '${request.method} ${request.path}',
          ),
          <String>[
            'GET ${SpeakeasyApiPaths.authSessions}',
            'POST ${SpeakeasyApiPaths.authRefresh}',
          ],
        );
      },
    );
  }
}
