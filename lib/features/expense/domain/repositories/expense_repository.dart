import '../entities/expense.dart';

/// Abstract repository interface for expense operations.
/// Defined in domain layer; implemented in data layer.
abstract class ExpenseRepository {
  /// Returns a stream of active expenses.
  Stream<List<Expense>> getExpensesStream();

  /// Returns a stream of soft-deleted expenses in the recycle bin.
  Stream<List<Expense>> getRecycleBinExpensesStream();
  
  /// Adds a new expense.
  Future<void> addExpense(Expense expense);
  
  /// Soft deletes an expense.
  Future<void> deleteExpense(String id);

  /// Restores a soft-deleted expense.
  Future<void> restoreExpense(String id);

  /// Permanently deletes an expense.
  Future<void> deleteForever(String id);

  /// Permanently deletes all soft-deleted expenses.
  Future<void> emptyRecycleBin();

  /// Updates an existing expense.
  Future<void> updateExpense(Expense expense);
}
