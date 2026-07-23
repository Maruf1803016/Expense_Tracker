import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final Category category;
  final VoidCallback? onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = category.type == CategoryType.income;
    final displayColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            category.icon,
            color: displayColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              CurrencyFormatter.format(expense.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: displayColor,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                DateFormatter.format(expense.date),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (expense.note.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.fiber_manual_record, size: 4, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
