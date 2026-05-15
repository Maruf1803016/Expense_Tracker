import 'package:rxdart/rxdart.dart';
import '../../../budget/domain/usecases/get_budget_status.dart';
import '../../../expense/domain/usecases/get_expenses.dart';
import '../../../expense/domain/usecases/get_monthly_summary.dart';
import '../entities/export_data.dart';

class GetMonthlyExportDataUseCase {
  final GetMonthlySummaryUseCase getSummary;
  final GetBudgetStatusStreamUseCase getBudgets;
  final GetExpensesStreamUseCase getExpenses;

  GetMonthlyExportDataUseCase({
    required this.getSummary,
    required this.getBudgets,
    required this.getExpenses,
  });

  /// Assembles all required export data for a specific [month] and [year].
  /// This takes a single snapshot of the current state from the reactive streams.
  Future<MonthlyExportData> call(int month, int year) async {
    return Rx.combineLatest3(
      getSummary(month, year),
      getBudgets(month, year),
      getExpenses(),
      (summary, budgets, expenses) {
        // Filter raw expenses for the month to match the summary/budgets
        final monthlyExpenses = expenses.where((e) {
          return e.date.month == month && e.date.year == year;
        }).toList();

        return MonthlyExportData(
          month: month,
          year: year,
          summary: summary,
          budgetStatuses: budgets,
          expenses: monthlyExpenses,
        );
      },
    ).first; // Take the first result (one-shot fetch)
  }
}
