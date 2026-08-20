import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.date,
    super.isRead,
    super.type,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AppNotificationModel(
      id: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'reminder',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': Timestamp.fromDate(date),
      'isRead': isRead,
      'type': type,
    };
  }

  factory AppNotificationModel.fromEntity(AppNotification entity) {
    return AppNotificationModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      date: entity.date,
      isRead: entity.isRead,
      type: entity.type,
    );
  }
}
