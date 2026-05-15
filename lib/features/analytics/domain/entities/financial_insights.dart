import 'package:equatable/equatable.dart';

/// Entity representing advanced financial analytics and behavior insights.
class FinancialInsights extends Equatable {
  /// Overall financial health score (0-100)
  final int healthScore;

  /// Efficiency of savings: (Income - Expenses) / Income
  final double savingsRatio;

  /// Adherence to set budgets: % of categories within limits
  final double budgetAdherenceScore;

  /// Total categories evaluated for budget adherence
  final int totalBudgetedCategories;

  /// Number of categories currently within their budget limit
  final int successfulBudgets;

  /// Measure of spending stability vs average or previous month
  final double stabilityScore;

  /// Percentage change in spending compared to previous month
  final double trendComparison;

  /// Category name with the highest spending
  final String topSpendingCategory;

  /// Percentage of total spending attributed to the top spending category
  final double topSpendingCategoryPercentage;

  /// Monthly expense totals for the last 6 months (including current)
  final List<double> expenseTrend;

  const FinancialInsights({
    required this.healthScore,
    required this.savingsRatio,
    required this.budgetAdherenceScore,
    required this.totalBudgetedCategories,
    required this.successfulBudgets,
    required this.stabilityScore,
    required this.trendComparison,
    required this.topSpendingCategory,
    required this.topSpendingCategoryPercentage,
    required this.expenseTrend,
  });

  @override
  List<Object?> get props => [
        healthScore,
        savingsRatio,
        budgetAdherenceScore,
        totalBudgetedCategories,
        successfulBudgets,
        stabilityScore,
        trendComparison,
        topSpendingCategory,
        topSpendingCategoryPercentage,
        expenseTrend,
      ];
}
