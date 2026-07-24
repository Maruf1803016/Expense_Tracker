import 'package:expense_tracker/features/plan/domain/entities/plan.dart';

abstract class PlanRepository {
  Stream<List<Plan>> getPlansStream();
  Future<void> addPlan(Plan plan);
  Future<void> updatePlan(Plan plan);
  Future<void> deletePlan(String id);
}
