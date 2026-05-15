import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/category/domain/usecases/seed_categories.dart';
import 'package:expense_tracker/features/category/domain/usecases/add_category.dart';
import 'package:expense_tracker/features/category/domain/usecases/delete_category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/expense/domain/entities/monthly_summary.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_monthly_summary.dart';
import 'package:expense_tracker/features/budget/domain/entities/budget.dart';
import 'package:expense_tracker/features/budget/domain/entities/category_budget_status.dart';
import 'package:expense_tracker/features/budget/domain/usecases/get_budget_status.dart';
import 'package:expense_tracker/features/budget/domain/usecases/set_budget.dart';

class ExpenseProvider with ChangeNotifier {
  final GetCategoriesStreamUseCase _getCategoriesStream;
  final SeedCategoriesUseCase _seedCategories;
  final GetExpensesStreamUseCase _getExpensesStream;
  final AddExpenseUseCase _addExpense;
  final UpdateExpenseUseCase _updateExpense;
  final DeleteExpenseUseCase _deleteExpense;
  final GetMonthlySummaryUseCase _getMonthlySummary;
  final AddCategoryUseCase _addCategory;
  final DeleteCategoryUseCase _deleteCategory;
  final SetBudgetUseCase _setBudget;
  final GetBudgetStatusStreamUseCase _getBudgetStatus;

  ExpenseProvider({
    required GetCategoriesStreamUseCase getCategoriesStream,
    required SeedCategoriesUseCase seedCategories,
    required GetExpensesStreamUseCase getExpensesStream,
    required AddExpenseUseCase addExpense,
    required UpdateExpenseUseCase updateExpense,
    required DeleteExpenseUseCase deleteExpense,
    required GetMonthlySummaryUseCase getMonthlySummary,
    required AddCategoryUseCase addCategory,
    required DeleteCategoryUseCase deleteCategory,
    required SetBudgetUseCase setBudget,
    required GetBudgetStatusStreamUseCase getBudgetStatus,
  })  : _getCategoriesStream = getCategoriesStream,
        _seedCategories = seedCategories,
        _getExpensesStream = getExpensesStream,
        _addExpense = addExpense,
        _updateExpense = updateExpense,
        _deleteExpense = deleteExpense,
        _getMonthlySummary = getMonthlySummary,
        _addCategory = addCategory,
        _deleteCategory = deleteCategory,
        _setBudget = setBudget,
        _getBudgetStatus = getBudgetStatus;

  // -- State --
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  MonthlySummary _summary = MonthlySummary.empty();
  MonthlySummary get summary => _summary;

  List<CategoryBudgetStatus> _budgetStatuses = [];
  List<CategoryBudgetStatus> get budgetStatuses => _budgetStatuses;

  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _summarySubscription;
  StreamSubscription? _budgetSubscription;

  // -- Chart Data --

  List<PieChartSectionData> get pieChartSections {
    final totalSpending = _summary.totalExpense;
    if (totalSpending == 0) return [];

    return _summary.categoryBreakdown.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;
      final category = getCategoryById(categoryId);
      if (category == null || category.type != CategoryType.expense) return null;

      final percentage = (amount / totalSpending) * 100;
      
      return PieChartSectionData(
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        color: _getDeterministicColor(categoryId),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white,
        ),
      );
    }).whereType<PieChartSectionData>().toList();
  }

  List<BarChartGroupData> get incomeExpenseBarGroups {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: _summary.totalIncome,
            color: AppTheme.incomeColor,
            width: 25,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: _summary.totalExpense,
            color: AppTheme.expenseColor,
            width: 25,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ),
    ];
  }

  Color _getDeterministicColor(String id) {
    final colors = [
      Colors.blue, Colors.purple, Colors.orange, Colors.teal,
      Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  bool _isInitializing = false;

  Future<void> init() async {
    if (_isInitializing) return;
    _isInitializing = true;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _seedCategories(const NoParams());

      _categoriesSubscription?.cancel();
      _categoriesSubscription = _getCategoriesStream().listen((data) {
        _categories = data;
        _isLoading = false;
        notifyListeners();
      });

      _expensesSubscription?.cancel();
      _expensesSubscription = _getExpensesStream().listen((data) {
        _expenses = data;
        notifyListeners();
      });

      _updateSummarySubscription();
      _updateBudgetSubscription();
    } catch (e) {
      _errorMessage = 'Failed to initialize expenses';
      _isLoading = false;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  void clear() {
    _categoriesSubscription?.cancel();
    _expensesSubscription?.cancel();
    _summarySubscription?.cancel();
    _budgetSubscription?.cancel();
    
    _categories = [];
    _expenses = [];
    _summary = MonthlySummary.empty();
    _budgetStatuses = [];
    _errorMessage = null;
    notifyListeners();
  }

  // -- Actions --

  Future<void> addExpense(Expense expense) async {
    await _addExpense(expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _updateExpense(expense);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _deleteExpense(id);
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _addCategory(category);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _deleteCategory(id);
    notifyListeners();
  }

  Future<void> setBudget(String categoryId, double limit) async {
    final budget = Budget(
      categoryId: categoryId,
      monthlyLimit: limit,
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );
    await _setBudget(budget);
    notifyListeners();
  }

  // -- Subscriptions --

  void _updateSummarySubscription() {
    _summarySubscription?.cancel();
    _summarySubscription = _getMonthlySummary(_selectedMonth.month, _selectedMonth.year).listen((data) {
      _summary = data;
      notifyListeners();
    });
  }

  void _updateBudgetSubscription() {
    _budgetSubscription?.cancel();
    _budgetSubscription = _getBudgetStatus(_selectedMonth.month, _selectedMonth.year).listen((data) {
      _budgetStatuses = data;
      notifyListeners();
    });
  }

  void changeMonth(DateTime month) {
    _selectedMonth = month;
    _updateSummarySubscription();
    _updateBudgetSubscription();
    notifyListeners();
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => Category(
          id: id,
          name: 'Deleted Category',
          type: CategoryType.expense,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _expensesSubscription?.cancel();
    _summarySubscription?.cancel();
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
