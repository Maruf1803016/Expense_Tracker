import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';

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
    final isPlanLinked = expense.planId != null;
    final accounts = context.watch<AccountProvider>().accounts;
    final account = accounts.any((a) => a.id == expense.accountId) 
        ? accounts.firstWhere((a) => a.id == expense.accountId) 
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(
          color: isPlanLinked 
              ? AppTheme.emeraldGreen.withOpacity(0.5) 
              : Colors.white.withOpacity(0.05),
          width: isPlanLinked ? 1.5 : 1.0,
        ),
      ),
      color: AppTheme.secondaryBackground,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Stack(
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & Sub-category row
                          Row(
                            children: [
                              Icon(
                                category.icon,
                                size: 14,
                                color: displayColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  category.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              if (expense.subCategory != null && expense.subCategory!.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  expense.subCategoryIcon != null
                                      ? IconUtils.getIcon(expense.subCategoryIcon)
                                      : Icons.label_outline,
                                  size: 12,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    expense.subCategory!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                              if (account != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    account.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                              if (isPlanLinked) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emeraldGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'GOAL',
                                    style: TextStyle(
                                      color: AppTheme.emeraldGreen,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Transaction Title
                          Text(
                            expense.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Note / Date
                          Text(
                            expense.note.isNotEmpty ? expense.note : DateFormatter.format(expense.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Amount
                    Text(
                      (isIncome ? '+' : '-') + CurrencyFormatter.format(expense.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: displayColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isPlanLinked)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.emeraldGreen,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.track_changes_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
