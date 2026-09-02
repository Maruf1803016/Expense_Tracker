import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

class ExpenseSuggestion {
  final String title;
  final String categoryId;
  final String? subCategory;
  final String? subCategoryIcon;
  final String accountId;
  final CategoryType type;
  final double typicalAmount;
  final int usageCount;

  const ExpenseSuggestion({
    required this.title,
    required this.categoryId,
    this.subCategory,
    this.subCategoryIcon,
    required this.accountId,
    required this.type,
    required this.typicalAmount,
    required this.usageCount,
  });
}

class FrequencySuggestionService {
  /// Inspects the last [maxInspectCount] (default 50) local transactions and ranks top suggestions.
  static List<ExpenseSuggestion> generateTopSuggestions(
    List<Expense> expenses, {
    int maxInspectCount = 50,
    int maxResults = 5,
  }) {
    final validExpenses = expenses.where((e) => !e.isDeleted && e.title.trim().isNotEmpty).toList();
    if (validExpenses.isEmpty) return [];

    final sample = validExpenses.take(maxInspectCount).toList();
    final Map<String, _SuggestionAccumulator> map = {};

    for (int i = 0; i < sample.length; i++) {
      final e = sample[i];
      final key = '${e.title.trim().toLowerCase()}_${e.categoryId}_${e.accountId}_${e.type.name}';
      
      // Recency weight: recent items get a boost
      final recencyWeight = (sample.length - i) / sample.length;

      if (!map.containsKey(key)) {
        map[key] = _SuggestionAccumulator(
          title: e.title.trim(),
          categoryId: e.categoryId,
          subCategory: e.subCategory,
          subCategoryIcon: e.subCategoryIcon,
          accountId: e.accountId,
          type: e.type,
          latestAmount: e.amount,
          count: 1,
          score: 1.0 + (recencyWeight * 0.5),
        );
      } else {
        final acc = map[key]!;
        acc.count += 1;
        acc.score += 1.0 + (recencyWeight * 0.5);
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return sorted.take(maxResults).map((acc) {
      return ExpenseSuggestion(
        title: acc.title,
        categoryId: acc.categoryId,
        subCategory: acc.subCategory,
        subCategoryIcon: acc.subCategoryIcon,
        accountId: acc.accountId,
        type: acc.type,
        typicalAmount: acc.latestAmount,
        usageCount: acc.count,
      );
    }).toList();
  }

  /// Filters historical transaction titles for autocomplete dropdown matching [query].
  static List<ExpenseSuggestion> filterSuggestionsByQuery(
    List<Expense> expenses,
    String query, {
    int maxResults = 5,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.length < 2) return [];

    final allSuggestions = generateTopSuggestions(expenses, maxInspectCount: 100, maxResults: 50);
    return allSuggestions
        .where((s) => s.title.toLowerCase().contains(cleanQuery))
        .take(maxResults)
        .toList();
  }
}

class _SuggestionAccumulator {
  final String title;
  final String categoryId;
  final String? subCategory;
  final String? subCategoryIcon;
  final String accountId;
  final CategoryType type;
  final double latestAmount;
  int count;
  double score;

  _SuggestionAccumulator({
    required this.title,
    required this.categoryId,
    this.subCategory,
    this.subCategoryIcon,
    required this.accountId,
    required this.type,
    required this.latestAmount,
    required this.count,
    required this.score,
  });
}
