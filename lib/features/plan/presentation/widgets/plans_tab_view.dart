import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
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
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBackground,
            AppTheme.secondaryBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Goals Progress',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$activeGoalsCount Active',
                  style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold),
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
                  const Text('Total Saved', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalSaved),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Target Total', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(targetTotal),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
              color: AppTheme.emeraldGreen,
              backgroundColor: AppTheme.emeraldGreen.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(overallProgress * 100).toStringAsFixed(0)}% of target saved',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
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
          body: planProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))
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
                                
                                // Computed dynamic saved progress (Expense is deposit, Income is withdrawal)
                                final amountSaved = planExpenses.fold<double>(0.0, (sum, e) => e.type == CategoryType.expense ? sum + e.amount : sum - e.amount);
                                final remaining = plan.totalBudget - amountSaved;
                                final double percentUsed = plan.totalBudget > 0 ? (amountSaved / plan.totalBudget) : 0.0;
                                final monthlyNeeded = _getMonthlyNeededText(remaining, plan.endDate);
                                
                                Color progressColor;
                                if (percentUsed < 0.8) {
                                  progressColor = AppTheme.emeraldGreen;
                                } else if (percentUsed <= 1.0) {
                                  progressColor = Colors.amber;
                                } else {
                                  progressColor = Colors.amber; // Caps at positive progress color
                                }

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  color: AppTheme.secondaryBackground,
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
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    percentUsed >= 1.0 ? 'Completed' : '${(percentUsed * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
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
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white.withOpacity(0.5),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.4)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${DateFormatter.format(plan.startDate)} - ${DateFormatter.format(plan.endDate)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white.withOpacity(0.4),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  _buildStatColumn('Target', CurrencyFormatter.format(plan.totalBudget)),
                                                  _buildStatColumn('Saved', CurrencyFormatter.format(amountSaved), valueColor: progressColor),
                                                  _buildStatColumn('Remaining', CurrencyFormatter.format(remaining.clamp(0.0, double.infinity))),
                                                  _buildStatColumn('Monthly Needed', monthlyNeeded),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: LinearProgressIndicator(
                                                  value: percentUsed.clamp(0.0, 1.0),
                                                  minHeight: 8,
                                                  color: progressColor,
                                                  backgroundColor: progressColor.withOpacity(0.1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1, color: Colors.white10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppTheme.emeraldGreen.withOpacity(0.15),
                                                  foregroundColor: AppTheme.emeraldGreen,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                icon: const Icon(Icons.add, size: 16),
                                                label: const Text('Add Money', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                onPressed: () => _showDepositWithdrawSheet(context, plan, true, amountSaved),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppTheme.expenseColor,
                                                  side: BorderSide(color: amountSaved > 0 ? AppTheme.expenseColor.withOpacity(0.4) : Colors.white10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                icon: const Icon(Icons.remove, size: 16),
                                                label: const Text('Withdraw', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                onPressed: amountSaved > 0
                                                    ? () => _showDepositWithdrawSheet(context, plan, false, amountSaved)
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.history_rounded, size: 20, color: Colors.white60),
                                              tooltip: 'Goal History',
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
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteGoalDialog(BuildContext context, Plan plan) async {
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final expenseProvider = context.read<ExpenseProvider>();
      final planProvider = context.read<PlanProvider>();
      final messenger = ScaffoldMessenger.of(context);
      await expenseProvider.orphanPlanExpenses(plan.id);
      await planProvider.delete(plan.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Goal "${plan.title}" deleted'),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );
    }
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
      backgroundColor: AppTheme.secondaryBackground,
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: sortedHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No transaction history yet',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedHistory.length,
                        itemBuilder: (context, idx) {
                          final tx = sortedHistory[idx];
                          final isDeposit = tx.type == CategoryType.expense; // expense represents deposit

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDeposit ? AppTheme.emeraldGreen : AppTheme.expenseColor).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDeposit ? Icons.add_rounded : Icons.remove_rounded,
                                color: isDeposit ? AppTheme.emeraldGreen : AppTheme.expenseColor,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              isDeposit ? 'Deposit' : 'Withdrawal',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, yyyy · h:mm a').format(tx.date),
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                            trailing: Text(
                              (isDeposit ? '+' : '-') + CurrencyFormatter.format(tx.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDeposit ? AppTheme.emeraldGreen : AppTheme.expenseColor,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.track_changes_rounded, size: 64, color: AppTheme.emeraldGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Goals Yet',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Set dynamic goals with fixed date ranges and track specific projects, events, or trips.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
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

    final displayColor = widget.isDeposit ? AppTheme.emeraldGreen : AppTheme.expenseColor;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
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
                style: TextStyle(
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
                    backgroundColor: AppTheme.secondaryBackground,
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    label: Text(
                      currencySymbol + preset.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
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
              color: AppTheme.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Effect on Savings', style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text(
                  '${CurrencyFormatter.format(widget.currentSaved)} → ${CurrencyFormatter.format(futureSaved)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // custom numpad
          _buildNumpad(),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: displayColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: enteredAmount > 0
                ? () => _confirmAction(context, enteredAmount)
                : null,
            child: Text(
              widget.isDeposit ? 'Add Money' : 'Withdraw',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        _buildNumpadRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildNumpadRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildNumpadRow(['7', '8', '9']),
        const SizedBox(height: 8),
        _buildNumpadRow(['.', '0', 'backspace']),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        final isBackspace = key == 'backspace';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: AspectRatio(
              aspectRatio: 2.0,
              child: InkWell(
                onTap: () => _handleNumpadTap(key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: isBackspace
                      ? const Icon(Icons.backspace_outlined, color: Colors.white70, size: 18)
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleNumpadTap(String key) {
    setState(() {
      if (key == 'backspace') {
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

    // Deposit is saved as CategoryType.expense (reduces net balance, increases goal saved progress)
    // Withdrawal is saved as CategoryType.income (increases net balance, decreases goal saved progress)
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

    Navigator.pop(context); // Close sheet immediately to show confetti clearly

    try {
      await expenseProvider.addExpense(tx);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.isDeposit ? 'Deposit successful' : 'Withdrawal successful'),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );

      // Trigger confetti celebrate if goal becomes complete on this deposit
      if (widget.isDeposit && !wasFull && nowFull) {
        widget.confettiController.play();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.expenseColor,
        ),
      );
    }
  }
}
