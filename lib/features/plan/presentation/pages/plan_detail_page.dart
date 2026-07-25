import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

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
      final planProvider = context.read<PlanProvider>();
      
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
    final expenses = expenseProvider.expenses;
    final planExpenses = expenses.where((e) => e.planId == plan.id && !e.isDeleted).toList();
    final amountSpent = planExpenses.fold<double>(0.0, (sum, e) => e.type == CategoryType.expense ? sum + e.amount : sum - e.amount);
    final remaining = plan.totalBudget - amountSpent;
    final distinctCategoryIds = {
      ...plan.categoryIds,
      ...planExpenses.map((e) => e.categoryId),
    }.toList();
    final double percentUsed = plan.totalBudget > 0 ? (amountSpent / plan.totalBudget) : 0.0;

    Color progressColor;
    if (percentUsed < 0.8) {
      progressColor = AppTheme.emerald;
    } else if (percentUsed <= 1.0) {
      progressColor = AppTheme.gold;
    } else {
      progressColor = AppTheme.brick;
    }

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(plan.title, style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.brick),
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
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.muted),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormatter.format(plan.startDate)} - ${DateFormatter.format(plan.endDate)}',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Overall Budget Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.paperCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Target Budget', plan.totalBudget, AppTheme.textDark),
                          _buildStatItem('Saved', amountSpent, progressColor),
                          _buildStatItem('Remaining', remaining, remaining >= 0 ? AppTheme.emerald : AppTheme.brick),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentUsed.clamp(0.0, 1.0),
                          minHeight: 8,
                          color: progressColor,
                          backgroundColor: AppTheme.paper2,
                        ),
                      ),
                      if (percentUsed > 1.0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.brick),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Over target by ${CurrencyFormatter.format(amountSpent - plan.totalBudget)}',
                                style: GoogleFonts.inter(
                                  color: AppTheme.brick,
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
              const SizedBox(height: 28),

              // Category Breakdown
              if (distinctCategoryIds.isNotEmpty) ...[
                Text(
                  'Category Breakdown',
                  style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.paperCard,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.line),
                  ),
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
                                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${CurrencyFormatter.format(catSpent)} / ${CurrencyFormatter.format(plan.totalBudget)}',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: catPercent.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppTheme.paper2,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Recent Transactions list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.emerald),
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
                      style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 13),
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
                    final catColor = AppTheme.getCategoryColor(category.id, category.name);
                    final isExpense = exp.type == CategoryType.expense;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.paperCard,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(category.icon, color: catColor, size: 20),
                        ),
                        title: Text(exp.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14)),
                        subtitle: Text(
                          exp.subCategory ?? category.name,
                          style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11),
                        ),
                        trailing: Text(
                          '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(exp.amount)}',
                          style: GoogleFonts.spaceGrotesk(
                            color: isExpense ? AppTheme.brick : AppTheme.emerald, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: amountColor),
        ),
      ],
    );
  }
}
