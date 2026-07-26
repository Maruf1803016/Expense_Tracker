import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Stream<List<ExpenseModel>> getExpenses();
  Stream<List<ExpenseModel>> getRecycleBinExpenses();
  Future<void> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id); // Soft delete
  Future<void> restoreExpense(String id);
  Future<void> deleteForever(String id);
  Future<void> emptyRecycleBin();
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  ExpenseRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  CollectionReference get _expenseCollection {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId).collection('expenses');
  }

  @override
  Stream<List<ExpenseModel>> getExpenses() {
    return _expenseCollection
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        return ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Sort manually in memory to avoid index requirements
      docs.sort((a, b) => b.date.compareTo(a.date));
      return docs;
    });
  }

  @override
  Stream<List<ExpenseModel>> getRecycleBinExpenses() {
    return _expenseCollection
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        return ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Sort manually in memory
      docs.sort((a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
      return docs;
    });
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _expenseCollection.add(expense.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to add expense: $e');
    }
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _expenseCollection.doc(expense.id).update(expense.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to update expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await _expenseCollection.doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to soft delete expense: $e');
    }
  }

  @override
  Future<void> restoreExpense(String id) async {
    try {
      await _expenseCollection.doc(id).update({
        'isDeleted': false,
        'deletedAt': null,
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to restore expense: $e');
    }
  }

  @override
  Future<void> deleteForever(String id) async {
    try {
      await _expenseCollection.doc(id).delete().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to permanently delete expense: $e');
    }
  }

  @override
  Future<void> emptyRecycleBin() async {
    try {
      final snapshot = await _expenseCollection.where('isDeleted', isEqualTo: true).get();
      final batch = firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to empty recycle bin: $e');
    }
  }
}
