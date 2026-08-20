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

            // Header and Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DEBT & LOANS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.muted,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddLoanSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Loan/Debt'),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                  color: AppTheme.paperCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.line),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.handshake_outlined, size: 40, color: AppTheme.muted.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      _filter == 'settled' ? 'No settled loans yet' : 'No active loans or debts',
                      style: GoogleFonts.inter(color: AppTheme.muted, fontWeight: FontWeight.w500),
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
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.goldLine),
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
                  color: AppTheme.goldSoft.withOpacity(0.7),
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppTheme.goldSoft),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(provider.netLoanBalance),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: provider.netLoanBalance >= 0 ? AppTheme.goldSoft : AppTheme.brick,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.goldLine),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owed to You (Lent)',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.goldSoft.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(provider.totalLent),
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: AppTheme.goldLine),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You Owe (Borrowed)',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.goldSoft.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(provider.totalBorrowed),
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ink : AppTheme.paperCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.ink : AppTheme.line),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.goldSoft : AppTheme.muted,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.gold : AppTheme.paper2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.muted,
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
    final primaryColor = isLent ? AppTheme.emerald : AppTheme.brick;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () {
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
                        color: primaryColor.withOpacity(0.12),
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
                          Icon(Icons.event_outlined, size: 12, color: AppTheme.muted),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${DateFormatter.format(loan.dueDate!)}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
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
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'With ${loan.counterparty}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.muted,
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
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
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
                    backgroundColor: AppTheme.paper2,
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Debt / Loan',
                    style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 16),

                  // Mode Selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.paper2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => type = LoanType.lent),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == LoanType.lent ? AppTheme.emerald : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Lent (Owed to Me)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: type == LoanType.lent ? Colors.white : AppTheme.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => type = LoanType.borrowed),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == LoanType.borrowed ? AppTheme.brick : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Borrowed (I Owe)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: type == LoanType.borrowed ? Colors.white : AppTheme.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Title', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'e.g. Personal Loan, Office Lunch Share'),
                  ),
                  const SizedBox(height: 16),

                  Text('Counterparty / Person', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: counterpartyController,
                    decoration: const InputDecoration(hintText: 'e.g. John Doe, Alex'),
                  ),
                  const SizedBox(height: 16),

                  Text('Total Amount', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: '0.00'),
                  ),
                  const SizedBox(height: 16),

                  Text('Due Date (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
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
                        color: AppTheme.paper2,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dueDate != null ? DateFormatter.format(dueDate!) : 'No due date set',
                            style: GoogleFonts.inter(
                              color: dueDate != null ? AppTheme.textDark : AppTheme.muted,
                              fontSize: 14,
                            ),
                          ),
                          Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Notes (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(hintText: 'Add repayment terms or details...'),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
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
                          const SnackBar(content: Text('Loan record created'), backgroundColor: AppTheme.emerald),
                        );
                      }
                    },
                    child: const Text('Create Record'),
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
