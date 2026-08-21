import 'dart:async';
import 'package:flutter/material.dart';
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
        if (list.length < 10) {
          final samples = [
            AppNotification(
              id: 'notif_1',
              title: 'Budget Alert: Food & Dining',
              body: 'You have reached 85% of your monthly dining allocation.',
              date: DateTime.now().subtract(const Duration(minutes: 15)),
              type: 'budget',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_2',
              title: 'Recurring Rent Due Tomorrow',
              body: 'Monthly Apartment Rent (\$1,850.00) is scheduled for clearance tomorrow.',
              date: DateTime.now().subtract(const Duration(hours: 1)),
              type: 'reminder',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_3',
              title: 'Salary Deposit Confirmed',
              body: 'Monthly Salary of \$4,500.00 has cleared into Checking Account.',
              date: DateTime.now().subtract(const Duration(hours: 3)),
              type: 'alert',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_4',
              title: 'Goal Milestone Reached',
              body: 'You have funded 50% of your Wedding Savings Goal.',
              date: DateTime.now().subtract(const Duration(hours: 6)),
              type: 'budget',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_5',
              title: 'Trip Budget Reminder: Cox’s Bazar',
              body: '3 expenses logged toward your retreat budget.',
              date: DateTime.now().subtract(const Duration(hours: 12)),
              type: 'reminder',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_6',
              title: 'Debt Payment Due in 3 Days',
              body: 'Equipment Loan monthly installment (\$500.00) is due soon.',
              date: DateTime.now().subtract(const Duration(hours: 18)),
              type: 'alert',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_7',
              title: 'Weekly Financial Field Note',
              body: 'Your savings rate was 83% this week. Strong discipline!',
              date: DateTime.now().subtract(const Duration(days: 1)),
              type: 'budget',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_8',
              title: 'Work Routine Schedule',
              body: 'Clinical Shift logged for 5 days (33.5 hrs) this month.',
              date: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
              type: 'reminder',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_9',
              title: 'Subscription Renewal Alert',
              body: 'Cloud Storage subscription (\$9.99) will renew next week.',
              date: DateTime.now().subtract(const Duration(days: 2)),
              type: 'reminder',
              isRead: false,
            ),
            AppNotification(
              id: 'notif_10',
              title: 'Monthly Ledger Summary Ready',
              body: 'Your July report is prepared for export to PDF / CSV.',
              date: DateTime.now().subtract(const Duration(days: 3)),
              type: 'alert',
              isRead: false,
            ),
          ];
          for (final s in samples) {
            repository.addNotification(s);
          }
        }
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
