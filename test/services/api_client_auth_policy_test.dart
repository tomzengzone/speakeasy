import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/storage_service.dart';

import '../support/hive_test_support.dart';

class _CapturedRequest {
  const _CapturedRequest({
    required this.path,
    required this.authorization,
    required this.body,
  });

  final String path;
  final String? authorization;
  final Map<String, dynamic> body;
}

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late HttpServer server;
  final List<_CapturedRequest> requests = <_CapturedRequest>[];
  int refreshStatusCode = HttpStatus.ok;

  setUpAll(() async {
    PackageInfo.setMockInitialValues(
      appName: 'SpeakEasy',
      packageName: 'com.speakeasy.app',
      version: '3.4.5',
      buildNumber: '123',
      buildSignature: 'test',
    );
    HttpOverrides.global = _RealHttpOverrides();
    hiveDirectory = await Directory.systemTemp.createTemp(
      'speakeasy_auth_policy_',
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
      final String rawBody = await utf8.decoder.bind(request).join();
      requests.add(
        _CapturedRequest(
          path: request.uri.path,
          authorization: request.headers.value(HttpHeaders.authorizationHeader),
          body: rawBody.isEmpty
              ? <String, dynamic>{}
              : (jsonDecode(rawBody) as Map).cast<String, dynamic>(),
        ),
      );

      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == SpeakeasyApiPaths.authRefresh &&
          refreshStatusCode == HttpStatus.unauthorized) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'error': <String, dynamic>{
              'code': 'UNAUTHENTICATED',
              'message': 'Refresh token is invalid.',
            },
          }),
        );
      } else if (request.uri.path ==
          SpeakeasyApiPaths.authPhoneVerificationCode) {
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(
          jsonEncode(<String, dynamic>{'schema_version': 1, 'status': 'sent'}),
        );
      } else if (request.uri.path == SpeakeasyApiPaths.userMe) {
        request.response.write(
          jsonEncode(<String, dynamic>{
            'user': <String, dynamic>{
              'user_id': 'user-1',
              'display_name': 'Test User',
              'account_status': 'active',
              'onboarding_status': 'completed',
            },
          }),
        );
      } else {
        request.response.write(
          jsonEncode(<String, dynamic>{
            'schema_version': 1,
            'access_token': 'new-access-token',
            'refresh_token': 'new-refresh-token',
            'expires_at': '2099-01-01T00:00:00Z',
            'user': <String, dynamic>{
              'user_id': 'user-1',
              'display_name': 'Test User',
              'account_status': 'active',
              'onboarding_status': 'completed',
            },
          }),
        );
      }
      await request.response.close();
    });
  });

  setUp(() async {
    requests.clear();
    refreshStatusCode = HttpStatus.ok;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await StorageService.instance.clearAuthSession();
  });

  tearDownAll(() async {
    await server.close(force: true);
    HttpOverrides.global = null;
    await deleteHiveTestDirectory(hiveDirectory);
  });

  Future<void> saveCredentials({required bool nearExpiry}) {
    return ApiClient.saveCredentials(
      AuthCredentials(
        accessToken: 'existing-access-token',
        refreshToken: 'existing-refresh-token',
        expiresAt: nearExpiry
            ? DateTime.now().toUtc().add(const Duration(seconds: 10))
            : DateTime.utc(2099),
      ),
    );
  }

  test('phone, Apple, and WeChat login explicitly bypass auth', () async {
    await saveCredentials(nearExpiry: true);

    await ApiClient.verifySmsCode('+8613800000000', '000000');
    await ApiClient.signInWithApple(
      authorizationCode: 'apple-code',
      identityToken: 'apple-token',
      nonce: 'raw-apple-nonce',
    );
    await ApiClient.signInWithWeChat(code: 'wechat-code');

    expect(requests.map((_CapturedRequest request) => request.path), <String>[
      SpeakeasyApiPaths.authLoginPhone,
      SpeakeasyApiPaths.authLoginApple,
      SpeakeasyApiPaths.authLoginWechat,
    ]);
    expect(
      requests.map((_CapturedRequest request) => request.authorization),
      everyElement(isNull),
    );
    for (final _CapturedRequest request in requests) {
      expect(request.body['device_name'], isNotEmpty);
      expect(
        request.body['platform'],
        isIn(<String>['ios', 'android', 'unknown']),
      );
      expect(request.body['app_version'], '3.4.5');
      expect(
        request.body['device_id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
    expect(requests[1].body['nonce'], 'raw-apple-nonce');
  });

  test('phone verification request uses installation-scoped endpoint', () async {
    await saveCredentials(nearExpiry: true);

    final Map<String, dynamic> response = await ApiClient.sendSmsCode(
      ' +8613800000000 ',
    );

    expect(response['code'], 0);
    expect(requests, hasLength(1));
    expect(requests.single.path, SpeakeasyApiPaths.authPhoneVerificationCode);
    expect(requests.single.authorization, isNull);
    expect(requests.single.body['schema_version'], 1);
    expect(requests.single.body['phone_number'], '+8613800000000');
    expect(
      requests.single.body['device_id'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('refresh explicitly bypasses auth and a 401 cannot recurse', () async {
    await saveCredentials(nearExpiry: false);
    refreshStatusCode = HttpStatus.unauthorized;

    await expectLater(
      ApiClient.refreshToken(refreshToken: 'explicit-refresh-token'),
      throwsA(
        isA<RefreshFailure>().having(
          (RefreshFailure failure) => failure.kind,
          'kind',
          RefreshFailureKind.authentication,
        ),
      ),
    );

    expect(requests, hasLength(1));
    expect(requests.single.path, SpeakeasyApiPaths.authRefresh);
    expect(requests.single.authorization, isNull);
  });

  test('business requests keep the required-auth default', () async {
    await saveCredentials(nearExpiry: false);

    await ApiClient.getMe();

    expect(requests, hasLength(1));
    expect(requests.single.path, SpeakeasyApiPaths.userMe);
    expect(requests.single.authorization, 'Bearer existing-access-token');
  });
}
