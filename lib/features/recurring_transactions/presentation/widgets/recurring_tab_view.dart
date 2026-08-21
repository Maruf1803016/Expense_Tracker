import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/edit_recurring_transaction_sheet.dart';

class RecurringTabView extends StatelessWidget {
  const RecurringTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecurringTransactionProvider>();
    final sources = provider.sources;

    if (provider.isLoading && sources.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }

    final totalMonthly = sources.fold<double>(0.0, (sum, s) => sum + s.expectedAmount);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.paperCard,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECURRING COMMITMENTS',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalMonthly),
                    style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.paper2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Text(
                  '${sources.length} Active Rules',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
              ),
            ],
          ),
        ),

        if (sources.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Icon(Icons.repeat_rounded, size: 40, color: AppTheme.muted),
                  const SizedBox(height: 12),
                  Text('No Recurring Rules', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Text('Schedule salary, rent, subscriptions, or utility bills.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
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
    final color = isIncome ? AppTheme.emerald : AppTheme.brick;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
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
        title: Text(
          source.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
        ),
        subtitle: Text(
          '${source.frequency.toUpperCase()} • Due ${DateFormatter.format(source.nextDueDate)}',
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(source.expectedAmount)}',
              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.muted),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditRecurringTransactionSheet(source: source),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
