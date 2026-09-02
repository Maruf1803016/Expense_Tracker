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
import 'package:expense_tracker/core/utils/haptics_service.dart';

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
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          foregroundColor: context.textPrimary,
          title: Text('Transaction Detail', style: GoogleFonts.fraunces(fontWeight: FontWeight.w500, color: context.textPrimary)),
        ),
        body: Center(
          child: Text(
            'Transaction not found.',
            style: GoogleFonts.inter(color: context.textMuted),
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
    final amountColor = isIncome ? context.emerald : (isTransfer ? context.gold : context.brick);
    final amountPrefix = isIncome ? '+ ' : (isTransfer ? '⇄ ' : '- ');

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          'Transaction Detail',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500, color: context.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.brick),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, expense!),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (expense.paymentStatus == PaymentStatus.pending) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: context.gold.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'PENDING',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: context.gold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        '$amountPrefix${CurrencyFormatter.format(expense.amount)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    expense.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Ledger Section
            Text(
              'TRANSACTION INFORMATION',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    label: 'Date & Time',
                    value: DateFormatter.format(expense.date),
                    icon: Icons.calendar_today_rounded,
                  ),
                  Divider(height: 1, color: context.line),
                  _buildDetailRow(
                    context,
                    label: 'Category',
                    value: category?.name ?? (isTransfer ? 'Transfer' : 'Uncategorized'),
                    subValue: expense.subCategory,
                    icon: category?.icon ?? (isTransfer ? Icons.swap_horiz_rounded : Icons.category_rounded),
                    iconColor: category != null
                        ? AppTheme.getCategoryColor(category.id, category.name)
                        : context.gold,
                  ),
                  Divider(height: 1, color: context.line),
                  _buildDetailRow(
                    context,
                    label: isTransfer ? 'From Account' : 'Account',
                    value: account?.name ?? 'Unknown Account',
                    icon: account?.icon ?? Icons.account_balance_wallet_rounded,
                    iconColor: account?.color ?? context.textPrimary,
                  ),
                  if (isTransfer && toAccount != null) ...[
                    Divider(height: 1, color: context.line),
                    _buildDetailRow(
                      context,
                      label: 'To Account',
                      value: toAccount.name,
                      icon: toAccount.icon,
                      iconColor: toAccount.color,
                    ),
                  ],
                  Divider(height: 1, color: context.line),
                  _buildDetailRow(
                    context,
                    label: 'Payment Status',
                    value: expense.paymentStatus == PaymentStatus.pending ? 'Pending Clearance' : 'Settled & Cleared',
                    icon: expense.paymentStatus == PaymentStatus.pending ? Icons.hourglass_empty_rounded : Icons.check_circle_outline_rounded,
                    iconColor: expense.paymentStatus == PaymentStatus.pending ? context.gold : context.emerald,
                  ),
                  if (expense.paymentMethod != null && expense.paymentMethod!.isNotEmpty) ...[
                    Divider(height: 1, color: context.line),
                    _buildDetailRow(
                      context,
                      label: 'Payment Method',
                      value: expense.paymentMethod!,
                      icon: Icons.payment_rounded,
                    ),
                  ],
                  if (expense.payerPayee != null && expense.payerPayee!.isNotEmpty) ...[
                    Divider(height: 1, color: context.line),
                    _buildDetailRow(
                      context,
                      label: isIncome ? 'Payer / Source' : 'Payee / Counterparty',
                      value: expense.payerPayee!,
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                  if (linkedGoal != null) ...[
                    Divider(height: 1, color: context.line),
                    _buildDetailRow(
                      context,
                      label: 'Linked Savings Goal',
                      value: linkedGoal.title,
                      icon: Icons.track_changes_rounded,
                      iconColor: context.gold,
                    ),
                  ],
                  if (linkedTrip != null) ...[
                    Divider(height: 1, color: context.line),
                    _buildDetailRow(
                      context,
                      label: 'Linked Trip Plan',
                      value: linkedTrip.title,
                      icon: Icons.card_travel_rounded,
                      iconColor: context.gold,
                    ),
                  ],
                  if (expense.note.isNotEmpty) ...[
                    Divider(height: 1, color: context.line),
                    _buildDetailRow(
                      context,
                      label: 'Notes',
                      value: expense.note,
                      icon: Icons.notes_rounded,
                    ),
                  ],
                ],
              ),
            ),

            if (expense.splitDetails != null && expense.splitDetails!.isSplit) ...[
              const SizedBox(height: 16),
              Text(
                'SPLIT BILL BREAKDOWN',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              _buildSplitBreakdownCard(context, expense, expenseProvider),
            ],

            const SizedBox(height: 20),

            // Primary Action Button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddExpensePage(expenseToEdit: expense),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    'Modify Entry',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
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
              color: context.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? context.textMuted),
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
                    color: context.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (subValue != null && subValue.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textMuted,
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
        backgroundColor: ctx.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: ctx.line),
        ),
        title: Text('Delete Transaction', style: GoogleFonts.fraunces(color: ctx.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${expense.title}"? It will be moved to the Recycle Bin.',
          style: GoogleFonts.inter(color: ctx.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: ctx.textMuted)),
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
                    backgroundColor: context.emerald,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: ctx.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBreakdownCard(
    BuildContext context,
    Expense expense,
    ExpenseProvider expenseProvider,
  ) {
    final split = expense.splitDetails!;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.call_split_rounded, color: context.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Split Bill Breakdown',
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: split.isFullySettled
                      ? context.emerald.withValues(alpha: 0.15)
                      : AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  split.isFullySettled ? 'FULLY SETTLED' : 'PENDING SPLIT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: split.isFullySettled ? context.emerald : AppTheme.gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.line),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Bill:',
                style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
              ),
              Text(
                CurrencyFormatter.format(split.totalBillAmount),
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payer:',
                style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
              ),
              Text(
                split.isPaidByMe ? 'You (Payer)' : split.paidBy,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Share:',
                style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
              ),
              Text(
                CurrencyFormatter.format(split.myShare),
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.gold),
              ),
            ],
          ),
          if (!split.isPaidByMe) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: expense.paymentStatus == PaymentStatus.settled
                    ? context.emerald.withValues(alpha: 0.1)
                    : context.brick.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: expense.paymentStatus == PaymentStatus.settled
                      ? context.emerald.withValues(alpha: 0.3)
                      : context.brick.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    expense.paymentStatus == PaymentStatus.settled
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    color: expense.paymentStatus == PaymentStatus.settled ? context.emerald : context.brick,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expense.paymentStatus == PaymentStatus.settled
                          ? 'You settled your share with ${split.paidBy}.'
                          : 'You owe ${split.paidBy} ${CurrencyFormatter.format(expense.amount)}.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  if (expense.paymentStatus == PaymentStatus.pending) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () async {
                        HapticsService.selection();
                        await expenseProvider.settleFullSplitBill(expense.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settled your split share successfully!'),
                              backgroundColor: AppTheme.emerald,
                            ),
                          );
                        }
                      },
                      child: Text('Settle Up', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (split.splits.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'COUNTERPARTIES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              ...split.splits.map((s) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.line),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: s.isSettled ? context.emerald.withValues(alpha: 0.2) : AppTheme.gold.withValues(alpha: 0.2),
                        child: Icon(
                          s.isSettled ? Icons.check_rounded : Icons.person_rounded,
                          size: 13,
                          color: s.isSettled ? context.emerald : AppTheme.gold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                            ),
                            Text(
                              s.isSettled ? 'Settled' : 'Pending payment',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: s.isSettled ? context.emerald : context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(s.amount),
                        style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      if (!s.isSettled)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () async {
                            HapticsService.selection();
                            await expenseProvider.settleSplitParticipant(expense.id, s.name);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Marked ${s.name} as settled'),
                                  backgroundColor: AppTheme.emerald,
                                ),
                              );
                            }
                          },
                          child: Text('Settle', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}
