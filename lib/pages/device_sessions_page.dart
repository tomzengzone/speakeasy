import 'dart:async';

import 'package:flutter/material.dart';

import 'package:speakeasy/application/session/device_session_coordinator.dart';
import 'package:speakeasy/application/session/device_session_models.dart';
import 'package:speakeasy/services/app_session.dart';

class DeviceSessionsPage extends StatefulWidget {
  const DeviceSessionsPage({super.key, this.coordinator, this.logoutAll});

  final DeviceSessionCoordinator? coordinator;
  final Future<DeviceLogoutResult> Function()? logoutAll;

  @override
  State<DeviceSessionsPage> createState() => _DeviceSessionsPageState();
}

class _DeviceSessionsPageState extends State<DeviceSessionsPage> {
  late final DeviceSessionCoordinator _coordinator =
      widget.coordinator ?? const DeviceSessionCoordinator();

  List<DeviceSessionSummary> _sessions = const <DeviceSessionSummary>[];
  bool _isLoading = true;
  String? _loadError;
  String? _activeAction;
  String? _actionError;
  Future<void> Function()? _retryAction;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSessions());
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final List<DeviceSessionSummary> sessions = await _coordinator
          .loadSessions();
      if (!mounted) {
        return;
      }
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = '设备会话加载失败，请检查网络后重试。';
      });
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD46B6B),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _revokeSession(
    DeviceSessionSummary session, {
    bool confirm = true,
  }) async {
    if (confirm &&
        !await _confirm(
          title: '退出这台设备？',
          message: '${session.deviceName} 将需要重新登录。',
          confirmLabel: '退出设备',
        )) {
      return;
    }
    await _runAction(
      actionKey: 'session:${session.sessionId}',
      action: () => _coordinator.revokeSession(session),
      retry: () => _revokeSession(session, confirm: false),
      failureMessage: '未能退出 ${session.deviceName}，请重试。',
      onSuccess: () {
        _sessions = _sessions
            .where(
              (DeviceSessionSummary item) =>
                  item.sessionId != session.sessionId,
            )
            .toList(growable: false);
        _showMessage('已退出 ${session.deviceName}');
      },
    );
  }

  Future<void> _logoutOthers({bool confirm = true}) async {
    if (confirm &&
        !await _confirm(
          title: '退出其他设备？',
          message: '除当前设备外，其他所有设备都需要重新登录。',
          confirmLabel: '退出其他设备',
        )) {
      return;
    }
    await _runAction(
      actionKey: 'others',
      action: _coordinator.logoutOthers,
      retry: () => _logoutOthers(confirm: false),
      failureMessage: '未能退出其他设备，请重试。',
      onSuccess: () {
        _sessions = _sessions
            .where((DeviceSessionSummary item) => item.isCurrent)
            .toList(growable: false);
        _showMessage('其他设备已退出');
      },
    );
  }

  Future<void> _logoutAll() async {
    if (!await _confirm(
      title: '退出全部设备？',
      message: '包括当前设备在内的所有设备都需要重新登录。',
      confirmLabel: '全部退出',
    )) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _activeAction = 'all';
      _actionError = null;
      _retryAction = null;
    });
    final Future<DeviceLogoutResult> Function() logout =
        widget.logoutAll ?? AppSessionScope.of(context).logoutAll;
    try {
      await logout();
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = '本机登录状态清理失败，请立即重试。';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
    }
  }

  Future<void> _runAction({
    required String actionKey,
    required Future<void> Function() action,
    required Future<void> Function() retry,
    required String failureMessage,
    required VoidCallback onSuccess,
  }) async {
    if (_activeAction != null) {
      return;
    }
    setState(() {
      _activeAction = actionKey;
      _actionError = null;
      _retryAction = null;
    });
    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(onSuccess);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _actionError = failureMessage;
        _retryAction = retry;
      });
    } finally {
      if (mounted) {
        setState(() => _activeAction = null);
      }
    }
  }

  void _showMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EC),
      appBar: AppBar(
        title: const Text('设备与登录'),
        backgroundColor: const Color(0xFFF5F2EC),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        key: ValueKey<String>('device_sessions_loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (_loadError != null) {
      return _PageState(
        key: const ValueKey<String>('device_sessions_error'),
        icon: Icons.cloud_off_rounded,
        title: '无法加载设备',
        message: _loadError!,
        actionLabel: '重试',
        onAction: _loadSessions,
      );
    }

    final List<DeviceSessionSummary> otherSessions = _sessions
        .where((DeviceSessionSummary item) => !item.isCurrent)
        .toList(growable: false);
    return ListView(
      key: const ValueKey<String>('device_sessions_content'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const Text(
          '已登录设备',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          '只显示设备类型、应用版本和活动时间。',
          style: TextStyle(color: Color(0xFF6F6F6F)),
        ),
        if (_actionError != null) ...[
          const SizedBox(height: 14),
          _ActionError(message: _actionError!, onRetry: _retryAction),
        ],
        const SizedBox(height: 16),
        if (_sessions.isEmpty)
          const _PageState(
            key: ValueKey<String>('device_sessions_empty'),
            icon: Icons.devices_other_rounded,
            title: '暂无活跃设备',
            message: '重新登录后，设备会显示在这里。',
          )
        else
          ..._sessions.map(
            (DeviceSessionSummary session) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionCard(
                session: session,
                isLoading: _activeAction == 'session:${session.sessionId}',
                actionsEnabled: _activeAction == null,
                onRevoke: () => unawaited(_revokeSession(session)),
              ),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey<String>('logout_other_sessions_button'),
          onPressed: otherSessions.isEmpty || _activeAction != null
              ? null
              : () => unawaited(_logoutOthers()),
          icon: _activeAction == 'others'
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.phonelink_erase_rounded),
          label: const Text('退出其他设备'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const ValueKey<String>('logout_all_sessions_button'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD46B6B),
          ),
          onPressed: _activeAction != null
              ? null
              : () => unawaited(_logoutAll()),
          icon: _activeAction == 'all'
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.logout_rounded),
          label: const Text('退出全部设备'),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isLoading,
    required this.actionsEnabled,
    required this.onRevoke,
  });

  final DeviceSessionSummary session;
  final bool isLoading;
  final bool actionsEnabled;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final String? version = session.appVersion;
    return Card(
      key: ValueKey<String>('device_session_${session.sessionId}'),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8F0EC),
              foregroundColor: const Color(0xFF3F6F60),
              child: Icon(_deviceIcon(session.platform)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (session.isCurrent)
                        const Chip(
                          key: ValueKey<String>('current_device_badge'),
                          visualDensity: VisualDensity.compact,
                          label: Text('当前设备'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      _platformLabel(session.platform),
                      if (version != null) 'App $version',
                    ].join(' · '),
                    style: const TextStyle(color: Color(0xFF6F6F6F)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '最近活动 ${_formatDateTime(session.lastActiveAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                  Text(
                    '首次登录 ${_formatDateTime(session.createdAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                  if (!session.isCurrent) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      key: ValueKey<String>(
                        'revoke_session_${session.sessionId}',
                      ),
                      onPressed: actionsEnabled ? onRevoke : null,
                      child: isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('退出此设备'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionError extends StatelessWidget {
  const _ActionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey<String>('device_sessions_action_error'),
      color: const Color(0xFFFFECEA),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFB64D45)),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _PageState extends StatelessWidget {
  const _PageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF7A7A7A)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6F6F6F)),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _deviceIcon(String platform) {
  return switch (platform.toLowerCase()) {
    'ios' => Icons.phone_iphone_rounded,
    'android' => Icons.phone_android_rounded,
    _ => Icons.devices_other_rounded,
  };
}

String _platformLabel(String platform) {
  return switch (platform.toLowerCase()) {
    'ios' => 'iOS',
    'android' => 'Android',
    _ => '未知平台',
  };
}

String _formatDateTime(DateTime value) {
  final DateTime local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
