import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:expense_tracker/features/notifications/domain/repositories/notification_repository.dart';
import 'package:expense_tracker/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<AppNotification>> getNotificationsStream() {
    return remoteDataSource.getNotifications();
  }

  @override
  Future<void> addNotification(AppNotification notification) {
    return remoteDataSource.addNotification(AppNotificationModel.fromEntity(notification));
  }

  @override
  Future<void> markAsRead(String id) {
    return remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() {
    return remoteDataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String id) {
    return remoteDataSource.deleteNotification(id);
  }

  @override
  Future<void> clearAllNotifications() {
    return remoteDataSource.clearAll();
  }
}
