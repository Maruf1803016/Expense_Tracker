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

    double maxY = 100.0;
    for (var v in [...incomeTrend, ...expenseTrend]) {
      if (v > maxY) maxY = v;
    }
    maxY = maxY * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem('Inflow', AppTheme.emerald),
            const SizedBox(width: 16),
            _buildLegendItem('Outflow', AppTheme.brick),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 2.1,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (monthLabels.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 3 > 0 ? maxY / 3 : 100,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: AppTheme.line.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (val, meta) {
                      final idx = val.round();
                      if (idx >= 0 && idx < monthLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            monthLabels[idx],
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: AppTheme.emerald,
                      strokeWidth: 1.5,
                      strokeColor: AppTheme.paperCard,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.emerald.withValues(alpha: 0.08),
                  ),
                ),
                LineChartBarData(
                  spots: expenseTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppTheme.brick,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: AppTheme.brick,
                      strokeWidth: 1.5,
                      strokeColor: AppTheme.paperCard,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.brick.withValues(alpha: 0.08),
                  ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textDark, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
