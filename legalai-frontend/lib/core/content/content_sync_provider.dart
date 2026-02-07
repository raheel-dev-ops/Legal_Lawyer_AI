import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';
import '../network/dio_provider.dart';
import 'content_cache.dart';
import '../cache/http_cache.dart';

final contentSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  await _runContentSync(ref, force: false);
});

final contentSyncControllerProvider = Provider<ContentSyncController>((ref) {
  return ContentSyncController(ref);
});

class ContentSyncController {
  final Ref _ref;
  ContentSyncController(this._ref);

  Future<bool> refresh() {
    return _runContentSync(_ref, force: true);
  }
}

Future<bool> _runContentSync(Ref ref, {required bool force}) async {
  final dio = ref.watch(dioProvider);
  final logger = ref.read(appLoggerProvider);
  try {
    final manifest = await HttpCache.getOrFetchJson<Map<String, dynamic>>(
      key: 'content.manifest',
      fetcher: (etag) {
        return dio.get(
          '/content/manifest',
          options: Options(
            headers: {
              if (etag != null) 'If-None-Match': etag,
            },
            validateStatus: (status) => status != null && (status == 304 || (status >= 200 && status < 300)),
          ),
        );
      },
      decode: (data) => Map<String, dynamic>.from(data as Map),
    );
    final version = (manifest['version'] as num?)?.toInt() ?? 0;
    final cachedVersion = await ContentCache.getVersion();
    if (!force && cachedVersion == version) {
      return true;
    }

    final files = manifest['files'] as Map<String, dynamic>? ?? {};
    final rightsUrl = _resolveUrl(dio, files['rights']?['url'] as String? ?? '/content/rights.json');
    final templatesUrl = _resolveUrl(dio, files['templates']?['url'] as String? ?? '/content/templates.json');
    final pathwaysUrl = _resolveUrl(dio, files['pathways']?['url'] as String? ?? '/content/pathways.json');

    final rightsResponse = await dio.getUri(rightsUrl);
    final templatesResponse = await dio.getUri(templatesUrl);
    final pathwaysResponse = await dio.getUri(pathwaysUrl);

    if (rightsResponse.data is List) {
      await ContentCache.saveRights(rightsResponse.data as List<dynamic>);
    }
    if (templatesResponse.data is List) {
      await ContentCache.saveTemplates(templatesResponse.data as List<dynamic>);
    }
    if (pathwaysResponse.data is List) {
      await ContentCache.savePathways(pathwaysResponse.data as List<dynamic>);
    }
    await ContentCache.setVersion(version);
    logger.info('content.sync.success', {'version': version});
    return true;
  } catch (e) {
    logger.warn('content.sync.failed');
    return false;
  }
}

Uri _resolveUrl(Dio dio, String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Uri.parse(url);
  }
  final base = Uri.parse(dio.options.baseUrl);
  if (url.startsWith('/')) {
    return base.replace(path: url);
  }
  return base.resolve(url);
}
