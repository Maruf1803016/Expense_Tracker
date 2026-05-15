import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

enum ExpenseSortType { newest, oldest, highestAmount, lowestAmount }

class ExpenseQueryEngine {
  /// 🔍 The Pure Logic Core
  /// Filters and sorts expenses based on multi-criteria parameters.
  /// This engine has ZERO dependencies on Firebase or UI.
  List<Expense> query(
    List<Expense> expenses, {
    String? query,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    ExpenseSortType sortType = ExpenseSortType.newest,
    required List<Category> allCategories, // Needed for category name matching
  }) {
    // 1. Filtering
    var filtered = expenses.where((e) {
      // Keyword Match (Note or Category Name)
      if (query != null && query.isNotEmpty) {
        final noteMatch = e.note.toLowerCase().contains(query.toLowerCase());
        final category = allCategories.firstWhere((c) => c.id == e.categoryId, 
            orElse: () => const Category(id: '', name: '', type: CategoryType.expense));
        final categoryMatch = category.name.toLowerCase().contains(query.toLowerCase());
        
        if (!noteMatch && !categoryMatch) return false;
      }

      // Category Filter
      if (categoryIds != null && categoryIds.isNotEmpty && !categoryIds.contains(e.categoryId)) {
        return false;
      }

      // Date Range Filter
      if (startDate != null && e.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && e.date.isAfter(endDate)) {
        return false;
      }

      // Amount Range Filter
      if (minAmount != null && e.amount < minAmount) {
        return false;
      }
      if (maxAmount != null && e.amount > maxAmount) {
        return false;
      }

      return true;
    }).toList();

    // 2. Sorting
    switch (sortType) {
      case ExpenseSortType.newest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case ExpenseSortType.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case ExpenseSortType.highestAmount:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSortType.lowestAmount:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }
}
