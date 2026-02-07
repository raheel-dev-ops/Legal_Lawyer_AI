import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../logging/app_logger.dart';
import '../router/app_router.dart';
import 'notification_refresh_provider.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';

const _contentUpdatesTopic = 'content_updates';
const _lawyerUpdatesTopic = 'lawyer_updates';

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize(Ref ref) async {
    if (_initialized || kIsWeb) return;

    await _requestPermissions();
    await _initLocalNotifications();
    await _configureForeground();

    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      _bumpRefresh(ref);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNavigation(ref, message);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNavigation(ref, initial);
    }

    _messaging.onTokenRefresh.listen((token) {
      _registerToken(ref, token);
    });

    _initialized = true;
  }

  Future<void> applyPreferences(Ref ref, {
    required bool contentUpdates,
    required bool lawyerUpdates,
  }) async {
    if (kIsWeb) return;

    if (contentUpdates) {
      await _messaging.subscribeToTopic(_contentUpdatesTopic);
    } else {
      await _messaging.unsubscribeFromTopic(_contentUpdatesTopic);
    }

    if (lawyerUpdates) {
      await _messaging.subscribeToTopic(_lawyerUpdatesTopic);
    } else {
      await _messaging.unsubscribeFromTopic(_lawyerUpdatesTopic);
    }
  }

  Future<void> registerCurrentToken(Ref ref) async {
    if (kIsWeb) return;
    final logger = ref.read(appLoggerProvider);
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(ref, token);
      }
    } catch (_) {
      logger.warn('push.token.fetch_failed');
    }
  }

  Future<void> unregisterCurrentToken(Ref ref) async {
    if (kIsWeb) return;
    final logger = ref.read(appLoggerProvider);
    String? token;
    try {
      token = await _messaging.getToken();
    } catch (_) {
      logger.warn('push.token.fetch_failed');
    }
    if (token == null) {
      await _messaging.unsubscribeFromTopic(_contentUpdatesTopic);
      await _messaging.unsubscribeFromTopic(_lawyerUpdatesTopic);
      return;
    }
    try {
      await ref.read(notificationRepositoryProvider).unregisterDeviceToken(token);
    } catch (_) {}
    await _messaging.unsubscribeFromTopic(_contentUpdatesTopic);
    await _messaging.unsubscribeFromTopic(_lawyerUpdatesTopic);
  }

  Future<void> _registerToken(Ref ref, String token) async {
    if (kIsWeb) return;
    final logger = ref.read(appLoggerProvider);
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await ref.read(notificationRepositoryProvider).registerDeviceToken(platform, token);
      logger.info('push.token.registered');
    } catch (e) {
      logger.warn('push.token.registration_failed');
    }
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureForeground() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'legalai_updates',
      'LegalAI Updates',
      description: 'LegalAI notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'legalai_updates',
        'LegalAI Updates',
        channelDescription: 'LegalAI notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  void _handleNavigation(Ref ref, RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null || route.isEmpty) return;
    ref.read(goRouterProvider).push(route);
  }

  void _bumpRefresh(Ref ref) {
    ref.read(notificationRefreshProvider.notifier).state++;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
