import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_indicator.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_skeleton.dart';
import 'package:expense_tracker/features/budget/domain/entities/category_budget_status.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/income_expense_bar_chart.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/spending_pie_chart.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final exportProvider = context.watch<ExportProvider>();
    final summary = provider.summary;
    final selectedMonth = provider.selectedMonth;

    if (exportProvider.isExporting) {
      return const LoadingIndicator(message: 'Generating your report...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Selector & Export Button
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

          if (provider.isLoading) ...[
            const LoadingSkeleton(height: 200),
            const SizedBox(height: 24),
            const LoadingSkeleton(height: 100),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: LoadingSkeleton(height: 100)),
                SizedBox(width: 16),
                Expanded(child: LoadingSkeleton(height: 100)),
              ],
            ),
          ] else if (summary.totalIncome == 0 && summary.totalExpense == 0) ...[
            const EmptyState(
              title: 'No Data for this Month',
              message: 'Try switching months or add your first transaction to see the breakdown.',
              icon: Icons.analytics_outlined,
            ),
          ] else ...[
            // Charts Section
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

            // Net Balance Card
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

            // Income & Expense Row
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

            // Budgets Section
            _buildSectionHeader(context, 'Monthly Budgets'),
            const SizedBox(height: 16),
            if (provider.budgetStatuses.isEmpty)
              const Center(child: Text('Add categories to start budgeting'))
            else
              ...provider.budgetStatuses.map((status) => _buildBudgetTile(context, provider, status)),

            const SizedBox(height: 40),

            // Breakdown Title
            _buildSectionHeader(context, 'Category Breakdown'),
            const SizedBox(height: 16),

            // Breakdown List
            if (summary.categoryBreakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'No data for this month',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...summary.categoryBreakdown.entries.map((entry) {
                final category = provider.getCategoryById(entry.key);
                return _buildBreakdownItem(
                  context,
                  category?.name ?? 'Unknown',
                  entry.value,
                  summary.totalIncome + summary.totalExpense,
                );
              }).toList(),
          ],
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

  Widget _buildBreakdownItem(BuildContext context, String name, double amount, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? amount / total : 0,
            backgroundColor: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTile(BuildContext context, ExpenseProvider provider, CategoryBudgetStatus status) {
    final Color stateColor = status.isExceeded
        ? Colors.red
        : (status.percentageUsed > 0.8 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showSetBudgetDialog(context, provider, status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spent: ${CurrencyFormatter.format(status.spent)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  status.limit > 0 
                      ? 'Limit: ${CurrencyFormatter.format(status.limit)}' 
                      : 'No limit set',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: status.limit > 0 ? status.percentageUsed.clamp(0.0, 1.0) : 0.0,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(stateColor),
              ),
            ),
            if (status.limit > 0) ...[
              const SizedBox(height: 8),
              Text(
                status.isExceeded 
                    ? 'Overspent by ${CurrencyFormatter.format(status.spent - status.limit)}'
                    : '${CurrencyFormatter.format(status.remaining)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: stateColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, ExpenseProvider provider, CategoryBudgetStatus status) {
    final controller = TextEditingController(text: status.limit > 0 ? status.limit.toStringAsFixed(0) : '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for ${status.categoryName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Limit',
            prefixText: '\$ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final limit = double.tryParse(controller.text) ?? 0.0;
              await provider.setBudget(status.categoryId, limit);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
