import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/plan/presentation/pages/plan_detail_page.dart';

class PlansTabView extends StatefulWidget {
  const PlansTabView({super.key});

  @override
  State<PlansTabView> createState() => _PlansTabViewState();
}

class _PlansTabViewState extends State<PlansTabView> {
  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final plans = planProvider.plans.where((p) => !p.isArchived).toList();
    final expenses = expenseProvider.expenses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: planProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen))
          : plans.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    
                    // Computed live spending
                    final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted);
                    final amountSpent = planExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                    final remaining = plan.totalBudget - amountSpent;
                    
                    final double percentUsed = plan.totalBudget > 0 ? (amountSpent / plan.totalBudget) : 0.0;
                    
                    Color progressColor;
                    if (percentUsed < 0.8) {
                      progressColor = AppTheme.emeraldGreen;
                    } else if (percentUsed <= 1.0) {
                      progressColor = Colors.amber;
                    } else {
                      progressColor = AppTheme.expenseColor;
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      color: AppTheme.secondaryBackground,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlanDetailPage(plan: plan),
                            ),
                          );
                        },
                        onLongPress: () async {
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
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
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
                                  IconButton(
                                    icon: const Icon(Icons.add_card_outlined, size: 20, color: AppTheme.emeraldGreen),
                                    tooltip: 'Add Expense to Plan',
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AddExpensePage(
                                            preselectedPlanId: plan.id,
                                            preselectedCategoryId: plan.categoryIds.isNotEmpty ? plan.categoryIds.first : null,
                                          ),
                                        ),
                                      );
                                    },
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Budget',
                                        style: TextStyle(fontSize: 12, color: Colors.white54),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(plan.totalBudget),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Spent',
                                        style: TextStyle(fontSize: 12, color: Colors.white54),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(amountSpent),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: progressColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Remaining',
                                        style: TextStyle(fontSize: 12, color: Colors.white54),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.format(remaining),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: remaining >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                                        ),
                                      ),
                                    ],
                                  ),
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
                              if (percentUsed > 1.0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.expenseColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Over budget by ${CurrencyFormatter.format(amountSpent - plan.totalBudget)}',
                                      style: TextStyle(
                                        color: AppTheme.expenseColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
