class AuthCredentials {
  const AuthCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now);

  bool needsRefreshAt(
    DateTime now, {
    Duration skew = const Duration(minutes: 1),
  }) {
    return !expiresAt.isAfter(now.toUtc().add(skew));
  }

  AuthCredentials copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthCredentials(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
  }

  factory AuthCredentials.fromJson(Map<String, dynamic> json) {
    final String accessToken = _readCredentialString(
      json['accessToken'] ?? json['token'],
    );
    final String refreshToken = _readCredentialString(json['refreshToken']);
    final String expiresAtRaw = _readCredentialString(json['expiresAt']);
    final DateTime? expiresAt = DateTime.tryParse(expiresAtRaw);

    if (accessToken.isEmpty || refreshToken.isEmpty || expiresAt == null) {
      throw const FormatException('Incomplete authentication credentials');
    }

    return AuthCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt.toUtc(),
    );
  }
}

String _readCredentialString(Object? value) {
  return value is String ? value.trim() : '';
}
