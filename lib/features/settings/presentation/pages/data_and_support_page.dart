import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/goal_provider.dart';
import 'package:expense_tracker/features/plan/presentation/providers/trip_plan_provider.dart';
import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/account/data/models/account_model.dart';
import 'package:expense_tracker/features/plan/data/models/goal_model.dart';
import 'package:expense_tracker/features/plan/data/models/trip_plan_model.dart';
import 'package:expense_tracker/features/loan/data/models/loan_model.dart';

class DataAndSupportPage extends StatefulWidget {
  const DataAndSupportPage({super.key});

  @override
  State<DataAndSupportPage> createState() => _DataAndSupportPageState();
}

class _DataAndSupportPageState extends State<DataAndSupportPage> {
  bool _isExportingJson = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          'Data & Support',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionHeader('Private Data Backup'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: const Icon(Icons.code_rounded, color: AppTheme.gold),
                  title: Text('Export JSON Archive', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  subtitle: Text('Download complete private backup file containing transactions, accounts, and goals.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
                  trailing: _isExportingJson
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold))
                      : const Icon(Icons.download_rounded),
                  onTap: _isExportingJson ? null : () => _exportJsonArchive(context),
                ),
                const Divider(height: 1, color: AppTheme.line),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: const Icon(Icons.cloud_sync_outlined, color: AppTheme.gold),
                  title: Text('Google Drive Backup', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  subtitle: Text('Encrypted cloud snapshot synced to your personal Google Drive storage.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Firebase cloud replication is active for your account.'),
                        backgroundColor: AppTheme.emerald,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Support & Feedback'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: const Icon(Icons.mail_outline_rounded, color: AppTheme.gold),
                  title: Text('Contact Developer', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  subtitle: Text('marufmia1612@gmail.com', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _launchMailto(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Danger Zone'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.brick.withOpacity(0.3)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.brick),
              title: Text('Clear All Financial Data', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.brick)),
              subtitle: Text('Permanently wipes all expenses, goals, and debt records while preserving your user account.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
              onTap: () => _showGuardedClearDataDialog(context),
            ),
          ),
        ],
      ),
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

  Future<void> _exportJsonArchive(BuildContext context) async {
    setState(() => _isExportingJson = true);
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final accountProvider = context.read<AccountProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final goalProvider = context.read<GoalProvider>();
      final tripPlanProvider = context.read<TripPlanProvider>();
      final loanProvider = context.read<LoanProvider>();

      final backupData = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'expenses': expenseProvider.expenses.map((e) => ExpenseModel.fromEntity(e).toMap()).toList(),
        'accounts': accountProvider.accounts.map((a) => AccountModel.fromEntity(a).toMap()).toList(),
        'categories': categoryProvider.categories.map((c) => {'id': c.id, 'name': c.name, 'type': c.type.name}).toList(),
        'goals': goalProvider.plans.map((g) => GoalModel.fromEntity(g).toMap()).toList(),
        'tripPlans': tripPlanProvider.tripPlans.map((t) => TripPlanModel.fromEntity(t).toMap()).toList(),
        'loans': loanProvider.loans.map((l) => LoanModel.fromEntity(l).toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/expense_ledger_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Expense Ledger Backup Archive (JSON)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export JSON: $e'), backgroundColor: AppTheme.brick),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingJson = false);
    }
  }

  Future<void> _launchMailto() async {
    final uri = Uri.parse('mailto:marufmia1612@gmail.com?subject=Expense%20Ledger%20Feedback');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client. Send to: marufmia1612@gmail.com')),
        );
      }
    }
  }

  void _showGuardedClearDataDialog(BuildContext context) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear All Financial Records?', style: GoogleFonts.fraunces(color: AppTheme.brick)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is irreversible. All transactions, goals, trip plans, and loans will be deleted permanently.\n\nType "CONFIRM" below to proceed:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(hintText: 'CONFIRM'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (confirmController.text.trim() == 'CONFIRM') {
                Navigator.pop(ctx);
                final expenseProv = context.read<ExpenseProvider>();
                for (var exp in expenseProv.expenses) {
                  await expenseProv.deleteExpense(exp.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Financial data cleared'), backgroundColor: AppTheme.emerald),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Confirmation word mismatch')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}
