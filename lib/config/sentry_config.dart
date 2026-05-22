import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_config.dart';

class SentryConfig {
  const SentryConfig._({
    required this.dsn,
    required this.environment,
    required this.release,
  });

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');

  final String dsn;
  final String environment;
  final String release;

  static Future<SentryConfig> load() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String buildNumber = packageInfo.buildNumber.trim();
    final String version = packageInfo.version.trim();
    final String versionLabel = buildNumber.isEmpty
        ? version
        : '$version+$buildNumber';

    return SentryConfig._(
      dsn: _dsn,
      environment: _environment,
      release: '${packageInfo.packageName}@$versionLabel',
    );
  }

  static String get _environment {
    if (kDebugMode || AppConfig.isDevelopment) {
      return 'dev';
    }
    return 'prod';
  }
}
