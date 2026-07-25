import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';

class PlanDetailPage extends StatelessWidget {
  final Plan plan;

  const PlanDetailPage({super.key, required this.plan});

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
            style: TextButton.styleFrom(foregroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final expenseProvider = context.read<ExpenseProvider>();
      final planProvider = context.read<PlanProvider>();
      
      // 1. Orphan the linked expenses
      await expenseProvider.orphanPlanExpenses(plan.id);
      
      // 2. Delete the plan itself
      await planProvider.delete(plan.id);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('Goal "${plan.title}" deleted'),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );
      
      navigator.pop(); // Go back to the plans list
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.expenses;
    final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted).toList();
    final amountSpent = planExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final remaining = plan.totalBudget - amountSpent;
    final distinctCategoryIds = {
      ...plan.categoryIds,
      ...planExpenses.map((e) => e.categoryId),
    }.toList();
    final double percentUsed = plan.totalBudget > 0 ? (amountSpent / plan.totalBudget) : 0.0;

    Color progressColor;
    if (percentUsed < 0.8) {
      progressColor = AppTheme.emeraldGreen;
    } else if (percentUsed <= 1.0) {
      progressColor = Colors.amber;
    } else {
      progressColor = AppTheme.expenseColor;
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.expenseColor),
            onPressed: () => _deletePlanFlow(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormatter.format(plan.startDate)} - ${DateFormatter.format(plan.endDate)}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Overall Budget Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                color: AppTheme.secondaryBackground,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Total Budget', plan.totalBudget, Colors.white),
                          _buildStatItem('Spent', amountSpent, progressColor),
                          _buildStatItem('Remaining', remaining, remaining >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentUsed.clamp(0.0, 1.0),
                          minHeight: 10,
                          color: progressColor,
                          backgroundColor: progressColor.withOpacity(0.1),
                        ),
                      ),
                      if (percentUsed > 1.0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.expenseColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Over budget by ${CurrencyFormatter.format(amountSpent - plan.totalBudget)}',
                                style: const TextStyle(
                                  color: AppTheme.expenseColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Breakdown
              if (distinctCategoryIds.isNotEmpty) ...[
                const Text(
                  'Category Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  color: AppTheme.secondaryBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: distinctCategoryIds.asMap().entries.map((itemEntry) {
                        final idx = itemEntry.key;
                        final catId = itemEntry.value;
                        final category = expenseProvider.getCategoryById(catId);
                        final catExpenses = planExpenses.where((e) => e.categoryId == catId);
                        final catSpent = catExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                        final double catPercent = plan.totalBudget > 0 ? (catSpent / plan.totalBudget) : 0.0;
                        final catColor = AppTheme.getCategoryColor(catId, category.name);

                        return Padding(
                          padding: EdgeInsets.only(top: idx == 0 ? 0.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(category.icon, size: 16, color: catColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        category.name,
                                        style: const TextStyle(fontSize: 13, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${CurrencyFormatter.format(catSpent)} / ${CurrencyFormatter.format(plan.totalBudget)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: catPercent.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  color: catColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Recent Transactions list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.emeraldGreen),
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
              const SizedBox(height: 12),
              if (planExpenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No transactions logged under this goal yet.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: planExpenses.length,
                  itemBuilder: (context, index) {
                    final exp = planExpenses[index];
                    final category = expenseProvider.getCategoryById(exp.categoryId);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.secondaryBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.expenseColor.withOpacity(0.1),
                          child: Icon(category.icon, color: AppTheme.expenseColor),
                        ),
                        title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(
                          exp.subCategory ?? category.name,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                        ),
                        trailing: Text(
                          '- ${CurrencyFormatter.format(exp.amount)}',
                          style: const TextStyle(color: AppTheme.expenseColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: amountColor),
        ),
      ],
    );
  }
}
