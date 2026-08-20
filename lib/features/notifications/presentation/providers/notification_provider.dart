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
