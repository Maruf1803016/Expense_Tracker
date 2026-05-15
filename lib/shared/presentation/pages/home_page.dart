import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/analytics/presentation/providers/financial_insights_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/monthly_summary_page.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_management_page.dart';
import 'package:expense_tracker/features/analytics/presentation/pages/insights_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_search_page.dart';

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
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpensePage()),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final expense = context.read<ExpenseProvider>();
    // final insights = context.read<FinancialInsightsProvider>(); // clear if method exists
    
    expense.clear();
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Expenses', 'Summary', 'Insights', 'Categories'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExpenseSearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out?'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}
