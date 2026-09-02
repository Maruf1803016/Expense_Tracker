import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class TripPlanDetailPage extends StatelessWidget {
  final TripPlan plan;

  const TripPlanDetailPage({super.key, required this.plan});

  Future<void> _deletePlanFlow(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: context.line),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Remove Trip Plan?', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.brick)),
        content: Text('Remove plan "${plan.title}"?\n\nAll transactions linked to this plan will remain untouched in your ledger.', style: GoogleFonts.inter(color: context.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.brick, foregroundColor: Colors.white),
            child: const Text('Remove Plan & Retain Transactions'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final navigator = Navigator.of(context);
      final expenseProvider = context.read<ExpenseProvider>();
      final planProvider = context.read<TripPlanProvider>();

      await expenseProvider.orphanPlanExpenses(plan.id);
      await planProvider.delete(plan.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trip plan "${plan.title}" removed'), backgroundColor: AppTheme.emerald),
        );
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final planProvider = context.watch<TripPlanProvider>();
    final matching = planProvider.tripPlans.where((p) => p.id == plan.id).toList();
    final currentPlan = matching.isNotEmpty ? matching.first : plan;
    final expenses = expenseProvider.expenses;
    final planExpenses = expenses.where((e) => e.planId == currentPlan.id && !e.isDeleted).toList();
    final amountSpent = planExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final remaining = (currentPlan.budgetAmount - amountSpent).clamp(0.0, double.infinity);
    final double percentUsed = currentPlan.budgetAmount > 0 ? (amountSpent / currentPlan.budgetAmount) : 0.0;

    final dateStr = currentPlan.endDate != null
        ? '${DateFormatter.format(currentPlan.startDate)} - ${DateFormatter.format(currentPlan.endDate!)}'
        : DateFormatter.format(currentPlan.startDate);

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
            tooltip: 'Delete plan',
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
              'TRIP & EVENT PLAN',
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
              currentPlan.title,
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
                        dateStr,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.gold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (percentUsed > 1.0 ? context.brick : context.emerald).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          percentUsed > 1.0 ? 'OVER BUDGET' : (percentUsed >= 1.0 ? 'FULLY SPENT' : 'ACTIVE'),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: percentUsed > 1.0 ? context.brick : context.emerald,
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
                        CurrencyFormatter.format(amountSpent),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'spent of ${CurrencyFormatter.format(currentPlan.budgetAmount)}',
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
                      color: percentUsed > 1.0 ? context.brick : context.gold,
                      backgroundColor: context.line.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${planExpenses.length} linked ${planExpenses.length == 1 ? 'expense' : 'expenses'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.format(remaining)} remaining',
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
                  _buildFactualRow(context, 'WORKING BUDGET', CurrencyFormatter.format(currentPlan.budgetAmount)),
                  Divider(color: context.line, height: 20),
                  _buildFactualRow(context, 'DATES', dateStr),
                  Divider(color: context.line, height: 20),
                  _buildFactualRow(context, 'LINKED SPEND', '${planExpenses.length} records'),
                  Divider(color: context.line, height: 20),
                  _buildFactualRow(context, 'BUDGET HEALTH', percentUsed > 1.0 ? 'Over limit' : '${((1 - percentUsed.clamp(0.0, 1.0)) * 100).toStringAsFixed(0)}% available'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: Text(
                  'Add Linked Expense',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  HapticsService.selection();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpensePage(preselectedPlanId: currentPlan.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(Icons.edit_outlined, size: 16, color: context.textPrimary),
                label: Text(
                  'Modify Plan',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.cardBg,
                  side: BorderSide(color: context.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  HapticsService.selection();
                  _showEditPlanDialog(context, currentPlan);
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    HapticsService.lightImpact();
                    await planProvider.delete(currentPlan.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Trip plan completed!'), backgroundColor: context.emerald),
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
                          'Complete Plan',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.emerald),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Linked Spend History
            Text(
              'LINKED EXPENSES',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.gold,
              ),
            ),
            const SizedBox(height: 12),
            if (planExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No expenses linked to this plan yet.',
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
                          CurrencyFormatter.format(exp.amount),
                          style: GoogleFonts.spaceGrotesk(
                            color: context.brick,
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

  void _showEditPlanDialog(BuildContext context, TripPlan plan) {
    final titleController = TextEditingController(text: plan.title);
    final budgetController = TextEditingController(text: plan.budgetAmount.toStringAsFixed(0));
    DateTime startDate = plan.startDate;
    DateTime? endDate = plan.endDate;

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
                  Text('Modify Plan', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
                  IconButton(icon: Icon(Icons.close, color: ctx.textMuted), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: GoogleFonts.inter(color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Plan Title',
                  labelStyle: GoogleFonts.inter(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.spaceGrotesk(color: ctx.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  labelStyle: GoogleFonts.inter(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Dates: ${DateFormatter.format(startDate)}${endDate != null ? ' - ${DateFormatter.format(endDate)}' : ''}',
                  style: GoogleFonts.inter(fontSize: 13, color: ctx.textPrimary),
                ),
                trailing: Icon(Icons.calendar_month, color: ctx.gold),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setSheetState(() => startDate = picked);
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
                  final newBudget = double.tryParse(budgetController.text.trim()) ?? plan.budgetAmount;
                  final newTitle = titleController.text.trim();
                  if (newTitle.isEmpty) return;
                  Navigator.pop(ctx);
                  final planProvider = context.read<TripPlanProvider>();
                  await planProvider.update(plan.copyWith(
                    title: newTitle,
                    budgetAmount: newBudget,
                    startDate: startDate,
                    endDate: endDate,
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
