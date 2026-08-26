import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

void main() {
  test(
    'refresh calls the canonical endpoint and preserves rotated credentials',
    () async {
      late String requestedPath;
      late Map<String, dynamic> requestedBody;

      final Map<String, dynamic> result = await ApiClient.refreshToken(
        refreshToken: 'refresh-token-1',
        transport: (String path, Map<String, dynamic> body) async {
          requestedPath = path;
          requestedBody = body;
          return <String, dynamic>{
            '_httpStatus': 200,
            'schema_version': 1,
            'access_token': 'access-token-2',
            'refresh_token': 'refresh-token-2',
            'expires_at': '2026-08-27T00:00:00Z',
            'user': <String, dynamic>{
              'user_id': 'user-1',
              'display_name': '测试用户',
              'account_status': 'active',
              'onboarding_status': 'completed',
            },
          };
        },
      );

      expect(requestedPath, SpeakeasyApiPaths.authRefresh);
      expect(requestedBody, <String, dynamic>{
        'schema_version': 1,
        'refresh_token': 'refresh-token-1',
      });
      expect(result['code'], 0);
      expect(result['data']['accessToken'], 'access-token-2');
      expect(result['data']['refreshToken'], 'refresh-token-2');
      expect(result['data']['expiresAt'], '2026-08-27T00:00:00.000Z');
    },
  );
}
