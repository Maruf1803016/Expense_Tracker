import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/analysis/domain/logic/expense_aggregator.dart';

void main() {
  group('ExpenseAggregator - groupSpentByCategory', () {
    final aggregator = ExpenseAggregator();

    test('should exclude income transactions from category grouping totals', () {
      final now = DateTime.now();
      final transactions = [
        Expense(
          id: '1',
          title: 'Salary Income',
          amount: 8000.0,
          categoryId: 'income_cat_1',
          date: now,
          note: 'Freeland salary',
          type: CategoryType.income,
        ),
        Expense(
          id: '2',
          title: 'Food Expense',
          amount: 250.0,
          categoryId: 'food_cat_1',
          date: now,
          note: 'Dinner',
          type: CategoryType.expense,
        ),
      ];

      final spentBreakdown = aggregator.groupSpentByCategory(transactions);

      expect(spentBreakdown.containsKey('income_cat_1'), isFalse);
      expect(spentBreakdown['food_cat_1'], 250.0);
    });
  });
}
