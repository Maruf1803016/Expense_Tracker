import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import '../providers/expense_provider.dart';

class SpendingPieChart extends StatelessWidget {
  const SpendingPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final sections = provider.pieChartSections;

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOutBack,
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context, provider),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, ExpenseProvider provider) {
    final breakdown = provider.summary.categoryBreakdown;
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: breakdown.keys.map((categoryId) {
        final category = provider.getCategoryById(categoryId);
        // Only show legend for expense categories
        if (category.type != CategoryType.expense) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                // ignore: invalid_use_of_protected_member
                color: provider.pieChartSections
                    .firstWhere((s) => s.value == breakdown[categoryId])
                    .color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              category.name,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
