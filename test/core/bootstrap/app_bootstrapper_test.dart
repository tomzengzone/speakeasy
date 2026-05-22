import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/core/bootstrap/app_bootstrapper.dart';

void main() {
  test('bootstrap 按顺序执行初始化并产出 bundle', () async {
    final List<String> calls = <String>[];
    final List<String> statuses = <String>[];
    final AppBootstrapper bootstrapper = AppBootstrapper(
      storageGateway: _FakeStorageBootstrapGateway(calls),
      environmentGateway: _FakeEnvironmentBootstrapGateway(calls),
      notificationGateway: _FakeNotificationBootstrapGateway(calls),
      sentryGateway: _FakeSentryBootstrapGateway(calls),
    );

    final AppBootstrapBundle bundle = await bootstrapper.bootstrap(
      onStatus: statuses.add,
    );

    expect(statuses, <String>[
      '正在初始化本地数据…',
      '正在加载环境配置…',
      '正在初始化通知服务…',
      '正在初始化监控…',
      '正在进入应用…',
    ]);
    expect(calls, <String>['storage', 'env', 'notification', 'sentry']);
    expect(bundle.createSession, isNotNull);
    expect(bundle.createAudioService, isNotNull);
  });

  test('bootstrap 在软失败时继续后续步骤', () async {
    final List<String> calls = <String>[];
    final AppBootstrapper bootstrapper = AppBootstrapper(
      storageGateway: _FakeStorageBootstrapGateway(calls),
      environmentGateway: _FakeEnvironmentBootstrapGateway(calls)
        ..shouldThrow = true,
      notificationGateway: _FakeNotificationBootstrapGateway(calls),
      sentryGateway: _FakeSentryBootstrapGateway(calls),
    );

    await bootstrapper.bootstrap(onStatus: (_) {});

    expect(calls, <String>['storage', 'env', 'notification', 'sentry']);
  });

  test('bootstrap 在 storage 失败时中断并向上抛错', () async {
    final List<String> calls = <String>[];
    final AppBootstrapper bootstrapper = AppBootstrapper(
      storageGateway: _FakeStorageBootstrapGateway(calls)..shouldThrow = true,
      environmentGateway: _FakeEnvironmentBootstrapGateway(calls),
      notificationGateway: _FakeNotificationBootstrapGateway(calls),
      sentryGateway: _FakeSentryBootstrapGateway(calls),
    );

    expect(
      () => bootstrapper.bootstrap(onStatus: (_) {}),
      throwsA(isA<StateError>()),
    );
    expect(calls, <String>['storage']);
  });
}

class _FakeStorageBootstrapGateway implements StorageBootstrapGateway {
  _FakeStorageBootstrapGateway(this.calls);

  final List<String> calls;
  bool shouldThrow = false;

  @override
  Future<void> initStorage() async {
    calls.add('storage');
    if (shouldThrow) {
      throw StateError('storage failed');
    }
  }
}

class _FakeEnvironmentBootstrapGateway implements EnvironmentBootstrapGateway {
  _FakeEnvironmentBootstrapGateway(this.calls);

  final List<String> calls;
  bool shouldThrow = false;

  @override
  Future<void> loadEnv(String? fileName) async {
    calls.add('env');
    if (shouldThrow) {
      throw StateError('env failed');
    }
  }
}

class _FakeNotificationBootstrapGateway
    implements NotificationBootstrapGateway {
  _FakeNotificationBootstrapGateway(this.calls);

  final List<String> calls;

  @override
  Future<void> initNotifications() async {
    calls.add('notification');
  }
}

class _FakeSentryBootstrapGateway implements SentryBootstrapGateway {
  _FakeSentryBootstrapGateway(this.calls);

  final List<String> calls;

  @override
  Future<void> initSentry() async {
    calls.add('sentry');
  }
}
