import 'package:rxdart/rxdart.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expense/domain/entities/monthly_summary.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/analysis/domain/logic/financial_analysis_service.dart';

class GetMonthlySummaryUseCase {
  final ExpenseRepository expenseRepository;
  final CategoryRepository categoryRepository;
  final FinancialAnalysisService analysisService;

  GetMonthlySummaryUseCase({
    required this.expenseRepository,
    required this.categoryRepository,
    required this.analysisService,
  });

  /// Orchestrates current month aggregation by delegating math to the logic layer.
  Stream<MonthlySummary> call(int month, int year) {
    return Rx.combineLatest2(
      expenseRepository.getExpensesStream(),
      categoryRepository.getCategoriesStream(),
      (expenses, categories) {
        final snapshot = analysisService.generateMonthlySnapshot(
          expenses,
          categories,
          month,
          year,
        );

        return MonthlySummary(
          totalIncome: snapshot['income'],
          totalExpense: snapshot['expense'],
          netBalance: snapshot['balance'],
          categoryBreakdown: snapshot['breakdown'],
        );
      },
    );
  }
}
