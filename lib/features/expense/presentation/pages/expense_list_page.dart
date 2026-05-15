import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_indicator.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_detail_page.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return _buildBody(context, provider);
  }

  Widget _buildBody(BuildContext context, ExpenseProvider provider) {
    if (provider.isLoading && provider.expenses.isEmpty) {
      return LoadingIndicator(message: 'Loading expenses...');
    }

    if (provider.errorMessage != null && provider.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.init(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildBalanceSummary(context, provider),
        Expanded(
          child: provider.expenses.isEmpty
              ? const EmptyState(
                  title: 'No expenses yet',
                  message: 'Tap the + button to add your first transaction and start tracking!',
                  icon: Icons.receipt_long_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () => provider.init(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: provider.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = provider.expenses[index];
                      final category = provider.getCategoryById(expense.categoryId);
                      final isExpense = category.type == CategoryType.expense;

                      return _ExpenseItem(
                        expense: expense,
                        category: category,
                        isExpense: isExpense,
                        onLongPress: () => _showDeleteBottomSheet(context, provider, expense),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExpenseDetailPage(expense: expense),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showDeleteBottomSheet(BuildContext context, ExpenseProvider provider, Expense expense) {
    final category = provider.getCategoryById(expense.categoryId);
    final isExpense = category.type == CategoryType.expense;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Move to Recycle Bin?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isExpense ? AppTheme.expenseColor : AppTheme.incomeColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconUtils.getIcon(category.icon),
                    color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                  ),
                ),
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormatter.format(expense.date)),
                trailing: Text(
                  CurrencyFormatter.format(expense.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await provider.deleteExpense(expense.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moved to Recycle Bin')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.expenseColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Move to Bin', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(BuildContext context, ExpenseProvider provider) {
    final totalIncome = provider.expenses
        .where((e) => e.type == CategoryType.income)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalExpenses = provider.expenses
        .where((e) => e.type == CategoryType.expense)
        .fold<double>(0, (sum, e) => sum + e.amount);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBackground,
            AppTheme.secondaryBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Balance',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalIncome - totalExpenses),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(Icons.account_balance_wallet_rounded, color: AppTheme.emeraldGreen.withOpacity(0.5), size: 40),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryItem(context, 'Income', totalIncome, AppTheme.incomeColor, Icons.arrow_upward_rounded),
              const SizedBox(width: 24),
              _buildSummaryItem(context, 'Expense', totalExpenses, AppTheme.expenseColor, Icons.arrow_downward_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ExpenseItem extends StatefulWidget {
  final Expense expense;
  final Category category;
  final bool isExpense;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _ExpenseItem({
    required this.expense,
    required this.category,
    required this.isExpense,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  State<_ExpenseItem> createState() => _ExpenseItemState();
}

class _ExpenseItemState extends State<_ExpenseItem> {
  Timer? _timer;

  void _startTimer() {
    _timer = Timer(const Duration(milliseconds: 600), () {
      HapticFeedback.mediumImpact();
      widget.onLongPress();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startTimer(),
      onTapUp: (_) => _cancelTimer(),
      onTapCancel: () => _cancelTimer(),
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (widget.isExpense ? AppTheme.expenseColor : AppTheme.incomeColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconUtils.getIcon(widget.category.icon),
              color: widget.isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              size: 20,
            ),
          ),
          title: Text(
            widget.category.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateFormatter.format(widget.expense.date)}${widget.expense.note.isNotEmpty ? ' • ${widget.expense.note}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          trailing: Text(
            CurrencyFormatter.format(widget.expense.amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
          ),
        ),
      ),
    );
  }
}
