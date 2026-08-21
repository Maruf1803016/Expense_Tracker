import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final String expenseId;

  const TransactionDetailPage({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final goalProvider = context.watch<GoalProvider>();
    final tripPlanProvider = context.watch<TripPlanProvider>();

    Expense? expense;
    try {
      expense = expenseProvider.expenses.firstWhere((e) => e.id == expenseId);
    } catch (_) {
      expense = null;
    }

    if (expense == null) {
      return Scaffold(
        backgroundColor: AppTheme.paper,
        appBar: AppBar(
          title: Text('Transaction Detail', style: GoogleFonts.fraunces(fontWeight: FontWeight.w500)),
        ),
        body: Center(
          child: Text(
            'Transaction not found.',
            style: GoogleFonts.inter(color: AppTheme.muted),
          ),
        ),
      );
    }

    // Resolve Category
    Category? category;
    try {
      category = categoryProvider.categories.firstWhere((c) => c.id == expense!.categoryId);
    } catch (_) {}

    // Resolve Account
    final account = accountProvider.getAccountById(expense.accountId);
    final toAccount = expense.toAccountId != null ? accountProvider.getAccountById(expense.toAccountId!) : null;

    // Resolve Linked Goal / Trip Plan
    final linkedGoal = expense.planId != null
        ? goalProvider.plans.where((p) => p.id == expense!.planId).firstOrNull
        : null;
    final linkedTrip = expense.planId != null
        ? tripPlanProvider.tripPlans.where((p) => p.id == expense!.planId).firstOrNull
        : null;

    final isIncome = expense.type == CategoryType.income;
    final isTransfer = expense.type == CategoryType.transfer;
    final amountColor = isIncome ? AppTheme.emerald : (isTransfer ? AppTheme.gold : AppTheme.brick);
    final amountPrefix = isIncome ? '+ ' : (isTransfer ? '⇄ ' : '- ');

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          'Transaction Detail',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.brick),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, expense!),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.paperCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (expense.paymentStatus == PaymentStatus.pending) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                          ),
                          child: Text(
                            'PENDING',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        '$amountPrefix${CurrencyFormatter.format(expense.amount)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expense.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Ledger Section
            Text(
              'TRANSACTION INFORMATION',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.paperCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Date & Time',
                    value: DateFormatter.format(expense.date),
                    icon: Icons.calendar_today_rounded,
                  ),
                  const Divider(height: 1, color: AppTheme.line),
                  _buildDetailRow(
                    label: 'Category',
                    value: category?.name ?? (isTransfer ? 'Transfer' : 'Uncategorized'),
                    subValue: expense.subCategory,
                    icon: category?.icon ?? (isTransfer ? Icons.swap_horiz_rounded : Icons.category_rounded),
                    iconColor: category != null
                        ? AppTheme.getCategoryColor(category.id, category.name)
                        : AppTheme.gold,
                  ),
                  const Divider(height: 1, color: AppTheme.line),
                  _buildDetailRow(
                    label: isTransfer ? 'From Account' : 'Account',
                    value: account?.name ?? 'Unknown Account',
                    icon: account?.icon ?? Icons.account_balance_wallet_rounded,
                    iconColor: account?.color ?? AppTheme.textDark,
                  ),
                  if (isTransfer && toAccount != null) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildDetailRow(
                      label: 'To Account',
                      value: toAccount.name,
                      icon: toAccount.icon,
                      iconColor: toAccount.color,
                    ),
                  ],
                  if (expense.paymentMethod != null && expense.paymentMethod!.isNotEmpty) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildDetailRow(
                      label: 'Payment Method',
                      value: expense.paymentMethod!,
                      icon: Icons.payment_rounded,
                    ),
                  ],
                  if (expense.payerPayee != null && expense.payerPayee!.isNotEmpty) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildDetailRow(
                      label: isIncome ? 'Payer / Source' : 'Payee / Counterparty',
                      value: expense.payerPayee!,
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                  if (linkedGoal != null) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildDetailRow(
                      label: 'Linked Savings Goal',
                      value: linkedGoal.title,
                      icon: Icons.track_changes_rounded,
                      iconColor: AppTheme.gold,
                    ),
                  ],
                  if (linkedTrip != null) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildDetailRow(
                      label: 'Linked Trip Plan',
                      value: linkedTrip.title,
                      icon: Icons.card_travel_rounded,
                      iconColor: AppTheme.gold,
                    ),
                  ],
                  if (expense.note.isNotEmpty) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildDetailRow(
                      label: 'Notes',
                      value: expense.note,
                      icon: Icons.notes_rounded,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Primary Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddExpensePage(expenseToEdit: expense),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text(
                  'Modify Entry',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    String? subValue,
    required IconData icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.paper2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppTheme.muted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                if (subValue != null && subValue.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${expense.title}"? It will be moved to the Recycle Bin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ExpenseProvider>().deleteExpense(expense.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${expense.title}" moved to Recycle Bin'),
                    backgroundColor: AppTheme.emerald,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
