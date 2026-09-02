import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/pages/add_expense_page.dart';
import 'package:expense_tracker/features/expense/presentation/pages/transaction_detail_page.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/expense_list_item.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/providers/recurring_transaction_provider.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/edit_recurring_transaction_sheet.dart';
import 'package:expense_tracker/features/account/presentation/providers/account_provider.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/presentation/pages/accounts_management_page.dart';

import 'package:expense_tracker/features/loan/presentation/providers/loan_provider.dart';
import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/history/presentation/pages/history_page.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  String _searchQuery = '';
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final loanProvider = context.watch<LoanProvider>();
    final expenses = provider.expenses;
    final selectedMonth = provider.selectedMonth;
    final bool hasOlderTransactions = expenses.any(
      (e) => !e.isDeleted && ((e.date.year < selectedMonth.year) || (e.date.year == selectedMonth.year && e.date.month < selectedMonth.month)),
    );

    final filteredExpenses = expenses.where((e) {
      if (_searchQuery.isEmpty) {
        if (e.date.year != selectedMonth.year || e.date.month != selectedMonth.month) {
          return false;
        }
      }
      bool matchesTab = true;
      switch (provider.selectedFilter) {
        case ExpenseFilter.all:
          matchesTab = true;
          break;
        case ExpenseFilter.expense:
          matchesTab = e.type == CategoryType.expense && e.toAccountId == null;
          break;
        case ExpenseFilter.income:
          matchesTab = e.type == CategoryType.income && e.toAccountId == null;
          break;
        case ExpenseFilter.transfer:
          matchesTab = e.type == CategoryType.transfer || e.toAccountId != null;
          break;
        case ExpenseFilter.pending:
          matchesTab = e.paymentStatus == PaymentStatus.pending;
          break;
        case ExpenseFilter.plan:
          matchesTab = e.planId != null;
          break;
      }
      if (!matchesTab) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = e.title.toLowerCase();
        final note = e.note.toLowerCase();
        
        final category = provider.getCategoryById(e.categoryId);
        final categoryName = category.name.toLowerCase();
        
        final subCategoryName = (e.subCategory ?? '').toLowerCase();
        
        final matchedAccounts = accountProvider.accounts.where((a) => a.id == e.accountId);
        final accountName = (matchedAccounts.isNotEmpty ? matchedAccounts.first.name : '').toLowerCase();

        final matchesQuery = title.contains(query) ||
            note.contains(query) ||
            categoryName.contains(query) ||
            subCategoryName.contains(query) ||
            accountName.contains(query);

        if (!matchesQuery) return false;
      }

      if (_selectedCategoryId != null) {
        if (e.categoryId != _selectedCategoryId) return false;
      }

      return true;
    }).toList();

    final recurringSources = context.watch<RecurringTransactionProvider>().sources;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueIncomeSources = recurringSources
        .where((s) => s.type == 'income')
        .where((s) {
          final due = DateTime(s.nextDueDate.year, s.nextDueDate.month, s.nextDueDate.day);
          return due.difference(today).inDays <= 0;
        })
        .toList()
      ..sort((a, b) {
        final cmp = a.nextDueDate.compareTo(b.nextDueDate);
        if (cmp != 0) return cmp;
        return a.createdAt.compareTo(b.createdAt);
      });

    final dueExpenseSources = recurringSources
        .where((s) => s.type == 'expense')
        .where((s) {
          final due = DateTime(s.nextDueDate.year, s.nextDueDate.month, s.nextDueDate.day);
          return due.difference(today).inDays <= 0;
        })
        .toList()
      ..sort((a, b) {
        final cmp = a.nextDueDate.compareTo(b.nextDueDate);
        if (cmp != 0) return cmp;
        return a.createdAt.compareTo(b.createdAt);
      });

    final hasDueRecurring = dueIncomeSources.isNotEmpty || dueExpenseSources.isNotEmpty;

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.init(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildBalanceSummary(context, provider),
          _buildNetWorthCard(context, provider),
          if (hasDueRecurring) ...[
            _buildDueRecurringStrip(context, dueIncomeSources, dueExpenseSources),
            const SizedBox(height: 12),
          ],
          _buildSearchAndFilters(context, provider),
          const SizedBox(height: 12),
          ..._buildTransactionWidgets(context, provider, filteredExpenses, hasOlderTransactions),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionWidgets(
    BuildContext context,
    ExpenseProvider provider,
    List<Expense> filteredExpenses,
    bool hasOlderTransactions,
  ) {
    if (provider.isLoading && provider.expenses.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        ),
      ];
    }

    if (provider.errorMessage != null && provider.expenses.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.brick),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.brick),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.init(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (provider.expenses.isEmpty) {
      return [_buildEmptyState(context)];
    }

    if (filteredExpenses.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.search_off_rounded, size: 48, color: AppTheme.muted),
                SizedBox(height: 12),
                Text(
                  'No results found',
                  style: TextStyle(color: AppTheme.muted, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Sort descending
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Map to list items with group headers
    final widgets = <Widget>[];
    String? currentGroupLabel;

    for (var expense in filteredExpenses) {
      final label = _getDateLabel(expense.date);
      if (currentGroupLabel != label) {
        currentGroupLabel = label;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: context.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ),
        );
      }

      final category = provider.getCategoryById(expense.categoryId);
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ExpenseListItem(
            expense: expense,
            category: category,
          ),
        ),
      );
    }

    if (hasOlderTransactions && _searchQuery.isEmpty) {
      widgets.add(
        Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: context.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: AppTheme.gold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historical Ledger Archive',
                          style: GoogleFonts.fraunces(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View and filter all previous months & multi-year records',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppTheme.gold, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.gold),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions Yet',
              style: GoogleFonts.fraunces(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Add transactions using the floating action button at the bottom.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteBottomSheet(BuildContext context, ExpenseProvider provider, Expense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.cardBg,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppTheme.gold),
                title: Text('Edit Transaction', style: TextStyle(color: ctx.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpensePage(expenseToEdit: expense),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.brick),
                title: Text('Delete Transaction', style: TextStyle(color: ctx.textPrimary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (alertCtx) => AlertDialog(
                      backgroundColor: alertCtx.cardBg,
                      title: Text('Delete Transaction', style: TextStyle(color: alertCtx.textPrimary)),
                      content: Text('Are you sure you want to delete this transaction?', style: TextStyle(color: alertCtx.textMuted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(alertCtx, false),
                          child: Text('Cancel', style: TextStyle(color: alertCtx.textMuted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(alertCtx, true),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.brick),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await provider.deleteExpense(expense.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceSummary(BuildContext context, ExpenseProvider provider) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isHidden = settingsProvider.hideAmounts;

    final totalIncome = provider.expenses
        .where((e) => e.type == CategoryType.income && e.toAccountId == null)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalExpenses = provider.expenses
        .where((e) => e.type == CategoryType.expense && e.toAccountId == null)
        .fold<double>(0, (sum, e) => sum + e.amount);
    
    final netSavings = totalIncome - totalExpenses;
    final double savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editorial Field Note Kicker & Headline
          Text(
            'TODAY’S FIELD NOTE',
            style: GoogleFonts.inter(
              color: AppTheme.gold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Money, in order.',
            style: GoogleFonts.fraunces(
              color: context.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'The few signals that matter before the day moves on.',
            style: GoogleFonts.inter(
              color: context.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Archival Ink Hero Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF152A20) : AppTheme.ink,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: context.isDark ? const Color(0xFF234433) : AppTheme.ink2, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVAILABLE BALANCE',
                  style: GoogleFonts.inter(
                    color: AppTheme.goldSoft,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHidden ? '••••••••' : CurrencyFormatter.format(netSavings),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Across your asset accounts, with liabilities held apart for a truthful net worth.',
                  style: GoogleFonts.inter(
                    color: AppTheme.goldSoft.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3-Card Summary Strip
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  'Inflow',
                  isHidden ? '••••••' : CurrencyFormatter.format(totalIncome),
                  'Cash in',
                  Icons.arrow_upward_rounded,
                  AppTheme.emerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  'Outflow',
                  isHidden ? '••••••' : CurrencyFormatter.format(totalExpenses),
                  'Cash out',
                  Icons.arrow_downward_rounded,
                  AppTheme.brick,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatCard(
                  context,
                  'Savings',
                  isHidden ? '••%' : '${savingsRate.toStringAsFixed(0)}%',
                  'Saved rate',
                  Icons.star_rounded,
                  AppTheme.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(BuildContext context, String label, String value, String caption, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: context.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: GoogleFonts.inter(fontSize: 9, color: context.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(BuildContext context, ExpenseProvider expenseProvider) {
    final settingsProvider = context.watch<SettingsProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final loanProvider = context.watch<LoanProvider>();
    final isHidden = settingsProvider.hideAmounts;

    final accounts = accountProvider.accounts;
    double totalAccountsBalance = 0.0;
    for (final account in accounts) {
      totalAccountsBalance += Account.calculateBalance(account, expenseProvider.expenses);
    }

    final netWorth = totalAccountsBalance + loanProvider.netLoanBalance;
    final assetFoliosCount = accounts.length;
    final liabilitiesCount = loanProvider.activeLoans.where((l) => l.type == LoanType.borrowed).length;

    // This month's pulse calculations
    final now = DateTime.now();
    final thisMonthExpenses = expenseProvider.expenses.where((e) =>
        e.date.year == now.year && e.date.month == now.month).toList();

    final thisMonthInflow = thisMonthExpenses
        .where((e) => e.type == CategoryType.income && e.toAccountId == null)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final thisMonthOutflow = thisMonthExpenses
        .where((e) => e.type == CategoryType.expense && e.toAccountId == null)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final thisMonthNet = thisMonthInflow - thisMonthOutflow;
    final hasMovement = thisMonthInflow > 0 || thisMonthOutflow > 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Privacy Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net worth',
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Semantics(
                  label: isHidden ? 'Show amounts' : 'Hide amounts',
                  button: true,
                  child: Tooltip(
                    message: isHidden ? 'Show amounts' : 'Hide amounts',
                    child: InkWell(
                      onTap: () => settingsProvider.toggleHideAmounts(),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 15,
                              color: context.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isHidden ? 'Show amounts' : 'Hide amounts',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Primary Net Worth Value
            Text(
              isHidden ? '••••••••' : CurrencyFormatter.format(netWorth),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),

            // Position Explanation
            Text(
              'Accounts plus loan position',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // Context Row: Asset Folios & Liabilities
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$assetFoliosCount ${assetFoliosCount == 1 ? 'asset folio' : 'asset folios'}',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: liabilitiesCount > 0 ? AppTheme.brick : context.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  liabilitiesCount > 0
                      ? '$liabilitiesCount ${liabilitiesCount == 1 ? 'liability' : 'liabilities'}'
                      : 'No liabilities',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: liabilitiesCount > 0 ? AppTheme.brick : context.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: context.line),
            const SizedBox(height: 10),

            // This-Month Pulse
            if (hasMovement)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPulseCol(context, 'Inflow', isHidden ? '••••••' : CurrencyFormatter.format(thisMonthInflow), AppTheme.emerald),
                  _buildPulseCol(context, 'Outflow', isHidden ? '••••••' : CurrencyFormatter.format(thisMonthOutflow), AppTheme.brick),
                  _buildPulseCol(context, 'Net', isHidden ? '••••••' : CurrencyFormatter.format(thisMonthNet), thisMonthNet >= 0 ? AppTheme.emerald : AppTheme.brick),
                ],
              )
            else
              Text(
                'No movement recorded this month',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: context.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseCol(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildDueRecurringStrip(
    BuildContext context,
    List<RecurringTransactionSource> dueIncomes,
    List<RecurringTransactionSource> dueExpenses,
  ) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isHidden = settingsProvider.hideAmounts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dueIncomes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'UPCOMING INCOME',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...dueIncomes.map((source) => _buildDueRecurringCard(context, source, isIncome: true, isHidden: isHidden)),
            const SizedBox(height: 8),
          ],
          if (dueExpenses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'UPCOMING BILLS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...dueExpenses.map((source) => _buildDueRecurringCard(context, source, isIncome: false, isHidden: isHidden)),
          ],
        ],
      ),
    );
  }

  Widget _buildDueRecurringCard(
    BuildContext context,
    RecurringTransactionSource source, {
    required bool isIncome,
    required bool isHidden,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(source.nextDueDate.year, source.nextDueDate.month, source.nextDueDate.day);
    final daysDiff = due.difference(today).inDays;

    final String badgeText;
    final Color badgeColor;
    final Color textColor;

    if (daysDiff < 0) {
      badgeText = 'OVERDUE';
      badgeColor = AppTheme.brick.withOpacity(0.15);
      textColor = AppTheme.brick;
    } else {
      badgeText = 'DUE TODAY';
      badgeColor = AppTheme.gold.withOpacity(0.15);
      textColor = AppTheme.gold;
    }

    final formattedAmount = isHidden ? '••••••' : CurrencyFormatter.format(source.expectedAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: context.cardBg,
            builder: (ctx) => EditRecurringTransactionSheet(source: source),
          );
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                source.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: context.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${source.frequency.toUpperCase()} • ',
                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 11),
                ),
                TextSpan(
                  text: formattedAmount,
                  style: GoogleFonts.inter(
                    color: isIncome ? AppTheme.emerald : context.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await context.read<RecurringTransactionProvider>().markAsComplete(source);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(isIncome ? 'Income marked as received' : 'Bill marked as paid'),
                  backgroundColor: AppTheme.emerald,
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed: $e. Tap to retry.'),
                  backgroundColor: AppTheme.brick,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => context.read<RecurringTransactionProvider>().markAsComplete(source),
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: (isIncome ? AppTheme.emerald : (context.isDark ? AppTheme.goldSoft : AppTheme.ink)).withOpacity(0.12),
            foregroundColor: isIncome ? AppTheme.emerald : (context.isDark ? AppTheme.goldSoft : AppTheme.ink),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            isIncome ? 'Mark received' : 'Mark paid',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: GoogleFonts.inter(color: context.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: context.textMuted, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: Icon(Icons.clear, color: context.textMuted, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: context.cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill(
                  context: context,
                  label: 'All',
                  isSelected: provider.selectedFilter == ExpenseFilter.all,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.all);
                  },
                  color: AppTheme.gold,
                ),
                _buildCategoryPill(
                  context: context,
                  label: 'Expense',
                  icon: Icons.arrow_downward_rounded,
                  isSelected: provider.selectedFilter == ExpenseFilter.expense,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.expense);
                  },
                  color: AppTheme.brick,
                ),
                _buildCategoryPill(
                  context: context,
                  label: 'Income',
                  icon: Icons.arrow_upward_rounded,
                  isSelected: provider.selectedFilter == ExpenseFilter.income,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.income);
                  },
                  color: AppTheme.emerald,
                ),
                _buildCategoryPill(
                  context: context,
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  isSelected: provider.selectedFilter == ExpenseFilter.transfer,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.transfer);
                  },
                  color: context.isDark ? AppTheme.goldSoft : AppTheme.ink2,
                ),
                _buildCategoryPill(
                  context: context,
                  label: 'Pending',
                  icon: Icons.hourglass_empty_rounded,
                  isSelected: provider.selectedFilter == ExpenseFilter.pending,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.pending);
                  },
                  color: AppTheme.gold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required BuildContext context,
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final activeBg = context.isDark ? AppTheme.goldSoft : AppTheme.ink;
    final activeText = context.isDark ? const Color(0xFF121C15) : AppTheme.goldSoft;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : context.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeBg : context.line,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: isSelected ? activeText : context.textMuted),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? activeText : context.textPrimary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);
    if (checkDate == today) {
      return 'TODAY';
    } else if (checkDate == yesterday) {
      return 'YESTERDAY';
    } else if (checkDate.isAfter(today)) {
      return 'UPCOMING • ${DateFormat('EEEE, MMM d').format(date).toUpperCase()}';
    } else {
      return DateFormat('EEEE, MMM d').format(date).toUpperCase();
    }
  }
}

abstract class _DashboardListItem {}

class _HeaderItem implements _DashboardListItem {
  final String title;
  _HeaderItem(this.title);
}

class _TransactionItem implements _DashboardListItem {
  final Expense expense;
  _TransactionItem(this.expense);
}



class _HairlinePatternPainter extends CustomPainter {
  final Color color;
  _HairlinePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double angleRad = 115 * math.pi / 180;
    final double spacing = 34.0;
    
    final double tanAngle = math.tan(angleRad);
    
    for (double x = -size.height * tanAngle - size.width; x < size.width + size.height * 2; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * tanAngle, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
