import 'package:expense_tracker/features/plan/domain/entities/goal.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

abstract class GoalRepository {
  Stream<List<Goal>> getPlansStream();
  Future<void> addPlan(Goal plan);
  Future<void> addPlanWithExpenses(Goal plan, List<Expense> expenses);
  Future<void> updatePlan(Goal plan);
  Future<void> deletePlan(String id);
}
