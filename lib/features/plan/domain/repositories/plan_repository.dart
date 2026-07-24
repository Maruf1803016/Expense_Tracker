import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

abstract class PlanRepository {
  Stream<List<Plan>> getPlansStream();
  Future<void> addPlan(Plan plan);
  Future<void> addPlanWithExpenses(Plan plan, List<Expense> expenses);
  Future<void> updatePlan(Plan plan);
  Future<void> deletePlan(String id);
}
