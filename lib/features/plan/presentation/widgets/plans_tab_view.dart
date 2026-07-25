import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/plan/presentation/pages/plan_detail_page.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';

class PlansTabView extends StatefulWidget {
  const PlansTabView({super.key});

  @override
  State<PlansTabView> createState() => _PlansTabViewState();
}

class _PlansTabViewState extends State<PlansTabView> {
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

  Widget _buildSummaryHeader(List<Plan> plans, List<Expense> expenses) {
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
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Goals Progress',
                style: GoogleFonts.inter(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeGoalsCount Active',
                  style: GoogleFonts.inter(color: AppTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Saved', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalSaved),
                    style: GoogleFonts.spaceGrotesk(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Target Total', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(targetTotal),
                    style: GoogleFonts.spaceGrotesk(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              minHeight: 8,
              color: AppTheme.emerald,
              backgroundColor: AppTheme.paper2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(overallProgress * 100).toStringAsFixed(0)}% of target saved',
            style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final plans = planProvider.plans.where((p) => !p.isArchived).toList();
    final expenses = expenseProvider.expenses;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0, right: 8.0),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddExpensePage(preselectedPlanMode: true),
                  ),
                );
              },
              backgroundColor: AppTheme.ink,
              child: const Icon(Icons.add, color: AppTheme.goldSoft),
            ),
          ),
          body: planProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
              : Column(
                  children: [
                    if (plans.isNotEmpty) _buildSummaryHeader(plans, expenses),
                    Expanded(
                      child: plans.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              itemCount: plans.length,
                              itemBuilder: (context, index) {
                                final plan = plans[index];
                                final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted).toList();
                                
                                final amountSaved = planExpenses.fold<double>(0.0, (sum, e) => e.type == CategoryType.expense ? sum + e.amount : sum - e.amount);
                                final remaining = plan.totalBudget - amountSaved;
                                final double percentUsed = plan.totalBudget > 0 ? (amountSaved / plan.totalBudget) : 0.0;
                                final monthlyNeeded = _getMonthlyNeededText(remaining, plan.endDate);
                                
                                Color progressColor;
                                if (percentUsed < 0.8) {
                                  progressColor = AppTheme.emerald;
                                } else if (percentUsed <= 1.0) {
                                  progressColor = AppTheme.gold;
                                } else {
                                  progressColor = AppTheme.brick;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.paperCard,
                                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                    border: Border.all(color: AppTheme.line),
                                  ),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(AppTheme.cardRadius),
                                          topRight: Radius.circular(AppTheme.cardRadius),
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => PlanDetailPage(plan: plan),
                                            ),
                                          );
                                        },
                                        onLongPress: () => _showDeleteGoalDialog(context, plan),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                                                        color: AppTheme.textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    percentUsed >= 1.0 ? 'Completed' : '${(percentUsed * 100).toStringAsFixed(0)}%',
                                                    style: GoogleFonts.spaceGrotesk(
                                                      color: progressColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (plan.note.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  plan.note,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppTheme.muted,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Saved', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 10)),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        CurrencyFormatter.format(amountSaved),
                                                        style: GoogleFonts.spaceGrotesk(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text('Goal Target', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 10)),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        CurrencyFormatter.format(plan.totalBudget),
                                                        style: GoogleFonts.spaceGrotesk(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: LinearProgressIndicator(
                                                  value: percentUsed.clamp(0.0, 1.0),
                                                  minHeight: 6,
                                                  color: progressColor,
                                                  backgroundColor: AppTheme.paper2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Target: ${DateFormatter.format(plan.endDate)}',
                                                    style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 10),
                                                  ),
                                                  if (percentUsed < 1.0)
                                                    Text(
                                                      'Monthly needed: $monthlyNeeded',
                                                      style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.add_rounded, size: 18),
                                              label: const Text('Deposit'),
                                              style: TextButton.styleFrom(foregroundColor: AppTheme.emerald),
                                              onPressed: () => _showDepositWithdrawSheet(context, plan, true, amountSaved),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.remove_rounded, size: 18),
                                              label: const Text('Withdraw'),
                                              style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
                                              onPressed: () => _showDepositWithdrawSheet(context, plan, false, amountSaved),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.history_rounded, size: 18),
                                              label: const Text('History'),
                                              style: TextButton.styleFrom(foregroundColor: AppTheme.gold),
                                              onPressed: () => _showHistorySheet(context, plan, planExpenses),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.track_changes_rounded, size: 64, color: AppTheme.gold),
          ),
          const SizedBox(height: 24),
          Text(
            'No Goals Yet',
            style: GoogleFonts.fraunces(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Set dynamic goals with fixed date ranges and track specific projects, events, or trips.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.muted),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteGoalDialog(BuildContext context, Plan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete goal "${plan.title}"? linked transactions will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final planProvider = context.read<PlanProvider>();
              final expenseProvider = context.read<ExpenseProvider>();
              await expenseProvider.orphanPlanExpenses(plan.id);
              await planProvider.delete(plan.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDepositWithdrawSheet(BuildContext context, Plan plan, bool isDeposit, double currentSaved) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DepositWithdrawModal(
        plan: plan,
        isDeposit: isDeposit,
        currentSaved: currentSaved,
        confettiController: _confettiController,
      ),
    );
  }

  void _showHistorySheet(BuildContext context, Plan plan, List<Expense> planExpenses) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: AppTheme.paperCard,
      builder: (context) {
        final sortedHistory = List<Expense>.from(planExpenses)
          ..sort((a, b) => b.date.compareTo(a.date));

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${plan.title} History',
                    style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: sortedHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No history logged yet.',
                          style: GoogleFonts.inter(color: AppTheme.muted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedHistory.length,
                        itemBuilder: (context, index) {
                          final exp = sortedHistory[index];
                          final isExpense = exp.type == CategoryType.expense;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.paperCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: ListTile(
                              leading: Icon(
                                isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isExpense ? AppTheme.brick : AppTheme.emerald,
                              ),
                              title: Text(exp.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                              subtitle: Text(
                                DateFormatter.format(exp.date),
                                style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11),
                              ),
                              trailing: Text(
                                '${isExpense ? '+' : '-'} ${CurrencyFormatter.format(exp.amount)}',
                                style: GoogleFonts.spaceGrotesk(
                                  color: isExpense ? AppTheme.emerald : AppTheme.brick, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DepositWithdrawModal extends StatefulWidget {
  final Plan plan;
  final bool isDeposit;
  final double currentSaved;
  final ConfettiController confettiController;

  const _DepositWithdrawModal({
    required this.plan,
    required this.isDeposit,
    required this.currentSaved,
    required this.confettiController,
  });

  @override
  State<_DepositWithdrawModal> createState() => _DepositWithdrawModalState();
}

class _DepositWithdrawModalState extends State<_DepositWithdrawModal> {
  String _amountStr = '';

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currentSymbol;
    final displayAmount = _amountStr.isEmpty ? '0' : _amountStr;
    final enteredAmount = double.tryParse(_amountStr) ?? 0.0;
    
    final double futureSaved = widget.isDeposit 
        ? widget.currentSaved + enteredAmount
        : (widget.currentSaved - enteredAmount).clamp(0.0, double.infinity);

    final presetChips = currencySymbol == '৳'
        ? [500.0, 1000.0, 2000.0, 5000.0]
        : [50.0, 100.0, 200.0, 500.0];

    final displayColor = widget.isDeposit ? AppTheme.emerald : AppTheme.brick;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isDeposit ? 'Deposit to ${widget.plan.title}' : 'Withdraw from ${widget.plan.title}',
                style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.muted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$currencySymbol $displayAmount',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: displayColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preset chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: presetChips.map((preset) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ActionChip(
                    backgroundColor: AppTheme.paperCard,
                    side: const BorderSide(color: AppTheme.line),
                    label: Text(
                      currencySymbol + preset.toStringAsFixed(0),
                      style: GoogleFonts.inter(color: AppTheme.textDark, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      setState(() {
                        _amountStr = preset.toStringAsFixed(0);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Progress', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(widget.currentSaved),
                      style: GoogleFonts.spaceGrotesk(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_rounded, color: AppTheme.muted),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('New Progress', style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(futureSaved),
                      style: GoogleFonts.spaceGrotesk(color: displayColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Custom on-screen Numpad (Space Grotesk typography)
          _buildNumpad(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: enteredAmount > 0 ? () => _confirmAction(context, enteredAmount) : null,
            child: Text(
              widget.isDeposit ? 'Confirm Deposit' : 'Confirm Withdrawal',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Table(
      children: keys.map((row) {
        return TableRow(
          children: row.map((key) {
            final isBack = key == '⌫';
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: InkWell(
                onTap: () => _handleNumpadPress(key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.paper2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: isBack
                      ? const Icon(Icons.backspace_outlined, size: 18, color: AppTheme.textDark)
                      : Text(
                          key,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  void _handleNumpadPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) {
          if (_amountStr.isEmpty) {
            _amountStr = '0.';
          } else {
            _amountStr += '.';
          }
        }
      } else {
        if (_amountStr.length >= 8) return;
        if (_amountStr.contains('.')) {
          final dotIndex = _amountStr.indexOf('.');
          if (_amountStr.substring(dotIndex + 1).length >= 2) {
            return;
          }
        }
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          _amountStr += key;
        }
      }
    });
  }

  Future<void> _confirmAction(BuildContext context, double amount) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);
    
    final double savedBeforeThisDeposit = widget.currentSaved;
    final double savedAfterThisDeposit = widget.isDeposit
        ? widget.currentSaved + amount
        : (widget.currentSaved - amount).clamp(0.0, double.infinity);

    final wasFull = (savedBeforeThisDeposit >= widget.plan.totalBudget);
    final nowFull = (savedAfterThisDeposit >= widget.plan.totalBudget);

    final String txTitle = widget.isDeposit
        ? 'Deposit to ${widget.plan.title}'
        : 'Withdrawal from ${widget.plan.title}';

    final tx = Expense(
      id: const Uuid().v4(),
      title: txTitle,
      amount: amount,
      categoryId: widget.plan.categoryIds.isNotEmpty ? widget.plan.categoryIds.first : 'investment',
      date: DateTime.now(),
      note: widget.isDeposit ? 'Goal deposit' : 'Goal withdrawal',
      type: widget.isDeposit ? CategoryType.expense : CategoryType.income,
      planId: widget.plan.id,
    );

    Navigator.pop(context);

    try {
      await expenseProvider.addExpense(tx);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.isDeposit ? 'Deposit successful' : 'Withdrawal successful'),
          backgroundColor: AppTheme.emerald,
        ),
      );

      if (widget.isDeposit && !wasFull && nowFull) {
        widget.confettiController.play();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.brick,
        ),
      );
    }
  }
}
