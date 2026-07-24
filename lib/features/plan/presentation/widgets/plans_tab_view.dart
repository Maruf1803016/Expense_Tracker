import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';

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
                        borderRadius: BorderRadius.circular(20),
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                            if (plan.categoryIds.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 12),
                              const Text(
                                'Category Breakdown',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...plan.categoryIds.asMap().entries.map((itemEntry) {
                                final idx = itemEntry.key;
                                final catId = itemEntry.value;
                                final category = expenseProvider.getCategoryById(catId);
                                final catExpenses = planExpenses.where((e) => e.categoryId == catId);
                                final catSpent = catExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
                                final double catPercent = plan.totalBudget > 0 ? (catSpent / plan.totalBudget) : 0.0;
                                final catColor = ExpenseProvider.pieColors[idx % ExpenseProvider.pieColors.length];

                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(catPercent * 100).toStringAsFixed(1)}% of total budget',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
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
            child: const Icon(Icons.assignment_outlined, size: 64, color: AppTheme.emeraldGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Custom Plans Yet',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Set dynamic custom budgets with fixed date ranges and track specific projects or trips.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
