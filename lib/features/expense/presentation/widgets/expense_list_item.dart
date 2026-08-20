import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/expense/presentation/pages/transaction_detail_page.dart';

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
    final isIncome = expense.type == CategoryType.income;
    final isTransfer = expense.type == CategoryType.transfer;
    final displayColor = isIncome 
        ? AppTheme.emerald 
        : (isTransfer ? AppTheme.gold : AppTheme.brick);
    final prefix = isIncome ? '+' : (isTransfer ? '⇄' : '-');
    final isPlanLinked = expense.planId != null;

    final accounts = context.watch<AccountProvider>().accounts;
    final account = accounts.where((a) => a.id == expense.accountId).firstOrNull;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isPlanLinked ? AppTheme.gold.withOpacity(0.5) : AppTheme.line,
          width: isPlanLinked ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: onTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailPage(expenseId: expense.id),
                  ),
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category Icon Capsule
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    category.icon,
                    size: 20,
                    color: displayColor,
                  ),
                ),
                const SizedBox(width: 14),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        expense.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Category & Sub-category & Account metadata row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.muted,
                              ),
                            ),
                          ),
                          if (expense.subCategory != null && expense.subCategory!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text('•', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11)),
                            const SizedBox(width: 4),
                            if (expense.subCategoryIcon != null) ...[
                              Icon(
                                IconUtils.getIcon(expense.subCategoryIcon),
                                size: 11,
                                color: AppTheme.muted,
                              ),
                              const SizedBox(width: 2),
                            ],
                            Flexible(
                              child: Text(
                                expense.subCategory!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ),
                          ],
                          if (account != null) ...[
                            const SizedBox(width: 4),
                            Text('•', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Amount & Pending Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (expense.paymentStatus == PaymentStatus.pending) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                            ),
                            child: Text(
                              'PENDING',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.gold,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '$prefix ${CurrencyFormatter.format(expense.amount)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: displayColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.format(expense.date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
