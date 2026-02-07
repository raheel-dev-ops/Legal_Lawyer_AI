import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../../features/notifications/domain/models/notification_preferences.dart';
import 'push_notifications_service.dart';

part 'push_notifications_controller.g.dart';

@Riverpod(keepAlive: true)
class PushNotificationsController extends _$PushNotificationsController {
  @override
  Future<void> build() async {
    await PushNotificationsService.instance.initialize(ref);

    Future(() async {
      final user = ref.read(authControllerProvider).asData?.value;
      if (user != null) {
        await PushNotificationsService.instance.registerCurrentToken(ref);
        final prefs = await ref.read(notificationRepositoryProvider).getPreferences();
        await PushNotificationsService.instance.applyPreferences(
          ref,
          contentUpdates: prefs.contentUpdates,
          lawyerUpdates: prefs.lawyerUpdates,
        );
      }
    });

    ref.listen<AsyncValue<dynamic>>(
      authControllerProvider,
      (previous, next) {
        final user = next.asData?.value;
        if (user != null) {
          Future(() async {
            await PushNotificationsService.instance.registerCurrentToken(ref);
            final prefs = await ref.read(notificationRepositoryProvider).getPreferences();
            await PushNotificationsService.instance.applyPreferences(
              ref,
              contentUpdates: prefs.contentUpdates,
              lawyerUpdates: prefs.lawyerUpdates,
            );
          });
        }
      },
    );
  }

  Future<void> syncPreferences(NotificationPreferences prefs) async {
    await PushNotificationsService.instance.applyPreferences(
      ref,
      contentUpdates: prefs.contentUpdates,
      lawyerUpdates: prefs.lawyerUpdates,
    );
  }

  Future<void> unregisterDeviceToken() async {
    await PushNotificationsService.instance.unregisterCurrentToken(ref);
  }
}
