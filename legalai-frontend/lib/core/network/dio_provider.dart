import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_provider.dart';
import 'auth_interceptor.dart';
import '../logging/app_logger.dart';
import '../session/session_invalidator.dart';
import 'safe_log_interceptor.dart';
import '../preferences/preferences_providers.dart';
import 'connectivity_service.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AppConstants.apiBaseUrl.contains('ngrok-free.dev'))
          'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  final storage = ref.watch(secureStorageProvider);
  final logger = ref.watch(appLoggerProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final online = await isOnline();
        if (!online) {
          logger.warn('network.offline', {
            'method': options.method,
            'path': options.path,
          });
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: 'No internet connection',
            ),
          );
        }
        final safeMode = ref.read(safeModeProvider);
        options.headers['X-Safe-Mode'] = safeMode ? '1' : '0';
        handler.next(options);
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      dio: dio,
      logger: logger,
      onSessionInvalidated: () {
        ref.read(sessionInvalidationProvider.notifier).bump();
      },
    ),
  );

  dio.interceptors.add(SafeLogInterceptor(logger));

  return dio;
}
