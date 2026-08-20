import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/plan/data/models/goal_model.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';

abstract class GoalRemoteDataSource {
  Stream<List<GoalModel>> getPlans();
  Future<void> addPlan(GoalModel plan);
  Future<void> addPlanWithExpenses(GoalModel plan, List<ExpenseModel> expenses);
  Future<void> updatePlan(GoalModel plan);
  Future<void> deletePlan(String id);
}

class GoalRemoteDataSourceImpl implements GoalRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  GoalRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _planCollection {
    return _userDoc.collection('plans'); // stays 'plans' in Firestore
  }

  Future<T> _executeWithRetry<T>(Future<T> Function(Duration timeout) operation) async {
    try {
      return await operation(const Duration(seconds: 8));
    } catch (e1) {
      debugPrint('[GoalRemoteDataSource] First attempt failed: $e1. Retrying in 1 second...');
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
  Stream<List<GoalModel>> getPlans() {
    return _planCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addPlan(GoalModel plan) async {
    try {
      await _executeWithRetry((timeout) {
        return _planCollection.doc(plan.id).set(plan.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to add goal: $e');
    }
  }

  @override
  Future<void> addPlanWithExpenses(GoalModel plan, List<ExpenseModel> expenses) async {
    try {
      final batch = firestore.batch();
      final userDoc = _userDoc;
      final planRef = userDoc.collection('plans').doc(plan.id);
      batch.set(planRef, plan.toMap());
      
      final expenseCollection = userDoc.collection('expenses');
      for (var exp in expenses) {
        batch.set(expenseCollection.doc(exp.id), exp.toMap());
      }
      
      await _executeWithRetry((timeout) {
        return batch.commit().timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to save goal and expenses in batch: $e');
    }
  }

  @override
  Future<void> updatePlan(GoalModel plan) async {
    try {
      await _executeWithRetry((timeout) {
        return _planCollection.doc(plan.id).update(plan.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to update goal: $e');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _executeWithRetry((timeout) {
        return _planCollection.doc(id).delete().timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to delete goal: $e');
    }
  }
}
