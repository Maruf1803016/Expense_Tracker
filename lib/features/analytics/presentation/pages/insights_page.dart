import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_skeleton.dart';
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
    final insights = insightsProvider.insights;
    final alerts = alertsProvider.alerts;

    if (insightsProvider.isLoading || alertsProvider.isLoading) {
      return ListView(
        padding: const EdgeInsets.all(24.0),
        children: const [
          LoadingSkeleton(height: 250, borderRadius: 24),
          SizedBox(height: 24),
          LoadingSkeleton(height: 80, borderRadius: 16),
          SizedBox(height: 24),
          LoadingSkeleton(height: 120, borderRadius: 16),
          SizedBox(height: 24),
          LoadingSkeleton(height: 80, borderRadius: 16),
        ],
      );
    }

    if (insights == null) {
      return const EmptyState(
        title: 'No Analysis Available',
        message: 'Add expenses to see insights.',
        icon: Icons.psychology_outlined,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHealthScoreCard(insights.healthScore),
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

  Widget _buildHealthScoreCard(int score) {
    Color color = AppTheme.incomeColor;
    String label = 'Strong';
    if (score < 50) {
      color = AppTheme.expenseColor;
      label = 'Risk';
    } else if (score < 80) {
      color = Colors.orange;
      label = 'Moderate';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Financial Health Score', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    color: color,
                    backgroundColor: color.withOpacity(0.1),
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Budget Performance', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? successful / total : 1.0,
              color: AppTheme.incomeColor,
            ),
            const SizedBox(height: 8),
            Text('$successful of $total categories under budget'),
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
