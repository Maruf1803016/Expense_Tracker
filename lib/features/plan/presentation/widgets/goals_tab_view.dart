import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/presentation/pages/goal_detail_page.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';

import 'package:uuid/uuid.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_add_card.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class GoalsTabView extends StatefulWidget {
  const GoalsTabView({super.key});

  @override
  State<GoalsTabView> createState() => _GoalsTabViewState();
}

class _GoalsTabViewState extends State<GoalsTabView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getMonthlyNeededText(double remaining, DateTime endDate) {
    if (remaining <= 0) return '—';
    final days = endDate.difference(DateTime.now()).inDays;
    if (days <= 0) return '—';
    final monthsLeft = days / 30.0;
    final needed = remaining / monthsLeft;
    return CurrencyFormatter.format(needed);
  }

  Widget _buildSummaryHeader(List<Goal> plans, List<Expense> expenses) {
    int activeGoalsCount = plans.length;
    double totalSaved = 0.0;
    double targetTotal = 0.0;

    for (var plan in plans) {
      final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted);
      final amountSaved = planExpenses.fold<double>(0.0, (sum, e) => e.type == CategoryType.expense ? sum + e.amount : sum - e.amount);
      totalSaved += amountSaved;
      targetTotal += plan.totalBudget;
    }

    final double overallProgress = targetTotal > 0 ? (totalSaved / targetTotal) : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
              Row(
                children: [
                  Icon(Icons.savings_outlined, color: context.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Savings Goals Progress',
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$activeGoalsCount Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.line),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL SAVED',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalSaved),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.emerald,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TARGET TOTAL',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(targetTotal),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              minHeight: 6,
              color: context.gold,
              backgroundColor: context.surface2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(overallProgress * 100).toStringAsFixed(0)}% of target saved',
            style: GoogleFonts.inter(color: context.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<GoalProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final plans = planProvider.plans.where((p) => !p.isArchived).toList();
    final expenses = expenseProvider.expenses;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: planProvider.isLoading && plans.isEmpty
              ? Center(child: CircularProgressIndicator(color: context.gold))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // 1. Main Summary Header Card
                    _buildSummaryHeader(plans, expenses),

                    // 2. Dedicated Add a Savings Goal Card (Under Main Card)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkLedgerAddCard(
                        title: 'Add a savings goal',
                        subtitle: 'Set target amount and deadline to track progress',
                        icon: Icons.savings_outlined,
                        buttonText: 'Add',
                        onTap: () {
                          HapticsService.selection();
                          _showAddGoalSheet(context);
                        },
                      ),
                    ),

                    // Section Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
                      child: Text(
                        'SAVINGS GOALS (${plans.length})',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: context.textMuted,
                        ),
                      ),
                    ),

                    if (plans.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...plans.map((plan) {
                        final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted).toList();
                        final amountSaved = planExpenses.fold<double>(0.0, (sum, e) => e.type == CategoryType.expense ? sum + e.amount : sum - e.amount);
                        final remaining = plan.totalBudget - amountSaved;
                        final double percentUsed = plan.totalBudget > 0 ? (amountSaved / plan.totalBudget) : 0.0;
                        final monthlyNeeded = _getMonthlyNeededText(remaining, plan.endDate);

                        Color progressColor;
                        if (percentUsed < 0.8) {
                          progressColor = context.emerald;
                        } else if (percentUsed <= 1.0) {
                          progressColor = context.gold;
                        } else {
                          progressColor = context.brick;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            border: Border.all(color: context.line),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            onTap: () {
                              HapticsService.selection();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GoalDetailPage(plan: plan),
                                ),
                              );
                            },
                            onLongPress: () => _showDeleteGoalDialog(context, plan),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          plan.title,
                                          style: GoogleFonts.fraunces(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            percentUsed >= 1.0 ? 'Completed' : '${(percentUsed * 100).toStringAsFixed(0)}%',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: progressColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline_rounded, color: context.brick, size: 18),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            onPressed: () => _showDeleteGoalDialog(context, plan),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (plan.note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      plan.note,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: context.textMuted,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Saved', style: GoogleFonts.inter(color: context.textMuted, fontSize: 10)),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.format(amountSaved),
                                            style: GoogleFonts.spaceGrotesk(color: context.emerald, fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      if (plan.financedAmount != null && plan.financedAmount! > 0)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text('Financed', style: GoogleFonts.inter(color: context.textMuted, fontSize: 10)),
                                            const SizedBox(height: 2),
                                            Text(
                                              CurrencyFormatter.format(plan.financedAmount!),
                                              style: GoogleFonts.spaceGrotesk(color: context.gold, fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Goal Target', style: GoogleFonts.inter(color: context.textMuted, fontSize: 10)),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.format(plan.totalBudget),
                                            style: GoogleFonts.spaceGrotesk(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: percentUsed.clamp(0.0, 1.0),
                                      minHeight: 6,
                                      color: progressColor,
                                      backgroundColor: context.surface2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Target: ${DateFormatter.format(plan.endDate)}',
                                        style: GoogleFonts.inter(color: context.textMuted, fontSize: 10),
                                      ),
                                      if (percentUsed < 1.0)
                                        Text(
                                          'Monthly needed: $monthlyNeeded',
                                          style: GoogleFonts.inter(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ),
      ],
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    final titleController = TextEditingController();
    final targetAmountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: ctx.line),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAVINGS GOAL',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: ctx.gold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'New Savings Goal',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ctx.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text('Goal Title', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                style: GoogleFonts.inter(color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Emergency Fund, House Downpayment',
                  hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Target Amount', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.spaceGrotesk(color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: '5000.00',
                  hintStyle: GoogleFonts.spaceGrotesk(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Target Deadline', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted)),
              const SizedBox(height: 6),
              StatefulBuilder(
                builder: (ctx, setModalState) => OutlinedButton.icon(
                  icon: Icon(Icons.calendar_today_rounded, size: 16, color: ctx.gold),
                  label: Text(DateFormatter.format(endDate), style: GoogleFonts.inter(color: ctx.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    backgroundColor: ctx.cardBg,
                    side: BorderSide(color: ctx.line),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: endDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setModalState(() => endDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text('Notes (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                style: GoogleFonts.inter(color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add details or motivation...',
                  hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctx.gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    HapticsService.lightImpact();
                    final title = titleController.text.trim();
                    final amount = double.tryParse(targetAmountController.text.trim());
                    if (title.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid title and target amount')),
                      );
                      return;
                    }

                    final newGoal = Goal(
                      id: const Uuid().v4(),
                      title: title,
                      totalBudget: amount,
                      startDate: startDate,
                      endDate: endDate,
                      note: noteController.text.trim(),
                      isArchived: false,
                      createdAt: DateTime.now(),
                    );

                    await context.read<GoalProvider>().add(newGoal);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Savings goal created'), backgroundColor: context.emerald),
                      );
                    }
                  },
                  child: const Text('Create Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.track_changes_rounded, size: 64, color: context.gold),
          ),
          const SizedBox(height: 24),
          Text(
            'No Goals Yet',
            style: GoogleFonts.fraunces(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Set dynamic goals with fixed date ranges and track specific projects, events, or trips.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteGoalDialog(BuildContext context, Goal plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Delete Goal', style: TextStyle(color: context.textPrimary)),
        content: Text(
          'Are you sure you want to delete goal "${plan.title}"? linked transactions will be kept.',
          style: TextStyle(color: context.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              HapticsService.lightImpact();
              Navigator.pop(context);
              final planProvider = context.read<GoalProvider>();
              final expenseProvider = context.read<ExpenseProvider>();
              await expenseProvider.orphanPlanExpenses(plan.id);
              await planProvider.delete(plan.id);
            },
            style: TextButton.styleFrom(foregroundColor: context.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
