import 'package:equatable/equatable.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../../expense/domain/entities/monthly_summary.dart';
import '../../../budget/domain/entities/category_budget_status.dart';

/// Entity that encapsulates all data required for a specific month's export.
/// This avoids the export layer from having to query multiple sources.
class MonthlyExportData extends Equatable {
  final int month;
  final int year;
  final MonthlySummary summary;
  final List<CategoryBudgetStatus> budgetStatuses;
  final List<Expense> expenses;

  const MonthlyExportData({
    required this.month,
    required this.year,
    required this.summary,
    required this.budgetStatuses,
    required this.expenses,
  });

  @override
  List<Object?> get props => [month, year, summary, budgetStatuses, expenses];
}
