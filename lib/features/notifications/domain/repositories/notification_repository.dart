import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> getNotificationsStream();
  Future<void> addNotification(AppNotification notification);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> clearAllNotifications();
}
