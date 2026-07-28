import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/core/error/failures.dart';
import 'package:expense_tracker/features/budget/domain/entities/budget.dart';
import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budget/data/datasources/budget_remote_data_source.dart';
import 'package:expense_tracker/features/budget/data/models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource remoteDataSource;

  BudgetRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Budget>> getBudgetsStream(int month, int year) {
    return remoteDataSource.getBudgets(month, year);
  }

  @override
  Future<void> setBudget(Budget budget) async {
    try {
      final model = BudgetModel.fromEntity(budget);
      await remoteDataSource.setBudget(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while setting budget.');
    }
  }
}
