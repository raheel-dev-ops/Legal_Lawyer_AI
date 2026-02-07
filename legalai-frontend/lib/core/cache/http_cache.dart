import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HttpCacheEntry {
  final dynamic data;
  final String? etag;
  final DateTime storedAt;

  HttpCacheEntry({
    required this.data,
    required this.etag,
    required this.storedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'etag': etag,
      'storedAt': storedAt.millisecondsSinceEpoch,
    };
  }

  static HttpCacheEntry fromJson(Map<dynamic, dynamic> json) {
    final storedAtRaw = json['storedAt'];
    return HttpCacheEntry(
      data: json['data'],
      etag: json['etag'] as String?,
      storedAt: DateTime.fromMillisecondsSinceEpoch(
        storedAtRaw is int ? storedAtRaw : 0,
      ),
    );
  }
}

class HttpCache {
  static const String _boxName = 'http_cache';

  static dynamic _normalizeJson(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _normalizeJson(val)));
    }
    if (value is List) {
      return value.map(_normalizeJson).toList();
    }
    return value;
  }

  static Future<Box> _box() async {
    return Hive.openBox(_boxName);
  }

  static Future<HttpCacheEntry?> getEntry(String key) async {
    final box = await _box();
    final raw = box.get(key);
    if (raw is Map) {
      final entry = HttpCacheEntry.fromJson(raw);
      final normalized = _normalizeJson(entry.data);
      if (!identical(normalized, entry.data)) {
        return HttpCacheEntry(
          data: normalized,
          etag: entry.etag,
          storedAt: entry.storedAt,
        );
      }
      return entry;
    }
    return null;
  }

  static Future<void> setEntry(String key, HttpCacheEntry entry) async {
    final box = await _box();
    await box.put(key, entry.toJson());
  }

  static Future<void> invalidate(String key) async {
    final box = await _box();
    await box.delete(key);
  }

  static Future<void> invalidatePrefix(String prefix) async {
    final box = await _box();
    final keys = box.keys.where((k) => k.toString().startsWith(prefix)).toList();
    await box.deleteAll(keys);
  }

  static Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }

  static Future<T> getOrFetchJson<T>({
    required String key,
    required Future<Response<dynamic>> Function(String? etag) fetcher,
    required T Function(dynamic data) decode,
  }) async {
    final cached = await getEntry(key);
    final response = await fetcher(cached?.etag);
    if (response.statusCode == 304) {
      if (cached != null) {
        return decode(cached.data);
      }
      final retry = await fetcher(null);
      final data = retry.data;
      final etag = retry.headers.value('etag');
      await setEntry(
        key,
        HttpCacheEntry(
          data: data,
          etag: etag,
          storedAt: DateTime.now(),
        ),
      );
      return decode(data);
    }
    final data = response.data;
    final etag = response.headers.value('etag');
    await setEntry(
      key,
      HttpCacheEntry(
        data: data,
        etag: etag,
        storedAt: DateTime.now(),
      ),
    );
    return decode(data);
  }
}
