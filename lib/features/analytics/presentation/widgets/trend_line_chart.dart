import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> trendData;

  const TrendLineChart({super.key, required this.trendData});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.expenses;

    // Calculate last 6 months starting from current month
    final now = DateTime.now();
    final List<double> incomeTrend = [];
    final List<double> expenseTrend = [];
    final List<String> monthLabels = [];

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final targetYear = targetDate.year;
      final targetMonth = targetDate.month;

      final monthExpenses = expenses.where((e) => e.date.year == targetYear && e.date.month == targetMonth && !e.isDeleted);
      
      final monthlyIncome = monthExpenses.where((e) => e.type == CategoryType.income).fold<double>(0.0, (sum, e) => sum + e.amount);
      final monthlyExpense = monthExpenses.where((e) => e.type == CategoryType.expense).fold<double>(0.0, (sum, e) => sum + e.amount);

      incomeTrend.add(monthlyIncome);
      expenseTrend.add(monthlyExpense);
      monthLabels.add(DateFormat('MMM').format(targetDate));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem('Income', AppTheme.emerald),
            const SizedBox(width: 16),
            _buildLegendItem('Expense', AppTheme.brick),
          ],
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < monthLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            monthLabels[idx],
                            style: const TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 24,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: incomeTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppTheme.emerald,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: expenseTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppTheme.brick,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
