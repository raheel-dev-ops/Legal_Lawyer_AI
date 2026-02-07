import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/admin_notifications_remote_data_source.dart';
import '../../domain/models/admin_notification_model.dart';

part 'admin_notifications_controller.g.dart';

final adminNotificationsRefreshProvider = legacy.StateProvider<int>((ref) => 0);

@Riverpod(keepAlive: true)
class AdminNotificationsController extends _$AdminNotificationsController {
  @override
  void build() {}

  Future<void> markRead(int id) async {
    ref.read(appLoggerProvider).info('admin.notifications.read.start', {'id': id});
    try {
      await ref.read(adminNotificationsRepositoryProvider).markRead(id);
      ref.read(adminNotificationsRefreshProvider.notifier).state++;
      ref.read(appLoggerProvider).info('admin.notifications.read.success', {'id': id});
    } catch (err, stack) {
      ref.read(appLoggerProvider).warn('admin.notifications.read.failed', {
        'id': id,
        'error': err.toString(),
      });
      Error.throwWithStackTrace(err, stack);
    }
  }
}

@Riverpod(keepAlive: true)
class AdminNotificationsStreamController extends _$AdminNotificationsStreamController {
  StreamSubscription<AdminNotification>? _subscription;
  Timer? _reconnectTimer;
  int _lastId = 0;
  int _backoffSeconds = 2;
  bool _active = false;

  @override
  void build() {
    ref.onDispose(_dispose);
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      _handleAuthChange(next);
    });
    _handleAuthChange(ref.read(authControllerProvider));
  }

  void _handleAuthChange(AsyncValue<dynamic> value) {
    final user = value.asData?.value;
    if (user?.isAdmin == true) {
      if (!_active) {
        _startStream();
      }
      return;
    }
    _stopStream();
  }

  void _startStream() {
    _active = true;
    _subscription?.cancel();
    _reconnectTimer?.cancel();

    final repo = ref.read(adminNotificationsRepositoryProvider);
    _subscription = repo.stream(lastId: _lastId).listen(
      (event) {
        if (event.id > _lastId) {
          _lastId = event.id;
        }
        ref.read(adminNotificationsRefreshProvider.notifier).state++;
      },
      onError: (_, __) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );
  }

  void _scheduleReconnect() {
    if (!_active) return;
    _subscription?.cancel();
    final delay = Duration(seconds: _backoffSeconds);
    _backoffSeconds = (_backoffSeconds * 2).clamp(2, 10).toInt();
    _reconnectTimer = Timer(delay, _startStream);
  }

  void _stopStream() {
    _active = false;
    _subscription?.cancel();
    _reconnectTimer?.cancel();
    _subscription = null;
    _reconnectTimer = null;
    _backoffSeconds = 2;
    _lastId = 0;
  }

  void _dispose() {
    _stopStream();
  }
}

@Riverpod(keepAlive: false)
Future<List<AdminNotification>> adminNotifications(Ref ref) async {
  ref.watch(adminNotificationsRefreshProvider);
  return ref.watch(adminNotificationsRepositoryProvider).getNotifications();
}

@Riverpod(keepAlive: false)
Future<int> adminNotificationsUnreadCount(Ref ref) async {
  ref.watch(adminNotificationsRefreshProvider);
  return ref.watch(adminNotificationsRepositoryProvider).unreadCount();
}
