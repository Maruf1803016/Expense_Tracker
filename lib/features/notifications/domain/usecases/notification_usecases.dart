import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:expense_tracker/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsStreamUseCase {
  final NotificationRepository repository;
  GetNotificationsStreamUseCase(this.repository);

  Stream<List<AppNotification>> call() {
    return repository.getNotificationsStream();
  }
}

class AddNotificationUseCase {
  final NotificationRepository repository;
  AddNotificationUseCase(this.repository);

  Future<void> call(AppNotification notification) {
    return repository.addNotification(notification);
  }
}

class MarkNotificationAsReadUseCase {
  final NotificationRepository repository;
  MarkNotificationAsReadUseCase(this.repository);

  Future<void> call(String id) {
    return repository.markAsRead(id);
  }
}

class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository repository;
  MarkAllNotificationsAsReadUseCase(this.repository);

  Future<void> call() {
    return repository.markAllAsRead();
  }
}

class DeleteNotificationUseCase {
  final NotificationRepository repository;
  DeleteNotificationUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteNotification(id);
  }
}

class ClearAllNotificationsUseCase {
  final NotificationRepository repository;
  ClearAllNotificationsUseCase(this.repository);

  Future<void> call() {
    return repository.clearAllNotifications();
  }
}
