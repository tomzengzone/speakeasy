import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';

void main() {
  test('auth credentials decode the complete backend contract', () {
    final AuthCredentials credentials =
        AuthCredentials.fromJson(<String, dynamic>{
          'accessToken': ' access-token ',
          'refreshToken': ' refresh-token ',
          'expiresAt': '2026-08-27T00:00:00+08:00',
        });

    expect(credentials.accessToken, 'access-token');
    expect(credentials.refreshToken, 'refresh-token');
    expect(credentials.expiresAt, DateTime.parse('2026-08-26T16:00:00Z'));
    expect(credentials.isExpiredAt(DateTime.utc(2026, 8, 26, 15)), isFalse);
    expect(credentials.isExpiredAt(DateTime.utc(2026, 8, 26, 16)), isTrue);
    expect(
      credentials.needsRefreshAt(DateTime.utc(2026, 8, 26, 15, 58)),
      isFalse,
    );
    expect(
      credentials.needsRefreshAt(DateTime.utc(2026, 8, 26, 15, 59)),
      isTrue,
    );
  });

  test('auth credentials reject any incomplete token set', () {
    for (final Map<String, dynamic> json in <Map<String, dynamic>>[
      <String, dynamic>{
        'refreshToken': 'refresh-token',
        'expiresAt': '2026-08-27T00:00:00Z',
      },
      <String, dynamic>{
        'accessToken': 'access-token',
        'expiresAt': '2026-08-27T00:00:00Z',
      },
      <String, dynamic>{
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresAt': 'not-a-date',
      },
    ]) {
      expect(() => AuthCredentials.fromJson(json), throwsFormatException);
    }
  });
}
