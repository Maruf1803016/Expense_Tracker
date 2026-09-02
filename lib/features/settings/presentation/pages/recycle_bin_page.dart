import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final deletedExpenses = provider.recycleBinExpenses;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text(
          'Recycle Bin',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        actions: [
          if (deletedExpenses.isNotEmpty)
            TextButton(
              onPressed: () {
                HapticsService.selection();
                _showEmptyBinDialog(context, provider);
              },
              child: Text(
                'Empty Bin',
                style: GoogleFonts.inter(color: context.brick, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: deletedExpenses.isEmpty
          ? const EmptyState(
              title: 'Recycle Bin is Empty',
              message: 'Deleted transactions will appear here for 30 days before being permanently removed.',
              icon: Icons.delete_outline_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: deletedExpenses.length,
              itemBuilder: (context, index) {
                final expense = deletedExpenses[index];
                final category = provider.getCategoryById(expense.categoryId);
                final isIncome = category.type == CategoryType.income;
                final catColor = AppTheme.getCategoryColor(category.id, category.name);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: context.line),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          IconUtils.getIcon(IconUtils.getIconName(category.icon), categoryName: category.name),
                          color: catColor,
                          size: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      expense.title.isNotEmpty ? expense.title : category.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Deleted on ${DateFormatter.format(expense.deletedAt ?? DateTime.now())}',
                      style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(expense.amount)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isIncome ? context.emerald : context.brick,
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: context.textMuted, size: 20),
                          color: context.cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.line),
                          ),
                          onSelected: (val) {
                            HapticsService.selection();
                            if (val == 'restore') {
                              provider.restoreExpense(expense.id);
                            } else {
                              _showDeleteForeverDialog(context, provider, expense.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  Icon(Icons.restore, size: 18, color: ctx.emerald),
                                  const SizedBox(width: 8),
                                  Text('Restore', style: GoogleFonts.inter(color: ctx.textPrimary, fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever, size: 18, color: ctx.brick),
                                  const SizedBox(width: 8),
                                  Text('Delete Forever', style: GoogleFonts.inter(color: ctx.brick, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEmptyBinDialog(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.line),
        ),
        title: Text(
          'Empty Recycle Bin?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          'This will permanently delete all items in the bin. This action cannot be undone.',
          style: GoogleFonts.inter(color: context.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.brick,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              HapticsService.lightImpact();
              provider.emptyRecycleBin();
              Navigator.pop(context);
            },
            child: Text('Empty Bin', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteForeverDialog(BuildContext context, ExpenseProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.line),
        ),
        title: Text(
          'Delete Permanently?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          'This item will be removed forever.',
          style: GoogleFonts.inter(color: context.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.brick,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              HapticsService.lightImpact();
              provider.deleteForever(id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
