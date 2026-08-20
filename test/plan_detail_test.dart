import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  group('Goal / Plan Details Category Breakdown', () {
    test('should include all distinct category IDs present in both plan setup and logged transactions', () {
      final now = DateTime.now();
      
      final plan = Goal(
        id: 'goal_wedding_123',
        title: 'Wedding Event',
        totalBudget: 150000.0,
        startDate: now,
        endDate: now.add(const Duration(days: 60)),
        categoryIds: const ['food_dining_cat'],
        note: 'Goal note details',
        createdAt: now,
      );

      final planExpenses = [
        Expense(
          id: 'exp_1',
          title: 'Catering',
          amount: 75000.0,
          categoryId: 'food_dining_cat',
          date: now,
          note: 'Buffet',
          planId: 'goal_wedding_123',
          accountId: 'acc_1',
        ),
        Expense(
          id: 'exp_2',
          title: 'Wedding Car',
          amount: 40000.0,
          categoryId: 'transportation_cat',
          date: now,
          note: 'Car rental',
          planId: 'goal_wedding_123',
          accountId: 'acc_1',
        ),
      ];

      // Replicate calculation done in plan_detail_page.dart
      final distinctCategoryIds = {
        ...plan.categoryIds,
        ...planExpenses.map((e) => e.categoryId),
      }.toList();

      expect(distinctCategoryIds.length, 2);
      expect(distinctCategoryIds, contains('food_dining_cat'));
      expect(distinctCategoryIds, contains('transportation_cat'));
    });
  });
}
