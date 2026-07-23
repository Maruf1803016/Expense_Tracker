import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/category/domain/usecases/seed_categories.dart';
import 'package:expense_tracker/features/category/domain/usecases/add_category.dart';
import 'package:expense_tracker/features/category/domain/usecases/delete_category.dart';
import 'package:expense_tracker/features/category/domain/usecases/update_category.dart';
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
import 'package:expense_tracker/features/budget/domain/usecases/get_global_budget.dart';
import 'package:expense_tracker/features/budget/domain/usecases/set_global_budget.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_recycle_bin_expenses.dart';
import 'package:expense_tracker/features/expense/domain/usecases/restore_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/delete_forever.dart';
import 'package:expense_tracker/features/expense/domain/usecases/empty_recycle_bin.dart';

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
  final UpdateCategoryUseCase _updateCategory;
  final SetBudgetUseCase _setBudget;
  final GetBudgetStatusStreamUseCase _getBudgetStatus;
  
  final GetGlobalBudgetUseCase _getGlobalBudget;
  final SetGlobalBudgetUseCase _setGlobalBudget;

  final GetRecycleBinExpensesStreamUseCase _getRecycleBinExpensesStream;
  final RestoreExpenseUseCase _restoreExpense;
  final DeleteForeverUseCase _deleteForever;
  final EmptyRecycleBinUseCase _emptyRecycleBin;

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
    required UpdateCategoryUseCase updateCategory,
    required SetBudgetUseCase setBudget,
    required GetBudgetStatusStreamUseCase getBudgetStatus,
    required GetGlobalBudgetUseCase getGlobalBudget,
    required SetGlobalBudgetUseCase setGlobalBudget,
    required GetRecycleBinExpensesStreamUseCase getRecycleBinExpensesStream,
    required RestoreExpenseUseCase restoreExpense,
    required DeleteForeverUseCase deleteForever,
    required EmptyRecycleBinUseCase emptyRecycleBin,
  })  : _getCategoriesStream = getCategoriesStream,
        _seedCategories = seedCategories,
        _getExpensesStream = getExpensesStream,
        _addExpense = addExpense,
        _updateExpense = updateExpense,
        _deleteExpense = deleteExpense,
        _getMonthlySummary = getMonthlySummary,
        _addCategory = addCategory,
        _deleteCategory = deleteCategory,
        _updateCategory = updateCategory,
        _setBudget = setBudget,
        _getBudgetStatus = getBudgetStatus,
        _getGlobalBudget = getGlobalBudget,
        _setGlobalBudget = setGlobalBudget,
        _getRecycleBinExpensesStream = getRecycleBinExpensesStream,
        _restoreExpense = restoreExpense,
        _deleteForever = deleteForever,
        _emptyRecycleBin = emptyRecycleBin;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  List<Expense> _recycleBinExpenses = [];
  List<Expense> get recycleBinExpenses => _recycleBinExpenses;

  MonthlySummary _summary = MonthlySummary.empty();
  MonthlySummary get summary => _summary;

  List<CategoryBudgetStatus> _budgetStatuses = [];
  List<CategoryBudgetStatus> get rolledUpBudgetStatuses {
    final Map<String, CategoryBudgetStatus> rolledUp = {};
    
    for (var status in _budgetStatuses) {
      final category = getCategoryById(status.categoryId);
      final parentId = category.parentId ?? category.id;
      final parentCategory = getCategoryById(parentId);
      
      if (rolledUp.containsKey(parentId)) {
        final existing = rolledUp[parentId]!;
        rolledUp[parentId] = CategoryBudgetStatus.fromAmounts(
          categoryId: parentId,
          categoryName: parentCategory.name,
          limit: existing.limit + status.limit,
          spent: existing.spent + status.spent,
          month: status.month,
          year: status.year,
        );
      } else {
        rolledUp[parentId] = CategoryBudgetStatus.fromAmounts(
          categoryId: parentId,
          categoryName: parentCategory.name,
          limit: status.limit,
          spent: status.spent,
          month: status.month,
          year: status.year,
        );
      }
    }
    
    return rolledUp.values.toList();
  }

  double _monthlyBudget = 0.0;
  double get monthlyBudget => _monthlyBudget;

  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _recycleBinSubscription;
  StreamSubscription? _summarySubscription;
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _globalBudgetSubscription;

  static const List<Color> pieColors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D),
    Color(0xFF6C5CE7), Color(0xFFA8E6CF), Color(0xFFFF8B94),
    Color(0xFF45B7D1), Color(0xFFFFA07A), Color(0xFFE17055),
    Color(0xFF74B9FF), Color(0xFFFDCB6E), Color(0xFFE84393),
    Color(0xFF00CEC9), Color(0xFFD63031), Color(0xFFA29BFE),
  ];

  List<PieChartSectionData> get pieChartSections {
    final totalSpending = _summary.totalExpense;
    if (totalSpending == 0) return [];

    // 1. Roll up sub-categories into parents
    final Map<String, double> rolledUpBreakdown = {};
    for (var entry in _summary.categoryBreakdown.entries) {
      final category = getCategoryById(entry.key);
      if (category.type != CategoryType.expense) continue;
      
      // Strict Parent Grouping: Use parentId if it exists, otherwise use category id
      final parentId = category.parentId ?? category.id;
      rolledUpBreakdown[parentId] = (rolledUpBreakdown[parentId] ?? 0.0) + entry.value;
    }

    // 2. Sort High to Low
    final sortedEntries = rolledUpBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 3. Map to PieChartSectionData with unique colors from the list
    return sortedEntries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final categoryId = entry.key;
      final amount = entry.value;
      
      // Get parent category name
      final categoryName = getCategoryById(categoryId).name;
      final percentage = (amount / totalSpending) * 100;
      
      return PieChartSectionData(
        value: amount,
        title: '$categoryName\n${percentage.toStringAsFixed(0)}%',
        color: pieColors[index % pieColors.length],
        radius: 60,
        showTitle: true,
        titleStyle: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> get categoryBarGroups {
    final entries = _summary.categoryBreakdown.entries.toList();
    if (entries.isEmpty) return [];

    // Group by type and sort high to low
    final incomeEntries = entries
        .where((e) => getCategoryById(e.key).type == CategoryType.income)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final expenseEntries = entries
        .where((e) => getCategoryById(e.key).type == CategoryType.expense)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final allSorted = [...incomeEntries, ...expenseEntries];

    return List.generate(allSorted.length, (index) {
      final entry = allSorted[index];
      final category = getCategoryById(entry.key);
      final isIncome = category.type == CategoryType.income;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Map<String, double> get rolledUpCategoryBreakdown {
    final Map<String, double> rolledUp = {};
    for (var entry in _summary.categoryBreakdown.entries) {
      final category = getCategoryById(entry.key);
      final parentId = category.parentId ?? category.id;
      rolledUp[parentId] = (rolledUp[parentId] ?? 0.0) + entry.value;
    }
    
    final incomeEntries = rolledUp.entries
        .where((e) => getCategoryById(e.key).type == CategoryType.income)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final expenseEntries = rolledUp.entries
        .where((e) => getCategoryById(e.key).type == CategoryType.expense)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return Map.fromEntries([...incomeEntries, ...expenseEntries]);
  }

  String getCategoryNameAt(int index) {
    final entries = rolledUpCategoryBreakdown.entries.toList();
    if (index >= 0 && index < entries.length) {
      return getCategoryById(entries[index].key).name;
    }
    return '';
  }

  double get healthScore {
    // Budget efficiency calculation for summary page if needed, but this is the health score logic
    // We will implement the specific logic in Fix 6
    return _calculateHealthScore();
  }

  double _calculateHealthScore() {
    if (_summary.totalIncome == 0 || monthlyBudget == 0) return 0;
    
    // savingsRate = (totalIncome - totalExpenses) / totalIncome   → worth 40 points
    double savingsRate = (_summary.totalIncome - _summary.totalExpense) / _summary.totalIncome;
    double savingsPoints = (savingsRate.clamp(0.0, 1.0) * 40);

    // budgetAdherence = 1 - (totalExpenses / budget)              → worth 30 points
    double budgetAdherence = 1 - (_summary.totalExpense / monthlyBudget);
    double budgetPoints = (budgetAdherence.clamp(0.0, 1.0) * 30);

    // consistencyScore = based on number of days with recorded expenses → worth 30 points
    // Simplified: check unique days in the month with expenses
    final uniqueDays = _expenses.where((e) => e.date.month == _selectedMonth.month && e.date.year == _selectedMonth.year)
                                .map((e) => e.date.day).toSet().length;
    double consistencyPoints = (uniqueDays / 15).clamp(0.0, 1.0) * 30; // 15 days for max points

    return savingsPoints + budgetPoints + consistencyPoints;
  }

  String get healthStatus {
    final score = healthScore;
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Work';
  }

  Color _getDeterministicColor(String id) {
    // No longer used for pie chart but kept for compatibility
    return pieColors[id.hashCode.abs() % pieColors.length];
  }

  bool _isInitializing = false;

  Future<void> init({bool force = false}) async {
    if (_isInitializing) return;
    if (!force && _isInitialized) return;
    
    _isInitializing = true;

    // Only show loading if we have no data at all
    if (_categories.isEmpty && _expenses.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    debugPrint('🚀 ExpenseProvider: Starting initialization (force: $force)...');

    try {
      _categoriesSubscription?.cancel();
      _categoriesSubscription = _getCategoriesStream().listen(
        (data) {
          _isInitialized = true;
          if (const ListEquality().equals(_categories, data)) return;
          _categories = List<Category>.from(data);
          _isLoading = false; 
          notifyListeners();
        },
        onError: (e) {
          _isLoading = false;
          _isInitialized = true;
          notifyListeners();
        }
      );

      _expensesSubscription?.cancel();
      _expensesSubscription = _getExpensesStream().listen(
        (data) {
          _isInitialized = true;
          if (const ListEquality().equals(_expenses, data)) return;
          _expenses = List<Expense>.from(data);
          _isLoading = false; 
          notifyListeners();
        },
        onError: (e) {
          _isLoading = false;
          _isInitialized = true;
          notifyListeners();
        }
      );

      _recycleBinSubscription?.cancel();
      _recycleBinSubscription = _getRecycleBinExpensesStream().listen((data) {
        if (const ListEquality().equals(_recycleBinExpenses, data)) return;
        _recycleBinExpenses = List<Expense>.from(data);
        notifyListeners();
      });

      // Safety timeout: resolve loading state faster
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_isLoading) {
          _isLoading = false;
          _isInitialized = true;
          notifyListeners();
        }
      });

      _updateSummarySubscription();
      _updateBudgetSubscription();

      _globalBudgetSubscription?.cancel();
      _globalBudgetSubscription = _getGlobalBudget().listen((data) {
        if (_monthlyBudget == data) return;
        _monthlyBudget = data;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  void clear() {
    _categoriesSubscription?.cancel();
    _expensesSubscription?.cancel();
    _recycleBinSubscription?.cancel();
    _summarySubscription?.cancel();
    _budgetSubscription?.cancel();
    _globalBudgetSubscription?.cancel();
    
    _categories = [];
    _expenses = [];
    _recycleBinExpenses = [];
    _monthlyBudget = 0.0;
    _summary = MonthlySummary.empty();
    _budgetStatuses = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _addExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await _updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _deleteExpense(id);
  }

  Future<void> restoreExpense(String id) async {
    await _restoreExpense(id);
  }

  Future<void> deleteForever(String id) async {
    await _deleteForever(id);
  }

  Future<void> emptyRecycleBin() async {
    await _emptyRecycleBin();
  }

  Future<void> addCategory(Category category) async {
    await _addCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _deleteCategory(id);
  }

  Future<void> updateCategory(Category category) async {
    await _updateCategory(category);
  }

  Future<void> setBudget(String categoryId, double limit) async {
    final budget = Budget(
      categoryId: categoryId,
      monthlyLimit: limit,
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );
    await _setBudget(budget);
  }

  Future<void> setGlobalBudget(double amount) async {
    await _setGlobalBudget(amount);
  }

  void _updateSummarySubscription() {
    _summarySubscription?.cancel();
    _summarySubscription = _getMonthlySummary(_selectedMonth.month, _selectedMonth.year).listen((data) {
      if (_summary == data) return;
      _summary = data;
      notifyListeners();
    });
  }

  void _updateBudgetSubscription() {
    _budgetSubscription?.cancel();
    _budgetSubscription = _getBudgetStatus(_selectedMonth.month, _selectedMonth.year).listen((data) {
      if (const ListEquality().equals(_budgetStatuses, data)) return;
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

  Category getCategoryById(String id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => Category(
        id: id,
        name: 'Uncategorized',
        type: CategoryType.expense,
        icon: 'category',
      ),
    );
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _expensesSubscription?.cancel();
    _recycleBinSubscription?.cancel();
    _summarySubscription?.cancel();
    _budgetSubscription?.cancel();
    _globalBudgetSubscription?.cancel();
    super.dispose();
  }
}
