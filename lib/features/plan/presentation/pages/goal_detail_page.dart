import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class GoalDetailPage extends StatelessWidget {
  final Goal plan;

  const GoalDetailPage({super.key, required this.plan});

  Future<void> _deletePlanFlow(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${plan.title}"?\n\nThe transactions linked to this goal will NOT be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final expenseProvider = context.read<ExpenseProvider>();
      final planProvider = context.read<GoalProvider>();
      
      await expenseProvider.orphanPlanExpenses(plan.id);
      await planProvider.delete(plan.id);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('Goal "${plan.title}" deleted'),
          backgroundColor: AppTheme.emerald,
        ),
      );
      
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final planProvider = context.watch<GoalProvider>();
    final matching = planProvider.plans.where((p) => p.id == plan.id).toList();
    final currentGoal = matching.isNotEmpty ? matching.first : plan;
    final expenses = expenseProvider.expenses;
    final planExpenses = expenses.where((e) => e.planId == currentGoal.id && !e.isDeleted).toList();
    final amountSaved = planExpenses.fold<double>(0.0, (sum, e) => e.type == CategoryType.expense ? sum + e.amount : sum - e.amount);
    final remaining = (currentGoal.totalBudget - amountSaved).clamp(0.0, double.infinity);
    final double percentUsed = currentGoal.totalBudget > 0 ? (amountSaved / currentGoal.totalBudget) : 0.0;

    final now = DateTime.now();
    final daysLeft = currentGoal.endDate.isAfter(now) ? currentGoal.endDate.difference(now).inDays : 0;
    final dailyReq = daysLeft > 0 ? (remaining / daysLeft) : 0.0;
    final weeksLeft = daysLeft > 0 ? (daysLeft / 7.0) : 0.0;
    final weeklyReq = weeksLeft > 0 ? (remaining / weeksLeft) : 0.0;

    Color progressColor;
    if (percentUsed < 0.8) {
      progressColor = AppTheme.emerald;
    } else if (percentUsed <= 1.0) {
      progressColor = AppTheme.gold;
    } else {
      progressColor = AppTheme.brick;
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.brick),
            tooltip: 'Delete goal',
            onPressed: () => _deletePlanFlow(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kicker
            Text(
              'SAVINGS GOAL',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: context.gold,
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              currentGoal.title,
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormatter.format(currentGoal.endDate),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.gold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (percentUsed >= 1.0 ? context.emerald : context.gold).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          percentUsed >= 1.0 ? 'ACHIEVED' : 'IN PROGRESS',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: percentUsed >= 1.0 ? context.emerald : context.gold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.format(amountSaved),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'of ${CurrencyFormatter.format(currentGoal.totalBudget)} target',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentUsed.clamp(0.0, 1.0),
                      minHeight: 8,
                      color: progressColor,
                      backgroundColor: context.line.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(percentUsed * 100).toStringAsFixed(0)}% personally funded',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.format(remaining)} to go',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Symmetrical 2x2 Requirement Grid
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: context.line),
                              bottom: BorderSide(color: context.line),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEADLINE PACE',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: context.gold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$daysLeft days left',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: context.line),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DAILY REQUIREMENT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: context.gold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(dailyReq),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: context.line),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WEEKLY REQUIREMENT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: context.gold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.format(weeklyReq),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT STATUS',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: context.gold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                percentUsed >= 1.0 ? 'Achieved' : 'In Progress',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: percentUsed >= 1.0 ? context.emerald : context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.south_east_rounded, size: 16),
                label: Text(
                  'Deposit',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showDepositWithdrawSheet(context, currentGoal, true, amountSaved),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(Icons.north_east_rounded, size: 16, color: context.textPrimary),
                label: Text(
                  'Withdraw',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.cardBg,
                  side: BorderSide(color: context.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showDepositWithdrawSheet(context, currentGoal, false, amountSaved),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showEditGoalDialog(context, currentGoal),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 15, color: context.gold),
                        const SizedBox(width: 6),
                        Text(
                          'Modify Goal',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.gold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 16, color: context.line),
                const SizedBox(width: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await planProvider.update(currentGoal.copyWith(isArchived: true));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Goal completed and archived!'), backgroundColor: context.emerald),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 15, color: context.emerald),
                        const SizedBox(width: 6),
                        Text(
                          'Complete Goal',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.emerald),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Structured Metadata Card
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFactualRow(context, 'WHOLE TARGET', CurrencyFormatter.format(currentGoal.totalBudget)),
                  Divider(color: context.line, height: 20),
                  _buildFactualRow(context, 'PERSONAL SAVINGS TARGET', CurrencyFormatter.format(currentGoal.totalBudget)),
                  Divider(color: context.line, height: 20),
                  _buildFactualRow(context, 'DEADLINE', DateFormatter.format(currentGoal.endDate)),
                  Divider(color: context.line, height: 20),
                  _buildFactualRow(context, 'STATUS', percentUsed >= 1.0 ? 'Completed' : 'In progress'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Funding History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FUNDING HISTORY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: context.gold,
                  ),
                ),
                Text(
                  '${planExpenses.length} RECORDS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (planExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No funding movements recorded yet.',
                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: planExpenses.length,
                itemBuilder: (context, index) {
                  final exp = planExpenses[index];
                  final isExpense = exp.type == CategoryType.expense;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: context.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exp.title,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.format(exp.date),
                              style: GoogleFonts.inter(color: context.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        Text(
                          '${isExpense ? '+' : '-'} ${CurrencyFormatter.format(exp.amount)}',
                          style: GoogleFonts.spaceGrotesk(
                            color: isExpense ? context.emerald : context.brick,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFactualRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: context.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showDepositWithdrawSheet(BuildContext context, Goal goal, bool isDeposit, double currentSaved) {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: ctx.line),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDeposit ? 'Deposit to ${goal.title}' : 'Withdraw from ${goal.title}',
                  style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: ctx.textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: ctx.textMuted, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold, color: ctx.textPrimary),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: GoogleFonts.inter(color: ctx.textMuted),
                hintText: '0.00',
                hintStyle: GoogleFonts.spaceGrotesk(color: ctx.textMuted),
                filled: true,
                fillColor: ctx.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ctx.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ctx.line),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDeposit ? ctx.emerald : ctx.brick,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                HapticsService.lightImpact();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amount <= 0) return;
                Navigator.pop(ctx);
                final expenseProvider = context.read<ExpenseProvider>();
                final accountProvider = context.read<AccountProvider>();
                final defaultAccount = accountProvider.accounts.firstWhere((a) => a.isDefault, orElse: () => accountProvider.accounts.first);
                final expense = Expense(
                  id: const Uuid().v4(),
                  title: isDeposit ? 'Goal Deposit: ${goal.title}' : 'Goal Withdrawal: ${goal.title}',
                  amount: amount,
                  categoryId: goal.categoryIds.isNotEmpty ? goal.categoryIds.first : 'investment',
                  date: DateTime.now(),
                  note: isDeposit ? 'Deposit to ${goal.title}' : 'Withdrawal from ${goal.title}',
                  accountId: defaultAccount.id,
                  planId: goal.id,
                  type: isDeposit ? CategoryType.expense : CategoryType.income,
                );
                await expenseProvider.addExpense(expense);
              },
              child: Text(
                isDeposit ? 'Confirm Deposit' : 'Confirm Withdrawal',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    final titleController = TextEditingController(text: goal.title);
    final targetController = TextEditingController(text: goal.totalBudget.toStringAsFixed(0));
    DateTime selectedEndDate = goal.endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: ctx.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: ctx.line),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Modify Goal', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
                  IconButton(icon: Icon(Icons.close, color: ctx.textMuted), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: GoogleFonts.inter(color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  labelStyle: GoogleFonts.inter(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ctx.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ctx.line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.spaceGrotesk(color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  labelStyle: GoogleFonts.inter(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ctx.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: ctx.line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Target Date: ${DateFormatter.format(selectedEndDate)}', style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary)),
                trailing: Icon(Icons.calendar_month, color: ctx.gold),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedEndDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedEndDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  HapticsService.lightImpact();
                  final newTarget = double.tryParse(targetController.text.trim()) ?? goal.totalBudget;
                  final newTitle = titleController.text.trim();
                  if (newTitle.isEmpty) return;
                  Navigator.pop(ctx);
                  final goalProvider = context.read<GoalProvider>();
                  await goalProvider.update(goal.copyWith(
                    title: newTitle,
                    totalBudget: newTarget,
                    endDate: selectedEndDate,
                  ));
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
