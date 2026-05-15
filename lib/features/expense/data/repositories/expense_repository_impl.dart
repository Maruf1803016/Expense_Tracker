import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/core/error/failures.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Expense>> getExpensesStream() {
    return remoteDataSource.getExpenses();
  }

  @override
  Future<void> addExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await remoteDataSource.addExpense(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while adding expense.');
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await remoteDataSource.updateExpense(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while updating expense.');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await remoteDataSource.deleteExpense(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while deleting expense.');
    }
  }
}
