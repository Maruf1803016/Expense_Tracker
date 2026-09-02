import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:expense_tracker/features/notifications/domain/entities/app_notification.dart';
import 'package:expense_tracker/features/notifications/domain/repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository repository;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<AppNotification>>? _subscription;

  NotificationProvider({required this.repository});

  void init() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = repository.getNotificationsStream().listen(
      (list) {
        _notifications = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[NotificationProvider] Error loading notifications: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  String get unreadBadge => unreadCount > 9 ? '9+' : '$unreadCount';

  Future<void> add(AppNotification notification) async {
    try {
      await repository.addNotification(notification);
      // Play audible alert sound and trigger haptic pulse
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('[NotificationProvider] Error adding notification: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await repository.markAsRead(id);
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking all as read: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.deleteNotification(id);
    } catch (e) {
      debugPrint('[NotificationProvider] Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> evaluateDebtReminders(dynamic loans) async {
    try {
      final now = DateTime.now();
      for (final loan in loans) {
        if (loan.isCompleted == true) continue;
        if (loan.dueDate == null) continue;

        final DateTime due = loan.dueDate as DateTime;
        final differenceDays = due.difference(DateTime(now.year, now.month, now.day)).inDays;

        if (differenceDays <= 7 && differenceDays >= -30) {
          final isLent = loan.type.toString().contains('lent');
          final String title;
          final String body;

          if (differenceDays < 0) {
            title = isLent ? 'Overdue Collection: ${loan.title}' : 'Overdue Debt: ${loan.title}';
            body = '${loan.counterparty} – \$${loan.remainingAmount.toStringAsFixed(2)} was due on ${due.day}/${due.month}/${due.year}.';
          } else if (differenceDays == 0) {
            title = isLent ? 'Collection Due Today: ${loan.title}' : 'Debt Payment Due Today: ${loan.title}';
            body = '${loan.counterparty} – \$${loan.remainingAmount.toStringAsFixed(2)} is due today.';
          } else if (differenceDays == 1) {
            title = isLent ? 'Collect Tomorrow: ${loan.title}' : 'Debt Payment Due Tomorrow: ${loan.title}';
            body = '${loan.counterparty} – \$${loan.remainingAmount.toStringAsFixed(2)} is due tomorrow.';
          } else {
            title = isLent ? 'Upcoming Collection: ${loan.title}' : 'Debt Due in $differenceDays Days: ${loan.title}';
            body = '${loan.counterparty} – \$${loan.remainingAmount.toStringAsFixed(2)} due on ${due.day}/${due.month}/${due.year}.';
          }

          final notifId = 'debt_remind_${loan.id}_$differenceDays';
          final alreadyExists = _notifications.any((n) => n.id == notifId);
          if (!alreadyExists) {
            await repository.addNotification(
              AppNotification(
                id: notifId,
                title: title,
                body: body,
                date: now,
                type: 'alert',
                isRead: false,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error generating debt reminders: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await repository.clearAllNotifications();
    } catch (e) {
      debugPrint('[NotificationProvider] Error clearing notifications: $e');
      rethrow;
    }
  }

  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
