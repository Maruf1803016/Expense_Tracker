import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/plan/presentation/widgets/goals_tab_view.dart';
import 'package:expense_tracker/features/plan/presentation/widgets/trip_plans_tab_view.dart';

import 'package:expense_tracker/features/loan/presentation/widgets/loans_tab_view.dart';

class HorizonPage extends StatefulWidget {
  const HorizonPage({super.key});

  @override
  State<HorizonPage> createState() => _HorizonPageState();
}

class _HorizonPageState extends State<HorizonPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.paper,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.paper,
            child: TabBar(
              tabs: [
                Tab(child: Text('Goals', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                Tab(child: Text('Plans', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                Tab(child: Text('Debt & Loans', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
              ],
              indicatorColor: AppTheme.ink,
              indicatorWeight: 2.5,
              labelColor: AppTheme.ink,
              unselectedLabelColor: AppTheme.muted,
              dividerColor: AppTheme.line,
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            GoalsTabView(),
            TripPlansTabView(),
            LoansTabView(),
          ],
        ),
      ),
    );
  }
}
