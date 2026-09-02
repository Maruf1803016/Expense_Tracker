import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/plan/presentation/widgets/goals_tab_view.dart';
import 'package:expense_tracker/features/plan/presentation/widgets/trip_plans_tab_view.dart';
import 'package:expense_tracker/features/loan/presentation/widgets/loans_tab_view.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/recurring_tab_view.dart';
import 'package:expense_tracker/features/work_routine/presentation/pages/work_routine_page.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/work_routine/presentation/providers/work_routine_provider.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';

class HorizonPage extends StatefulWidget {
  const HorizonPage({super.key});

  @override
  State<HorizonPage> createState() => _HorizonPageState();
}

class _HorizonPageState extends State<HorizonPage> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final tripPlanProvider = context.watch<TripPlanProvider>();
    final loanProvider = context.watch<LoanProvider>();
    final recurringProvider = context.watch<RecurringTransactionProvider>();
    final workRoutineProvider = context.watch<WorkRoutineProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isHidden = settingsProvider.hideAmounts;

    // 1. Goals metrics
    final activeGoalsList = goalProvider.plans.where((g) => !g.isArchived).toList();
    final activeGoals = activeGoalsList.length;
    double totalGoalSaved = 0.0;
    double targetGoalTotal = 0.0;
    for (var g in activeGoalsList) {
      final gExpenses = expenseProvider.expenses.where((e) => e.planId == g.id && !e.isDeleted);
      final saved = gExpenses.fold<double>(0.0, (sum, e) => e.type == CategoryType.expense ? sum + e.amount : sum - e.amount);
      totalGoalSaved += saved;
      targetGoalTotal += g.totalBudget;
    }

    // 2. Trip plans metrics
    final activeTripPlansList = tripPlanProvider.tripPlans;
    final activeTripPlans = activeTripPlansList.length;
    double totalTripBudget = 0.0;
    double totalTripSpent = 0.0;
    for (var tp in activeTripPlansList) {
      totalTripBudget += tp.budgetAmount;
      final tpExpenses = expenseProvider.expenses.where((e) => e.planId == tp.id && !e.isDeleted);
      totalTripSpent += tpExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    }
    final remainingTripBudget = totalTripBudget - totalTripSpent;

    // 3. Debt & Loans metrics
    final activeLoansList = loanProvider.activeLoans;
    final totalBorrowed = loanProvider.totalBorrowed;
    final totalLent = loanProvider.totalLent;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueSoonLoans = activeLoansList.where((l) {
      if (l.dueDate == null) return false;
      final due = DateTime(l.dueDate!.year, l.dueDate!.month, l.dueDate!.day);
      final diff = due.difference(today).inDays;
      return diff <= 7;
    }).length;

    // 4. Recurring metrics
    final recurringSources = recurringProvider.sources;
    final dueIn7Days = recurringSources.where((s) {
      final due = DateTime(s.nextDueDate.year, s.nextDueDate.month, s.nextDueDate.day);
      final diff = due.difference(today).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();
    final totalRecurringDue = dueIn7Days.fold<double>(0.0, (sum, s) => sum + s.expectedAmount);
    final incomeDueCount = dueIn7Days.where((s) => s.type == 'income').length;
    final billsDueCount = dueIn7Days.where((s) => s.type == 'expense').length;

    // 5. Work & Routine metrics
    final routines = workRoutineProvider.routines;
    final currentYear = now.year;
    final currentMonth = now.month;
    int totalPlannedDays = 0;
    int totalAttendedDays = 0;
    for (var r in routines) {
      totalPlannedDays += r.getPlannedDays(currentYear, currentMonth);
      totalAttendedDays += r.getAttendedDays(currentYear, currentMonth);
    }

    final totalActivePlans = activeGoals + activeTripPlans + activeLoansList.length + recurringSources.length + routines.length;

    // Modules data definitions
    final modules = [
      _ModuleData(
        icon: Icons.savings_rounded,
        iconColor: context.emerald,
        title: 'Savings Goals',
        primaryMetric: isHidden
            ? '•••••• / ••••••'
            : targetGoalTotal > 0
                ? '${CurrencyFormatter.format(totalGoalSaved)} / ${CurrencyFormatter.format(targetGoalTotal)}'
                : (activeGoals > 0 ? '${CurrencyFormatter.format(totalGoalSaved)} saved' : 'No active goals'),
        contextualStatus: activeGoals > 0
            ? '$activeGoals ${activeGoals == 1 ? 'goal' : 'goals'} active'
            : 'Track targets & milestones',
        progress: targetGoalTotal > 0 ? (totalGoalSaved / targetGoalTotal).clamp(0.0, 1.0) : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const _ModuleScaffold(title: 'Savings Goals', body: GoalsTabView())),
          );
        },
      ),
      _ModuleData(
        icon: Icons.flight_takeoff_rounded,
        iconColor: context.gold,
        title: 'Trip & Event Plans',
        primaryMetric: isHidden
            ? '••••••'
            : activeTripPlans > 0
                ? '${CurrencyFormatter.format(remainingTripBudget)} remaining budget'
                : 'No active plans',
        contextualStatus: activeTripPlans > 0
            ? '$activeTripPlans ${activeTripPlans == 1 ? 'plan' : 'plans'} active'
            : 'Plan trips & events',
        progress: totalTripBudget > 0 ? (totalTripSpent / totalTripBudget).clamp(0.0, 1.0) : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const _ModuleScaffold(title: 'Trip & Event Plans', body: TripPlansTabView())),
          );
        },
      ),
      _ModuleData(
        icon: Icons.handshake_rounded,
        iconColor: context.brick,
        title: 'Debt & Loans',
        primaryMetric: isHidden
            ? '••••••'
            : totalBorrowed > 0
                ? '${CurrencyFormatter.format(totalBorrowed)} payable balance'
                : (totalLent > 0 ? '${CurrencyFormatter.format(totalLent)} receivable' : 'No balances'),
        contextualStatus: dueSoonLoans > 0
            ? '$dueSoonLoans payment due soon'
            : (activeLoansList.isNotEmpty ? '${activeLoansList.length} loans tracked' : 'No payment due'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const _ModuleScaffold(title: 'Debt & Loans', body: LoansTabView())),
          );
        },
      ),
      _ModuleData(
        icon: Icons.autorenew_rounded,
        iconColor: context.isDark ? AppTheme.goldSoft : AppTheme.ink,
        title: 'Recurring & Bills',
        primaryMetric: isHidden
            ? '••••••'
            : dueIn7Days.isNotEmpty
                ? '${CurrencyFormatter.format(totalRecurringDue)} due in 7d'
                : (recurringSources.isNotEmpty ? '${recurringSources.length} active schedules' : 'No schedules'),
        contextualStatus: dueIn7Days.isNotEmpty
            ? '$incomeDueCount income · $billsDueCount bills due'
            : (recurringSources.isNotEmpty ? 'All schedules up to date' : 'Automate subscriptions'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const _ModuleScaffold(title: 'Recurring Income & Bills', body: RecurringTabView())),
          );
        },
      ),
      _ModuleData(
        icon: Icons.schedule_rounded,
        iconColor: const Color(0xFFC89B3C),
        title: 'Work & Routine',
        primaryMetric: routines.isNotEmpty
            ? '$totalAttendedDays / $totalPlannedDays days attended'
            : 'No active routines',
        contextualStatus: routines.isNotEmpty
            ? '${routines.length} ${routines.length == 1 ? 'routine' : 'routines'} active this month'
            : 'Log shifts, tuition, and attendance',
        progress: totalPlannedDays > 0 ? (totalAttendedDays / totalPlannedDays).clamp(0.0, 1.0) : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WorkRoutinePage()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Compact Editorial Summary Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: context.isDark ? AppTheme.darkSurface2 : AppTheme.ink,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.goldLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FORWARD HORIZON',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppTheme.goldSoft,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.goldSoft.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$totalActivePlans active commitments',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plans & Progress',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Forward-looking targets, debt amortization, recurring commitments, and work schedules.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.goldSoft.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Header with View Mode Switcher (Grid / List)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HORIZON MODULES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: context.textMuted,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!_isGrid) setState(() => _isGrid = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isGrid ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 14,
                                color: _isGrid
                                    ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft)
                                    : context.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Grid',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isGrid
                                      ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft)
                                      : context.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_isGrid) setState(() => _isGrid = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isGrid ? (context.isDark ? AppTheme.goldSoft : AppTheme.ink) : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.view_agenda_rounded,
                                size: 14,
                                color: !_isGrid
                                    ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft)
                                    : context.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'List',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: !_isGrid
                                      ? (context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft)
                                      : context.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Modules Content
            if (_isGrid) ...[
              // 2-Column Uniform Grid Layout
              for (int i = 0; i < modules.length; i += 2) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildHorizonGridCard(
                        context: context,
                        module: modules[i],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i + 1 < modules.length
                          ? _buildHorizonGridCard(
                              context: context,
                              module: modules[i + 1],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                if (i + 2 < modules.length) const SizedBox(height: 12),
              ],
            ] else ...[
              // Single-Column Full-Width List Layout
              for (int i = 0; i < modules.length; i++) ...[
                _buildHorizonListCard(
                  context: context,
                  module: modules[i],
                ),
                if (i < modules.length - 1) const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Compact 2-column Grid Card
  Widget _buildHorizonGridCard({
    required BuildContext context,
    required _ModuleData module,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 154),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Icon capsule
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: module.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(module.icon, size: 20, color: module.iconColor),
                ),
              ),
              const SizedBox(height: 10),

              // Title & Metrics
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    module.primaryMetric,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.contextualStatus,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: context.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (module.progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: module.progress,
                        backgroundColor: context.surface2,
                        valueColor: AlwaysStoppedAnimation<Color>(module.iconColor),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Single-column full-width list card
  Widget _buildHorizonListCard({
    required BuildContext context,
    required _ModuleData module,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Capsule
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: module.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(module.icon, size: 20, color: module.iconColor),
                ),
              ),
              const SizedBox(width: 14),

              // Content Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.primaryMetric,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.contextualStatus,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Forward affordance
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String primaryMetric;
  final String contextualStatus;
  final double? progress;
  final VoidCallback onTap;

  const _ModuleData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.primaryMetric,
    required this.contextualStatus,
    this.progress,
    required this.onTap,
  });
}

class _ModuleScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const _ModuleScaffold({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary)),
        backgroundColor: context.bg,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: body,
    );
  }
}
