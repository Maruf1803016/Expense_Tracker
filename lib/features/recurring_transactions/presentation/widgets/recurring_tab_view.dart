import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/edit_recurring_transaction_sheet.dart';
import 'package:expense_tracker/shared/presentation/widgets/ink_ledger_add_card.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class RecurringTabView extends StatelessWidget {
  const RecurringTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecurringTransactionProvider>();
    final sources = provider.sources;

    if (provider.isLoading && sources.isEmpty) {
      return Center(child: CircularProgressIndicator(color: context.gold));
    }

    final totalIncome = sources.where((s) => s.type.toLowerCase() == 'income').fold<double>(0.0, (sum, s) => sum + s.expectedAmount);
    final totalExpense = sources.where((s) => s.type.toLowerCase() == 'expense').fold<double>(0.0, (sum, s) => sum + s.expectedAmount);
    final netCommitment = totalIncome - totalExpense;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Main Hero Summary Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
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
                  Row(
                    children: [
                      Icon(Icons.autorenew_rounded, color: context.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Recurring Commitments',
                        style: GoogleFonts.fraunces(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${sources.length} Active Rules',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.gold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: context.line),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCHEDULED INFLOW',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: context.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(totalIncome),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: context.line),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCHEDULED OUTFLOW',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: context.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(totalExpense),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: context.line),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Recurring Cash Flow',
                    style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                  ),
                  Text(
                    '${netCommitment >= 0 ? '+' : ''}${CurrencyFormatter.format(netCommitment)}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: netCommitment >= 0 ? context.emerald : context.brick,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Dedicated Add Recurring Rule Card (Under Main Card)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkLedgerAddCard(
            title: 'Add a recurring rule',
            subtitle: 'Automate salary, bills, rent, and subscriptions',
            icon: Icons.repeat_rounded,
            buttonText: 'Add',
            onTap: () {
              HapticsService.selection();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const EditRecurringTransactionSheet(),
              );
            },
          ),
        ),

        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
          child: Text(
            'ACTIVE SCHEDULES (${sources.length})',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: context.textMuted,
            ),
          ),
        ),

        if (sources.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.repeat_rounded, size: 40, color: context.textMuted),
                  const SizedBox(height: 12),
                  Text('No Recurring Rules', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Schedule salary, rent, subscriptions, or utility bills.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
          )
        else
          ...sources.map((source) => _buildSourceCard(context, source, provider)),
      ],
    );
  }

  Widget _buildSourceCard(BuildContext context, RecurringTransactionSource source, RecurringTransactionProvider provider) {
    final isIncome = source.type.toLowerCase() == 'income';
    final color = isIncome ? context.emerald : context.brick;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.line),
      ),
      child: InkWell(
        onTap: () {
          HapticsService.selection();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EditRecurringTransactionSheet(source: source),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.repeat_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${source.frequency.toUpperCase()} • Due ${DateFormatter.format(source.nextDueDate)}',
                      style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(source.expectedAmount)}',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
