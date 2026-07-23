import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_detail_page.dart';

class ExpenseSearchDelegate extends SearchDelegate<Expense?> {
  @override
  String get searchFieldLabel => 'Search expenses...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final expenses = provider.expenses;

    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search notes or categories', style: TextStyle(color: Colors.white54)),
      );
    }

    final lowerQuery = query.toLowerCase();
    final results = expenses.where((e) {
      final category = provider.getCategoryById(e.categoryId);
      return e.note.toLowerCase().contains(lowerQuery) ||
          category.name.toLowerCase().contains(lowerQuery) ||
          (e.subCategory?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final expense = results[index];
        final category = provider.getCategoryById(expense.categoryId);
        final isExpense = category.type == CategoryType.expense;
        final displayColor = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseDetailPage(expense: expense),
                ),
              );
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: displayColor, size: 20),
            ),
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${DateFormatter.format(expense.date)}${expense.note.isNotEmpty ? " • ${expense.note}" : ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              CurrencyFormatter.format(expense.amount),
              style: TextStyle(
                color: displayColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
