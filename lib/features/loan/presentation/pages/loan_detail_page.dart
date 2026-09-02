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
import 'package:expense_tracker/core/utils/haptics_service.dart';

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
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          title: Text('Loan Details', style: GoogleFonts.fraunces(color: context.textPrimary)),
        ),
        body: Center(
          child: Text('Loan not found', style: GoogleFonts.inter(color: context.textMuted)),
        ),
      );
    }

    final isLent = loan.type == LoanType.lent;
    final primaryColor = isLent ? context.emerald : context.brick;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isLent ? 'Lent Record' : 'Debt Record',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500, color: context.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.brick),
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
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
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
                          color: primaryColor.withValues(alpha: 0.12),
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
                            color: context.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SETTLED',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: context.emerald,
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
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'With ${loan.counterparty}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Remaining Amount
                  Text(
                    'Remaining Balance',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.textMuted,
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
                      backgroundColor: context.surface2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: ${CurrencyFormatter.format(loan.paidAmount)} (${(loan.progress * 100).toInt()}%)',
                        style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
                      ),
                      Text(
                        'Total: ${CurrencyFormatter.format(loan.originalAmount)}',
                        style: GoogleFonts.inter(fontSize: 12, color: context.textMuted, fontWeight: FontWeight.w600),
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
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              child: Column(
                children: [
                  _buildMetaTile(
                    context,
                    label: 'Created Date',
                    value: DateFormatter.format(loan.createdAt),
                    icon: Icons.calendar_today_rounded,
                  ),
                  if (loan.dueDate != null) ...[
                    Divider(height: 1, color: context.line),
                    _buildMetaTile(
                      context,
                      label: 'Due Date',
                      value: DateFormatter.format(loan.dueDate!),
                      icon: Icons.event_available_rounded,
                      trailing: TextButton(
                        onPressed: () => _showExtendDueDateDialog(context, loan),
                        child: Text(
                          'Postpone / Set New Date',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.gold),
                        ),
                      ),
                    ),
                  ],
                  if (loan.notes != null && loan.notes!.isNotEmpty) ...[
                    Divider(height: 1, color: context.line),
                    _buildMetaTile(
                      context,
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
                    color: context.textMuted,
                  ),
                ),
                Text(
                  '${loan.repayments.length} Payments',
                  style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (loan.repayments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: context.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No repayments recorded yet.',
                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: context.line),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loan.repayments.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: context.line),
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
                          color: context.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormatter.format(repayment.date)}${account != null ? ' • ${account.name}' : ''}${repayment.note != null ? ' • ${repayment.note}' : ''}',
                        style: GoogleFonts.inter(fontSize: 12, color: context.textMuted),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.emerald.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded, color: context.emerald, size: 16),
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
                  onPressed: () {
                    HapticsService.selection();
                    _showRecordPaymentSheet(context, loan);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Record Repayment', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.emerald,
                    foregroundColor: Colors.white,
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
                  HapticsService.lightImpact();
                  await loanProvider.toggleComplete(loan.id, !loan.isCompleted);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loan.isCompleted ? 'Loan reactivated' : 'Loan marked as settled'),
                        backgroundColor: context.emerald,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.line),
                  backgroundColor: context.cardBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                ),
                child: Text(
                  loan.isCompleted ? 'Reactivate Loan' : 'Mark as Fully Settled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTile(BuildContext context, {required String label, required String value, required IconData icon, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: context.textMuted)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showExtendDueDateDialog(BuildContext context, Loan loan) {
    DateTime newDueDate = loan.dueDate ?? DateTime.now().add(const Duration(days: 30));
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ctx.cardBg,
          title: Text('Extend Due Date', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: ctx.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Extended Due Date', style: GoogleFonts.inter(fontSize: 12, color: ctx.textMuted)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: newDueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setDialogState(() => newDueDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: ctx.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ctx.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormatter.format(newDueDate), style: GoogleFonts.inter(color: ctx.textPrimary)),
                      Icon(Icons.calendar_today_rounded, size: 16, color: ctx.gold),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Reason / History Note (Optional)', style: GoogleFonts.inter(fontSize: 12, color: ctx.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                style: GoogleFonts.inter(color: ctx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Mutual agreement to extend 1 month',
                  hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                  filled: true,
                  fillColor: ctx.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ctx.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ctx.line)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: ctx.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ctx.gold, foregroundColor: Colors.white),
              onPressed: () async {
                HapticsService.lightImpact();
                final reason = reasonController.text.trim();
                final existingNotes = loan.notes ?? '';
                final updatedNotes = reason.isNotEmpty
                    ? '$existingNotes\n[Due date extended to ${DateFormatter.format(newDueDate)}: $reason]'.trim()
                    : existingNotes;

                final updatedLoan = Loan(
                  id: loan.id,
                  title: loan.title,
                  counterparty: loan.counterparty,
                  originalAmount: loan.originalAmount,
                  type: loan.type,
                  createdAt: loan.createdAt,
                  dueDate: newDueDate,
                  notes: updatedNotes.isNotEmpty ? updatedNotes : null,
                  isCompleted: loan.isCompleted,
                  repayments: loan.repayments,
                );

                await context.read<LoanProvider>().update(updatedLoan);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Extension'),
            ),
          ],
        ),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: ctx.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: ctx.line),
            ),
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
                  style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: ctx.textPrimary),
                ),
                const SizedBox(height: 16),

                Text('Amount', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.spaceGrotesk(color: ctx.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Remaining: ${CurrencyFormatter.format(loan.remainingAmount)}',
                    hintStyle: GoogleFonts.spaceGrotesk(color: ctx.textMuted),
                    filled: true,
                    fillColor: ctx.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Account (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedAccountId,
                  dropdownColor: ctx.cardBg,
                  style: GoogleFonts.inter(color: ctx.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Select Account',
                    hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                    filled: true,
                    fillColor: ctx.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('No Account Linked', style: TextStyle(color: ctx.textPrimary))),
                    ...accountProvider.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name, style: TextStyle(color: ctx.textPrimary)))),
                  ],
                  onChanged: (val) => setModalState(() => selectedAccountId = val),
                ),
                const SizedBox(height: 16),

                Text('Notes (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  style: GoogleFonts.inter(color: ctx.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Partial bank transfer',
                    hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                    filled: true,
                    fillColor: ctx.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ctx.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      HapticsService.lightImpact();
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
                            backgroundColor: context.emerald,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Repayment'),
                  ),
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
        backgroundColor: context.cardBg,
        title: Text('Delete Loan Record', style: TextStyle(color: context.textPrimary)),
        content: Text('Are you sure you want to delete "${loan.title}"?', style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          TextButton(
            onPressed: () async {
              HapticsService.lightImpact();
              Navigator.pop(ctx);
              await context.read<LoanProvider>().delete(loan.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Loan deleted'), backgroundColor: context.emerald),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: context.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
