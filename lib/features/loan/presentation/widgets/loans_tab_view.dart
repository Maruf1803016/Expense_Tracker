import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/loan/presentation/pages/loan_detail_page.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_add_card.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class LoansTabView extends StatefulWidget {
  const LoansTabView({super.key});

  @override
  State<LoansTabView> createState() => _LoansTabViewState();
}

class _LoansTabViewState extends State<LoansTabView> {
  String _filter = 'active'; // 'active', 'lent', 'borrowed', 'settled'

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.watch<LoanProvider>();
    final allLoans = loanProvider.loans;

    List<Loan> filteredLoans;
    if (_filter == 'active') {
      filteredLoans = loanProvider.activeLoans;
    } else if (_filter == 'lent') {
      filteredLoans = allLoans.where((l) => l.type == LoanType.lent && !l.isCompleted).toList();
    } else if (_filter == 'borrowed') {
      filteredLoans = allLoans.where((l) => l.type == LoanType.borrowed && !l.isCompleted).toList();
    } else {
      filteredLoans = loanProvider.completedLoans;
    }

    return RefreshIndicator(
      onRefresh: () async => loanProvider.init(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Hero Card
            _buildMetricsHero(loanProvider),
            const SizedBox(height: 20),

            // Dedicated Add a Loan Card
            InkLedgerAddCard(
              title: 'Add a loan',
              subtitle: 'Record money lent to or borrowed from someone',
              icon: Icons.handshake_outlined,
              buttonText: 'Add',
              onTap: () => _showAddLoanSheet(context),
            ),
            const SizedBox(height: 16),

            // Section Header
            Text(
              'DEBT & LOANS LEDGER',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 10),

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('Active', 'active', count: loanProvider.activeLoans.length),
                  _buildFilterPill('Lent (Receivable)', 'lent'),
                  _buildFilterPill('Borrowed (Debt)', 'borrowed'),
                  _buildFilterPill('Settled', 'settled', count: loanProvider.completedLoans.length),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loan Cards List
            if (filteredLoans.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: context.line),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.handshake_outlined, size: 40, color: context.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      _filter == 'settled' ? 'No settled loans yet' : 'No active loans or debts',
                      style: GoogleFonts.inter(color: context.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLoans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  return _buildLoanCard(context, filteredLoans[idx]);
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsHero(LoanProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
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
              Text(
                'NET POSITION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: context.textMuted,
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined, size: 16, color: context.gold),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(provider.netLoanBalance),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: provider.netLoanBalance >= 0 ? context.emerald : context.brick,
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.line),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owed to You (Lent)',
                      style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(provider.totalLent),
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: context.line),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You Owe (Borrowed)',
                      style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(provider.totalBorrowed),
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String value, {int? count}) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        HapticsService.selection();
        setState(() => _filter = value);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.gold : context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? context.gold : context.line),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.textMuted,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : context.surface2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : context.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, Loan loan) {
    final isLent = loan.type == LoanType.lent;
    final primaryColor = isLent ? context.emerald : context.brick;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () {
            HapticsService.selection();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LoanDetailPage(loanId: loan.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLent ? 'LENT' : 'BORROWED',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (loan.dueDate != null)
                      Row(
                        children: [
                          Icon(Icons.event_outlined, size: 12, color: context.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${DateFormatter.format(loan.dueDate!)}',
                            style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fraunces(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'With ${loan.counterparty}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(loan.remainingAmount),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'of ${CurrencyFormatter.format(loan.originalAmount)}',
                          style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: loan.progress,
                    minHeight: 6,
                    backgroundColor: context.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddLoanSheet(BuildContext context) {
    final titleController = TextEditingController();
    final counterpartyController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    LoanType type = LoanType.lent;
    DateTime? dueDate;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Debt / Loan',
                    style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: ctx.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Mode Selector
                  Container(
                    decoration: BoxDecoration(
                      color: ctx.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ctx.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticsService.selection();
                              setModalState(() => type = LoanType.lent);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == LoanType.lent ? ctx.emerald : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Lent (Owed to Me)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: type == LoanType.lent ? Colors.white : ctx.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticsService.selection();
                              setModalState(() => type = LoanType.borrowed);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == LoanType.borrowed ? ctx.brick : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Borrowed (I Owe)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: type == LoanType.borrowed ? Colors.white : ctx.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Title', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.inter(color: ctx.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Personal Loan, Office Lunch Share',
                      hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                      filled: true,
                      fillColor: ctx.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Counterparty / Person', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: counterpartyController,
                    style: GoogleFonts.inter(color: ctx.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. John Doe, Alex',
                      hintStyle: GoogleFonts.inter(color: ctx.textMuted),
                      filled: true,
                      fillColor: ctx.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Total Amount', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceGrotesk(color: ctx.textPrimary),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.spaceGrotesk(color: ctx.textMuted),
                      filled: true,
                      fillColor: ctx.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.line)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Due Date (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setModalState(() => dueDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: ctx.cardBg,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: ctx.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dueDate != null ? DateFormatter.format(dueDate!) : 'No due date set',
                            style: GoogleFonts.inter(
                              color: dueDate != null ? ctx.textPrimary : ctx.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          Icon(Icons.calendar_today_rounded, size: 16, color: ctx.gold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Notes (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    style: GoogleFonts.inter(color: ctx.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add repayment terms or details...',
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
                        backgroundColor: ctx.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        HapticsService.lightImpact();
                        final title = titleController.text.trim();
                        final counterparty = counterpartyController.text.trim();
                        final amt = double.tryParse(amountController.text.trim());

                        if (title.isEmpty || counterparty.isEmpty || amt == null || amt <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please fill out title, person name, and valid amount')),
                          );
                          return;
                        }

                        final loan = Loan(
                          id: const Uuid().v4(),
                          title: title,
                          counterparty: counterparty,
                          type: type,
                          originalAmount: amt,
                          dueDate: dueDate,
                          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                          createdAt: DateTime.now(),
                        );

                        await context.read<LoanProvider>().add(loan);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Loan record created'), backgroundColor: context.emerald),
                          );
                        }
                      },
                      child: const Text('Create Record'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
