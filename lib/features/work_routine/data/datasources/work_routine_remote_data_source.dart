import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/work_routine/data/models/work_routine_model.dart';

abstract class WorkRoutineRemoteDataSource {
  Stream<List<WorkRoutineModel>> getWorkRoutines();
  Future<void> addWorkRoutine(WorkRoutineModel routine);
  Future<void> updateWorkRoutine(WorkRoutineModel routine);
  Future<void> deleteWorkRoutine(String id);
  Future<void> logAttendance(String routineId, AttendanceEntryModel entry);
  Future<void> deleteAttendance(String routineId, String entryId);
}

class WorkRoutineRemoteDataSourceImpl implements WorkRoutineRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  WorkRoutineRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _routineCollection {
    return _userDoc.collection('workRoutines');
  }

  Future<T> _executeWithRetry<T>(Future<T> Function(Duration timeout) operation) async {
    try {
      return await operation(const Duration(seconds: 8));
    } catch (e1) {
      debugPrint('[WorkRoutineRemoteDataSource] First attempt failed: $e1. Retrying in 1 second...');
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
  Stream<List<WorkRoutineModel>> getWorkRoutines() {
    return _routineCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WorkRoutineModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addWorkRoutine(WorkRoutineModel routine) async {
    try {
      await _executeWithRetry((timeout) {
        return _routineCollection.doc(routine.id).set(routine.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to add work routine: $e');
    }
  }

  @override
  Future<void> updateWorkRoutine(WorkRoutineModel routine) async {
    try {
      await _executeWithRetry((timeout) {
        return _routineCollection.doc(routine.id).update(routine.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to update work routine: $e');
    }
  }

  @override
  Future<void> deleteWorkRoutine(String id) async {
    try {
      await _executeWithRetry((timeout) {
        return _routineCollection.doc(id).delete().timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to delete work routine: $e');
    }
  }

  @override
  Future<void> logAttendance(String routineId, AttendanceEntryModel entry) async {
    try {
      await _executeWithRetry((timeout) async {
        final docRef = _routineCollection.doc(routineId);
        return firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw const ServerException('Work routine not found');
          final data = snapshot.data() as Map<String, dynamic>;
          final entries = (data['entries'] as List<dynamic>? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();

          // Replace existing entry for the same day if exists, else append
          entries.removeWhere((e) {
            final entryDate = (e['date'] as Timestamp).toDate();
            return entryDate.year == entry.date.year &&
                entryDate.month == entry.date.month &&
                entryDate.day == entry.date.day;
          });
          entries.add(entry.toMap());

          transaction.update(docRef, {'entries': entries});
        }).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to log attendance: $e');
    }
  }

  @override
  Future<void> deleteAttendance(String routineId, String entryId) async {
    try {
      await _executeWithRetry((timeout) async {
        final docRef = _routineCollection.doc(routineId);
        return firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw const ServerException('Work routine not found');
          final data = snapshot.data() as Map<String, dynamic>;
          final entries = (data['entries'] as List<dynamic>? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();

          entries.removeWhere((e) => e['id'] == entryId);
          transaction.update(docRef, {'entries': entries});
        }).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to delete attendance: $e');
    }
  }
}
