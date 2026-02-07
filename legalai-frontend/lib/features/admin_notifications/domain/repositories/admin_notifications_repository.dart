import '../models/admin_notification_model.dart';

abstract class AdminNotificationsRepository {
  Future<List<AdminNotification>> getNotifications({int? before, int limit = 20});
  Future<int> unreadCount();
  Future<void> markRead(int id);
  Stream<AdminNotification> stream({int? lastId});
}
