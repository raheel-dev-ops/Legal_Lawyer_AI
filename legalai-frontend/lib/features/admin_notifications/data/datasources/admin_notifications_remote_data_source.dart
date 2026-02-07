import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/models/admin_notification_model.dart';
import '../../domain/repositories/admin_notifications_repository.dart';

part 'admin_notifications_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
AdminNotificationsRepository adminNotificationsRepository(Ref ref) {
  return AdminNotificationsRemoteDataSource(ref.watch(dioProvider));
}

class AdminNotificationsRemoteDataSource implements AdminNotificationsRepository {
  final Dio _dio;

  AdminNotificationsRemoteDataSource(this._dio);

  @override
  Future<List<AdminNotification>> getNotifications({int? before, int limit = 20}) async {
    final response = await _dio.get('/admin/notifications', queryParameters: {
      'limit': limit,
      if (before != null) 'before': before,
    });
    final items = (response.data['items'] as List?) ?? [];
    return items.map((e) => AdminNotification.fromApi(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> unreadCount() async {
    final response = await _dio.get('/admin/notifications/unread-count');
    return (response.data['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markRead(int id) async {
    await _dio.post('/admin/notifications/$id/read');
  }

  @override
  Stream<AdminNotification> stream({int? lastId}) async* {
    final response = await _dio.get<ResponseBody>(
      '/admin/notifications/stream',
      queryParameters: {
        if (lastId != null && lastId > 0) 'last_id': lastId,
      },
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(milliseconds: 0),
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final body = response.data;
    if (body == null) return;

    final stream = body.stream.cast<List<int>>().transform(utf8.decoder);
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(chunk);
      var content = buffer.toString().replaceAll('\r', '');
      var separatorIndex = content.indexOf('\n\n');
      while (separatorIndex != -1) {
        final block = content.substring(0, separatorIndex);
        content = content.substring(separatorIndex + 2);
        final payload = _parseEvent(block);
        if (payload != null) {
          yield AdminNotification.fromApi(payload);
        }
        separatorIndex = content.indexOf('\n\n');
      }
      buffer
        ..clear()
        ..write(content);
    }
  }

  Map<String, dynamic>? _parseEvent(String block) {
    String? event;
    final dataLines = <String>[];
    for (final rawLine in block.split('\n')) {
      final line = rawLine.trimRight();
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
        continue;
      }
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }

    if (event != 'notification') return null;
    if (dataLines.isEmpty) return null;

    final raw = dataLines.join('\n').trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
