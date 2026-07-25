import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/budget/domain/entities/category_budget_status.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/income_expense_bar_chart.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/spending_pie_chart.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/monthly_summary.dart';

class MonthlySummaryPage extends StatelessWidget {
  const MonthlySummaryPage({super.key});

  void _showExportOptions(BuildContext context, ExpenseProvider expenseProvider, ExportProvider exportProvider) {
    final selectedDate = expenseProvider.selectedMonth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Export Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              
              _buildOptionHeader('This Month (${DateFormatter.monthYear(selectedDate)})'),
              ListTile(
                leading: const Icon(Icons.table_view_rounded, color: Colors.green),
                title: const Text('CSV Spreadsheet'),
                onTap: () async {
                  Navigator.pop(context);
                  await exportProvider.exportMonth(
                    month: selectedDate.month,
                    year: selectedDate.year,
                    format: ExportFormat.csv,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                title: const Text('PDF Professional Report'),
                onTap: () async {
                  Navigator.pop(context);
                  await exportProvider.exportMonth(
                    month: selectedDate.month,
                    year: selectedDate.year,
                    format: ExportFormat.pdf,
                  );
                },
              ),

              const Divider(),

              _buildOptionHeader('Bulk Export'),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: Colors.blue),
                title: const Text('Last 3 Months (PDFs)'),
                subtitle: const Text('Package of reports for recent history'),
                onTap: () async {
                  Navigator.pop(context);
                  await exportProvider.exportLast3Months(
                    currentMonth: selectedDate,
                    format: ExportFormat.pdf,
                  );
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSavingsCard(BuildContext context, MonthlySummary summary) {
    final double net = summary.netBalance;
    final bool isSaved = net >= 0;
    final Color accentColor = isSaved ? AppTheme.incomeColor : AppTheme.expenseColor;
    final IconData icon = isSaved ? Icons.savings_rounded : Icons.trending_down_rounded;
    final String statusText = isSaved ? 'Net Savings' : 'Net Loss';
    final String message = isSaved 
        ? 'Great job! You saved ${CurrencyFormatter.format(net)} this month.' 
        : 'You spent ${CurrencyFormatter.format(net.abs())} more than your income.';

    return Card(
      elevation: 0,
      color: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: accentColor.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              statusText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(net),
              style: TextStyle(
                color: accentColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildBudgetDetailItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final exportProvider = context.watch<ExportProvider>();
    final summary = provider.summary;
    final selectedMonth = provider.selectedMonth;

    if (exportProvider.isExporting) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
    }

    if (provider.isLoading && provider.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
    }

    if (summary.totalIncome == 0 && summary.totalExpense == 0) {
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
              child: const Icon(Icons.bar_chart_rounded, size: 64, color: AppTheme.emeraldGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Summary Available',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start adding expenses to see your monthly breakdown and budget progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildMonthSelector(context, provider, selectedMonth)),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _showExportOptions(context, provider, exportProvider),
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Export Report',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHeroSavingsCard(context, summary),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'Spending Insights'),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SpendingPieChart(),
                  SizedBox(height: 32),
                  Divider(),
                  SizedBox(height: 16),
                  IncomeExpenseBarChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'Financial Totals'),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context,
            title: 'Net Balance',
            amount: summary.netBalance,
            color: summary.netBalance >= 0 
                ? AppTheme.incomeColor 
                : AppTheme.expenseColor,
            isMain: true,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Income',
                  amount: summary.totalIncome,
                  color: AppTheme.incomeColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Expense',
                  amount: summary.totalExpense,
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          _buildSectionHeader(context, 'Category Breakdown'),
          const SizedBox(height: 16),

          if (provider.rolledUpCategoryBreakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text('No data for this month', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: provider.rolledUpCategoryBreakdown.entries.toList().asMap().entries.map((e) {
                    final index = e.key;
                    final entry = e.value;
                    final category = provider.getCategoryById(entry.key);
                    final total = summary.totalIncome + summary.totalExpense;
                    final percentage = total > 0 ? (entry.value / total) : 0.0;
                    final catColor = AppTheme.getCategoryColor(category.id, category.name);
                    
                    final budgetStatus = provider.rolledUpBudgetStatuses.firstWhere(
                      (b) => b.categoryId == category.id,
                      orElse: () => CategoryBudgetStatus.fromAmounts(
                        categoryId: category.id,
                        categoryName: category.name,
                        limit: 0.0,
                        spent: entry.value,
                        month: selectedMonth.month,
                        year: selectedMonth.year,
                      ),
                    );
                    final double? budgetLimit = (category.type == CategoryType.expense && budgetStatus.limit > 0) ? budgetStatus.limit : null;
                    final double progressValue = budgetLimit != null ? (entry.value / budgetLimit).clamp(0.0, 1.0) : percentage;
                    final Color progressBarColor = budgetLimit != null 
                        ? (entry.value > budgetLimit ? AppTheme.expenseColor : AppTheme.emeraldGreen) 
                        : catColor;
                    
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                category.icon,
                                color: catColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        category.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        budgetLimit != null
                                            ? '${CurrencyFormatter.format(entry.value)} / ${CurrencyFormatter.format(budgetLimit)} (budget)'
                                            : CurrencyFormatter.format(entry.value),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progressValue,
                                      minHeight: 8,
                                      backgroundColor: Colors.white.withOpacity(0.05),
                                      color: progressBarColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    budgetLimit != null
                                        ? '${(entry.value / budgetLimit * 100).toStringAsFixed(0)}% of budget · ${(percentage * 100).toStringAsFixed(1)}% of total spending'
                                        : '${(percentage * 100).toStringAsFixed(1)}% of total spending',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, ExpenseProvider provider, DateTime date) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final newDate = DateTime(date.year, date.month - 1);
                provider.changeMonth(newDate);
              },
            ),
            Text(
              DateFormatter.monthYear(date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final newDate = DateTime(date.year, date.month + 1);
                provider.changeMonth(newDate);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    bool isMain = false,
  }) {
    return Card(
      elevation: isMain ? 4 : 1,
      child: Padding(
        padding: EdgeInsets.all(isMain ? 24.0 : 16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isMain ? 16 : 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                color: color,
                fontSize: isMain ? 32 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }



}
