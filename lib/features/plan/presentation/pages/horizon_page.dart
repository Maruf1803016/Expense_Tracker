import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/plan/presentation/widgets/goals_tab_view.dart';
import 'package:expense_tracker/features/plan/presentation/widgets/trip_plans_tab_view.dart';
import 'package:expense_tracker/features/loan/presentation/widgets/loans_tab_view.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/recurring_tab_view.dart';
import 'package:expense_tracker/features/work_routine/presentation/pages/work_routine_page.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';

class HorizonPage extends StatefulWidget {
  const HorizonPage({super.key});

  @override
  State<HorizonPage> createState() => _HorizonPageState();
}

class _HorizonPageState extends State<HorizonPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _modules = [
    'Goals',
    'Trip & Event Plans',
    'Debt & Loans',
    'Recurring Bills',
    'Work & Routines',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final tripPlanProvider = context.watch<TripPlanProvider>();
    final loanProvider = context.watch<LoanProvider>();
    final recurringProvider = context.watch<RecurringTransactionProvider>();

    final activeGoals = goalProvider.plans.where((g) => !g.isArchived).length;
    final activeTripPlans = tripPlanProvider.tripPlans.length;
    final activeLoans = loanProvider.loans.length;
    final activeRecurring = recurringProvider.sources.length;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plans & Progress Hero Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.ink,
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
                            '5 Modules',
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
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppTheme.goldLine),
                    const SizedBox(height: 10),
                    // Quick Module Counters
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem('Goals', '$activeGoals Active'),
                        ),
                        Container(width: 1, height: 24, color: AppTheme.goldLine),
                        Expanded(
                          child: _buildMetricItem('Trip Plans', '$activeTripPlans Active'),
                        ),
                        Container(width: 1, height: 24, color: AppTheme.goldLine),
                        Expanded(
                          child: _buildMetricItem('Debt/Loans', '$activeLoans Rules'),
                        ),
                        Container(width: 1, height: 24, color: AppTheme.goldLine),
                        Expanded(
                          child: _buildMetricItem('Recurring', '$activeRecurring Rules'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable 5-Module Choice Bar
            Container(
              height: 38,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                indicatorColor: AppTheme.ink,
                indicatorWeight: 2.5,
                labelColor: AppTheme.ink,
                unselectedLabelColor: AppTheme.muted,
                dividerColor: AppTheme.line,
                tabs: _modules.map((m) => Tab(
                  child: Text(m, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  GoalsTabView(),
                  TripPlansTabView(),
                  LoansTabView(),
                  RecurringTabView(),
                  _WorkRoutineEmbedView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: AppTheme.goldSoft.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}

class _WorkRoutineEmbedView extends StatelessWidget {
  const _WorkRoutineEmbedView();

  @override
  Widget build(BuildContext context) {
    return const WorkRoutinePage();
  }
}

