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

  Widget _buildTotalBudgetOverview(BuildContext context, ExpenseProvider provider) {
    // Priority: Global monthly budget from SettingsProvider, then sum of category budgets
    final settingsProvider = context.watch<SettingsProvider>();
    final double totalBudget = settingsProvider.budget > 0 
        ? settingsProvider.budget 
        : provider.rolledUpBudgetStatuses.fold(0.0, (sum, item) => sum + item.limit);
    
    final double totalSpent = provider.summary.totalExpense;
    final double progress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final double efficiency = totalBudget > 0 ? ((1 - (totalSpent / totalBudget)) * 100).clamp(0.0, 100.0) : 0.0;
    final bool isOver = totalBudget > 0 && totalSpent > totalBudget;

    return Card(
      elevation: 0,
      color: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Monthly Budget', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalBudget),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isOver ? AppTheme.expenseColor : AppTheme.incomeColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOver ? 'Over Budget' : 'On Track',
                    style: TextStyle(
                      color: isOver ? AppTheme.expenseColor : AppTheme.incomeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: isOver ? AppTheme.expenseColor : AppTheme.incomeColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${efficiency.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Efficiency',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildBudgetDetailItem('Spent', totalSpent, isOver ? AppTheme.expenseColor : Colors.white),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                _buildBudgetDetailItem(
                  isOver ? 'Over By' : 'Remaining',
                  (totalBudget - totalSpent).abs(),
                  isOver ? AppTheme.expenseColor : AppTheme.incomeColor,
                ),
              ],
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
          _buildTotalBudgetOverview(context, provider),
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

          _buildSectionHeader(context, 'Monthly Budgets'),
          const SizedBox(height: 16),
          if (provider.rolledUpBudgetStatuses.isEmpty)
            const Center(child: Text('Add categories to start budgeting'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: provider.rolledUpBudgetStatuses.length,
              itemBuilder: (context, index) => _buildBudgetTile(context, provider, provider.rolledUpBudgetStatuses[index]),
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
                    
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: ExpenseProvider.pieColors[index % ExpenseProvider.pieColors.length].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                category.icon,
                                color: ExpenseProvider.pieColors[index % ExpenseProvider.pieColors.length],
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
                                        CurrencyFormatter.format(entry.value),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 8,
                                      backgroundColor: Colors.white.withOpacity(0.05),
                                      color: ExpenseProvider.pieColors[index % ExpenseProvider.pieColors.length],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(1)}% of total spending',
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


  Widget _buildBudgetTile(BuildContext context, ExpenseProvider provider, CategoryBudgetStatus status) {
    final Color stateColor = status.isExceeded
        ? Colors.red
        : (status.percentageUsed > 0.8 ? Colors.orange : Colors.green);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status.categoryName, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${CurrencyFormatter.format(status.spent)} ${status.limit > 0 ? "/ " + CurrencyFormatter.format(status.limit) : ""}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (status.limit > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status.percentageUsed.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status.isExceeded 
                    ? 'Over!'
                    : '${(status.percentageUsed * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: stateColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
