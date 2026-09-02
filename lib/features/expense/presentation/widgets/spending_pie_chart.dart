import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import '../providers/expense_provider.dart';

class SpendingPieChart extends StatefulWidget {
  const SpendingPieChart({super.key});

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final rawSections = provider.pieChartSections;

    if (rawSections.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSpending = provider.summary.totalExpense;
    final double innerRadius = 52.0; // Donut center hole
    final double normalThickness = 18.0;   // Donut border width
    final double touchedThickness = 24.0;

    final List<PieChartSectionData> updatedSections = [];
    final List<_DonutLegendItem> legendItems = [];

    for (int i = 0; i < rawSections.length; i++) {
      final isTouched = i == _touchedIndex;
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
      final percentage = totalSpending > 0 ? (rawSections[i].value / totalSpending) * 100 : 0.0;

      updatedSections.add(
        PieChartSectionData(
          value: rawSections[i].value,
          title: '', 
          color: isTouched ? catColor : catColor.withValues(alpha: _touchedIndex == -1 ? 1.0 : 0.45),
          radius: isTouched ? touchedThickness : normalThickness,
          showTitle: false,
        ),
      );

      legendItems.add(
        _DonutLegendItem(
          categoryName: category.name,
          color: catColor,
          amount: rawSections[i].value,
          percentage: percentage,
        ),
      );
    }

    // Active center readout
    String centerKicker = 'TOTAL SPEND';
    String centerAmount = CurrencyFormatter.format(totalSpending);
    String? centerSub;

    if (_touchedIndex >= 0 && _touchedIndex < legendItems.length) {
      final active = legendItems[_touchedIndex];
      centerKicker = active.categoryName.toUpperCase();
      centerAmount = CurrencyFormatter.format(active.amount);
      centerSub = '${active.percentage.toStringAsFixed(1)}% of total';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Interactive Donut with Center Readout
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 165,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  return;
                                }
                                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: updatedSections,
                          centerSpaceRadius: innerRadius,
                          sectionsSpace: 3,
                          startDegreeOffset: -90,
                        ),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _touchedIndex = -1;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerKicker,
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: context.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              centerAmount,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            if (centerSub != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                centerSub,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: context.gold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Interactive Legend
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legendItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSelected = idx == _touchedIndex;

                    return InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          _touchedIndex = isSelected ? -1 : idx;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        decoration: BoxDecoration(
                          color: isSelected ? item.color.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected ? Border.all(color: item.color.withValues(alpha: 0.5)) : null,
                        ),
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
                                  fontSize: 11,
                                  color: isSelected ? context.textPrimary : context.textPrimary.withValues(alpha: 0.85),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.percentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: isSelected ? context.gold : context.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutLegendItem {
  final String categoryName;
  final Color color;
  final double amount;
  final double percentage;

  _DonutLegendItem({
    required this.categoryName,
    required this.color,
    required this.amount,
    required this.percentage,
  });
}
