import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Analytics'),
              Tab(text: 'Goals'),
            ],
            indicatorColor: AppTheme.emeraldGreen,
            labelColor: AppTheme.emeraldGreen,
            unselectedLabelColor: Colors.white54,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAnalyticsContent(context),
                const PlansTabView(),
              ],
            ),
          ),
        ],
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
    }

    if (insights == null || expenseProvider.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights_rounded, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Insights Yet',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your spending habits, trends, and smart alerts will appear here as you track more transactions.',
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
          _buildHealthScoreCard(expenseProvider.healthScore, expenseProvider),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: AppTheme.secondaryBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending Trend',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Comparison to previous month',
                            style: TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (insights.trendComparison > 0 ? AppTheme.expenseColor : AppTheme.incomeColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          insights.trendComparison > 0
                              ? '+${insights.trendComparison.toStringAsFixed(0)}% (Warning)'
                              : '${insights.trendComparison.toStringAsFixed(0)}% (Good)',
                          style: TextStyle(
                            color: insights.trendComparison > 0 ? AppTheme.expenseColor : AppTheme.incomeColor,
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
          const SizedBox(height: 12),
          _buildTopCategory(insights.topSpendingCategory, insights.topSpendingCategoryPercentage),
          const SizedBox(height: 32),
          if (alerts.isNotEmpty) ...[
            const Text(
              'Smart Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildHealthScoreCard(double score, ExpenseProvider provider) {
    String description = '';
    String label = '';
    Color color = Colors.grey;

    if (provider.summary.totalIncome == 0) {
      description = 'Add income transactions to calculate your financial health score.';
      label = 'INCOMPLETE';
      color = Colors.grey;
    } else if (score >= 80) {
      description = 'Your finances are in great shape. Keep up the disciplined habits.';
      label = 'EXCELLENT';
      color = const Color(0xFF00C896);
    } else if (score >= 60) {
      description = 'Your financial health is decent but has room for improvement.';
      label = 'GOOD';
      color = const Color(0xFF4ECDC4);
    } else {
      description = 'Your financial health needs attention. Review your spending patterns.';
      label = 'POOR';
      color = const Color(0xFFFF6B6B);
    }

    return Card(
      elevation: 0,
      color: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Financial Health Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 14,
                    color: color,
                    backgroundColor: color.withOpacity(0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      label,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 32),
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
          color: isPositive ? AppTheme.incomeColor : Colors.white24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
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
    Color statusColor = const Color(0xFF00C896);
    
    if (isCritical) {
      statusText = 'Critical: Review your budgets immediately';
      statusColor = const Color(0xFFFF6B6B);
    } else if (isLow) {
      statusText = 'Warning: You are approaching budget limits';
      statusColor = const Color(0xFFFFE66D);
    }

    return Card(
      elevation: 0,
      color: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Budget Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 14,
                    color: statusColor,
                    backgroundColor: statusColor.withOpacity(0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const Text(
                      'Safe',
                      style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('On Track', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      const SizedBox(height: 4),
                      Text(
                        '$successful Categories',
                        style: const TextStyle(
                          color: Color(0xFF00C896),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Over Budget', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      const SizedBox(height: 4),
                      Text(
                        '${total - successful} Categories',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor.withOpacity(0.9),
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
    return Card(
      child: ListTile(
        leading: const Icon(Icons.pie_chart),
        title: const Text('Top Spending Category'),
        subtitle: Text(name),
        trailing: Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAlertCard(SmartAlert alert) {
    Color color = Colors.blue;
    IconData icon = Icons.info_outline;

    switch (alert.type) {
      case AlertType.spendingSpike:
        color = Colors.amber;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.budgetExceeded:
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case AlertType.unusualActivity:
        color = Colors.orange;
        icon = Icons.error_outline_rounded;
        break;
      case AlertType.trendWarning:
        color = Colors.blue;
        icon = Icons.trending_up_rounded;
        break;
    }


    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(alert.message),
      ),
    );
  }
}
