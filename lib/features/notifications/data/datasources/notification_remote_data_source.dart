import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/notifications/data/models/app_notification_model.dart';

abstract class NotificationRemoteDataSource {
  Stream<List<AppNotificationModel>> getNotifications();
  Future<void> addNotification(AppNotificationModel notification);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> clearAll();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  NotificationRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _notificationCollection {
    return _userDoc.collection('notifications');
  }

  Future<T> _executeWithRetry<T>(Future<T> Function(Duration timeout) operation) async {
    try {
      return await operation(const Duration(seconds: 8));
    } catch (e1) {
      debugPrint('[NotificationRemoteDataSource] First attempt failed: $e1. Retrying in 1 second...');
      await Future.delayed(const Duration(seconds: 1));
      try {
        return await operation(const Duration(seconds: 8));
      } catch (e2) {
        if (e2 is TimeoutException) {
          throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          );
        }
        rethrow;
      }
    }
  }

  @override
  Stream<List<AppNotificationModel>> getNotifications() {
    return _notificationCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addNotification(AppNotificationModel notification) async {
    try {
      await _executeWithRetry((timeout) {
        return _notificationCollection.doc(notification.id).set(notification.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to add notification: $e');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _executeWithRetry((timeout) {
        return _notificationCollection.doc(id).update({'isRead': true}).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _executeWithRetry((timeout) async {
        final unreadDocs = await _notificationCollection
            .where('isRead', isEqualTo: false)
            .get()
            .timeout(timeout);

        final batch = firestore.batch();
        for (var doc in unreadDocs.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit().timeout(timeout);
      });
    } catch (e) {
      throw ServerException('Failed to mark all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _executeWithRetry((timeout) {
        return _notificationCollection.doc(id).delete().timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _executeWithRetry((timeout) async {
        final allDocs = await _notificationCollection.get().timeout(timeout);
        final batch = firestore.batch();
        for (var doc in allDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit().timeout(timeout);
      });
    } catch (e) {
      throw ServerException('Failed to clear notifications: $e');
    }
  }
}
