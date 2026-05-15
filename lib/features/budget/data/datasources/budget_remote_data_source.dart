import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/budget/data/models/budget_model.dart';

abstract class BudgetRemoteDataSource {
  Stream<List<BudgetModel>> getBudgets(int month, int year);
  Future<void> setBudget(BudgetModel budget);
  Stream<double> getGlobalMonthlyBudget();
  Future<void> setGlobalMonthlyBudget(double amount);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  BudgetRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _budgetCollection {
    return _userDoc.collection('budgets');
  }

  @override
  Stream<List<BudgetModel>> getBudgets(int month, int year) {
    return _budgetCollection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BudgetModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  @override
  Future<void> setBudget(BudgetModel budget) async {
    try {
      // Use categoryId as the document ID for budgets (one budget per category/month)
      final docId = '${budget.categoryId}_${budget.month}_${budget.year}';
      await _budgetCollection.doc(docId).set(budget.toMap());
    } catch (e) {
      throw ServerException('Failed to set budget: $e');
    }
  }

  @override
  Stream<double> getGlobalMonthlyBudget() {
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists) return 0.0;
      final data = doc.data() as Map<String, dynamic>;
      return (data['monthlyBudget'] as num?)?.toDouble() ?? 0.0;
    });
  }

  @override
  Future<void> setGlobalMonthlyBudget(double amount) async {
    try {
      await _userDoc.update({'monthlyBudget': amount});
    } catch (e) {
      throw ServerException('Failed to set global budget: $e');
    }
  }
}
