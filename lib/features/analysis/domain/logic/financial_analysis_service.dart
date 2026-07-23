import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'expense_aggregator.dart';
import 'trend_calculator.dart';
import 'budget_calculator.dart';
import 'anomaly_detector.dart';

class FinancialAnalysisService {
  final ExpenseAggregator aggregator;
  final TrendCalculator trendCalculator;
  final BudgetCalculator budgetCalculator;
  final AnomalyDetector anomalyDetector;

  FinancialAnalysisService({
    required this.aggregator,
    required this.trendCalculator,
    required this.budgetCalculator,
    required this.anomalyDetector,
  });

  // ⚡ Performance Optimization: Monthly Summary Cache
  // Stores { 'month_year_dataHash': snapshot }
  final Map<String, Map<String, dynamic>> _snapshotCache = {};

  /// Orchestrates aggregation for a monthly summary snapshot.
  Map<String, dynamic> generateMonthlySnapshot(
    List<Expense> expenses,
    List<Category> categories,
    int month,
    int year,
  ) {
    // Determine a cache key based on params and data signature to detect any change
    final dataSignature = expenses.fold<double>(0.0, (sum, e) => sum + e.amount + e.date.millisecondsSinceEpoch);
    final cacheKey = '${month}_${year}_${expenses.length}_$dataSignature';
    
    if (_snapshotCache.containsKey(cacheKey)) {
      return _snapshotCache[cacheKey]!;
    }

    final filtered = aggregator.filterByMonth(expenses, month, year);
    final categoryTypeMap = {for (var c in categories) c.id: c.type};
    final (income, expense) = aggregator.calculateTotals(filtered, categoryTypeMap);
    final breakdown = aggregator.groupSpentByCategory(filtered);

    final snapshot = {
      'income': income,
      'expense': expense,
      'balance': income - expense,
      'breakdown': breakdown,
    };

    // Cache the result and limit cache size to prevent memory bloat
    if (_snapshotCache.length > 12) _snapshotCache.clear(); // Keep ~1 year of history
    _snapshotCache[cacheKey] = snapshot;

    return snapshot;
  }

  /// Calculates adherence metrics across all budgets.
  double getAdherenceScore(int successfulCount, int totalCount) {
    return budgetCalculator.calculateAdherenceRatio(successfulCount, totalCount);
  }

  /// 🔐 System Hardening: Clear cache on demand (e.g., logout)
  void clearCache() {
    _snapshotCache.clear();
  }
}
