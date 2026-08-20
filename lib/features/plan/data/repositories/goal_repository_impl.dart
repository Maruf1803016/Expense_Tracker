import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/core/error/failures.dart';
import 'package:expense_tracker/features/plan/data/datasources/goal_remote_data_source.dart';
import 'package:expense_tracker/features/plan/data/models/goal_model.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';
import 'package:expense_tracker/features/plan/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalRemoteDataSource remoteDataSource;

  GoalRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Goal>> getPlansStream() {
    return remoteDataSource.getPlans();
  }

  @override
  Future<void> addPlan(Goal plan) async {
    try {
      await remoteDataSource.addPlan(GoalModel.fromEntity(plan));
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while adding goal.');
    }
  }

  @override
  Future<void> addPlanWithExpenses(Goal plan, List<Expense> expenses) async {
    try {
      final planModel = GoalModel.fromEntity(plan);
      final expenseModels = expenses.map((e) => ExpenseModel.fromEntity(e)).toList();
      await remoteDataSource.addPlanWithExpenses(planModel, expenseModels);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while saving goal and expenses.');
    }
  }

  @override
  Future<void> updatePlan(Goal plan) async {
    try {
      await remoteDataSource.updatePlan(GoalModel.fromEntity(plan));
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while updating goal.');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await remoteDataSource.deletePlan(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while deleting goal.');
    }
  }
}
