import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/core/error/failures.dart';
import 'package:expense_tracker/features/plan/data/datasources/plan_remote_data_source.dart';
import 'package:expense_tracker/features/plan/data/models/plan_model.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/plan/domain/repositories/plan_repository.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';

class PlanRepositoryImpl implements PlanRepository {
  final PlanRemoteDataSource remoteDataSource;

  PlanRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Plan>> getPlansStream() {
    return remoteDataSource.getPlans();
  }

  @override
  Future<void> addPlan(Plan plan) async {
    try {
      await remoteDataSource.addPlan(PlanModel.fromEntity(plan));
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while adding plan.');
    }
  }

  @override
  Future<void> addPlanWithExpenses(Plan plan, List<Expense> expenses) async {
    try {
      final planModel = PlanModel.fromEntity(plan);
      final expenseModels = expenses.map((e) => ExpenseModel.fromEntity(e)).toList();
      await remoteDataSource.addPlanWithExpenses(planModel, expenseModels);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while saving plan and expenses.');
    }
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    try {
      await remoteDataSource.updatePlan(PlanModel.fromEntity(plan));
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while updating plan.');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await remoteDataSource.deletePlan(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while deleting plan.');
    }
  }
}
