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

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final deletedExpenses = provider.recycleBinExpenses;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        title: Text(
          'Recycle Bin',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        actions: [
          if (deletedExpenses.isNotEmpty)
            TextButton(
              onPressed: () => _showEmptyBinDialog(context, provider),
              child: Text(
                'Empty Bin',
                style: GoogleFonts.inter(color: AppTheme.brick, fontWeight: FontWeight.bold),
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
                    color: AppTheme.paperCard,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
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
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Deleted on ${DateFormatter.format(expense.deletedAt ?? DateTime.now())}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(expense.amount)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isIncome ? AppTheme.emerald : AppTheme.brick,
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppTheme.muted, size: 20),
                          color: AppTheme.paperCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppTheme.line),
                          ),
                          onSelected: (val) {
                            if (val == 'restore') {
                              provider.restoreExpense(expense.id);
                            } else {
                              _showDeleteForeverDialog(context, provider, expense.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  const Icon(Icons.restore, size: 18, color: AppTheme.emerald),
                                  const SizedBox(width: 8),
                                  Text('Restore', style: GoogleFonts.inter(color: AppTheme.textDark, fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_forever, size: 18, color: AppTheme.brick),
                                  const SizedBox(width: 8),
                                  Text('Delete Forever', style: GoogleFonts.inter(color: AppTheme.brick, fontSize: 13)),
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
        backgroundColor: AppTheme.paperCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.line),
        ),
        title: Text(
          'Empty Recycle Bin?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: Text(
          'This will permanently delete all items in the bin. This action cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brick,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
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
        backgroundColor: AppTheme.paperCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.line),
        ),
        title: Text(
          'Delete Permanently?',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: Text(
          'This item will be removed forever.',
          style: GoogleFonts.inter(color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brick,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
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
