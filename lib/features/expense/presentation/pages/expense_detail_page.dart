import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

class ExpenseDetailPage extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailPage({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final category = provider.getCategoryById(expense.categoryId);
    final isExpense = category.type == CategoryType.expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpensePage(expenseToEdit: expense),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(expense.amount),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Details Section
            _buildDetailRow(
              context,
              label: 'Category',
              value: category.name,
              icon: IconUtils.getIcon(category.icon),
              iconColor: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              label: 'Date',
              value: DateFormatter.format(expense.date),
              icon: Icons.calendar_today_outlined,
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              label: 'Type',
              value: category.type == CategoryType.expense ? 'Expense' : 'Income',
              icon: category.type == CategoryType.expense 
                  ? Icons.arrow_downward_rounded 
                  : Icons.arrow_upward_rounded,
              iconColor: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
            
            if (expense.note.isNotEmpty) ...[
              const Divider(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Note',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expense.note,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.grey).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Colors.grey, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
