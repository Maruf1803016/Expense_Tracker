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
          _buildSectionHeader('Spending Trend'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: TrendLineChart(trendData: insights.expenseTrend),
            ),
          ),
          const SizedBox(height: 24),
          _buildTrendSection(insights.trendComparison),
          const SizedBox(height: 24),
          _buildSectionHeader('Budget & Efficiency'),
          const SizedBox(height: 12),
          _buildEfficiencyCard(context, expenseProvider),
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
            _buildScoreLegend('Savings Rate', 'Worth 40 points', score > 60),
            const SizedBox(height: 8),
            _buildScoreLegend('Budget Adherence', 'Worth 30 points', score > 40),
            const SizedBox(height: 8),
            _buildScoreLegend('Consistency', 'Worth 30 points', score > 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard(BuildContext context, ExpenseProvider provider) {
    // In a real app we'd use context.read<SettingsProvider>() but here we can get it from ExpenseProvider if available
    // or assume the user has set it. Let's use provider.monthlyBudget
    final double totalBudget = provider.monthlyBudget;
    final double totalSpent = provider.summary.totalExpense;
    final double efficiency = totalBudget > 0 ? ((1 - (totalSpent / totalBudget)) * 100).clamp(0.0, 100.0) : 0.0;
    
    String effDesc = '';
    if (totalBudget == 0) {
      effDesc = 'Set a monthly budget in Settings to track your efficiency.';
    } else if (efficiency >= 80) {
      effDesc = 'You are well within your budget. Great spending control.';
    } else if (efficiency >= 60) {
      effDesc = 'You are managing your budget reasonably. Watch discretionary spending.';
    } else {
      effDesc = 'You are close to or over budget. Consider reducing expenses.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Budget Efficiency', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${efficiency.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              effDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
            ),
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

  Widget _buildTrendSection(double trend) {
    final isUp = trend > 0;
    return Card(
      child: ListTile(
        leading: Icon(
          isUp ? Icons.trending_up : Icons.trending_down,
          color: isUp ? AppTheme.expenseColor : AppTheme.incomeColor,
        ),
        title: const Text('Spending Trend'),
        subtitle: Text(isUp ? 'Increased by ${trend.toStringAsFixed(1)}%' : 'Decreased by ${trend.abs().toStringAsFixed(1)}%'),
        trailing: Text(
          isUp ? 'Warning' : 'Good',
          style: TextStyle(color: isUp ? AppTheme.expenseColor : AppTheme.incomeColor, fontWeight: FontWeight.bold),
        ),
      ),
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

    switch (alert.severity) {
      case AlertSeverity.high:
        color = Colors.red;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.medium:
        color = Colors.orange;
        icon = Icons.error_outline;
        break;
      case AlertSeverity.low:
        color = Colors.blue;
        icon = Icons.info_outline;
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
