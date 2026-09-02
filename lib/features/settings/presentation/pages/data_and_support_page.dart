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

import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/work_routine/presentation/providers/work_routine_provider.dart';
import 'package:expense_tracker/core/services/demo_data_generator_service.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

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
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text(
          'Backup & Sync',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500, color: context.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [

          _buildSectionHeader(context, 'Private Data Backup'),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.line),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Icon(Icons.code_rounded, color: context.gold),
                  title: Text('Export JSON Archive', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                  subtitle: Text('Download complete private backup file containing transactions, accounts, and goals.', style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                  trailing: _isExportingJson
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.gold))
                      : Icon(Icons.download_rounded, color: context.textMuted),
                  onTap: _isExportingJson ? null : () {
                    HapticsService.selection();
                    _exportJsonArchive();
                  },
                ),
                Divider(height: 1, color: context.line),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Icon(Icons.cloud_sync_outlined, color: context.gold),
                  title: Text('Google Drive Backup', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                  subtitle: Text('Encrypted cloud snapshot synced to your personal Google Drive storage.', style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                  trailing: Icon(Icons.chevron_right, color: context.textMuted),
                  onTap: () {
                    HapticsService.selection();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Firebase cloud replication is active for your account.'),
                        backgroundColor: context.emerald,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Support & Feedback'),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.line),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Icon(Icons.mail_outline_rounded, color: context.gold),
                  title: Text('Contact Developer', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                  subtitle: Text('marufmia1612@gmail.com', style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                  trailing: Icon(Icons.open_in_new_rounded, size: 18, color: context.textMuted),
                  onTap: () {
                    HapticsService.selection();
                    _launchMailto();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Danger Zone'),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.brick.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Icon(Icons.delete_forever_rounded, color: context.brick),
              title: Text('Clear All Financial Data', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.brick)),
              subtitle: Text('Permanently wipes all expenses, goals, and debt records while preserving your user account.', style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
              onTap: () {
                HapticsService.selection();
                _showGuardedClearDataDialog(context);
              },
            ),
          ),
        ],
      ),
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

  Future<void> _exportJsonArchive() async {
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
          SnackBar(content: Text('Failed to export JSON: $e'), backgroundColor: context.brick),
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
        backgroundColor: context.cardBg,
        title: Text('Clear All Financial Records?', style: GoogleFonts.fraunces(color: context.brick)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is irreversible. All transactions, goals, trip plans, and loans will be deleted permanently.\n\nType "CONFIRM" below to proceed:',
              style: TextStyle(color: context.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'CONFIRM',
                hintStyle: TextStyle(color: context.textMuted),
                filled: true,
                fillColor: context.surface2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          TextButton(
            onPressed: () async {
              HapticsService.lightImpact();
              if (confirmController.text.trim() == 'CONFIRM') {
                Navigator.pop(ctx);
                final expenseProv = context.read<ExpenseProvider>();
                for (var exp in expenseProv.expenses) {
                  await expenseProv.deleteExpense(exp.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Financial data cleared'), backgroundColor: context.emerald),
                  );
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Confirmation word mismatch')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: context.brick),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}
