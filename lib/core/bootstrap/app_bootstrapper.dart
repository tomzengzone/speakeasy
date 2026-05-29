import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:speakeasy/config/sentry_config.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/notification_service.dart';
import 'package:speakeasy/services/storage_service.dart';
import 'package:speakeasy/utils/error_handler.dart';

class AppBootstrapBundle {
  const AppBootstrapBundle({
    required this.createSession,
    required this.createAudioService,
  });

  final AppSession Function() createSession;
  final AudioService Function() createAudioService;
}

abstract class StorageBootstrapGateway {
  Future<void> initStorage();
}

abstract class EnvironmentBootstrapGateway {
  Future<void> loadEnv(String? fileName);
}

abstract class NotificationBootstrapGateway {
  Future<void> initNotifications();
}

abstract class SentryBootstrapGateway {
  Future<void> initSentry();
}

class DefaultStorageBootstrapGateway implements StorageBootstrapGateway {
  const DefaultStorageBootstrapGateway();

  static const String _hivePathOverride = String.fromEnvironment(
    'SPEAKEASY_HIVE_PATH',
  );
  static const String _hiveNamespace = String.fromEnvironment(
    'SPEAKEASY_HIVE_NAMESPACE',
  );
  static const bool _disableSharedPreferencesMigration = bool.fromEnvironment(
    'SPEAKEASY_DISABLE_SHARED_PREFS_MIGRATION',
  );

  @override
  Future<void> initStorage() {
    return StorageService.instance.init(
      hivePath: _hivePathOverride.trim().isEmpty ? null : _hivePathOverride,
      hiveNamespace: _hiveNamespace.trim().isEmpty ? null : _hiveNamespace,
      migrateFromSharedPreferences: !_disableSharedPreferencesMigration,
    );
  }
}

class DefaultEnvironmentBootstrapGateway
    implements EnvironmentBootstrapGateway {
  const DefaultEnvironmentBootstrapGateway();

  @override
  Future<void> loadEnv(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      return Future<void>.value();
    }
    return dotenv.load(fileName: fileName);
  }
}

class DefaultNotificationBootstrapGateway
    implements NotificationBootstrapGateway {
  const DefaultNotificationBootstrapGateway();

  @override
  Future<void> initNotifications() {
    return NotificationService.instance.init();
  }
}

class DefaultSentryBootstrapGateway implements SentryBootstrapGateway {
  const DefaultSentryBootstrapGateway();

  @override
  Future<void> initSentry() async {
    final SentryConfig sentryConfig = await SentryConfig.load();
    if (sentryConfig.dsn.trim().isEmpty) {
      debugPrint('[Boot] sentry disabled: missing SENTRY_DSN');
      return;
    }
    await SentryFlutter.init((options) {
      options.dsn = sentryConfig.dsn;
      options.environment = sentryConfig.environment;
      options.release = sentryConfig.release;
    });
  }
}

class AppBootstrapper {
  const AppBootstrapper({
    StorageBootstrapGateway storageGateway =
        const DefaultStorageBootstrapGateway(),
    EnvironmentBootstrapGateway environmentGateway =
        const DefaultEnvironmentBootstrapGateway(),
    NotificationBootstrapGateway notificationGateway =
        const DefaultNotificationBootstrapGateway(),
    SentryBootstrapGateway sentryGateway =
        const DefaultSentryBootstrapGateway(),
  }) : _storageGateway = storageGateway,
       _environmentGateway = environmentGateway,
       _notificationGateway = notificationGateway,
       _sentryGateway = sentryGateway;

  final StorageBootstrapGateway _storageGateway;
  final EnvironmentBootstrapGateway _environmentGateway;
  final NotificationBootstrapGateway _notificationGateway;
  final SentryBootstrapGateway _sentryGateway;

  Future<AppBootstrapBundle> bootstrap({
    required void Function(String status) onStatus,
  }) async {
    onStatus('正在初始化本地数据…');
    debugPrint('[Boot] init storage');
    await _storageGateway.initStorage();

    onStatus('正在加载环境配置…');
    final String? envFile = resolveEnvFileName();
    await _runSoftStep(
      context: 'dotenv load failed',
      failureLog: '[Boot] dotenv load failed, continue without env',
      action: () async {
        await _environmentGateway.loadEnv(envFile);
        if (envFile == null) {
          debugPrint('[Boot] skipped bundled env; using dart-define config');
        } else {
          debugPrint('[Boot] loaded env file: $envFile');
        }
      },
    );

    onStatus('正在初始化通知服务…');
    await _runSoftStep(
      context: 'Notification service initialization failed',
      failureLog: '[Boot] notification init failed, continue',
      action: _notificationGateway.initNotifications,
    );

    onStatus('正在初始化监控…');
    await _runSoftStep(
      context: 'Sentry initialization failed',
      failureLog: '[Boot] sentry init failed, continue',
      action: _sentryGateway.initSentry,
    );

    onStatus('正在进入应用…');
    return AppBootstrapBundle(
      createSession: AppSession.new,
      createAudioService: AudioService.new,
    );
  }

  Future<void> _runSoftStep({
    required String context,
    required String failureLog,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      ErrorHandler.handleError(error, stackTrace: stackTrace, context: context);
      debugPrint(failureLog);
    }
  }
}

String? resolveEnvFileName() {
  const String envFileOverride = String.fromEnvironment('ENV_FILE');
  if (envFileOverride.isNotEmpty) {
    return envFileOverride;
  }
  return null;
}
