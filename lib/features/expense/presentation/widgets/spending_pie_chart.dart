import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import '../providers/expense_provider.dart';

class SpendingPieChart extends StatelessWidget {
  const SpendingPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final rawSections = provider.pieChartSections;

    if (rawSections.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSpending = provider.summary.totalExpense;
    final double innerRadius = 45.0; // Donut center hole
    final double thickness = 18.0;   // Donut border width

    final List<PieChartSectionData> updatedSections = [];
    final List<_DonutLegendItem> legendItems = [];

    for (int i = 0; i < rawSections.length; i++) {
      final titleParts = rawSections[i].title.split('\n');
      final catName = titleParts.first;
      
      final category = provider.categories.firstWhere(
        (c) => c.name.toLowerCase() == catName.toLowerCase(),
        orElse: () => Category(
          id: 'unknown',
          name: catName,
          icon: Icons.category,
          type: CategoryType.expense,
          subCategories: const [],
        ),
      );

      final catColor = AppTheme.getCategoryColor(category.id, category.name);
      final percentage = (rawSections[i].value / totalSpending) * 100;

      updatedSections.add(
        PieChartSectionData(
          value: rawSections[i].value,
          title: '', 
          color: catColor,
          radius: thickness,
          showTitle: false,
        ),
      );

      legendItems.add(
        _DonutLegendItem(
          categoryName: category.name,
          color: catColor,
          percentage: percentage,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: updatedSections,
                  centerSpaceRadius: innerRadius,
                  sectionsSpace: 2,
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOut,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legendItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.categoryName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: AppTheme.muted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutLegendItem {
  final String categoryName;
  final Color color;
  final double percentage;

  _DonutLegendItem({
    required this.categoryName,
    required this.color,
    required this.percentage,
  });
}
