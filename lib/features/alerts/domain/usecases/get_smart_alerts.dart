import 'package:rxdart/rxdart.dart';
import 'package:expense_tracker/features/budget/domain/usecases/get_budget_status.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_monthly_summary.dart';
import 'package:expense_tracker/features/alerts/domain/entities/smart_alert.dart';
import 'package:expense_tracker/features/analysis/domain/logic/financial_analysis_service.dart';
import 'package:expense_tracker/features/shared/domain/policies/smart_alert_policy.dart';

class GetSmartAlertsStreamUseCase {
  final GetMonthlySummaryUseCase getSummary;
  final GetBudgetStatusStreamUseCase getBudgetStatus;
  final GetExpensesStreamUseCase getExpenses;
  final FinancialAnalysisService analysisService;

  GetSmartAlertsStreamUseCase({
    required this.getSummary,
    required this.getBudgetStatus,
    required this.getExpenses,
    required this.analysisService,
  });

  Stream<List<SmartAlert>> call(int month, int year) {
    final t1 = DateTime(year, month - 1);
    final t2 = DateTime(year, month - 2);

    return Rx.combineLatest5(
      getSummary(month, year),
      getSummary(t1.month, t1.year),
      getSummary(t2.month, t2.year),
      getBudgetStatus(month, year),
      getExpenses(),
      (current, prev, tMinus2, budgets, allExpenses) {
        final List<SmartAlert> alerts = [];
        final now = DateTime.now();

        // 1. Budget Breaches (Policy-driven)
        for (var b in budgets) {
          if (b.isExceeded) {
            alerts.add(SmartAlert(
              id: 'breach_${b.categoryId}',
              type: AlertType.budgetExceeded,
              title: 'Budget Breached',
              message: 'Limit exceeded in ${b.categoryName}.',
              severity: AlertSeverity.high,
              categoryId: b.categoryId,
              amount: b.spent,
              createdAt: now,
            ));
          }
        }

        // 2. Spending Spikes (Policy: spikeThreshold)
        current.categoryBreakdown.forEach((id, spent) {
          final prevSpent = prev.categoryBreakdown[id] ?? 0.0;
          if (analysisService.anomalyDetector.isAboveThreshold(spent, prevSpent, SmartAlertPolicy.spikeThreshold)) {
            final categoryName = budgets.cast<dynamic>().firstWhere((b) => b.categoryId == id, orElse: () => null)?.categoryName ?? 'Category';
            alerts.add(SmartAlert(
              id: 'spike_$id',
              type: AlertType.spendingSpike,
              title: 'Spending Spike',
              message: 'Spending in $categoryName is up significantly.',
              severity: AlertSeverity.medium,
              categoryId: id,
              amount: spent,
              createdAt: now,
            ));
          }
        });

        // 3. Trends (Policy: trendWindow)
        if (current.totalExpense > prev.totalExpense && prev.totalExpense > tMinus2.totalExpense && tMinus2.totalExpense > 0) {
          alerts.add(SmartAlert(
            id: 'trend_warning',
            type: AlertType.trendWarning,
            title: 'Spending Upward Trend',
            message: 'Expenses have increased for 3 consecutive months.',
            severity: AlertSeverity.medium,
            createdAt: now,
          ));
        }

        // 4. Outliers (Policy: anomalyMultiplier)
        final monthlyExpenses = allExpenses.where((e) => e.date.month == month && e.date.year == year).toList();
        final avgAmount = allExpenses.isEmpty ? 0.0 : allExpenses.fold(0.0, (sum, e) => sum + e.amount) / allExpenses.length;
        for (var e in monthlyExpenses) {
          if (analysisService.anomalyDetector.isOutlier(e.amount, avgAmount, SmartAlertPolicy.anomalyMultiplier)) {
            alerts.add(SmartAlert(
              id: 'unusual_${e.id}',
              type: AlertType.unusualActivity,
              title: 'Unusual Transaction',
              message: 'Transaction of ${e.amount} is unusually high.',
              severity: AlertSeverity.medium,
              categoryId: e.categoryId,
              amount: e.amount,
              createdAt: now,
            ));
          }
        }

        return alerts;
      },
    );
  }
}
