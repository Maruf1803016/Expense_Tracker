import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/providers/financial_insights_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/trend_line_chart.dart';
import 'package:expense_tracker/features/alerts/presentation/providers/smart_alerts_provider.dart';
import 'package:expense_tracker/features/alerts/domain/entities/smart_alert.dart';
import 'package:expense_tracker/features/plan/presentation/widgets/plans_tab_view.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
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
                Tab(child: Text('Analytics', style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.bold))),
                Tab(child: Text('Goals', style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.bold))),
              ],
              indicatorColor: AppTheme.ink,
              labelColor: AppTheme.ink,
              unselectedLabelColor: AppTheme.muted,
              dividerColor: AppTheme.line,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnalyticsContent(context),
            const PlansTabView(),
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
                color: AppTheme.gold.withOpacity(0.05),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHealthScoreCard(expenseProvider.healthScore, expenseProvider),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending Trend',
                            style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comparison to previous month',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (insights.trendComparison > 0 ? AppTheme.brick : AppTheme.emerald).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          insights.trendComparison > 0
                              ? '+${insights.trendComparison.toStringAsFixed(0)}% (Warning)'
                              : '${insights.trendComparison.toStringAsFixed(0)}% (Good)',
                          style: GoogleFonts.inter(
                            color: insights.trendComparison > 0 ? AppTheme.brick : AppTheme.emerald,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TrendLineChart(trendData: insights.expenseTrend),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Budget Performance'),
          const SizedBox(height: 12),
          _buildBudgetPerformance(insights.successfulBudgets, insights.totalBudgetedCategories),
          const SizedBox(height: 16),
          _buildTopCategory(insights.topSpendingCategory, insights.topSpendingCategoryPercentage),
          const SizedBox(height: 32),
          if (alerts.isNotEmpty) ...[
            Text(
              'Smart Alerts',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            ...alerts.map((alert) => _buildAlertCard(alert)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
    );
  }

  Widget _buildHealthScoreCard(double score, ExpenseProvider provider) {
    String description = '';
    String label = '';
    Color color = AppTheme.muted;

    if (provider.summary.totalIncome == 0) {
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Financial Health Score',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
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
                      style: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildScoreLegend('Savings Rate: ${provider.savingsPoints.toStringAsFixed(0)}/40', 'Worth 40 points', provider.savingsPoints >= 24),
            const SizedBox(height: 8),
            _buildScoreLegend('Budget Adherence: ${provider.budgetPoints.toStringAsFixed(0)}/30', 'Worth 30 points', provider.budgetPoints >= 18),
            const SizedBox(height: 8),
            _buildScoreLegend('Consistency: ${provider.consistencyPoints.toStringAsFixed(0)}/30', 'Worth 30 points', provider.consistencyPoints >= 18),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreLegend(String title, String subtitle, bool isPositive) {
    return Row(
      children: [
        Icon(
          isPositive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 16,
          color: isPositive ? AppTheme.emerald : AppTheme.muted,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetPerformance(int successful, int total) {
    final double percentage = total > 0 ? (successful / total) : 1.0;
    final bool isLow = percentage < 0.5;
    final bool isCritical = percentage < 0.2;
    
    String statusText = 'Excellent spending control!';
    Color statusColor = AppTheme.emerald;
    
    if (isCritical) {
      statusText = 'Critical: Review your budgets immediately';
      statusColor = AppTheme.brick;
    } else if (isLow) {
      statusText = 'Warning: You are approaching budget limits';
      statusColor = AppTheme.gold;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Budget Performance',
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 12,
                    color: statusColor,
                    backgroundColor: AppTheme.paper2,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Safe',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('On Track', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
                      const SizedBox(height: 4),
                      Text(
                        '$successful Categories',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppTheme.line),
                Expanded(
                  child: Column(
                    children: [
                      Text('Over Budget', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
                      const SizedBox(height: 4),
                      Text(
                        '${total - successful} Categories',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.brick,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategory(String name, double percentage) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: ListTile(
        leading: const Icon(Icons.pie_chart, color: AppTheme.gold),
        title: Text('Top Spending Category', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        subtitle: Text(name, style: GoogleFonts.inter(color: AppTheme.muted)),
        trailing: Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 16),
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(alert.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        subtitle: Text(alert.message, style: GoogleFonts.inter(color: AppTheme.muted)),
      ),
    );
  }
}
