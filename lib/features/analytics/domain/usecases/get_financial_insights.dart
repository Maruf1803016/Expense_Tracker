import 'package:rxdart/rxdart.dart';
import 'package:expense_tracker/features/budget/domain/usecases/get_budget_status.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_monthly_summary.dart';
import 'package:expense_tracker/features/analytics/domain/entities/financial_insights.dart';
import 'package:expense_tracker/features/analysis/domain/logic/financial_analysis_service.dart';
import 'package:expense_tracker/features/shared/domain/policies/insights_policy.dart';

class GetFinancialInsightsUseCase {
  final GetMonthlySummaryUseCase getSummary;
  final GetBudgetStatusStreamUseCase getBudgetStatus;
  final FinancialAnalysisService analysisService;

  GetFinancialInsightsUseCase({
    required this.getSummary,
    required this.getBudgetStatus,
    required this.analysisService,
  });

  Stream<FinancialInsights> call(int month, int year) {
    final prevDate = DateTime(year, month - 1);

    return Rx.combineLatest3(
      getSummary(month, year),
      getSummary(prevDate.month, prevDate.year),
      getBudgetStatus(month, year),
      (current, prev, budgets) {
        // Apply Insights Policy weights to orchestrated data
        final totalBudgeted = budgets.length;
        final successful = budgets.where((b) => !b.isExceeded).length;
        
        final adherenceScore = analysisService.getAdherenceScore(successful, totalBudgeted);
        final adherencePoints = adherenceScore * InsightsPolicy.budgetWeight * 100;

        final income = current.totalIncome;
        final expense = current.totalExpense;
        final savingsRatio = income > 0 ? (income - expense) / income : 0.0;
        final savingsPoints = (savingsRatio >= 0.2 ? 1.0 : (savingsRatio / 0.2).clamp(0.0, 1.0)) * InsightsPolicy.savingsWeight * 100;

        final stabilityPoints = analysisService.trendCalculator.calculatePercentageChange(current.totalExpense, prev.totalExpense).abs() < 50 ? InsightsPolicy.stabilityWeight * 100 : 0.0;

        final healthScore = (adherencePoints + savingsPoints + stabilityPoints).round();

        return FinancialInsights(
          healthScore: healthScore.clamp(0, 100),
          savingsRatio: savingsRatio,
          budgetAdherenceScore: adherenceScore,
          totalBudgetedCategories: totalBudgeted,
          successfulBudgets: successful,
          stabilityScore: stabilityPoints / (InsightsPolicy.stabilityWeight * 100),
          trendComparison: analysisService.trendCalculator.calculatePercentageChange(current.totalExpense, prev.totalExpense),
          topSpendingCategory: budgets.isNotEmpty ? budgets.reduce((a, b) => a.spent > b.spent ? a : b).categoryName : 'None',
          topSpendingCategoryPercentage: (current.totalExpense > 0 && budgets.isNotEmpty) ? (budgets.reduce((a, b) => a.spent > b.spent ? a : b).spent / current.totalExpense) : 0.0,
        );
      },
    );
  }
}
