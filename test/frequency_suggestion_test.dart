import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/services/frequency_suggestion_service.dart';

void main() {
  group('FrequencySuggestionService Tests', () {
    final mockExpenses = [
      Expense(
        id: '1',
        title: 'Coffee',
        amount: 4.50,
        categoryId: 'food',
        date: DateTime(2026, 9, 2),
        note: '',
        accountId: 'acc-1',
      ),
      Expense(
        id: '2',
        title: 'Coffee',
        amount: 4.50,
        categoryId: 'food',
        date: DateTime(2026, 9, 1),
        note: '',
        accountId: 'acc-1',
      ),
      Expense(
        id: '3',
        title: 'Supermarket Groceries',
        amount: 65.0,
        categoryId: 'groceries',
        date: DateTime(2026, 8, 30),
        note: '',
        accountId: 'acc-2',
      ),
      Expense(
        id: '4',
        title: 'Coffee',
        amount: 5.0,
        categoryId: 'food',
        date: DateTime(2026, 8, 29),
        note: '',
        accountId: 'acc-1',
      ),
    ];

    test('generateTopSuggestions ranks most frequent combination at top', () {
      final suggestions = FrequencySuggestionService.generateTopSuggestions(mockExpenses);
      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.first.title, 'Coffee');
      expect(suggestions.first.usageCount, 3);
      expect(suggestions.first.categoryId, 'food');
      expect(suggestions.first.accountId, 'acc-1');
    });

    test('filterSuggestionsByQuery returns matching items on query prefix', () {
      final filtered = FrequencySuggestionService.filterSuggestionsByQuery(mockExpenses, 'Cof');
      expect(filtered.length, 1);
      expect(filtered.first.title, 'Coffee');

      final groc = FrequencySuggestionService.filterSuggestionsByQuery(mockExpenses, 'groc');
      expect(groc.length, 1);
      expect(groc.first.title, 'Supermarket Groceries');

      final empty = FrequencySuggestionService.filterSuggestionsByQuery(mockExpenses, 'c');
      expect(empty.isEmpty, isTrue); // < 2 chars
    });
  });
}
