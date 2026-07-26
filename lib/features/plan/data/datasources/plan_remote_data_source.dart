import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/plan/data/models/plan_model.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';

abstract class PlanRemoteDataSource {
  Stream<List<PlanModel>> getPlans();
  Future<void> addPlan(PlanModel plan);
  Future<void> addPlanWithExpenses(PlanModel plan, List<ExpenseModel> expenses);
  Future<void> updatePlan(PlanModel plan);
  Future<void> deletePlan(String id);
}

class PlanRemoteDataSourceImpl implements PlanRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  PlanRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _planCollection {
    return _userDoc.collection('plans');
  }

  @override
  Stream<List<PlanModel>> getPlans() {
    return _planCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PlanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addPlan(PlanModel plan) async {
    try {
      await _planCollection.doc(plan.id).set(plan.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to add plan: $e');
    }
  }

  @override
  Future<void> addPlanWithExpenses(PlanModel plan, List<ExpenseModel> expenses) async {
    try {
      final batch = firestore.batch();
      final userDoc = _userDoc;
      final planRef = userDoc.collection('plans').doc(plan.id);
      batch.set(planRef, plan.toMap());
      
      final expenseCollection = userDoc.collection('expenses');
      for (var exp in expenses) {
        batch.set(expenseCollection.doc(exp.id), exp.toMap());
      }
      
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to save plan and expenses in batch: $e');
    }
  }

  @override
  Future<void> updatePlan(PlanModel plan) async {
    try {
      await _planCollection.doc(plan.id).update(plan.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to update plan: $e');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _planCollection.doc(id).delete().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to delete plan: $e');
    }
  }
}
