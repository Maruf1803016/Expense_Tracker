import '../entities/budget.dart';

/// Abstract repository interface for budget operations.
abstract class BudgetRepository {
  /// Returns a stream of budgets for a specific month and year.
  Stream<List<Budget>> getBudgetsStream(int month, int year);

  /// Sets or updates a budget.
  Future<void> setBudget(Budget budget);
}
