import '../entities/expense.dart';

/// Abstract repository interface for expense operations.
/// Defined in domain layer; implemented in data layer.
abstract class ExpenseRepository {
  /// Returns a stream of expenses.
  Stream<List<Expense>> getExpensesStream();
  
  /// Adds a new expense.
  Future<void> addExpense(Expense expense);
  
  /// Deletes an expense.
  Future<void> deleteExpense(String id);

  /// Updates an existing expense.
  Future<void> updateExpense(Expense expense);
}
