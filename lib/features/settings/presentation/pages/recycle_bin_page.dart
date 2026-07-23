import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final deletedExpenses = provider.recycleBinExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (deletedExpenses.isNotEmpty)
            TextButton(
              onPressed: () => _showEmptyBinDialog(context, provider),
              child: const Text('Empty Bin', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: deletedExpenses.isEmpty
          ? const EmptyState(
              title: 'Recycle Bin is Empty',
              message: 'Deleted expenses will appear here for 30 days before being permanently removed.',
              icon: Icons.delete_outline_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deletedExpenses.length,
              itemBuilder: (context, index) {
                final expense = deletedExpenses[index];
                final category = provider.getCategoryById(expense.categoryId);
                final isIncome = category.type == CategoryType.income;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isIncome ? AppTheme.incomeColor : AppTheme.expenseColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category.icon,
                        color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
                      ),
                    ),
                    title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Deleted on ${DateFormatter.format(expense.deletedAt ?? DateTime.now())}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(expense.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'restore') {
                              provider.restoreExpense(expense.id);
                            } else {
                              _showDeleteForeverDialog(context, provider, expense.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  Icon(Icons.restore, size: 20),
                                  SizedBox(width: 8),
                                  Text('Restore'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Forever', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEmptyBinDialog(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: const Text('This will permanently delete all items in the bin. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.emptyRecycleBin();
              Navigator.pop(context);
            },
            child: const Text('Empty Bin', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteForeverDialog(BuildContext context, ExpenseProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This item will be removed forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteForever(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
