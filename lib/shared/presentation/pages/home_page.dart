import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/monthly_summary_page.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_management_page.dart';
import 'package:expense_tracker/features/analytics/presentation/pages/insights_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/plan_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ExpenseListPage(),
    MonthlySummaryPage(),
    InsightsPage(),
    CategoryManagementPage(),
    SettingsPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initialsFor(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ME';
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpensePage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final titles = ['Expenses', 'Summary', 'Insights', 'Categories', 'Settings'];
    final user = context.watch<AuthProvider>().user;
    final displayName = user?.displayName?.trim();
    final hasDisplayName = displayName != null && displayName.isNotEmpty;
    final isDashboard = _currentIndex == 0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isDashboard ? 76 : kToolbarHeight,
        centerTitle: !isDashboard,
        title: isDashboard
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _greetingForHour(DateTime.now().hour),
                    style: GoogleFonts.inter(
                      color: AppTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDisplayName ? displayName : 'Your finances',
                    style: GoogleFonts.fraunces(
                      color: AppTheme.textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(titles[_currentIndex]),
        actions: [
          if (isDashboard) ...[
            IconButton(
              tooltip: 'Add Transaction',
              icon: const Icon(Icons.add_rounded),
              onPressed: _openAddExpense,
            ),
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications are coming soon.')),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.ink,
                foregroundImage: user?.photoUrl?.isNotEmpty == true
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: Text(
                  _initialsFor(displayName),
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.goldSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          if (_currentIndex == 2) ...[
            IconButton(
              tooltip: 'Add Goal',
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddExpensePage(preselectedPlanMode: true),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.paperCard,
        indicatorColor: AppTheme.line,
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: _currentIndex == 0 ? AppTheme.ink : AppTheme.muted),
            selectedIcon: const Icon(Icons.receipt_long, color: AppTheme.ink),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: _currentIndex == 1 ? AppTheme.ink : AppTheme.muted),
            selectedIcon: const Icon(Icons.bar_chart, color: AppTheme.ink),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: _currentIndex == 2 ? AppTheme.ink : AppTheme.muted),
            selectedIcon: const Icon(Icons.insights, color: AppTheme.ink),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined, color: _currentIndex == 3 ? AppTheme.ink : AppTheme.muted),
            selectedIcon: const Icon(Icons.category, color: AppTheme.ink),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: _currentIndex == 4 ? AppTheme.ink : AppTheme.muted),
            selectedIcon: const Icon(Icons.settings, color: AppTheme.ink),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
