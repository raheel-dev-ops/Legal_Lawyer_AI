import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../constants/app_constants.dart';

final BaseCacheManager _mediaCacheManager = CacheManager(
  Config(
    'mediaCache',
    stalePeriod: const Duration(days: 365),
    maxNrOfCacheObjects: 2000,
  ),
);

BaseCacheManager mediaCacheManager() => _mediaCacheManager;

String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) {
    return null;
  }
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = AppConstants.apiBaseUrl;
  final baseUri = Uri.parse(base);
  final root = Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : null,
  );
  var normalized = trimmed.replaceAll('\\', '/');
  normalized = normalized.replaceFirst(RegExp(r'^[a-zA-Z]:/'), '');
  const markers = ['storage/uploads/', 'uploads/'];
  for (final marker in markers) {
    final idx = normalized.indexOf(marker);
    if (idx != -1) {
      normalized = normalized.substring(idx + marker.length);
      break;
    }
  }
  normalized = normalized.replaceFirst(RegExp(r'^/+'), '');
  if (normalized.isEmpty) {
    return null;
  }
  var resolved = root.resolve('uploads/$normalized');
  if (baseUri.host.contains('ngrok-free.dev')) {
    final qp = Map<String, String>.from(resolved.queryParameters);
    qp['ngrok-skip-browser-warning'] = '1';
    resolved = resolved.replace(queryParameters: qp);
  }
  return resolved.toString();
}

Map<String, String>? resolveMediaHeaders(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }
  try {
    final host = Uri.parse(url).host;
    if (host.contains('ngrok-free.dev')) {
      return {'ngrok-skip-browser-warning': 'true'};
    }
  } catch (_) {}
  return null;
}

ImageProvider? resolveMediaImageProvider(
  BuildContext context,
  String? path, {
  double? width,
  double? height,
  bool preserveAspectRatio = true,
}) {
  final url = resolveMediaUrl(path);
  if (url == null) {
    return null;
  }
  final headers = resolveMediaHeaders(url);
  final provider = CachedNetworkImageProvider(
    url,
    headers: headers,
    cacheManager: _mediaCacheManager,
  );
  final dpr = MediaQuery.devicePixelRatioOf(context);
  var cacheWidth = width != null && width > 0 ? (width * dpr).round() : null;
  var cacheHeight = height != null && height > 0 ? (height * dpr).round() : null;
  if (cacheWidth == null && cacheHeight == null) {
    return provider;
  }
  if (preserveAspectRatio && cacheWidth != null && cacheHeight != null) {
    final maxSide = cacheWidth > cacheHeight ? cacheWidth : cacheHeight;
    cacheWidth = maxSide;
    cacheHeight = null;
  }
  return ResizeImage(
    provider,
    width: cacheWidth,
    height: cacheHeight,
  );
}
