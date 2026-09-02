import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_detail_page.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

enum TrendGranularity {
  auto,
  daily,
  weekly,
  monthly,
}

class _TrendPoint {
  final DateTime startDate;
  final DateTime endDate;
  final double inflow;
  final double outflow;
  final double net;
  final List<Expense> expenses;
  final String label;
  final String badgeLabel;
  final String fullPeriodLabel;

  _TrendPoint({
    required this.startDate,
    required this.endDate,
    required this.inflow,
    required this.outflow,
    required this.net,
    required this.expenses,
    required this.label,
    required this.badgeLabel,
    required this.fullPeriodLabel,
  });
}

class TrendLineChart extends StatefulWidget {
  final int selectedLensIndex; // 0: This Month, 1: 3 Months, 2: 6 Months, 3: This Year

  const TrendLineChart({
    super.key,
    required this.selectedLensIndex,
  });

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> with SingleTickerProviderStateMixin {
  // Zoom & Pan state
  double _zoomScale = 1.0;
  double _scrollOffset = 0.0;
  double _baseZoomScale = 1.0;
  double _baseScrollOffset = 0.0;
  Offset _lastFocalPoint = Offset.zero;

  // Hover & Scrubber state
  int? _hoveredIndex;

  // Mode: Daily spikes vs Cumulative flow
  bool _isCumulative = false;

  // Granularity Override
  TrendGranularity _granularity = TrendGranularity.auto;

  @override
  void didUpdateWidget(covariant TrendLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLensIndex != widget.selectedLensIndex) {
      setState(() {
        _zoomScale = 1.0;
        _scrollOffset = 0.0;
        _hoveredIndex = null;
        _granularity = TrendGranularity.auto;
      });
    }
  }

  TrendGranularity _effectiveGranularity(int lensIndex, double zoom) {
    if (_granularity != TrendGranularity.auto) {
      return _granularity;
    }
    // Auto-selection based on lens and zoom level
    if (lensIndex == 0) {
      return TrendGranularity.daily;
    } else if (lensIndex == 1) {
      return zoom >= 2.0 ? TrendGranularity.daily : TrendGranularity.weekly;
    } else if (lensIndex == 2) {
      if (zoom >= 3.5) return TrendGranularity.daily;
      if (zoom >= 1.8) return TrendGranularity.weekly;
      return TrendGranularity.monthly;
    } else {
      if (zoom >= 4.5) return TrendGranularity.daily;
      if (zoom >= 2.2) return TrendGranularity.weekly;
      return TrendGranularity.monthly;
    }
  }

  List<_TrendPoint> _computePoints(List<Expense> allExpenses, DateTime selectedMonth) {
    final List<_TrendPoint> points = [];
    final activeExpenses = allExpenses.where((e) => !e.isDeleted).toList();
    final effectiveGranularity = _effectiveGranularity(widget.selectedLensIndex, _zoomScale);

    if (widget.selectedLensIndex == 0) {
      final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(selectedMonth.year, selectedMonth.month, day);
        final dayExpenses = activeExpenses.where((e) {
          return e.date.year == selectedMonth.year &&
              e.date.month == selectedMonth.month &&
              e.date.day == day;
        }).toList();

        final inc = dayExpenses
            .where((e) => e.type == CategoryType.income && e.toAccountId == null)
            .fold<double>(0.0, (sum, e) => sum + e.amount);
        final exp = dayExpenses
            .where((e) => e.type == CategoryType.expense && e.toAccountId == null)
            .fold<double>(0.0, (sum, e) => sum + e.amount);

        points.add(_TrendPoint(
          startDate: date,
          endDate: date,
          inflow: inc,
          outflow: exp,
          net: inc - exp,
          expenses: dayExpenses,
          label: '$day',
          badgeLabel: DateFormat('d MMM').format(date),
          fullPeriodLabel: DateFormat('EEE, d MMM yyyy').format(date),
        ));
      }
    } else {
      int monthsCount = 3;
      if (widget.selectedLensIndex == 1) monthsCount = 3;
      if (widget.selectedLensIndex == 2) monthsCount = 6;
      if (widget.selectedLensIndex == 3) monthsCount = 12;

      final startDate = DateTime(selectedMonth.year, selectedMonth.month - monthsCount + 1, 1);
      final endDate = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

      if (effectiveGranularity == TrendGranularity.monthly) {
        for (int m = 0; m < monthsCount; m++) {
          final mDate = DateTime(startDate.year, startDate.month + m, 1);
          final mEndDate = DateTime(mDate.year, mDate.month + 1, 0, 23, 59, 59);
          final mExpenses = activeExpenses.where((e) {
            return e.date.isAfter(mDate.subtract(const Duration(seconds: 1))) &&
                e.date.isBefore(mEndDate.add(const Duration(seconds: 1)));
          }).toList();

          final inc = mExpenses
              .where((e) => e.type == CategoryType.income && e.toAccountId == null)
              .fold<double>(0.0, (sum, e) => sum + e.amount);
          final exp = mExpenses
              .where((e) => e.type == CategoryType.expense && e.toAccountId == null)
              .fold<double>(0.0, (sum, e) => sum + e.amount);

          points.add(_TrendPoint(
            startDate: mDate,
            endDate: mEndDate,
            inflow: inc,
            outflow: exp,
            net: inc - exp,
            expenses: mExpenses,
            label: DateFormat('MMM').format(mDate),
            badgeLabel: DateFormat('MMM yyyy').format(mDate),
            fullPeriodLabel: DateFormat('MMMM yyyy').format(mDate),
          ));
        }
      } else if (effectiveGranularity == TrendGranularity.weekly) {
        DateTime curWeekStart = startDate;
        int weekIndex = 1;
        while (curWeekStart.isBefore(endDate)) {
          DateTime curWeekEnd = curWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
          if (curWeekEnd.isAfter(endDate)) curWeekEnd = endDate;

          final wExpenses = activeExpenses.where((e) {
            return e.date.isAfter(curWeekStart.subtract(const Duration(seconds: 1))) &&
                e.date.isBefore(curWeekEnd.add(const Duration(seconds: 1)));
          }).toList();

          final inc = wExpenses
              .where((e) => e.type == CategoryType.income && e.toAccountId == null)
              .fold<double>(0.0, (sum, e) => sum + e.amount);
          final exp = wExpenses
              .where((e) => e.type == CategoryType.expense && e.toAccountId == null)
              .fold<double>(0.0, (sum, e) => sum + e.amount);

          final weekMonth = DateFormat('MMM').format(curWeekStart);
          final weekInMonth = ((curWeekStart.day - 1) ~/ 7) + 1;
          final isFirstWeekOfMonth = curWeekStart.day <= 7 || weekIndex == 1;

          points.add(_TrendPoint(
            startDate: curWeekStart,
            endDate: curWeekEnd,
            inflow: inc,
            outflow: exp,
            net: inc - exp,
            expenses: wExpenses,
            label: isFirstWeekOfMonth ? weekMonth : 'W$weekInMonth',
            badgeLabel: 'W$weekInMonth $weekMonth',
            fullPeriodLabel: '${DateFormat('d MMM').format(curWeekStart)} - ${DateFormat('d MMM yyyy').format(curWeekEnd)}',
          ));

          curWeekStart = curWeekStart.add(const Duration(days: 7));
          weekIndex++;
        }
      } else {
        final totalDays = endDate.difference(startDate).inDays + 1;
        for (int i = 0; i < totalDays; i++) {
          final date = startDate.add(Duration(days: i));
          final dayExpenses = activeExpenses.where((e) {
            return e.date.year == date.year &&
                e.date.month == date.month &&
                e.date.day == date.day;
          }).toList();

          final inc = dayExpenses
              .where((e) => e.type == CategoryType.income && e.toAccountId == null)
              .fold<double>(0.0, (sum, e) => sum + e.amount);
          final exp = dayExpenses
              .where((e) => e.type == CategoryType.expense && e.toAccountId == null)
              .fold<double>(0.0, (sum, e) => sum + e.amount);

          points.add(_TrendPoint(
            startDate: date,
            endDate: date,
            inflow: inc,
            outflow: exp,
            net: inc - exp,
            expenses: dayExpenses,
            label: date.day == 1 ? DateFormat('MMM d').format(date) : '${date.day}',
            badgeLabel: DateFormat('d MMM').format(date),
            fullPeriodLabel: DateFormat('EEE, d MMM yyyy').format(date),
          ));
        }
      }
    }

    if (_isCumulative && points.isNotEmpty) {
      double runningInflow = 0.0;
      double runningOutflow = 0.0;
      final cumulativePoints = <_TrendPoint>[];
      for (final p in points) {
        runningInflow += p.inflow;
        runningOutflow += p.outflow;
        cumulativePoints.add(_TrendPoint(
          startDate: p.startDate,
          endDate: p.endDate,
          inflow: runningInflow,
          outflow: runningOutflow,
          net: runningInflow - runningOutflow,
          expenses: p.expenses,
          label: p.label,
          badgeLabel: p.badgeLabel,
          fullPeriodLabel: p.fullPeriodLabel,
        ));
      }
      return cumulativePoints;
    }

    return points;
  }

  void _zoomToPreset(double scale, double targetFraction) {
    setState(() {
      _zoomScale = scale.clamp(1.0, 8.0);
      final maxScroll = (_zoomScale - 1.0);
      _scrollOffset = (targetFraction * maxScroll * 350.0).clamp(0.0, double.infinity);
    });
  }

  void _showPeriodTransactionsModal(BuildContext context, _TrendPoint point) {
    if (point.expenses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
          decoration: BoxDecoration(
            color: ctx.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERIOD TRANSACTIONS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: ctx.gold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          point.fullPeriodLabel,
                          style: GoogleFonts.fraunces(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ctx.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ctx.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ctx.line),
                    ),
                    child: Text(
                      '${point.expenses.length} items',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ctx.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ctx.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'In: +${CurrencyFormatter.format(point.inflow)}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.emerald),
                    ),
                    Container(width: 1, height: 16, color: ctx.line),
                    Text(
                      'Out: -${CurrencyFormatter.format(point.outflow)}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.brick),
                    ),
                    Container(width: 1, height: 16, color: ctx.line),
                    Text(
                      'Net: ${point.net >= 0 ? '+' : ''}${CurrencyFormatter.format(point.net)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: point.net >= 0 ? ctx.emerald : ctx.brick,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: point.expenses.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: context.line),
                  itemBuilder: (context, idx) {
                    final exp = point.expenses[idx];
                    final isIncome = exp.type == CategoryType.income;
                    final category = context.read<ExpenseProvider>().getCategoryById(exp.categoryId);
                    final catName = category.name.isNotEmpty ? category.name : 'General';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ExpenseDetailPage(expense: exp)),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isIncome ? ctx.emerald : ctx.brick).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 16,
                          color: isIncome ? ctx.emerald : ctx.brick,
                        ),
                      ),
                      title: Text(
                        exp.title.isNotEmpty ? exp.title : catName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: ctx.textPrimary),
                      ),
                      subtitle: Text(
                        '${DateFormat('d MMM').format(exp.date)} • $catName',
                        style: GoogleFonts.inter(fontSize: 11, color: ctx.textMuted),
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${CurrencyFormatter.format(exp.amount)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isIncome ? ctx.emerald : ctx.brick,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.expenses;
    final selectedMonth = expenseProvider.selectedMonth;

    final points = _computePoints(expenses, selectedMonth);
    if (points.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No data')));
    }
    double maxVal = 0.0;
    for (var p in points) {
      if (p.inflow > maxVal) maxVal = p.inflow;
      if (p.outflow > maxVal) maxVal = p.outflow;
    }
    final double maxY = maxVal > 0 ? (maxVal * 1.12) : 100.0;

    final activeHoveredIndex = _hoveredIndex?.clamp(0, points.length - 1);
    final hoveredPoint = activeHoveredIndex != null ? points[activeHoveredIndex] : null;
    final effectiveGranularity = _effectiveGranularity(widget.selectedLensIndex, _zoomScale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticsService.selection();
                  setState(() => _isCumulative = !_isCumulative);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isCumulative ? context.gold.withValues(alpha: 0.18) : context.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isCumulative ? context.gold : context.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCumulative ? Icons.stacked_line_chart_rounded : Icons.show_chart_rounded,
                        size: 13,
                        color: _isCumulative ? context.gold : context.textPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isCumulative ? 'Cumulative' : 'Spikes',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isCumulative ? context.gold : context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGranularitySegmentedItem(context, 'Daily', TrendGranularity.daily, effectiveGranularity),
                  const SizedBox(width: 4),
                  _buildGranularitySegmentedItem(context, 'Weekly', TrendGranularity.weekly, effectiveGranularity),
                  const SizedBox(width: 4),
                  _buildGranularitySegmentedItem(context, 'Monthly', TrendGranularity.monthly, effectiveGranularity),
                ],
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(context, 'Inflow', context.emerald),
                  const SizedBox(width: 8),
                  _buildLegendItem(context, 'Outflow', context.brick),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _buildCleanRangePills(context, widget.selectedLensIndex, selectedMonth),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (hoveredPoint != null && hoveredPoint.expenses.isNotEmpty)
              ? () => _showPeriodTransactionsModal(context, hoveredPoint)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hoveredPoint != null ? context.cardBg : context.surface2.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hoveredPoint != null ? AppTheme.gold : context.line.withValues(alpha: 0.6),
                width: hoveredPoint != null ? 1.4 : 1.0,
              ),
              boxShadow: hoveredPoint != null
                  ? [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: hoveredPoint != null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.isDark ? AppTheme.darkSurface2 : AppTheme.ink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hoveredPoint.badgeLabel,
                          style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.goldSoft),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hoveredPoint.fullPeriodLabel,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  'In: +${CurrencyFormatter.format(hoveredPoint.inflow)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: context.emerald,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Out: -${CurrencyFormatter.format(hoveredPoint.outflow)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: context.brick,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (hoveredPoint.expenses.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.gold),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${hoveredPoint.expenses.length} txns',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: context.gold),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 12, color: context.gold),
                            ],
                          ),
                        ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.touch_app_rounded, size: 13, color: context.textMuted),
                          const SizedBox(width: 5),
                          Text(
                            'Pinch to zoom, drag to pan across timeline',
                            style: GoogleFonts.inter(fontSize: 10, color: context.textMuted, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      if (_zoomScale > 1.0)
                        Text(
                          'Pinch / pan active',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: context.gold),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final canvasWidth = constraints.maxWidth;
            const double canvasHeight = 180.0;
            const double paddingLeft = 14.0;
            const double paddingRight = 14.0;

            final effectiveWidth = (canvasWidth - paddingLeft - paddingRight) * _zoomScale;
            final maxScroll = math.max(0.0, effectiveWidth - (canvasWidth - paddingLeft - paddingRight));
            final clampedScroll = _scrollOffset.clamp(0.0, maxScroll);

            void updateTouchPosition(Offset localPos) {
              final contentX = localPos.dx - paddingLeft + clampedScroll;
              final pointSpacing = points.length > 1 ? effectiveWidth / (points.length - 1) : 0.0;
              if (pointSpacing > 0) {
                final idx = (contentX / pointSpacing).round().clamp(0, points.length - 1);
                setState(() {
                  _hoveredIndex = idx;
                });
              }
            }

            return MouseRegion(
              onHover: (event) => updateTouchPosition(event.localPosition),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _baseZoomScale = _zoomScale;
                  _baseScrollOffset = _scrollOffset;
                  _lastFocalPoint = details.localFocalPoint;
                  updateTouchPosition(details.localFocalPoint);
                },
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.scale != 1.0) {
                      _zoomScale = (_baseZoomScale * details.scale).clamp(1.0, 8.0);
                    }
                    final deltaX = details.localFocalPoint.dx - _lastFocalPoint.dx;
                    final newEffectiveWidth = (canvasWidth - paddingLeft - paddingRight) * _zoomScale;
                    final newMaxScroll = math.max(0.0, newEffectiveWidth - (canvasWidth - paddingLeft - paddingRight));
                    _scrollOffset = (_baseScrollOffset - deltaX).clamp(0.0, newMaxScroll);
                    _lastFocalPoint = details.localFocalPoint;
                  });
                  updateTouchPosition(details.localFocalPoint);
                },
                onTapDown: (details) {
                  updateTouchPosition(details.localPosition);
                },
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: CustomPaint(
                    size: Size(canvasWidth, canvasHeight),
                    painter: _InteractiveTrendLinePainter(
                      points: points,
                      hoveredIndex: activeHoveredIndex,
                      zoomScale: _zoomScale,
                      scrollOffset: clampedScroll,
                      maxY: maxY,
                      isCumulative: _isCumulative,
                      paddingLeft: paddingLeft,
                      paddingRight: paddingRight,
                      effectiveGranularity: effectiveGranularity,
                      gridColor: context.line.withValues(alpha: 0.6),
                      labelColor: context.textMuted,
                      hoverColor: context.gold,
                      emeraldColor: context.emerald,
                      brickColor: context.brick,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGranularitySegmentedItem(
    BuildContext context,
    String label,
    TrendGranularity gran,
    TrendGranularity effectiveGran,
  ) {
    final isSelected = (_granularity == gran) || (_granularity == TrendGranularity.auto && effectiveGran == gran);
    return GestureDetector(
      onTap: () {
        HapticsService.selection();
        setState(() {
          _granularity = (_granularity == gran) ? TrendGranularity.auto : gran;
          _hoveredIndex = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.gold.withValues(alpha: 0.18) : context.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? context.gold : context.line,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? context.gold : context.textMuted,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCleanRangePills(BuildContext context, int lensIndex, DateTime selectedMonth) {
    final widgets = <Widget>[];

    if (lensIndex == 0) {
      widgets.add(_buildRangePresetPill(context, 'Full Month', 1.0, 0.0));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Week 1', 2.8, 0.0));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Week 2', 2.8, 0.28));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Week 3', 2.8, 0.58));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Week 4+', 2.8, 0.95));
    } else if (lensIndex == 1) {
      widgets.add(_buildRangePresetPill(context, 'Full 3 Months', 1.0, 0.0));
      widgets.add(const SizedBox(width: 6));
      for (int i = 0; i < 3; i++) {
        final mDate = DateTime(selectedMonth.year, selectedMonth.month - 2 + i, 1);
        final mName = DateFormat('MMMM').format(mDate);
        final frac = i / 2.0;
        widgets.add(_buildRangePresetPill(context, mName, 3.2, frac));
        widgets.add(const SizedBox(width: 6));
      }
    } else if (lensIndex == 2) {
      widgets.add(_buildRangePresetPill(context, 'Full 6 Months', 1.0, 0.0));
      widgets.add(const SizedBox(width: 6));
      for (int i = 0; i < 6; i++) {
        final mDate = DateTime(selectedMonth.year, selectedMonth.month - 5 + i, 1);
        final mName = DateFormat('MMM').format(mDate);
        final frac = i / 5.0;
        widgets.add(_buildRangePresetPill(context, mName, 4.5, frac));
        widgets.add(const SizedBox(width: 6));
      }
    } else {
      widgets.add(_buildRangePresetPill(context, 'Full Year', 1.0, 0.0));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Q1 (Jan-Mar)', 3.5, 0.0));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Q2 (Apr-Jun)', 3.5, 0.33));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Q3 (Jul-Sep)', 3.5, 0.66));
      widgets.add(const SizedBox(width: 6));
      widgets.add(_buildRangePresetPill(context, 'Q4 (Oct-Dec)', 3.5, 1.0));
    }

    return widgets;
  }

  Widget _buildRangePresetPill(BuildContext context, String title, double scale, double fraction) {
    final isActive = (_zoomScale == scale && scale == 1.0);
    return GestureDetector(
      onTap: () {
        HapticsService.selection();
        _zoomToPreset(scale, fraction);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? context.gold.withValues(alpha: 0.15) : context.surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? context.gold : context.line),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? context.gold : context.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
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
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(color: context.textPrimary, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Custom high-performance canvas painter for smooth zoomable, pan-able, multi-scale line charts
class _InteractiveTrendLinePainter extends CustomPainter {
  final List<_TrendPoint> points;
  final int? hoveredIndex;
  final double zoomScale;
  final double scrollOffset;
  final double maxY;
  final bool isCumulative;
  final double paddingLeft;
  final double paddingRight;
  final TrendGranularity effectiveGranularity;
  final Color gridColor;
  final Color labelColor;
  final Color hoverColor;
  final Color emeraldColor;
  final Color brickColor;

  _InteractiveTrendLinePainter({
    required this.points,
    required this.hoveredIndex,
    required this.zoomScale,
    required this.scrollOffset,
    required this.maxY,
    required this.isCumulative,
    required this.paddingLeft,
    required this.paddingRight,
    required this.effectiveGranularity,
    required this.gridColor,
    required this.labelColor,
    required this.hoverColor,
    required this.emeraldColor,
    required this.brickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double paddingTop = 16.0;
    const double paddingBottom = 26.0;
    final chartHeight = size.height - paddingTop - paddingBottom;
    final contentWidth = (size.width - paddingLeft - paddingRight) * zoomScale;
    final pointSpacing = points.length > 1 ? contentWidth / (points.length - 1) : 0.0;

    // 1. Draw horizontal reference grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const gridSteps = 3;
    for (int i = 0; i <= gridSteps; i++) {
      final y = paddingTop + (chartHeight * (i / gridSteps));
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    // Map data points to screen coordinates
    final inflowCoords = <Offset>[];
    final outflowCoords = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = paddingLeft + (i * pointSpacing) - scrollOffset;
      final inY = paddingTop + chartHeight - ((points[i].inflow / maxY) * chartHeight).clamp(0.0, chartHeight);
      final outY = paddingTop + chartHeight - ((points[i].outflow / maxY) * chartHeight).clamp(0.0, chartHeight);

      inflowCoords.add(Offset(x, inY));
      outflowCoords.add(Offset(x, outY));
    }

    // Clip to chart drawing area horizontally
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(paddingLeft, 0, size.width - paddingLeft - paddingRight, size.height));

    // 2. Draw Area Gradients & Smooth Bezier Curves
    _drawCurvedLineAndArea(
      canvas: canvas,
      coords: outflowCoords,
      color: brickColor,
      fillColor: brickColor.withValues(alpha: 0.12),
      chartHeight: chartHeight,
      paddingTop: paddingTop,
    );

    _drawCurvedLineAndArea(
      canvas: canvas,
      coords: inflowCoords,
      color: emeraldColor,
      fillColor: emeraldColor.withValues(alpha: 0.14),
      chartHeight: chartHeight,
      paddingTop: paddingTop,
    );

    // 3. Draw dots on key points or when zoomed in
    final shouldDrawDots = zoomScale > 1.8 || points.length <= 16;
    if (shouldDrawDots) {
      for (int i = 0; i < points.length; i++) {
        final inPt = inflowCoords[i];
        final outPt = outflowCoords[i];
        if (inPt.dx >= paddingLeft - 10 && inPt.dx <= size.width - paddingRight + 10) {
          if (points[i].inflow > 0) {
            canvas.drawCircle(inPt, 3.0, Paint()..color = emeraldColor);
            canvas.drawCircle(inPt, 1.5, Paint()..color = Colors.white);
          }
          if (points[i].outflow > 0) {
            canvas.drawCircle(outPt, 3.0, Paint()..color = brickColor);
            canvas.drawCircle(outPt, 1.5, Paint()..color = Colors.white);
          }
        }
      }
    }

    // 4. Draw Active Scrubber Line & Beacons (When Point is Hovered)
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < points.length) {
      final hX = inflowCoords[hoveredIndex!].dx;
      final inY = inflowCoords[hoveredIndex!].dy;
      final outY = outflowCoords[hoveredIndex!].dy;

      final scrubberPaint = Paint()
        ..color = hoverColor
        ..strokeWidth = 1.4;

      canvas.drawLine(
        Offset(hX, paddingTop),
        Offset(hX, paddingTop + chartHeight),
        scrubberPaint,
      );

      final inBeaconHalo = Paint()..color = emeraldColor.withValues(alpha: 0.25);
      final inBeaconCore = Paint()..color = emeraldColor;
      final inBeaconCenter = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(hX, inY), 8.0, inBeaconHalo);
      canvas.drawCircle(Offset(hX, inY), 4.5, inBeaconCore);
      canvas.drawCircle(Offset(hX, inY), 2.2, inBeaconCenter);

      final outBeaconHalo = Paint()..color = brickColor.withValues(alpha: 0.25);
      final outBeaconCore = Paint()..color = brickColor;
      final outBeaconCenter = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(hX, outY), 8.0, outBeaconHalo);
      canvas.drawCircle(Offset(hX, outY), 4.5, outBeaconCore);
      canvas.drawCircle(Offset(hX, outY), 2.2, outBeaconCenter);
    }

    canvas.restore();

    // 5. Draw Bottom X-Axis Labels with Intelligent Collision Avoidance
    final labelY = paddingTop + chartHeight + 8.0;
    double lastPaintedRight = -999.0;

    for (int i = 0; i < points.length; i++) {
      final isHovered = i == hoveredIndex;
      final x = paddingLeft + (i * pointSpacing) - scrollOffset;
      if (x < paddingLeft - 10 || x > size.width - paddingRight + 10) continue;

      final textSpan = TextSpan(
        text: points[i].label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: isHovered ? 10 : 9,
          fontWeight: isHovered ? FontWeight.bold : FontWeight.w600,
          color: isHovered ? hoverColor : labelColor,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textLeft = x - (textPainter.width / 2);
      final textRight = textLeft + textPainter.width;

      if (!isHovered && textLeft < lastPaintedRight + 10.0) {
        continue;
      }

      textPainter.paint(
        canvas,
        Offset(textLeft, labelY),
      );
      lastPaintedRight = textRight;
    }
  }

  void _drawCurvedLineAndArea({
    required Canvas canvas,
    required List<Offset> coords,
    required Color color,
    required Color fillColor,
    required double chartHeight,
    required double paddingTop,
  }) {
    if (coords.length < 2) return;

    final linePath = Path();
    final areaPath = Path();

    linePath.moveTo(coords.first.dx, coords.first.dy);
    areaPath.moveTo(coords.first.dx, paddingTop + chartHeight);
    areaPath.lineTo(coords.first.dx, coords.first.dy);

    for (int i = 0; i < coords.length - 1; i++) {
      final p0 = i > 0 ? coords[i - 1] : coords[i];
      final p1 = coords[i];
      final p2 = coords[i + 1];
      final p3 = i + 2 < coords.length ? coords[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      linePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      areaPath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    areaPath.lineTo(coords.last.dx, paddingTop + chartHeight);
    areaPath.close();

    canvas.drawPath(areaPath, Paint()..color = fillColor);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _InteractiveTrendLinePainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.isCumulative != isCumulative ||
        oldDelegate.effectiveGranularity != effectiveGranularity ||
        oldDelegate.points != points ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}
