import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/pages/recycle_bin_page.dart';
import 'package:expense_tracker/features/auth/presentation/pages/profile_page.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';

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

        // 2. Preferences Section
        _buildSectionHeader('Preferences'),
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
                title: const Text('Monthly Budget'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.format(settingsProvider.budget),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _showBudgetDialog(context, settingsProvider),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Data Section
        _buildSectionHeader('Data'),
        Card(
          child: ListTile(
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

  void _showBudgetDialog(BuildContext context, SettingsProvider settingsProvider) {
    final currentBudget = context.read<SettingsProvider>().budget;
    final budgetController = TextEditingController(
      text: currentBudget == 0 ? '' : currentBudget.toStringAsFixed(0),
    );
    
    // Select all text for easy overwrite
    budgetController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: budgetController.text.length,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: '${settingsProvider.currentSymbol} ',
            hintText: '0',
            filled: false,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.emeraldGreen, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              try {
                final value = double.tryParse(budgetController.text) ?? 0.0;
                await settingsProvider.setBudget(value);
                
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Budget updated successfully'),
                    backgroundColor: AppTheme.emeraldGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
                navigator.pop();
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to save budget: ${e.toString()}'),
                    backgroundColor: AppTheme.expenseColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
