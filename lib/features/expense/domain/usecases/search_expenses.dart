import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/logic/expense_query_engine.dart';

class SearchExpensesParams {
  final List<Expense> expenses;
  final List<Category> allCategories;
  final String? query;
  final List<String>? categoryIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final ExpenseSortType sortType;

  const SearchExpensesParams({
    required this.expenses,
    required this.allCategories,
    this.query,
    this.categoryIds,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortType = ExpenseSortType.newest,
  });
}

class SearchExpensesUseCase {
  final ExpenseQueryEngine queryEngine;

  SearchExpensesUseCase({required this.queryEngine});

  /// 🧩 Orchestration Layer
  /// Delegates all logic to the specialized query engine.
  List<Expense> call(SearchExpensesParams params) {
    return queryEngine.query(
      params.expenses,
      allCategories: params.allCategories,
      query: params.query,
      categoryIds: params.categoryIds,
      startDate: params.startDate,
      endDate: params.endDate,
      minAmount: params.minAmount,
      maxAmount: params.maxAmount,
      sortType: params.sortType,
    );
  }
}
