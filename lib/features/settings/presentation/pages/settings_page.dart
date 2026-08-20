import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/pages/recycle_bin_page.dart';
import 'package:expense_tracker/features/auth/presentation/pages/profile_page.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/account/presentation/pages/accounts_management_page.dart';
import 'package:expense_tracker/features/export/presentation/providers/export_provider.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_management_page.dart';
import 'package:expense_tracker/features/work_routine/presentation/pages/work_routine_page.dart';
import 'package:expense_tracker/features/history/presentation/pages/history_page.dart';
import 'package:expense_tracker/features/notifications/presentation/pages/notification_inbox_page.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final user = authProvider.user;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // 1. Profile Section
        _buildSectionHeader('Profile'),
        Card(
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                  ? FileImage(File(user.photoUrl!))
                  : null,
              child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(user?.displayName != null && user!.displayName!.isNotEmpty ? user.displayName! : 'User Profile'),
            subtitle: Text(user?.email ?? 'Not logged in'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 24),

        // 2. Money Section
        _buildSectionHeader('Money'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.monetization_on_outlined),
                title: const Text('Currency'),
                trailing: DropdownButton<String>(
                  value: settingsProvider.selectedCurrency,
                  underline: const SizedBox(),
                  items: SettingsProvider.currencySymbols.keys.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.updateCurrency(value);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Total Budgeted (This Month)'),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    formatCurrency(expenseProvider.rolledUpBudgetStatuses.fold(0.0, (sum, item) => sum + item.limit)),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                  ),
                ),
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
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  expenseProvider.summary.netBalance >= 0 
                      ? Icons.savings_outlined 
                      : Icons.trending_down_outlined,
                  color: expenseProvider.summary.netBalance >= 0 
                      ? AppTheme.incomeColor 
                      : AppTheme.expenseColor,
                ),
                title: Text(expenseProvider.summary.netBalance >= 0 ? 'Monthly Savings' : 'Monthly Loss'),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    CurrencyFormatter.format(expenseProvider.summary.netBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: expenseProvider.summary.netBalance >= 0 
                          ? AppTheme.incomeColor 
                          : AppTheme.expenseColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Data Section
        _buildSectionHeader('Data'),
        Card(
          child: Column(
            children: [
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
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export Data (CSV / PDF)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showExportSheet(context);
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
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context, authProvider, expenseProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, ExpenseProvider expense) {
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
              expense.clear();
              auth.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF4D6A))),
          ),
        ],
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const ExportBottomSheet();
      },
    );
  }
}

class ExportBottomSheet extends StatefulWidget {
  const ExportBottomSheet({super.key});

  @override
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  late int _selectedMonth;
  late int _selectedYear;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(6, (i) => now.year - i);
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Export Reports',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Select Month & Year',
            style: GoogleFonts.inter(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  dropdownColor: AppTheme.paperCard,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(months[index]),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonth = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  dropdownColor: AppTheme.paperCard,
                  style: GoogleFonts.inter(color: AppTheme.textDark),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: years.map((y) {
                    return DropdownMenuItem(
                      value: y,
                      child: Text(y.toString()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: Text('Export CSV', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    onPressed: () => _triggerExport(context, ExportFormat.csv),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text('Export PDF', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    onPressed: () => _triggerExport(context, ExportFormat.pdf),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.line),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _triggerExport3Months(context),
              child: Text(
                'Export Last 3 Months (CSV)',
                style: GoogleFonts.inter(color: AppTheme.textDark, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _triggerExport(BuildContext context, ExportFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final exportProv = context.read<ExportProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final accountProvider = context.read<AccountProvider>();
      final expenseProvider = context.read<ExpenseProvider>();

      final categoryNames = {for (var c in categoryProvider.categories) c.id: c.name};
      final accountNames = {for (var a in accountProvider.accounts) a.id: a.name};
      final accountBalances = {
        for (var a in accountProvider.accounts)
          a.id: Account.calculateBalance(a, expenseProvider.expenses)
      };

      await exportProv.exportMonth(
        month: _selectedMonth,
        year: _selectedYear,
        format: format,
        categoryNames: categoryNames,
        accountNames: accountNames,
        accountBalances: accountBalances,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${format == ExportFormat.csv ? "CSV" : "PDF"} Export Shared Successfully'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: AppTheme.brick,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _triggerExport3Months(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final exportProv = context.read<ExportProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final accountProvider = context.read<AccountProvider>();

      final categoryNames = {for (var c in categoryProvider.categories) c.id: c.name};
      final accountNames = {for (var a in accountProvider.accounts) a.id: a.name};

      await exportProv.exportLast3Months(
        currentMonth: DateTime.now(),
        format: ExportFormat.csv,
        categoryNames: categoryNames,
        accountNames: accountNames,
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Last 3 Months Export Shared Successfully'),
            backgroundColor: AppTheme.emerald,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: AppTheme.brick,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
