import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expense/domain/entities/monthly_summary.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_detail_page.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';

class WaterfallStepItem {
  final String stepNumber;
  final String? categoryId;
  final String title;
  final double originalAmount;
  final double amount;
  final bool isIncome;
  final bool isNet;
  final IconData icon;
  final Color primaryColor;
  final Color darkColor;
  final double runningBalance;
  final double percentage;

  const WaterfallStepItem({
    required this.stepNumber,
    this.categoryId,
    required this.title,
    required this.originalAmount,
    required this.amount,
    required this.isIncome,
    required this.isNet,
    required this.icon,
    required this.primaryColor,
    required this.darkColor,
    required this.runningBalance,
    required this.percentage,
  });
}

class WaterfallDiagram extends StatefulWidget {
  final MonthlySummary summary;
  final ExpenseProvider provider;

  const WaterfallDiagram({
    super.key,
    required this.summary,
    required this.provider,
  });

  @override
  State<WaterfallDiagram> createState() => _WaterfallDiagramState();
}

class _WaterfallDiagramState extends State<WaterfallDiagram> {
  int _selectedStepIndex = 0;
  bool _isSimulationMode = false;
  Timer? _playbackTimer;
  bool _isPlaying = false;

  // Custom simulation multipliers for category steps: key = stepNumber, value = multiplier (0.0 to 1.5)
  final Map<String, double> _stepMultipliers = {};

  static const List<Map<String, Color>> _palette = [
    {'primary': Color(0xFF7CB342), 'dark': Color(0xFF558B2F)}, // Lime Green (Stage 01 Inflow)
    {'primary': Color(0xFF00ACC1), 'dark': Color(0xFF00838F)}, // Cyan / Teal
    {'primary': Color(0xFF1E88E5), 'dark': Color(0xFF1565C0)}, // Blue
    {'primary': Color(0xFF5E35B1), 'dark': Color(0xFF4527A0)}, // Deep Purple
    {'primary': Color(0xFFD81B60), 'dark': Color(0xFFAD1457)}, // Magenta / Pink
    {'primary': Color(0xFFF4511E), 'dark': Color(0xFFD84315)}, // Deep Orange
    {'primary': Color(0xFF43A047), 'dark': Color(0xFF2E7D32)}, // Emerald (Net Surplus)
  ];

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startCascadePlayback(int totalSteps) {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = true;
      _selectedStepIndex = 0;
    });

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_selectedStepIndex < totalSteps - 1) {
        setState(() {
          _selectedStepIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  List<WaterfallStepItem> _buildSteps() {
    final summary = widget.summary;
    final provider = widget.provider;
    final totalIncome = summary.totalIncome;

    final steps = <WaterfallStepItem>[];
    double running = totalIncome;

    // Step 01: Inflow / Income
    final step1Num = '01';
    final step1Mult = _isSimulationMode ? (_stepMultipliers[step1Num] ?? 1.0) : 1.0;
    final simulatedIncome = totalIncome * step1Mult;
    running = simulatedIncome;

    steps.add(
      WaterfallStepItem(
        stepNumber: step1Num,
        categoryId: null,
        title: 'Gross Inflow',
        originalAmount: totalIncome,
        amount: simulatedIncome,
        isIncome: true,
        isNet: false,
        icon: Icons.account_balance_wallet_outlined,
        primaryColor: _palette[0]['primary']!,
        darkColor: _palette[0]['dark']!,
        runningBalance: running,
        percentage: 100.0,
      ),
    );

    // Top spending categories sorted descending
    final sortedCategories = provider.rolledUpCategoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int colorIdx = 1;
    final maxCategories = 4;
    double otherExpenses = 0;

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final originalAmount = entry.value;
      if (originalAmount <= 0) continue;

      if (i < maxCategories || sortedCategories.length <= maxCategories + 1) {
        final stepNum = (steps.length + 1).toString().padLeft(2, '0');
        final multiplier = _isSimulationMode ? (_stepMultipliers[stepNum] ?? 1.0) : 1.0;
        final simulatedAmount = originalAmount * multiplier;
        running -= simulatedAmount;

        final cat = provider.getCategoryById(entry.key);
        final colorPair = _palette[colorIdx % _palette.length];
        colorIdx++;

        final pct = simulatedIncome > 0 ? (simulatedAmount / simulatedIncome) * 100 : 0.0;

        steps.add(
          WaterfallStepItem(
            stepNumber: stepNum,
            categoryId: entry.key,
            title: cat?.name ?? 'Uncategorized',
            originalAmount: originalAmount,
            amount: simulatedAmount,
            isIncome: false,
            isNet: false,
            icon: cat?.icon ?? Icons.category_outlined,
            primaryColor: colorPair['primary']!,
            darkColor: colorPair['dark']!,
            runningBalance: running,
            percentage: pct,
          ),
        );
      } else {
        otherExpenses += originalAmount;
      }
    }

    if (otherExpenses > 0) {
      final stepNum = (steps.length + 1).toString().padLeft(2, '0');
      final multiplier = _isSimulationMode ? (_stepMultipliers[stepNum] ?? 1.0) : 1.0;
      final simulatedOther = otherExpenses * multiplier;
      running -= simulatedOther;

      final colorPair = _palette[colorIdx % _palette.length];
      final pct = simulatedIncome > 0 ? (simulatedOther / simulatedIncome) * 100 : 0.0;

      steps.add(
        WaterfallStepItem(
          stepNumber: stepNum,
          categoryId: null,
          title: 'Other Outflows',
          originalAmount: otherExpenses,
          amount: simulatedOther,
          isIncome: false,
          isNet: false,
          icon: Icons.more_horiz_rounded,
          primaryColor: colorPair['primary']!,
          darkColor: colorPair['dark']!,
          runningBalance: running,
          percentage: pct,
        ),
      );
    }

    // Final Step: Net Surplus / Deficit
    final isSaved = running >= 0;
    final finalStepNum = (steps.length + 1).toString().padLeft(2, '0');
    final netPct = simulatedIncome > 0 ? (running.abs() / simulatedIncome) * 100 : 0.0;

    steps.add(
      WaterfallStepItem(
        stepNumber: finalStepNum,
        categoryId: null,
        title: isSaved ? 'Net Retained' : 'Net Deficit',
        originalAmount: summary.netBalance.abs(),
        amount: running.abs(),
        isIncome: isSaved,
        isNet: true,
        icon: isSaved ? Icons.savings_outlined : Icons.warning_amber_rounded,
        primaryColor: isSaved ? const Color(0xFF43A047) : const Color(0xFFE53935),
        darkColor: isSaved ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        runningBalance: running,
        percentage: netPct,
      ),
    );

    return steps;
  }

  void _showInspectTransactionsSheet(BuildContext context, WaterfallStepItem step) {
    final provider = widget.provider;
    final selectedMonth = provider.selectedMonth;

    final transactions = provider.expenses.where((e) {
      if (e.isDeleted) return false;
      if (e.date.year != selectedMonth.year || e.date.month != selectedMonth.month) return false;
      if (step.isIncome) {
        return e.type.name == 'income' && e.toAccountId == null;
      }
      if (step.categoryId != null) {
        return e.categoryId == step.categoryId;
      }
      return e.type.name == 'expense' && e.toAccountId == null;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: ctx.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: ctx.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [step.primaryColor, step.darkColor],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(step.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stage ${step.stepNumber} Breakdown',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ctx.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            step.title,
                            style: GoogleFonts.fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ctx.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${step.isIncome ? '+' : '-'}${CurrencyFormatter.format(step.amount)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: step.isIncome ? ctx.emerald : ctx.brick,
                          ),
                        ),
                        Text(
                          '${transactions.length} items',
                          style: GoogleFonts.inter(fontSize: 11, color: ctx.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: ctx.line),

              // Transaction Items List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'No transactions recorded for this stage.',
                            style: GoogleFonts.inter(color: ctx.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (subCtx, idx) {
                          final item = transactions[idx];
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExpenseDetailPage(expense: item),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ctx.cardBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: ctx.line),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title.isNotEmpty ? item.title : step.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: ctx.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          DateFormatter.format(item.date),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: ctx.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${item.type.name == 'income' ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: item.type.name == 'income'
                                          ? ctx.emerald
                                          : ctx.brick,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: ctx.textMuted),
                                ],
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
    final steps = _buildSteps();
    final clampedIndex = _selectedStepIndex.clamp(0, steps.length - 1);
    final activeStep = steps[clampedIndex];

    // Compute continuous canvas height for the staircase
    final stepCount = steps.length;
    final stepHeight = 52.0;
    final staircaseCanvasHeight = (stepCount * stepHeight) + 80.0;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row 1: Badge + Action Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.gold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'WATERFALL MODEL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: context.gold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$stepCount Stages',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),

              // Interactive Action Chips: Replay + What-If
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _startCascadePlayback(steps.length),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isPlaying ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : context.surface2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 13,
                            color: _isPlaying ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft) : context.textPrimary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isPlaying ? 'Playing' : 'Replay',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isPlaying ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft) : context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _isSimulationMode = !_isSimulationMode;
                        if (!_isSimulationMode) {
                          _stepMultipliers.clear();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isSimulationMode ? context.gold : context.surface2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isSimulationMode ? context.gold : context.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 12,
                            color: _isSimulationMode ? Colors.white : context.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'What-If',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isSimulationMode ? Colors.white : context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Header Title
          Text(
            'Cash Cascade Progression',
            style: GoogleFonts.fraunces(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),

          // Simulation Mode Notification Banner if active
          if (_isSimulationMode) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_graph_rounded, color: context.gold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'What-If Active: Tap any stage to adjust spend slider.',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _stepMultipliers.clear()),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.brick,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Continuous 3D Isometric Staircase Canvas
          SizedBox(
            height: staircaseCanvasHeight,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final y = details.localPosition.dy;
                    // Map tap Y position to step index
                    final idx = ((y - 20) / stepHeight).floor().clamp(0, steps.length - 1);
                    setState(() => _selectedStepIndex = idx);
                  },
                  child: Stack(
                    children: [
                      // Continuous 3D Isometric Staircase Custom Painter
                      CustomPaint(
                        size: Size(constraints.maxWidth, staircaseCanvasHeight),
                        painter: _ContinuousIsometricStaircasePainter(
                          steps: steps,
                          selectedIndex: clampedIndex,
                          stepHeight: stepHeight,
                          isDark: context.isDark,
                          tileBg: context.surface2,
                          tileBorder: context.line,
                          tileText: context.textPrimary,
                          goldColor: context.gold,
                          goldSoft: AppTheme.goldSoft,
                        ),
                      ),

                      // Interactive Pointer Labels on the right
                      ...List.generate(steps.length, (index) {
                        final step = steps[index];
                        final isSelected = index == clampedIndex;
                        final stepY = 16.0 + (index * stepHeight);

                        return Positioned(
                          left: (constraints.maxWidth - 146.0).clamp(160.0, 300.0),
                          right: 0.0,
                          top: stepY - 4.0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _selectedStepIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? step.primaryColor.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? step.primaryColor.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    step.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${step.isIncome ? '+' : (step.isNet ? (step.runningBalance >= 0 ? '+' : '-') : '-')}${CurrencyFormatter.format(step.amount)}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: step.isIncome
                                          ? context.emerald
                                          : (step.isNet
                                              ? (step.runningBalance >= 0 ? context.emerald : context.brick)
                                              : context.brick),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // Watermark Badge: "Waterfall Model" at bottom right
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: context.gold, width: 3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Waterfall',
                                style: GoogleFonts.fraunces(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Model',
                                style: GoogleFonts.fraunces(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textMuted,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: context.line),
          const SizedBox(height: 14),

          // Active Stage Detail & Interactive Simulation Card
          _buildStageDetailCard(context, activeStep),
        ],
      ),
    );
  }

  Widget _buildStageDetailCard(BuildContext context, WaterfallStepItem step) {
    final currentMultiplier = _stepMultipliers[step.stepNumber] ?? 1.0;

    return Container(
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.line),
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [step.primaryColor, step.darkColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(step.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STAGE ${step.stepNumber}: ${step.title.toUpperCase()}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${step.percentage.toStringAsFixed(1)}% Share',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: step.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          step.isNet ? 'Final Net Balance' : 'Running Post-Stage Balance',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(step.runningBalance),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: step.runningBalance >= 0 ? context.emerald : context.brick,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Interactive Simulation Slider (if in simulation mode and not net step)
          if (_isSimulationMode && !step.isNet) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: context.line),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Simulation: ${(currentMultiplier * 100).toInt()}% Spend',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(step.amount),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: step.primaryColor,
                inactiveTrackColor: context.line,
                thumbColor: context.gold,
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: currentMultiplier,
                min: 0.0,
                max: 1.5,
                divisions: 30,
                onChanged: (val) {
                  setState(() {
                    _stepMultipliers[step.stepNumber] = val;
                  });
                },
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Inspect Stage Transactions Button
          if (!step.isNet)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showInspectTransactionsSheet(context, step),
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.cardBg,
                  side: BorderSide(color: context.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: Icon(Icons.receipt_long_rounded, size: 14, color: context.textPrimary),
                label: Text(
                  'Inspect Stage Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Continuous Isometric Descending Staircase Painter
/// Faithfully rendering the reference 3D isometric stepped waterfall diagram.
class _ContinuousIsometricStaircasePainter extends CustomPainter {
  final List<WaterfallStepItem> steps;
  final int selectedIndex;
  final double stepHeight;
  final bool isDark;
  final Color tileBg;
  final Color tileBorder;
  final Color tileText;
  final Color goldColor;
  final Color goldSoft;

  _ContinuousIsometricStaircasePainter({
    required this.steps,
    required this.selectedIndex,
    required this.stepHeight,
    required this.isDark,
    required this.tileBg,
    required this.tileBorder,
    required this.tileText,
    required this.goldColor,
    required this.goldSoft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = steps.length;
    if (count == 0) return;

    // Basis vectors for top-left to bottom-right isometric descent
    const double stepDx = 16.0; // Rightward shift per step (Top-Left to Bottom-Right)
    final double stepDy = stepHeight; // Downward shift per step
    const double treadWidth = 52.0;
    const double treadDepthX = 18.0;
    const double treadDepthY = 18.0;
    const double riserHeight = 18.0;

    // Top-most step starting origin (Top-Left)
    final double startX = 36.0;
    final double startY = 18.0;

    // 1. Draw solid left bevel extrusion of the entire staircase
    final leftWallPath = Path();
    for (int i = 0; i < count; i++) {
      final ox = startX + (i * stepDx);
      final oy = startY + (i * stepDy);

      final pBackLeft = Offset(ox, oy);
      final pFrontLeft = Offset(ox + treadDepthX, oy + treadDepthY);
      final pDropLeft = Offset(ox + treadDepthX, oy + treadDepthY + riserHeight);

      if (i == 0) {
        leftWallPath.moveTo(pBackLeft.dx, pBackLeft.dy);
      }
      leftWallPath.lineTo(pFrontLeft.dx, pFrontLeft.dy);
      leftWallPath.lineTo(pDropLeft.dx, pDropLeft.dy);
    }
    // Close left wall path downwards
    final lastOx = startX + ((count - 1) * stepDx);
    final lastOy = startY + ((count - 1) * stepDy);
    final lastBottomLeft = Offset(lastOx + treadDepthX, lastOy + treadDepthY + riserHeight);
    leftWallPath.lineTo(lastBottomLeft.dx - 12, lastBottomLeft.dy + 8);
    leftWallPath.lineTo(startX - 14, lastBottomLeft.dy + 8);
    leftWallPath.close();

    final leftShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.3 : 0.06);
    canvas.drawPath(leftWallPath, leftShadowPaint);

    // 2. Draw each connected step from top-left to bottom-right (0 to count-1)
    for (int i = 0; i < count; i++) {
      final step = steps[i];
      final isSelected = i == selectedIndex;

      final ox = startX + (i * stepDx);
      final oy = startY + (i * stepDy);

      // Tread points (top illuminated isometric parallelogram)
      final pBackLeft = Offset(ox, oy);
      final pBackRight = Offset(ox + treadWidth, oy - 10.0);
      final pFrontRight = Offset(ox + treadWidth + treadDepthX, oy - 10.0 + treadDepthY);
      final pFrontLeft = Offset(ox + treadDepthX, oy + treadDepthY);

      final treadPath = Path()
        ..moveTo(pBackLeft.dx, pBackLeft.dy)
        ..lineTo(pBackRight.dx, pBackRight.dy)
        ..lineTo(pFrontRight.dx, pFrontRight.dy)
        ..lineTo(pFrontLeft.dx, pFrontLeft.dy)
        ..close();

      // Top Tread Gradient Paint (Illuminated top face)
      final treadPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            step.primaryColor.withValues(alpha: isSelected ? 1.0 : 0.92),
            step.primaryColor,
          ],
        ).createShader(Rect.fromPoints(pBackLeft, pFrontRight));
      canvas.drawPath(treadPath, treadPaint);

      // Riser points (vertical drop face connecting to next step)
      final pDropLeft = Offset(pFrontLeft.dx, pFrontLeft.dy + riserHeight);
      final pDropRight = Offset(pFrontRight.dx, pFrontRight.dy + riserHeight);

      final riserPath = Path()
        ..moveTo(pFrontLeft.dx, pFrontLeft.dy)
        ..lineTo(pFrontRight.dx, pFrontRight.dy)
        ..lineTo(pDropRight.dx, pDropRight.dy)
        ..lineTo(pDropLeft.dx, pDropLeft.dy)
        ..close();

      // Riser Gradient Paint (Shaded vertical drop face)
      final riserPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            step.darkColor,
            step.darkColor.withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromPoints(pFrontLeft, pDropRight));
      canvas.drawPath(riserPath, riserPaint);

      // Right Side Step Bevel (facet)
      final rightFacetPath = Path()
        ..moveTo(pBackRight.dx, pBackRight.dy)
        ..lineTo(pFrontRight.dx, pFrontRight.dy)
        ..lineTo(pDropRight.dx, pDropRight.dy)
        ..lineTo(pBackRight.dx, pBackRight.dy + riserHeight)
        ..close();

      final rightFacetPaint = Paint()
        ..color = step.darkColor.withValues(alpha: 0.75);
      canvas.drawPath(rightFacetPath, rightFacetPaint);

      // Left Side Bevel facet for step
      final leftFacetPath = Path()
        ..moveTo(pBackLeft.dx, pBackLeft.dy)
        ..lineTo(pFrontLeft.dx, pFrontLeft.dy)
        ..lineTo(pDropLeft.dx, pDropLeft.dy)
        ..lineTo(pBackLeft.dx, pBackLeft.dy + riserHeight)
        ..close();

      final leftFacetPaint = Paint()
        ..color = step.darkColor.withValues(alpha: 0.65);
      canvas.drawPath(leftFacetPath, leftFacetPaint);

      // Highlight outline if selected
      if (isSelected) {
        final outlinePaint = Paint()
          ..color = goldColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawPath(treadPath, outlinePaint);
        canvas.drawPath(riserPath, outlinePaint);
        canvas.drawPath(rightFacetPath, outlinePaint);
      }

      // Draw crisp category icon on the tread face
      final treadCenter = Offset(
        (pBackLeft.dx + pFrontRight.dx) / 2,
        (pBackLeft.dy + pFrontRight.dy) / 2,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(step.icon.codePoint),
          style: TextStyle(
            fontSize: 16,
            fontFamily: step.icon.fontFamily,
            package: step.icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(treadCenter.dx - (textPainter.width / 2), treadCenter.dy - (textPainter.height / 2)),
      );

      // Draw pointer line and dot extending to the right label column
      final targetLabelX = size.width - 150.0;
      final pointerLinePaint = Paint()
        ..color = step.primaryColor.withValues(alpha: isSelected ? 0.9 : 0.4)
        ..strokeWidth = isSelected ? 1.8 : 1.2;

      final pStart = Offset(pFrontRight.dx + 4.0, pFrontRight.dy);
      final pEnd = Offset(targetLabelX - 8.0, pFrontRight.dy);

      if (pEnd.dx > pStart.dx) {
        canvas.drawLine(pStart, pEnd, pointerLinePaint);
      }
      canvas.drawCircle(
        pStart,
        isSelected ? 3.0 : 2.2,
        Paint()..color = step.primaryColor,
      );
      canvas.drawCircle(
        pEnd,
        isSelected ? 3.5 : 2.5,
        Paint()..color = step.primaryColor,
      );

      // 3. Draw Floating Isometric Number Tile (01, 02, 03...) on top-left
      final tileCenter = Offset(ox - 18.0, oy + 2.0);
      const double tileW = 26.0;
      const double tileH = 24.0;

      // Isometric tile quad
      final tilePath = Path()
        ..moveTo(tileCenter.dx - (tileW / 2), tileCenter.dy - (tileH / 2) + 3)
        ..lineTo(tileCenter.dx + (tileW / 2), tileCenter.dy - (tileH / 2) - 3)
        ..lineTo(tileCenter.dx + (tileW / 2), tileCenter.dy + (tileH / 2) - 3)
        ..lineTo(tileCenter.dx - (tileW / 2), tileCenter.dy + (tileH / 2) + 3)
        ..close();

      // Tile shadow
      canvas.drawPath(
        tilePath.shift(const Offset(1, 2)),
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );

      // Tile surface
      final tilePaint = Paint()
        ..color = isSelected ? (isDark ? AppTheme.darkSurface2 : AppTheme.ink) : tileBg;
      canvas.drawPath(tilePath, tilePaint);

      // Tile border
      final tileBorderPaint = Paint()
        ..color = isSelected ? goldColor : tileBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.5 : 1.0;
      canvas.drawPath(tilePath, tileBorderPaint);

      // Tile number text
      final numPainter = TextPainter(
        text: TextSpan(
          text: step.stepNumber,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? goldSoft : tileText,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      numPainter.paint(
        canvas,
        Offset(tileCenter.dx - (numPainter.width / 2), tileCenter.dy - (numPainter.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContinuousIsometricStaircasePainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.steps != steps ||
        oldDelegate.stepHeight != stepHeight ||
        oldDelegate.isDark != isDark ||
        oldDelegate.tileBg != tileBg ||
        oldDelegate.tileBorder != tileBorder ||
        oldDelegate.goldColor != goldColor;
  }
}
