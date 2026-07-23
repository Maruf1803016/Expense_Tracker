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
                    const Text(
                      'Amount',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
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
                    const SizedBox(height: 16),
                    Text(
                      expense.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Category
            _buildDetailField(
              label: 'Category',
              value: category.name,
              icon: category.icon,
              color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
            const SizedBox(height: 24),

            // Sub-category
            if (expense.subCategory != null && expense.subCategory!.isNotEmpty) ...[
              _buildDetailField(
                label: 'Sub-category',
                value: expense.subCategory!,
                icon: expense.subCategoryIcon != null
                    ? IconUtils.getIcon(expense.subCategoryIcon!)
                    : Icons.label_outline,
                color: const Color(0xFF00C896),
              ),
              const SizedBox(height: 24),
            ],

            // Date
            _buildDetailField(
              label: 'Date',
              value: DateFormatter.format(expense.date),
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 24),

            // Type
            _buildDetailField(
              label: 'Type',
              value: isExpense ? 'Expense' : 'Income',
              icon: isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
            const SizedBox(height: 24),

            // Note
            if (expense.note.isNotEmpty)
              _buildDetailField(
                label: 'Note',
                value: expense.note,
                icon: Icons.notes,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: color ?? Colors.white54, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
