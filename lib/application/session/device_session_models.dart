class DeviceSessionSummary {
  const DeviceSessionSummary({
    required this.sessionId,
    required this.isCurrent,
    required this.deviceName,
    required this.platform,
    required this.createdAt,
    required this.lastActiveAt,
    this.appVersion,
  });

  final String sessionId;
  final bool isCurrent;
  final String deviceName;
  final String platform;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  factory DeviceSessionSummary.fromJson(Map<String, dynamic> json) {
    final String sessionId = _requiredString(json, 'session_id');
    final String deviceName = _requiredString(json, 'device_name');
    final String platform = _requiredString(json, 'platform');
    final DateTime createdAt = _requiredDateTime(json, 'created_at');
    final DateTime lastActiveAt = _requiredDateTime(json, 'last_active_at');
    final Object? current = json['current'];
    if (current is! bool) {
      throw const FormatException('Invalid current session flag');
    }

    final String appVersion = (json['app_version'] as String? ?? '').trim();
    return DeviceSessionSummary(
      sessionId: sessionId,
      isCurrent: current,
      deviceName: deviceName,
      platform: platform,
      appVersion: appVersion.isEmpty ? null : appVersion,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
    );
  }
}

class DeviceLogoutResult {
  const DeviceLogoutResult({required this.remoteCompleted, this.userMessage});

  final bool remoteCompleted;
  final String? userMessage;
}

String _requiredString(Map<String, dynamic> json, String field) {
  final String value = (json[field] as String? ?? '').trim();
  if (value.isEmpty) {
    throw FormatException('Missing $field');
  }
  return value;
}

DateTime _requiredDateTime(Map<String, dynamic> json, String field) {
  final DateTime? value = DateTime.tryParse(_requiredString(json, field));
  if (value == null) {
    throw FormatException('Invalid $field');
  }
  return value.toLocal();
}
