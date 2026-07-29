import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_remote_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_transaction_source_model.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class RecurringTransactionRepositoryImpl implements RecurringTransactionRepository {
  final RecurringTransactionRemoteDataSource remoteDataSource;

  RecurringTransactionRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<RecurringTransactionSource>> getRecurringTransactionSourcesStream() {
    return remoteDataSource.getRecurringTransactionSources();
  }

  @override
  Future<void> addRecurringTransactionSource(RecurringTransactionSource source) {
    return remoteDataSource.addRecurringTransactionSource(
      RecurringTransactionSourceModel.fromEntity(source),
    );
  }

  @override
  Future<void> updateRecurringTransactionSource(RecurringTransactionSource source) {
    return remoteDataSource.updateRecurringTransactionSource(
      RecurringTransactionSourceModel.fromEntity(source),
    );
  }

  @override
  Future<void> deleteRecurringTransactionSource(String id) {
    return remoteDataSource.deleteRecurringTransactionSource(id);
  }
}
