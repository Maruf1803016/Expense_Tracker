import 'package:rxdart/rxdart.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/budget/domain/entities/category_budget_status.dart';
import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/analysis/domain/logic/financial_analysis_service.dart';

class GetBudgetStatusStreamUseCase {
  final CategoryRepository categoryRepository;
  final ExpenseRepository expenseRepository;
  final BudgetRepository budgetRepository;
  final FinancialAnalysisService analysisService;

  GetBudgetStatusStreamUseCase({
    required this.categoryRepository,
    required this.expenseRepository,
    required this.budgetRepository,
    required this.analysisService,
  });

  Stream<List<CategoryBudgetStatus>> call(int month, int year) {
    return Rx.combineLatest3(
      categoryRepository.getCategoriesStream(),
      expenseRepository.getExpensesStream(),
      budgetRepository.getBudgetsStream(month, year),
      (categories, expenses, budgets) {
        final filteredExpenses = analysisService.aggregator.filterByMonth(expenses, month, year);
        
        return categories.where((c) => c.type == CategoryType.expense).map((category) {
          final spent = filteredExpenses
              .where((e) => e.categoryId == category.id)
              .fold(0.0, (sum, e) => sum + e.amount);

          final budget = budgets.cast<dynamic>().firstWhere(
                (b) => b.categoryId == category.id,
                orElse: () => null,
              );

          final limit = budget?.monthlyLimit ?? 0.0;
          final (remaining, percentage, isExceeded) = 
              analysisService.budgetCalculator.calculateStatusProps(spent, limit);

          return CategoryBudgetStatus(
            categoryId: category.id,
            categoryName: category.name,
            limit: limit,
            spent: spent,
            remaining: remaining,
            percentageUsed: percentage,
            isExceeded: isExceeded,
          );
        }).toList();
      },
    );
  }
}
