import 'package:speakeasy/application/session/device_session_models.dart';
import 'package:speakeasy/services/api_client.dart';

abstract interface class DeviceSessionsRemoteApi {
  Future<Map<String, dynamic>> listSessions();

  Future<void> revokeSession(String sessionId);

  Future<void> logoutOthers();

  Future<void> logoutAll();

  Future<void> logoutCurrent();
}

class ApiClientDeviceSessionsRemoteApi implements DeviceSessionsRemoteApi {
  const ApiClientDeviceSessionsRemoteApi();

  @override
  Future<Map<String, dynamic>> listSessions() => ApiClient.listAuthSessions();

  @override
  Future<void> logoutAll() => ApiClient.logoutAllSessions();

  @override
  Future<void> logoutCurrent() => ApiClient.logoutCurrentSession();

  @override
  Future<void> logoutOthers() => ApiClient.logoutOtherSessions();

  @override
  Future<void> revokeSession(String sessionId) {
    return ApiClient.revokeAuthSession(sessionId);
  }
}

class DeviceSessionCoordinator {
  const DeviceSessionCoordinator({
    DeviceSessionsRemoteApi remoteApi =
        const ApiClientDeviceSessionsRemoteApi(),
  }) : _remoteApi = remoteApi;

  final DeviceSessionsRemoteApi _remoteApi;

  Future<List<DeviceSessionSummary>> loadSessions() async {
    final Map<String, dynamic> response = await _remoteApi.listSessions();
    final Object? sessionsJson = response['sessions'];
    if (sessionsJson is! List) {
      throw const FormatException('Invalid device session list');
    }

    final List<DeviceSessionSummary> sessions = sessionsJson
        .map((Object? value) {
          if (value is! Map) {
            throw const FormatException('Invalid device session');
          }
          return DeviceSessionSummary.fromJson(value.cast<String, dynamic>());
        })
        .toList(growable: false);
    return sessions.toList()
      ..sort((DeviceSessionSummary left, DeviceSessionSummary right) {
        if (left.isCurrent != right.isCurrent) {
          return left.isCurrent ? -1 : 1;
        }
        return right.lastActiveAt.compareTo(left.lastActiveAt);
      });
  }

  Future<void> revokeSession(DeviceSessionSummary session) {
    if (session.isCurrent) {
      throw ArgumentError.value(
        session.sessionId,
        'session',
        'Current session must use normal logout',
      );
    }
    return _remoteApi.revokeSession(session.sessionId);
  }

  Future<void> logoutOthers() => _remoteApi.logoutOthers();

  Future<DeviceLogoutResult> logoutCurrent({
    required Future<void> Function() clearLocalSession,
  }) {
    return _logoutAndClear(
      remoteLogout: _remoteApi.logoutCurrent,
      clearLocalSession: clearLocalSession,
      failureMessage: '本机已退出，但服务器端会话可能尚未撤销。',
    );
  }

  Future<DeviceLogoutResult> logoutAll({
    required Future<void> Function() clearLocalSession,
  }) {
    return _logoutAndClear(
      remoteLogout: _remoteApi.logoutAll,
      clearLocalSession: clearLocalSession,
      failureMessage: '本机已退出，但网络请求失败，其他设备可能尚未退出。',
      preserveRemoteUncertainty: true,
    );
  }

  Future<DeviceLogoutResult> _logoutAndClear({
    required Future<void> Function() remoteLogout,
    required Future<void> Function() clearLocalSession,
    required String failureMessage,
    bool preserveRemoteUncertainty = false,
  }) async {
    bool remoteCompleted = false;
    String resolvedFailureMessage = failureMessage;
    try {
      await remoteLogout();
      remoteCompleted = true;
    } catch (error) {
      if (error is SessionSecurityFailure) {
        resolvedFailureMessage = preserveRemoteUncertainty
            ? '${error.userMessage} 本次未能确认其他设备已退出。'
            : error.userMessage;
      }
      // Local credentials are cleared below even when the server is unreachable.
    }

    await clearLocalSession();
    return DeviceLogoutResult(
      remoteCompleted: remoteCompleted,
      userMessage: remoteCompleted ? null : resolvedFailureMessage,
    );
  }
}
