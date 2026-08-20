import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';

void main() {
  group('Notification Domain & Model Tests', () {
    test('AppNotification entity properties and copyWith', () {
      final notif = AppNotification(
        id: 'n1',
        title: 'Daily Reminder',
        body: 'Remember to record your evening expenses.',
        date: DateTime(2026, 8, 20),
        isRead: false,
        type: 'reminder',
      );

      expect(notif.isRead, false);
      expect(notif.type, 'reminder');

      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, true);
    });

    test('AppNotificationModel round-trips to map and back', () {
      final now = DateTime(2026, 8, 20, 18, 0);
      final notif = AppNotification(
        id: 'n2',
        title: 'Budget Alert',
        body: 'Food & Dining is at 92% of its monthly limit.',
        date: now,
        isRead: false,
        type: 'budget',
      );

      final model = AppNotificationModel.fromEntity(notif);
      final map = model.toMap();

      expect(map['title'], 'Budget Alert');
      expect(map['isRead'], false);
      expect(map['type'], 'budget');

      final fromMap = AppNotificationModel.fromMap(map, 'n2');
      expect(fromMap.id, 'n2');
      expect(fromMap.title, 'Budget Alert');
      expect(fromMap.isRead, false);
    });
  });
}
