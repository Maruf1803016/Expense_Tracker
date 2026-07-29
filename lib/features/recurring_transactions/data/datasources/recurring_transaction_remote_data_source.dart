import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_transaction_source_model.dart';

abstract class RecurringTransactionRemoteDataSource {
  Stream<List<RecurringTransactionSourceModel>> getRecurringTransactionSources();
  Future<void> addRecurringTransactionSource(RecurringTransactionSourceModel source);
  Future<void> updateRecurringTransactionSource(RecurringTransactionSourceModel source);
  Future<void> deleteRecurringTransactionSource(String id);
}

class RecurringTransactionRemoteDataSourceImpl implements RecurringTransactionRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  RecurringTransactionRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _recurringCollection {
    // Keep 'recurringIncomeSources' collection name as-is per spec instructions
    return _userDoc.collection('recurringIncomeSources');
  }

  @override
  Stream<List<RecurringTransactionSourceModel>> getRecurringTransactionSources() {
    return _recurringCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RecurringTransactionSourceModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  @override
  Future<void> addRecurringTransactionSource(RecurringTransactionSourceModel source) async {
    try {
      await _recurringCollection.doc(source.id).set(source.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to add recurring source: $e');
    }
  }

  @override
  Future<void> updateRecurringTransactionSource(RecurringTransactionSourceModel source) async {
    try {
      await _recurringCollection.doc(source.id).update(source.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to update recurring source: $e');
    }
  }

  @override
  Future<void> deleteRecurringTransactionSource(String id) async {
    try {
      await _recurringCollection.doc(id).delete().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to delete recurring source: $e');
    }
  }
}
