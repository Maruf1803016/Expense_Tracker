import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/recurring_income/data/models/recurring_income_source_model.dart';

abstract class RecurringIncomeRemoteDataSource {
  Stream<List<RecurringIncomeSourceModel>> getRecurringIncomeSources();
  Future<void> addRecurringIncomeSource(RecurringIncomeSourceModel source);
  Future<void> updateRecurringIncomeSource(RecurringIncomeSourceModel source);
  Future<void> deleteRecurringIncomeSource(String id);
}

class RecurringIncomeRemoteDataSourceImpl implements RecurringIncomeRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  RecurringIncomeRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _recurringCollection {
    return _userDoc.collection('recurringIncomeSources');
  }

  @override
  Stream<List<RecurringIncomeSourceModel>> getRecurringIncomeSources() {
    return _recurringCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RecurringIncomeSourceModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  @override
  Future<void> addRecurringIncomeSource(RecurringIncomeSourceModel source) async {
    try {
      await _recurringCollection.doc(source.id).set(source.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to add recurring income source: $e');
    }
  }

  @override
  Future<void> updateRecurringIncomeSource(RecurringIncomeSourceModel source) async {
    try {
      await _recurringCollection.doc(source.id).update(source.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to update recurring income source: $e');
    }
  }

  @override
  Future<void> deleteRecurringIncomeSource(String id) async {
    try {
      await _recurringCollection.doc(id).delete().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to delete recurring income source: $e');
    }
  }
}
