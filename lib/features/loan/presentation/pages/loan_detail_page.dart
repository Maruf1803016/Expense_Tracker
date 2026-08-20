import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';

class LoanDetailPage extends StatelessWidget {
  final String loanId;

  const LoanDetailPage({super.key, required this.loanId});

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.watch<LoanProvider>();
    final accountProvider = context.watch<AccountProvider>();

    final loan = loanProvider.loans.where((l) => l.id == loanId).firstOrNull;

    if (loan == null) {
      return Scaffold(
        backgroundColor: AppTheme.paper,
        appBar: AppBar(title: Text('Loan Details', style: GoogleFonts.fraunces())),
        body: Center(
          child: Text('Loan not found', style: GoogleFonts.inter(color: AppTheme.muted)),
        ),
      );
    }

    final isLent = loan.type == LoanType.lent;
    final primaryColor = isLent ? AppTheme.emerald : AppTheme.brick;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          isLent ? 'Lent Record' : 'Debt Record',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.brick),
            onPressed: () => _confirmDelete(context, loan),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppTheme.paperCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isLent ? 'MONEY OWED TO YOU' : 'MONEY YOU OWE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      if (loan.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SETTLED',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.emerald,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    loan.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'With ${loan.counterparty}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Remaining Amount
                  Text(
                    'Remaining Balance',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(loan.remainingAmount),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: loan.progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.paper2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: ${CurrencyFormatter.format(loan.paidAmount)} (${(loan.progress * 100).toInt()}%)',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(loan.originalAmount)}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metadata Card
            Text(
              'TERMS & DATES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.paperCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                children: [
                  _buildMetaTile(
                    label: 'Created Date',
                    value: DateFormatter.format(loan.createdAt),
                    icon: Icons.calendar_today_rounded,
                  ),
                  if (loan.dueDate != null) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildMetaTile(
                      label: 'Due Date',
                      value: DateFormatter.format(loan.dueDate!),
                      icon: Icons.event_available_rounded,
                    ),
                  ],
                  if (loan.notes != null && loan.notes!.isNotEmpty) ...[
                    const Divider(height: 1, color: AppTheme.line),
                    _buildMetaTile(
                      label: 'Notes',
                      value: loan.notes!,
                      icon: Icons.notes_rounded,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Repayment History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REPAYMENT HISTORY',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.muted,
                  ),
                ),
                Text(
                  '${loan.repayments.length} Payments',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (loan.repayments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppTheme.paperCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No repayments recorded yet.',
                  style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 13),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.paperCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.line),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loan.repayments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.line),
                  itemBuilder: (context, idx) {
                    final repayment = loan.repayments[idx];
                    final account = repayment.accountId != null
                        ? accountProvider.getAccountById(repayment.accountId!)
                        : null;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        CurrencyFormatter.format(repayment.amount),
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormatter.format(repayment.date)}${account != null ? ' • ${account.name}' : ''}${repayment.note != null ? ' • ${repayment.note}' : ''}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.emerald.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: AppTheme.emerald, size: 16),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),

            // Action Buttons
            if (!loan.isCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordPaymentSheet(context, loan),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Record Repayment', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.ink,
                    foregroundColor: AppTheme.goldSoft,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await loanProvider.toggleComplete(loan.id, !loan.isCompleted);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loan.isCompleted ? 'Loan reactivated' : 'Loan marked as settled'),
                        backgroundColor: AppTheme.emerald,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                ),
                child: Text(
                  loan.isCompleted ? 'Reactivate Loan' : 'Mark as Fully Settled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTile({required String label, required String value, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.muted),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentSheet(BuildContext context, Loan loan) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedAccountId;
    final accountProvider = context.read<AccountProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Repayment',
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 16),

                Text('Amount', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Remaining: ${CurrencyFormatter.format(loan.remainingAmount)}',
                  ),
                ),
                const SizedBox(height: 16),

                Text('Account (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedAccountId,
                  dropdownColor: AppTheme.paperCard,
                  decoration: const InputDecoration(hintText: 'Select Account'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Account Linked')),
                    ...accountProvider.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                  ],
                  onChanged: (val) => setModalState(() => selectedAccountId = val),
                ),
                const SizedBox(height: 16),

                Text('Notes (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(hintText: 'e.g. Partial bank transfer'),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text.trim());
                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid repayment amount')),
                      );
                      return;
                    }

                    final repayment = LoanRepayment(
                      id: const Uuid().v4(),
                      amount: amt,
                      date: DateTime.now(),
                      accountId: selectedAccountId,
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );

                    await context.read<LoanProvider>().addRepayment(loan.id, repayment);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Repayment of ${CurrencyFormatter.format(amt)} recorded'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                    }
                  },
                  child: const Text('Save Repayment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Loan Record'),
        content: Text('Are you sure you want to delete "${loan.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<LoanProvider>().delete(loan.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loan deleted'), backgroundColor: AppTheme.emerald),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
