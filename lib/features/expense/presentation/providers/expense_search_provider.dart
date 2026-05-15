import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/usecases/search_expenses.dart';
import 'package:expense_tracker/features/expense/domain/logic/expense_query_engine.dart';

class ExpenseSearchProvider with ChangeNotifier {
  final SearchExpensesUseCase _searchExpenses;

  ExpenseSearchProvider({
    required SearchExpensesUseCase searchExpenses,
  }) : _searchExpenses = searchExpenses;

  // -- Search State --
  String _query = '';
  List<String> _selectedCategoryIds = [];
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  ExpenseSortType _sortType = ExpenseSortType.newest;

  List<Expense> _results = [];
  List<Expense> get results => _results;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Timer? _debounce;

  // -- Getters --
  String get query => _query;
  List<String> get selectedCategoryIds => _selectedCategoryIds;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  ExpenseSortType get sortType => _sortType;

  // -- Actions --

  void updateQuery(String value, List<Expense> allExpenses, List<Category> allCategories) {
    _query = value;
    _debounceSearch(allExpenses, allCategories);
  }

  void updateFilters({
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    ExpenseSortType? sortType,
    required List<Expense> allExpenses,
    required List<Category> allCategories,
  }) {
    if (categoryIds != null) _selectedCategoryIds = categoryIds;
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;
    if (minAmount != null) _minAmount = minAmount;
    if (maxAmount != null) _maxAmount = maxAmount;
    if (sortType != null) _sortType = sortType;

    _performSearch(allExpenses, allCategories);
  }

  void clearFilters(List<Expense> allExpenses, List<Category> allCategories) {
    _query = '';
    _selectedCategoryIds = [];
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _sortType = ExpenseSortType.newest;
    _performSearch(allExpenses, allCategories);
  }

  void _debounceSearch(List<Expense> allExpenses, List<Category> allCategories) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(allExpenses, allCategories);
    });
  }

  void _performSearch(List<Expense> allExpenses, List<Category> allCategories) {
    _isLoading = true;
    notifyListeners();

    final params = SearchExpensesParams(
      expenses: allExpenses,
      allCategories: allCategories,
      query: _query,
      categoryIds: _selectedCategoryIds,
      startDate: _startDate,
      endDate: _endDate,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      sortType: _sortType,
    );

    _results = _searchExpenses(params);
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _selectedCategoryIds = [];
    _startDate = null;
    _endDate = null;
    _minAmount = null;
    _maxAmount = null;
    _sortType = ExpenseSortType.newest;
    _results = [];
    _isLoading = false;
    _debounce?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
