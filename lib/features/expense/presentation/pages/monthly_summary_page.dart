import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/budget/domain/entities/category_budget_status.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/income_expense_bar_chart.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/spending_pie_chart.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/monthly_summary.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

class MonthlySummaryPage extends StatelessWidget {
  const MonthlySummaryPage({super.key});

  void _showExportOptions(BuildContext context, ExpenseProvider expenseProvider, ExportProvider exportProvider) {
    final selectedDate = expenseProvider.selectedMonth;
    final categoryProvider = context.read<CategoryProvider>();
    final accountProvider = context.read<AccountProvider>();

    final categoryNames = {for (var c in categoryProvider.categories) c.id: c.name};
    final accountNames = {for (var a in accountProvider.accounts) a.id: a.name};
    final accountBalances = {
      for (var a in accountProvider.accounts)
        a.id: Account.calculateBalance(a, expenseProvider.expenses)
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppTheme.paperCard,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Export Data',
                  style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ),
              const Divider(),
              
              _buildOptionHeader('This Month (${DateFormatter.monthYear(selectedDate)})'),
              ListTile(
                leading: const Icon(Icons.table_view_rounded, color: AppTheme.emerald),
                title: Text('CSV Spreadsheet', style: GoogleFonts.inter(color: AppTheme.textDark)),
                onTap: () async {
                  Navigator.pop(context);
                  await exportProvider.exportMonth(
                    month: selectedDate.month,
                    year: selectedDate.year,
                    format: ExportFormat.csv,
                    categoryNames: categoryNames,
                    accountNames: accountNames,
                    accountBalances: accountBalances,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.brick),
                title: Text('PDF Professional Report', style: GoogleFonts.inter(color: AppTheme.textDark)),
                onTap: () async {
                  Navigator.pop(context);
                  await exportProvider.exportMonth(
                    month: selectedDate.month,
                    year: selectedDate.year,
                    format: ExportFormat.pdf,
                    categoryNames: categoryNames,
                    accountNames: accountNames,
                    accountBalances: accountBalances,
                  );
                },
              ),

              const Divider(),

              _buildOptionHeader('Bulk Export'),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: AppTheme.gold),
                title: Text('Last 3 Months (CSVs)', style: GoogleFonts.inter(color: AppTheme.textDark)),
                subtitle: Text('Package of reports for recent history', style: GoogleFonts.inter(color: AppTheme.muted)),
                onTap: () async {
                  Navigator.pop(context);
                  await exportProvider.exportLast3Months(
                    currentMonth: selectedDate,
                    format: ExportFormat.csv,
                    categoryNames: categoryNames,
                    accountNames: accountNames,
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
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.muted,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSavingsCard(BuildContext context, MonthlySummary summary) {
    final double net = summary.netBalance;
    final bool isSaved = net >= 0;
    final Color accentColor = isSaved ? AppTheme.emerald : AppTheme.brick;
    final IconData icon = isSaved ? Icons.savings_rounded : Icons.trending_down_rounded;
    final String statusText = isSaved ? 'NET SAVINGS' : 'NET LOSS';
    final String message = isSaved 
        ? 'Great job! You saved ${CurrencyFormatter.format(net)} this month.' 
        : 'You spent ${CurrencyFormatter.format(net.abs())} more than your income.';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: GoogleFonts.inter(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.format(net),
              style: GoogleFonts.spaceGrotesk(
                color: accentColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    if (provider.isLoading && provider.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    if (summary.totalIncome == 0 && summary.totalExpense == 0) {
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
              child: const Icon(Icons.bar_chart_rounded, size: 64, color: AppTheme.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'No Summary Available',
              style: GoogleFonts.fraunces(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding expenses to see your monthly breakdown and budget progress.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.muted),
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
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.paperCard,
                  side: const BorderSide(color: AppTheme.line),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () => _showExportOptions(context, provider, exportProvider),
                icon: const Icon(Icons.ios_share_rounded, color: AppTheme.ink),
                tooltip: 'Export Report',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHeroSavingsCard(context, summary),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'Spending Insights'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SpendingPieChart(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const IncomeExpenseBarChart(),
              ],
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
                ? AppTheme.emerald 
                : AppTheme.brick,
            isMain: true,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Income',
                  amount: summary.totalIncome,
                  color: AppTheme.emerald,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Expense',
                  amount: summary.totalExpense,
                  color: AppTheme.brick,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          _buildSectionHeader(context, 'Category Breakdown'),
          const SizedBox(height: 16),

          if (provider.rolledUpCategoryBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text('No data for this month', style: GoogleFonts.inter(color: AppTheme.muted)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.paperCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.line),
              ),
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
                      ? (entry.value > budgetLimit ? AppTheme.brick : AppTheme.emerald) 
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
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconUtils.getIcon(IconUtils.getIconName(category.icon), categoryName: category.name),
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
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      budgetLimit != null
                                          ? '${CurrencyFormatter.format(entry.value)} / ${CurrencyFormatter.format(budgetLimit)}'
                                          : CurrencyFormatter.format(entry.value),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: AppTheme.textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.paper2,
                                    color: progressBarColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  budgetLimit != null
                                      ? '${(entry.value / budgetLimit * 100).toStringAsFixed(0)}% of budget · ${(percentage * 100).toStringAsFixed(1)}% of total spending'
                                      : '${(percentage * 100).toStringAsFixed(1)}% of total spending',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.muted,
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, ExpenseProvider provider, DateTime date) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppTheme.ink),
              onPressed: () {
                final newDate = DateTime(date.year, date.month - 1);
                provider.changeMonth(newDate);
              },
            ),
            Text(
              DateFormatter.monthYear(date),
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppTheme.ink),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMain ? 24.0 : 16.0),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: AppTheme.muted,
                fontSize: isMain ? 13 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: isMain ? 28 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
