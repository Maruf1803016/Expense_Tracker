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
import 'package:expense_tracker/features/expense/presentation/widgets/waterfall_diagram.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/monthly_summary.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

class MonthlySummaryPage extends StatelessWidget {
  const MonthlySummaryPage({super.key});

  Widget _buildHeroSavingsCard(BuildContext context, MonthlySummary summary) {
    final double net = summary.netBalance;
    final bool isSaved = net >= 0;
    final Color accentColor = isSaved ? context.emerald : context.brick;
    final IconData icon = isSaved ? Icons.savings_rounded : Icons.trending_down_rounded;
    final String statusText = isSaved ? 'NET SAVINGS' : 'NET LOSS';
    final String message = isSaved 
        ? 'Great job! You saved ${CurrencyFormatter.format(net)} this month.' 
        : 'You spent ${CurrencyFormatter.format(net.abs())} more than your income.';

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: GoogleFonts.inter(
                color: context.textMuted,
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
                color: context.textPrimary,
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
      return Center(child: CircularProgressIndicator(color: context.gold));
    }

    if (provider.isLoading && provider.expenses.isEmpty) {
      return Center(child: CircularProgressIndicator(color: context.gold));
    }

    if (summary.totalIncome == 0 && summary.totalExpense == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart_rounded, size: 64, color: context.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'No Summary Available',
              style: GoogleFonts.fraunces(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding expenses to see your monthly breakdown and budget progress.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.textMuted),
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
          _buildMonthSelector(context, provider, selectedMonth),
          const SizedBox(height: 24),
          _buildHeroSavingsCard(context, summary),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'Spending Insights'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.line),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SpendingPieChart(),
                const SizedBox(height: 24),
                Divider(color: context.line),
                const SizedBox(height: 16),
                const IncomeExpenseBarChart(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          WaterfallDiagram(summary: summary, provider: provider),
          const SizedBox(height: 32),

          _buildSectionHeader(context, 'Financial Totals'),
          const SizedBox(height: 16),
          _buildSummaryCard(
            context,
            title: 'Net Balance',
            amount: summary.netBalance,
            color: summary.netBalance >= 0 
                ? context.emerald 
                : context.brick,
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
                  color: context.emerald,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: 'Total Expense',
                  amount: summary.totalExpense,
                  color: context.brick,
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
                child: Text('No data for this month', style: GoogleFonts.inter(color: context.textMuted)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: provider.rolledUpCategoryBreakdown.entries.toList().asMap().entries.map((e) {
                  final index = e.key;
                  final entry = e.value;
                  final category = provider.getCategoryById(entry.key);
                  final isIncome = category.type == CategoryType.income;
                  final totalBase = isIncome ? summary.totalIncome : summary.totalExpense;
                  final percentage = totalBase > 0 ? (entry.value / totalBase) : 0.0;
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
                  final double? budgetLimit = (!isIncome && budgetStatus.limit > 0) ? budgetStatus.limit : null;
                  final double progressValue = budgetLimit != null ? (entry.value / budgetLimit).clamp(0.0, 1.0) : percentage;
                  final Color progressBarColor = budgetLimit != null 
                      ? (entry.value > budgetLimit ? context.brick : context.emerald) 
                      : catColor;
                  
                  return Column(
                    children: [
                      if (index > 0) const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
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
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      budgetLimit != null
                                          ? '${CurrencyFormatter.format(entry.value)} / ${CurrencyFormatter.format(budgetLimit)}'
                                          : CurrencyFormatter.format(entry.value),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: context.textPrimary,
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
                                    backgroundColor: context.surface2,
                                    color: progressBarColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  budgetLimit != null
                                      ? '${(entry.value / budgetLimit * 100).toStringAsFixed(0)}% of budget · ${(percentage * 100).toStringAsFixed(1)}% of total spending'
                                      : '${(percentage * 100).toStringAsFixed(1)}% of total spending',
                                  style: GoogleFonts.inter(
                                    color: context.textMuted,
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
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, ExpenseProvider provider, DateTime date) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: context.textPrimary),
              onPressed: () {
                final newDate = DateTime(date.year, date.month - 1);
                provider.changeMonth(newDate);
              },
            ),
            Text(
              DateFormatter.monthYear(date),
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: context.textPrimary),
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMain ? 24.0 : 16.0),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: context.textMuted,
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
