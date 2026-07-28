import 'package:expense_tracker/features/recurring_income/data/datasources/recurring_income_remote_data_source.dart';
import 'package:expense_tracker/features/recurring_income/data/models/recurring_income_source_model.dart';
import 'package:expense_tracker/features/recurring_income/domain/entities/recurring_income_source.dart';
import 'package:expense_tracker/features/recurring_income/domain/repositories/recurring_income_repository.dart';

class RecurringIncomeRepositoryImpl implements RecurringIncomeRepository {
  final RecurringIncomeRemoteDataSource remoteDataSource;

  RecurringIncomeRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<RecurringIncomeSource>> getRecurringIncomeSourcesStream() {
    return remoteDataSource.getRecurringIncomeSources();
  }

  @override
  Future<void> addRecurringIncomeSource(RecurringIncomeSource source) {
    return remoteDataSource.addRecurringIncomeSource(
      RecurringIncomeSourceModel.fromEntity(source),
    );
  }

  @override
  Future<void> updateRecurringIncomeSource(RecurringIncomeSource source) {
    return remoteDataSource.updateRecurringIncomeSource(
      RecurringIncomeSourceModel.fromEntity(source),
    );
  }

  @override
  Future<void> deleteRecurringIncomeSource(String id) {
    return remoteDataSource.deleteRecurringIncomeSource(id);
  }
}
