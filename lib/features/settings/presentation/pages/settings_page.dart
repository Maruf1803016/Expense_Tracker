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
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/work_routine/presentation/providers/work_routine_provider.dart';
import 'package:expense_tracker/features/settings/presentation/pages/import_export_page.dart';
import 'package:expense_tracker/shared/presentation/widgets/currency_picker_sheet.dart';
import 'package:expense_tracker/core/services/demo_data_generator_service.dart';
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
        // 1. APPEARANCE & DISPLAY
        _buildSectionHeader(context, '1. Appearance & Display'),
        Card(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: context.line),
          ),
          child: ListTile(
            leading: Icon(
              settingsProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppTheme.gold,
            ),
            title: Text(
              'Dark Mode',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            subtitle: Text(
              settingsProvider.isDarkMode
                  ? 'Dark editorial theme active'
                  : 'Light warm-paper theme active',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.textMuted,
              ),
            ),
            trailing: Switch.adaptive(
              value: settingsProvider.isDarkMode,
              activeColor: AppTheme.goldSoft,
              activeTrackColor: context.isDark ? AppTheme.darkSurface2 : AppTheme.ink,
              onChanged: (bool val) {
                settingsProvider.toggleDarkMode(val);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 2. PREFERENCES & ACCOUNTS
        _buildSectionHeader(context, '2. Preferences & Accounts'),
        Card(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: context.line),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.monetization_on_outlined, color: context.textPrimary),
                title: Text('Currency', style: TextStyle(color: context.textPrimary)),
                subtitle: Text(
                  '${settingsProvider.selectedCurrency} (${settingsProvider.currentSymbol})',
                  style: TextStyle(color: context.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
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
              Divider(height: 1, color: context.line),
              ListTile(
                leading: Icon(Icons.account_balance_outlined, color: context.textPrimary),
                title: Text('Manage Accounts', style: TextStyle(color: context.textPrimary)),
                subtitle: Text('Checking, savings, and wallets', style: TextStyle(color: context.textMuted)),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountsManagementPage()),
                  );
                },
              ),
              Divider(height: 1, color: context.line),
              ListTile(
                leading: Icon(Icons.category_outlined, color: context.textPrimary),
                title: Text('Manage Categories', style: TextStyle(color: context.textPrimary)),
                subtitle: Text('Custom expense & income categories', style: TextStyle(color: context.textMuted)),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryManagementPage()),
                  );
                },
              ),
              Divider(height: 1, color: context.line),
              ListTile(
                leading: Icon(Icons.tune_rounded, color: context.textPrimary),
                title: Text('Preferences', style: TextStyle(color: context.textPrimary)),
                subtitle: Text('Time format, week start, and fiscal year', style: TextStyle(color: context.textMuted)),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PreferencesPage()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. AUTOMATION & NOTIFICATIONS
        _buildSectionHeader(context, '3. Automation & Notifications'),
        Card(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: context.line),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.alarm_outlined, color: context.textPrimary),
                title: Text('Transaction Reminder', style: TextStyle(color: context.textPrimary)),
                subtitle: Text(
                  settingsProvider.isDailyReminderEnabled ? 'Daily reminder active' : 'Off',
                  style: TextStyle(color: context.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionReminderPage()),
                  );
                },
              ),
              Divider(height: 1, color: context.line),
              ListTile(
                leading: Icon(Icons.notifications_none_rounded, color: context.textPrimary),
                title: Text('Notification Inbox', style: TextStyle(color: context.textPrimary)),
                subtitle: Text('Reminders, budget alerts, and notices', style: TextStyle(color: context.textMuted)),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
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

        // 4. DATA, BACKUP & ARCHIVE
        _buildSectionHeader(context, '4. Data, Backup & Archive'),
        Card(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: context.line),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.swap_vert_rounded, color: context.textPrimary),
                title: Text('Import & Export', style: TextStyle(color: context.textPrimary)),
                subtitle: Text('CSV, TSV, XLSX, JSON backup, and PDF report', style: TextStyle(color: context.textMuted)),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportExportPage()),
                  );
                },
              ),
              Divider(height: 1, color: context.line),
              ListTile(
                leading: Icon(Icons.cloud_sync_outlined, color: context.textPrimary),
                title: Text('Backup & Sync', style: TextStyle(color: context.textPrimary)),
                subtitle: Text('JSON archive export & cloud backup', style: TextStyle(color: context.textMuted)),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DataAndSupportPage()),
                  );
                },
              ),
              Divider(height: 1, color: context.line),
              ListTile(
                leading: Icon(Icons.history_rounded, color: context.textPrimary),
                title: Text('Historical Ledger', style: TextStyle(color: context.textPrimary)),
                subtitle: Text('Monthly archived ledger with 2-year retention', style: TextStyle(color: context.textMuted)),
                trailing: Icon(Icons.chevron_right, color: context.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  );
                },
              ),
              Divider(height: 1, color: context.line),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: context.textPrimary),
                title: Text('Recycle Bin', style: TextStyle(color: context.textPrimary)),
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
                    Icon(Icons.chevron_right, color: context.textMuted),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecycleBinPage()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 5. WORK & ROUTINE
        _buildSectionHeader(context, '5. Work & Routine'),
        Card(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: context.line),
          ),
          child: ListTile(
            leading: Icon(Icons.badge_outlined, color: context.textPrimary),
            title: Text('Work & Routine Log', style: TextStyle(color: context.textPrimary)),
            subtitle: Text('Attendance, shifts, and monthly hours', style: TextStyle(color: context.textMuted)),
            trailing: Icon(Icons.chevron_right, color: context.textMuted),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkRoutinePage(showAddCard: false)),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // 6. ACCOUNT & SESSION
        _buildSectionHeader(context, '6. Account & Session'),
        Card(
          color: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            side: BorderSide(color: context.line),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.brick),
            title: Text('Sign Out', style: GoogleFonts.inter(color: AppTheme.brick, fontWeight: FontWeight.w600)),
            onTap: () => _showLogoutDialog(context, authProvider, expenseProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: context.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, ExpenseProvider expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: ctx.line),
        ),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: ctx.textPrimary),
        ),
        content: Text(
          'Are you sure you want to sign out from your account?',
          style: GoogleFonts.inter(color: ctx.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: ctx.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brick,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
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
