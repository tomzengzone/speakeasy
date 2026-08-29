import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/services/api_client.dart';

void main() {
  for (final ({
        String code,
        SessionSecurityReason reason,
        String messageFragment,
      })
      scenario
      in <
        ({String code, SessionSecurityReason reason, String messageFragment})
      >[
        (
          code: 'SESSION_REVOKED',
          reason: SessionSecurityReason.sessionRevoked,
          messageFragment: '重新登录',
        ),
        (
          code: 'REFRESH_TOKEN_EXPIRED',
          reason: SessionSecurityReason.refreshTokenExpired,
          messageFragment: '登录已过期',
        ),
        (
          code: 'REFRESH_TOKEN_INVALID',
          reason: SessionSecurityReason.refreshTokenInvalid,
          messageFragment: '登录已失效',
        ),
        (
          code: 'TOKEN_REUSE_DETECTED',
          reason: SessionSecurityReason.tokenReuseDetected,
          messageFragment: '凭证异常',
        ),
        (
          code: 'ACCOUNT_DISABLED',
          reason: SessionSecurityReason.accountDisabled,
          messageFragment: '账号已被禁用',
        ),
      ]) {
    test(
      'refresh maps ${scenario.code} to a terminal session failure',
      () async {
        await expectLater(
          ApiClient.refreshToken(
            refreshToken: 'refresh-token',
            transport: (String path, Map<String, dynamic> body) async {
              return <String, dynamic>{
                '_httpStatus': 401,
                'error': <String, dynamic>{
                  'code': scenario.code,
                  'message': 'backend message',
                },
              };
            },
          ),
          throwsA(
            isA<SessionSecurityFailure>()
                .having(
                  (SessionSecurityFailure failure) => failure.reason,
                  'reason',
                  scenario.reason,
                )
                .having(
                  (SessionSecurityFailure failure) => failure.userMessage,
                  'userMessage',
                  contains(scenario.messageFragment),
                ),
          ),
        );
      },
    );
  }
}
