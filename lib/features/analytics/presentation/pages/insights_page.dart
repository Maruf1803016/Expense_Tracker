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
        backgroundColor: AppTheme.paper,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.paper,
            child: TabBar(
              tabs: [
                Tab(child: Text('Insights & Trends', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                Tab(child: Text('Monthly Summary', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
              ],
              indicatorColor: AppTheme.ink,
              indicatorWeight: 2.5,
              labelColor: AppTheme.ink,
              unselectedLabelColor: AppTheme.muted,
              dividerColor: AppTheme.line,
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    if (insights == null || expenseProvider.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights_rounded, size: 64, color: AppTheme.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'No Insights Yet',
              style: GoogleFonts.fraunces(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your spending habits, trends, and smart alerts will appear here as you track more transactions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.muted),
            ),
          ],
        ),
      );
    }

    // Calculate Inflow, Outflow, Net for current view
    final selectedMonth = expenseProvider.selectedMonth;
    var thisMonthExpenses = expenseProvider.expenses.where(
      (e) => e.date.year == selectedMonth.year && e.date.month == selectedMonth.month && !e.isDeleted,
    ).toList();
    if (thisMonthExpenses.isEmpty) {
      thisMonthExpenses = expenseProvider.expenses.where((e) => !e.isDeleted).toList();
    }
    final totalInflow = thisMonthExpenses
        .where((e) => e.type == CategoryType.income)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalOutflow = thisMonthExpenses
        .where((e) => e.type == CategoryType.expense)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final netCashFlow = totalInflow - totalOutflow;

    // Category Mix aggregation
    final categoryTotals = <String, double>{};
    final categoryProvider = context.watch<CategoryProvider>();
    for (var exp in thisMonthExpenses.where((e) => e.type == CategoryType.expense)) {
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
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Insights & Trends',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cash flow patterns and allocation mix across your ledger.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),

          // Compact Lens Selector
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.paper2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.line),
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
                        color: isSelected ? AppTheme.paperCard : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
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
                          color: isSelected ? AppTheme.textDark : AppTheme.muted,
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
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
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
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Income vs. Outflow trajectory',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (insights.trendComparison > 0 ? AppTheme.brick : AppTheme.emerald).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        insights.trendComparison > 0
                            ? '+${insights.trendComparison.toStringAsFixed(0)}% (Warning)'
                            : '${insights.trendComparison.toStringAsFixed(0)}% (Disciplined)',
                        style: GoogleFonts.inter(
                          color: insights.trendComparison > 0 ? AppTheme.brick : AppTheme.emerald,
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
                    color: AppTheme.paper2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.line.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('INFLOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.muted, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(totalInflow),
                              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: AppTheme.line),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OUTFLOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.muted, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(totalOutflow),
                              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.brick),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: AppTheme.line),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NET FLOW', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.muted, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(netCashFlow),
                              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TrendLineChart(trendData: insights.expenseTrend),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Category Mix Panel
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
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
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Spending distribution across categories',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
                        ),
                      ],
                    ),
                    Text(
                      '${sortedCategories.length} Categories',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600),
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
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
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
                                  color: catColor.withValues(alpha: 0.12),
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
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.paper2,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(percentage * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.muted),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(entry.value),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
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
                              backgroundColor: AppTheme.paper2,
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
          _buildHealthScoreCard(expenseProvider.healthScore, expenseProvider),
          const SizedBox(height: 14),

          // 4. Smart Alerts
          if (alerts.isNotEmpty) ...[
            Text(
              'Smart Alerts',
              style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            ...alerts.map((alert) => _buildAlertCard(alert)),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(double score, ExpenseProvider provider) {
    String description;
    String label;
    Color color;

    if (score == 0) {
      description = 'Add income transactions to calculate your financial health score.';
      label = 'INCOMPLETE';
      color = AppTheme.muted;
    } else if (score >= 80) {
      description = 'Your finances are in great shape. Keep up the disciplined habits.';
      label = 'EXCELLENT';
      color = AppTheme.emerald;
    } else if (score >= 60) {
      description = 'Your financial health is decent but has room for improvement.';
      label = 'GOOD';
      color = AppTheme.gold;
    } else {
      description = 'Your financial health needs attention. Review your spending patterns.';
      label = 'POOR';
      color = AppTheme.brick;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
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
                      backgroundColor: AppTheme.paper2,
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
                      style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.line),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniScoreItem('Savings', '${provider.savingsPoints.toStringAsFixed(0)}/40', provider.savingsPoints >= 24),
              ),
              Expanded(
                child: _buildMiniScoreItem('Budget', '${provider.budgetPoints.toStringAsFixed(0)}/30', provider.budgetPoints >= 18),
              ),
              Expanded(
                child: _buildMiniScoreItem('Consistency', '${provider.consistencyPoints.toStringAsFixed(0)}/30', provider.consistencyPoints >= 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScoreItem(String title, String score, bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.muted)),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              size: 12,
              color: isPositive ? AppTheme.emerald : AppTheme.muted,
            ),
            const SizedBox(width: 4),
            Text(
              score,
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard(SmartAlert alert) {
    Color color = AppTheme.gold;
    IconData icon = Icons.info_outline;

    switch (alert.type) {
      case AlertType.spendingSpike:
        color = AppTheme.gold;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.budgetExceeded:
        color = AppTheme.brick;
        icon = Icons.cancel_outlined;
        break;
      case AlertType.unusualActivity:
        color = AppTheme.gold;
        icon = Icons.error_outline_rounded;
        break;
      case AlertType.trendWarning:
        color = AppTheme.gold;
        icon = Icons.trending_up_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
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
        title: Text(alert.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
        subtitle: Text(alert.message, style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 11)),
      ),
    );
  }
}

