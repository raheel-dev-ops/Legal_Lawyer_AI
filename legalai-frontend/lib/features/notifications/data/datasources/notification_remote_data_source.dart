import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/cache/http_cache.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notification_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRemoteDataSource(ref.watch(dioProvider));
}

class NotificationRemoteDataSource implements NotificationRepository {
  final Dio _dio;

  NotificationRemoteDataSource(this._dio);

  @override
  Future<List<AppNotification>> getNotifications({int? before, int limit = 20}) async {
    final key = _notificationsKey(before, limit);
    return HttpCache.getOrFetchJson(
      key: key,
      fetcher: (etag) {
        return _dio.get(
          '/notifications',
          queryParameters: {
            'limit': limit,
            if (before != null) 'before': before,
          },
          options: Options(
            headers: {
              if (etag != null) 'If-None-Match': etag,
            },
            validateStatus: (status) => status != null && (status == 304 || (status >= 200 && status < 300)),
          ),
        );
      },
      decode: (data) {
        final items = (data['items'] as List?) ?? [];
        return items
            .map((e) => AppNotification.fromApi(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  @override
  Future<void> markRead(int id) async {
    await _dio.post('/notifications/$id/read');
    await HttpCache.invalidatePrefix('notifications:');
    await HttpCache.invalidatePrefix('notifications.unreadCount:');
  }

  @override
  Future<int> markAllRead() async {
    final response = await _dio.post('/notifications/mark-all-read');
    await HttpCache.invalidatePrefix('notifications:');
    await HttpCache.invalidatePrefix('notifications.unreadCount:');
    return (response.data['updated'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> unreadCount() async {
    final key = _unreadCountKey();
    return HttpCache.getOrFetchJson(
      key: key,
      fetcher: (etag) {
        return _dio.get(
          '/notifications/unread-count',
          options: Options(
            headers: {
              if (etag != null) 'If-None-Match': etag,
            },
            validateStatus: (status) => status != null && (status == 304 || (status >= 200 && status < 300)),
          ),
        );
      },
      decode: (data) => (data['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final response = await _dio.get('/notifications/preferences');
    return NotificationPreferences.fromApi(response.data as Map<String, dynamic>);
  }

  @override
  Future<NotificationPreferences> updatePreferences({
    bool? contentUpdates,
    bool? lawyerUpdates,
    bool? reminderNotifications,
  }) async {
    final data = <String, dynamic>{};
    if (contentUpdates != null) data['contentUpdates'] = contentUpdates;
    if (lawyerUpdates != null) data['lawyerUpdates'] = lawyerUpdates;
    if (reminderNotifications != null) data['reminderNotifications'] = reminderNotifications;
    final response = await _dio.put('/notifications/preferences', data: data);
    return NotificationPreferences.fromApi(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> registerDeviceToken(String platform, String token) async {
    await _dio.post('/notifications/register-device-token', data: {
      'platform': platform,
      'token': token,
    });
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await _dio.post('/notifications/unregister-device-token', data: {
      'token': token,
    });
  }
}

String _notificationsKey(int? before, int limit) => 'notifications:${before ?? 0}:$limit';
String _unreadCountKey() => 'notifications.unreadCount';
