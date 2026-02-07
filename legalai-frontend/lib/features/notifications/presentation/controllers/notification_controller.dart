import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/notifications/notification_refresh_provider.dart';
import '../../../../core/notifications/push_notifications_controller.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/utils/ttl_cache.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/notification_preferences.dart';

part 'notification_controller.g.dart';

const Duration _preferencesCacheTtl = Duration(minutes: 10);
const String _preferencesCacheKey = 'notificationPreferences';
final TtlCache _notificationCache = TtlCache(defaultTtl: _preferencesCacheTtl);

@riverpod
Future<List<AppNotification>> notifications(Ref ref, {int? before}) async {
  ref.watch(notificationRefreshProvider);
  final items = await ref.watch(notificationRepositoryProvider).getNotifications(before: before);
  return items;
}

@riverpod
Future<int> notificationUnreadCount(Ref ref) async {
  ref.watch(notificationRefreshProvider);
  final count = await ref.watch(notificationRepositoryProvider).unreadCount();
  return count;
}

@riverpod
Future<NotificationPreferences> notificationPreferences(Ref ref) async {
  final cached = _notificationCache.get<NotificationPreferences>(
    _preferencesCacheKey,
    ttl: _preferencesCacheTtl,
  );
  if (cached != null) {
    return cached;
  }
  final appPrefs = ref.read(appPreferencesProvider);
  final persisted = appPrefs.getNotificationPreferences();
  if (persisted != null && !appPrefs.isNotificationPreferencesStale(_preferencesCacheTtl)) {
    _notificationCache.set(_preferencesCacheKey, persisted);
    return persisted;
  }
  final prefs = await ref.watch(notificationRepositoryProvider).getPreferences();
  _notificationCache.set(_preferencesCacheKey, prefs);
  appPrefs.setNotificationPreferences(prefs);
  return prefs;
}

@Riverpod(keepAlive: true)
class NotificationController extends _$NotificationController {
  @override
  void build() {}

  Future<void> markRead(int id) async {
    ref.read(appLoggerProvider).info('notifications.read.start');
    try {
      await ref.read(notificationRepositoryProvider).markRead(id);
      ref.read(notificationRefreshProvider.notifier).state++;
      ref.read(appLoggerProvider).info('notifications.read.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('notifications.read.failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<int> markAllRead() async {
    ref.read(appLoggerProvider).info('notifications.read_all.start');
    try {
      final updated = await ref.read(notificationRepositoryProvider).markAllRead();
      ref.read(notificationRefreshProvider.notifier).state++;
      ref.read(appLoggerProvider).info('notifications.read_all.success', {
        'updated': updated,
      });
      return updated;
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('notifications.read_all.failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<NotificationPreferences> updatePreferences({
    bool? contentUpdates,
    bool? lawyerUpdates,
    bool? reminderNotifications,
  }) async {
    ref.read(appLoggerProvider).info('notifications.preferences.update.start');
    try {
      final prefs = await ref.read(notificationRepositoryProvider).updatePreferences(
        contentUpdates: contentUpdates,
        lawyerUpdates: lawyerUpdates,
        reminderNotifications: reminderNotifications,
      );
      _notificationCache.set(_preferencesCacheKey, prefs);
      ref.read(appPreferencesProvider).setNotificationPreferences(prefs);
      ref.invalidate(notificationPreferencesProvider);
      ref.read(notificationRefreshProvider.notifier).state++;
      await ref.read(pushNotificationsControllerProvider.notifier).syncPreferences(prefs);
      ref.read(appLoggerProvider).info('notifications.preferences.update.success');
      return prefs;
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('notifications.preferences.update.failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }
}
