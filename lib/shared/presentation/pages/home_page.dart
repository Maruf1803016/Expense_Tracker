import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/analytics/presentation/pages/insights_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/plan/presentation/pages/horizon_page.dart';
import 'package:expense_tracker/features/notifications/presentation/providers/notification_provider.dart';
import 'package:expense_tracker/features/notifications/presentation/pages/notification_inbox_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ExpenseListPage(),
    InsightsPage(),
    HorizonPage(),
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


  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.ink : AppTheme.muted;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Expenses', 'Stats', 'Horizon', 'Settings'];
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
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: Icon(
                        notifProvider.hasUnread ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                        color: notifProvider.hasUnread ? AppTheme.gold : AppTheme.textDark,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationInboxPage(),
                          ),
                        );
                      },
                    ),
                    if (notifProvider.hasUnread)
                      Positioned(
                        top: 10,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            notifProvider.unreadBadge,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
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

      bottomNavigationBar: Container(
        height: 68 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: AppTheme.paperCard,
          border: const Border(
            top: BorderSide(color: AppTheme.line),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            _buildNavItem(0, Icons.receipt_long_outlined, Icons.receipt_long, 'Expenses'),
            _buildNavItem(1, Icons.insights_outlined, Icons.insights, 'Stats'),
            Expanded(
              child: GestureDetector(
                onTap: _openAddExpense,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppTheme.ink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: AppTheme.goldSoft,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            _buildNavItem(2, Icons.track_changes_outlined, Icons.track_changes, 'Horizon'),
            _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Settings'),
          ],
        ),
      ),
    );
  }
}
