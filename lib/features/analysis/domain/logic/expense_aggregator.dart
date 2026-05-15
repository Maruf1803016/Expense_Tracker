import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

class ExpenseAggregator {
  /// 📊 Clean Responsibility: ONLY Grouping and Totals.
  /// No filtering, searching, or sorting happens here.
  
  /// Filters based on month/year is also a query concern, but often kept simple 
  /// for foundational summaries. We will keep it minimal here.
  List<Expense> filterByMonth(List<Expense> expenses, int month, int year) {
    return expenses.where((e) => e.date.month == month && e.date.year == year).toList();
  }

  /// Groups expenses by category and sums their amounts.
  Map<String, double> groupSpentByCategory(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (var expense in expenses) {
      totals[expense.categoryId] = (totals[expense.categoryId] ?? 0.0) + expense.amount;
    }
    return totals;
  }

  /// Calculates total income and total expense for a list of expenses.
  (double income, double expense) calculateTotals(
    List<Expense> expenses,
    Map<String, CategoryType> categoryMap,
  ) {
    double income = 0.0;
    double expense = 0.0;
    for (var e in expenses) {
      final type = categoryMap[e.categoryId] ?? CategoryType.expense;
      if (type == CategoryType.income) {
        income += e.amount;
      } else {
        expense += e.amount;
      }
    }
    return (income, expense);
  }
}
