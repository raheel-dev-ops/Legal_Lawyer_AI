import '../models/notification_model.dart';
import '../models/notification_preferences.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications({int? before, int limit = 20});
  Future<void> markRead(int id);
  Future<int> markAllRead();
  Future<int> unreadCount();
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences({
    bool? contentUpdates,
    bool? lawyerUpdates,
    bool? reminderNotifications,
  });
  Future<void> registerDeviceToken(String platform, String token);
  Future<void> unregisterDeviceToken(String token);
}
