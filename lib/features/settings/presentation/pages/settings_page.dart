import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/pages/recycle_bin_page.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/account/presentation/pages/accounts_management_page.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_management_page.dart';
import 'package:expense_tracker/features/work_routine/presentation/pages/work_routine_page.dart';
import 'package:expense_tracker/features/history/presentation/pages/history_page.dart';
import 'package:expense_tracker/features/notifications/presentation/pages/notification_inbox_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/preferences_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/data_and_support_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/transaction_reminder_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/import_export_page.dart';
import 'package:expense_tracker/shared/presentation/widgets/currency_picker_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // 1. Money Section
        _buildSectionHeader('Money'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.monetization_on_outlined),
                title: const Text('Currency'),
                subtitle: Text('${settingsProvider.selectedCurrency} (${settingsProvider.currentSymbol})'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => CurrencyPickerSheet(
                      selectedCode: settingsProvider.selectedCurrency,
                      onCurrencySelected: (code) => settingsProvider.updateCurrency(code),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Preferences'),
                subtitle: const Text('Time format, week start, and fiscal year'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PreferencesPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.alarm_outlined),
                title: const Text('Transaction Reminder'),
                subtitle: Text(
                  settingsProvider.isDailyReminderEnabled ? 'Daily reminder active' : 'Off',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionReminderPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: const Text('Manage Accounts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountsManagementPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Manage Categories'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryManagementPage()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Data & Portability Section
        _buildSectionHeader('Data & Portability'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.swap_vert_rounded),
                title: const Text('Import & Export'),
                subtitle: const Text('CSV, TSV, XLSX, JSON backup, and PDF report'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportExportPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Historical Ledger'),
                subtitle: const Text('Monthly archived ledger with 2-year retention'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Recycle Bin'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (expenseProvider.recycleBinExpenses.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.expenseColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${expenseProvider.recycleBinExpenses.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecycleBinPage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Backup & Support'),
                subtitle: const Text('JSON backup, Google Drive, and developer contact'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DataAndSupportPage()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Productivity Section
        _buildSectionHeader('Productivity & Logs'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Work & Routine Log'),
                subtitle: const Text('Attendance, shifts, and monthly hours'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkRoutinePage()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('Notification Inbox'),
                subtitle: const Text('Reminders, budget alerts, and notices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationInboxPage()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 4. Account Section
        _buildSectionHeader('Account'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.brick),
            title: Text('Sign Out', style: GoogleFonts.inter(color: AppTheme.brick, fontWeight: FontWeight.w600)),
            onTap: () => _showLogoutDialog(context, authProvider, expenseProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.muted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, ExpenseProvider expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.paperCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.line),
        ),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: Text(
          'Are you sure you want to sign out from your account?',
          style: GoogleFonts.inter(color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brick,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              expense.clear();
              auth.signOut();
            },
            child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
