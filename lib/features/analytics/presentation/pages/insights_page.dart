import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/providers/financial_insights_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/trend_line_chart.dart';
import 'package:expense_tracker/features/alerts/presentation/providers/smart_alerts_provider.dart';
import 'package:expense_tracker/features/alerts/domain/entities/smart_alert.dart';
import 'package:expense_tracker/features/expense/presentation/pages/monthly_summary_page.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _selectedLensIndex = 0;
  final List<String> _lensOptions = ['This Month', '3 Months', '6 Months', 'This Year'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedMonth = context.read<ExpenseProvider>().selectedMonth;
      context.read<FinancialInsightsProvider>().init(selectedMonth.month, selectedMonth.year);
      context.read<SmartAlertsProvider>().init(selectedMonth.month, selectedMonth.year);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: context.bg,
            child: TabBar(
              tabs: [
                Tab(child: Text('Insights & Trends', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                Tab(child: Text('Monthly Summary', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
              ],
              indicatorColor: context.gold,
              indicatorWeight: 2.5,
              labelColor: context.textPrimary,
              unselectedLabelColor: context.textMuted,
              dividerColor: context.line,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnalyticsContent(context),
            const MonthlySummaryPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context) {
    final insightsProvider = context.watch<FinancialInsightsProvider>();
    final alertsProvider = context.watch<SmartAlertsProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final insights = insightsProvider.insights;
    final alerts = alertsProvider.alerts;

    if (insightsProvider.isLoading || alertsProvider.isLoading || expenseProvider.isLoading) {
      return Center(child: CircularProgressIndicator(color: context.gold));
    }

    if (insights == null || expenseProvider.expenses.isEmpty) {
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
              child: Icon(Icons.insights_rounded, size: 64, color: context.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'No Insights Yet',
              style: GoogleFonts.fraunces(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your spending habits, trends, and smart alerts will appear here as you track more transactions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: context.textMuted),
            ),
          ],
        ),
      );
    }

    final selectedMonth = expenseProvider.selectedMonth;
    final allExpenses = expenseProvider.expenses.where((e) => !e.isDeleted).toList();
    
    DateTime rangeStart;
    final rangeEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

    if (_selectedLensIndex == 0) {
      rangeStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    } else if (_selectedLensIndex == 1) {
      rangeStart = DateTime(selectedMonth.year, selectedMonth.month - 2, 1);
    } else if (_selectedLensIndex == 2) {
      rangeStart = DateTime(selectedMonth.year, selectedMonth.month - 5, 1);
    } else {
      rangeStart = DateTime(selectedMonth.year, selectedMonth.month - 11, 1);
    }

    final lensExpenses = allExpenses.where((e) {
      return e.date.isAfter(rangeStart.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(rangeEnd.add(const Duration(seconds: 1)));
    }).toList();

    final totalInflow = lensExpenses
        .where((e) => e.type == CategoryType.income && e.toAccountId == null)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalOutflow = lensExpenses
        .where((e) => e.type == CategoryType.expense && e.toAccountId == null)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final netCashFlow = totalInflow - totalOutflow;

    final categoryTotals = <String, double>{};
    final categoryProvider = context.watch<CategoryProvider>();
    for (var exp in lensExpenses.where((e) => e.type == CategoryType.expense && e.toAccountId == null)) {
      final matchingCat = categoryProvider.categories.where((c) => c.id == exp.categoryId).firstOrNull;
      final catName = matchingCat?.name ?? exp.categoryId;
      final displayName = catName.isNotEmpty ? catName : 'Other';
      categoryTotals[displayName] = (categoryTotals[displayName] ?? 0.0) + exp.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Editorial Title Block
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FINANCIAL PULSE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: context.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Insights & Trends',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cash flow patterns and allocation mix across your ledger.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Compact Lens Selector
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
            ),
            child: Row(
              children: List.generate(_lensOptions.length, (idx) {
                final isSelected = _selectedLensIndex == idx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLensIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? context.cardBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _lensOptions[idx],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? context.textPrimary : context.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // 1. Cash Flow Trend Panel
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.line),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash Flow Trend',
                          style: GoogleFonts.fraunces(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Income vs. Outflow trajectory',
                          style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (insights.trendComparison > 0 ? context.brick : context.emerald).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        insights.trendComparison > 0
                            ? '+${insights.trendComparison.toStringAsFixed(0)}% (Warning)'
                            : '${insights.trendComparison.toStringAsFixed(0)}% (Disciplined)',
                        style: GoogleFonts.inter(
                          color: insights.trendComparison > 0 ? context.brick : context.emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Mini Inflow/Outflow/Net Flow Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.line.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('INFLOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(totalInflow),
                              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.emerald),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: context.line),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OUTFLOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(totalOutflow),
                              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.brick),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: context.line),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NET FLOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(netCashFlow),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: netCashFlow >= 0 ? context.emerald : context.brick,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TrendLineChart(selectedLensIndex: _selectedLensIndex),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Category Mix Panel
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.line),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Mix',
                          style: GoogleFonts.fraunces(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Spending distribution across categories',
                          style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                        ),
                      ],
                    ),
                    Text(
                      '${sortedCategories.length} Categories',
                      style: GoogleFonts.inter(fontSize: 11, color: context.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (sortedCategories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Text(
                        'No expense categories logged for this period.',
                        style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
                      ),
                    ),
                  )
                else
                  ...sortedCategories.take(5).map((entry) {
                    final percentage = totalOutflow > 0 ? (entry.value / totalOutflow) : 0.0;
                    final catColor = AppTheme.getCategoryColor(entry.key.toLowerCase(), entry.key);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Icon(
                                    IconUtils.getIcon(null, categoryName: entry.key),
                                    size: 12,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.surface2,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(percentage * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: context.textMuted),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(entry.value),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: percentage.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: context.surface2,
                              valueColor: AlwaysStoppedAnimation<Color>(catColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Compact Financial Health Score Card
          _buildHealthScoreCard(context, expenseProvider.healthScore, expenseProvider),
          const SizedBox(height: 14),

          // 4. Smart Alerts
          if (alerts.isNotEmpty) ...[
            Text(
              'Smart Alerts',
              style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            ...alerts.map((alert) => _buildAlertCard(context, alert)),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, double score, ExpenseProvider provider) {
    String description;
    String label;
    Color color;

    if (score == 0) {
      description = 'Add income transactions to calculate your financial health score.';
      label = 'INCOMPLETE';
      color = context.textMuted;
    } else if (score >= 80) {
      description = 'Your finances are in great shape. Keep up the disciplined habits.';
      label = 'EXCELLENT';
      color = context.emerald;
    } else if (score >= 60) {
      description = 'Your financial health is decent but has room for improvement.';
      label = 'GOOD';
      color = context.gold;
    } else {
      description = 'Your financial health needs attention. Review your spending patterns.';
      label = 'POOR';
      color = context.brick;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      value: score == 0 ? 1.0 : (score / 100),
                      strokeWidth: 5,
                      color: color,
                      backgroundColor: context.surface2,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                      ),
                      Text(
                        label,
                        style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health Discipline',
                      style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.inter(fontSize: 11, color: context.textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.line),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniScoreItem(context, 'Savings', '${provider.savingsPoints.toStringAsFixed(0)}/50', provider.savingsPoints >= 25),
              ),
              Expanded(
                child: _buildMiniScoreItem(
                  context,
                  'Cash Flow',
                  provider.summary.totalIncome >= provider.summary.totalExpense ? '+Surplus' : '-Deficit',
                  provider.summary.totalIncome >= provider.summary.totalExpense,
                ),
              ),
              Expanded(
                child: _buildMiniScoreItem(context, 'Consistency', '${provider.consistencyPoints.toStringAsFixed(0)}/50', provider.consistencyPoints >= 25),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScoreItem(BuildContext context, String title, String score, bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 10, color: context.textMuted)),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 12,
              color: isPositive ? context.emerald : context.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              score,
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, SmartAlert alert) {
    Color color = context.gold;
    IconData icon = Icons.info_outline;

    switch (alert.type) {
      case AlertType.spendingSpike:
        color = context.gold;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.budgetExceeded:
        color = context.brick;
        icon = Icons.cancel_outlined;
        break;
      case AlertType.unusualActivity:
        color = context.gold;
        icon = Icons.error_outline_rounded;
        break;
      case AlertType.trendWarning:
        color = context.gold;
        icon = Icons.trending_up_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(alert.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
        subtitle: Text(alert.message, style: GoogleFonts.inter(color: context.textMuted, fontSize: 11)),
      ),
    );
  }
}
