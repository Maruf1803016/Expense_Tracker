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
import 'package:expense_tracker/features/expense/presentation/pages/expense_detail_page.dart';
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
    final expenses = provider.expenses;

    final filteredExpenses = expenses.where((e) {
      bool matchesTab = true;
      switch (provider.selectedFilter) {
        case ExpenseFilter.all:
          matchesTab = true;
          break;
        case ExpenseFilter.expense:
          matchesTab = e.type == CategoryType.expense && e.planId == null;
          break;
        case ExpenseFilter.income:
          matchesTab = e.type == CategoryType.income;
          break;
        case ExpenseFilter.plan:
          matchesTab = e.planId != null;
          break;
      }
      if (!matchesTab) return false;

      if (_searchQuery.isNotEmpty) {
        final matchesQuery = e.title.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesQuery) return false;
      }

      if (_selectedCategoryId != null) {
        if (e.categoryId != _selectedCategoryId) return false;
      }

      return true;
    }).toList();

    final recurringSources = context.watch<RecurringTransactionProvider>().sources;
    final incomeSources = recurringSources.where((s) => s.type == 'income').toList();
    final expenseSources = recurringSources.where((s) => s.type == 'expense').toList();

    final showUpcomingIncome = (provider.selectedFilter == ExpenseFilter.income || provider.selectedFilter == ExpenseFilter.all) && incomeSources.isNotEmpty;
    final showUpcomingBills = (provider.selectedFilter == ExpenseFilter.expense || provider.selectedFilter == ExpenseFilter.all) && expenseSources.isNotEmpty;

    return Column(
      children: [
        _buildBalanceSummary(context, provider),
        _buildNetWorthCard(context, provider),
        _buildSearchAndFilters(context, provider),
        const SizedBox(height: 16),
        if (showUpcomingIncome) ...[
          _buildUpcomingSection(context, incomeSources, isIncome: true),
          const SizedBox(height: 16),
        ],
        if (showUpcomingBills) ...[
          _buildUpcomingSection(context, expenseSources, isIncome: false),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: _buildBody(context, provider, filteredExpenses),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ExpenseProvider provider, List<Expense> filteredExpenses) {
    if (provider.isLoading && provider.expenses.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    }

    if (provider.errorMessage != null && provider.expenses.isEmpty) {
      return Center(
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
      );
    }

    if (provider.expenses.isEmpty) {
      return _buildEmptyState(context);
    }

    if (filteredExpenses.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off_rounded, size: 64, color: AppTheme.muted),
              SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(color: AppTheme.muted, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Sort descending
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Map to list items with group headers
    final listItems = <_DashboardListItem>[];
    String? currentGroupLabel;
    
    for (var expense in filteredExpenses) {
      final label = _getDateLabel(expense.date);
      if (currentGroupLabel != label) {
        currentGroupLabel = label;
        listItems.add(_HeaderItem(label));
      }
      listItems.add(_TransactionItem(expense));
    }

    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: () => provider.init(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: listItems.length,
        itemBuilder: (context, index) {
          final item = listItems[index];

          if (item is _HeaderItem) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.muted,
                  letterSpacing: 1.2,
                ),
              ),
            );
          } else {
            final expense = (item as _TransactionItem).expense;
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
          }
        },
      ),
    );
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
              style: GoogleFonts.fraunces(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Add transactions using the floating action button at the bottom.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted),
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
      backgroundColor: AppTheme.paperCard,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppTheme.gold),
                title: const Text('Edit Transaction'),
                onTap: () {
                  Navigator.pop(context);
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
                title: const Text('Delete Transaction'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Transaction'),
                      content: const Text('Are you sure you want to delete this transaction?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
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
    final totalIncome = provider.expenses
        .where((e) => e.type == CategoryType.income)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final totalExpenses = provider.expenses
        .where((e) => e.type == CategoryType.expense)
        .fold<double>(0, (sum, e) => sum + e.amount);
    
    final netSavings = totalIncome - totalExpenses;
    final double savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

    final healthScore = provider.healthScore;
    final isOnTrack = healthScore >= 70;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.ink,
            AppTheme.ink2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HairlinePatternPainter(color: AppTheme.goldLine),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                            'TOTAL BALANCE',
                            style: GoogleFonts.inter(
                              color: AppTheme.goldSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(netSavings),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isOnTrack ? AppTheme.emerald : AppTheme.brick).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isOnTrack ? AppTheme.emerald : AppTheme.brick).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isOnTrack ? 'On Track' : 'Needs Attention',
                          style: GoogleFonts.inter(
                            color: isOnTrack ? AppTheme.goldSoft : AppTheme.goldSoft,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildSummaryItem(context, 'Income', totalIncome, AppTheme.emerald, Icons.arrow_upward_rounded),
                      const SizedBox(width: 24),
                      _buildSummaryItem(context, 'Expense', totalExpenses, AppTheme.brick, Icons.arrow_downward_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Savings Rate: ${savingsRate.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(color: AppTheme.goldSoft, fontSize: 11),
                      ),
                      Text(
                        'Net Savings: ${CurrencyFormatter.format(netSavings)}',
                        style: GoogleFonts.inter(color: AppTheme.goldSoft, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
              Text(
                label,
                style: GoogleFonts.inter(color: AppTheme.goldSoft, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            style: GoogleFonts.inter(color: AppTheme.textDark, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              hintStyle: GoogleFonts.inter(color: AppTheme.muted.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: AppTheme.muted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: const Icon(Icons.clear, color: AppTheme.muted, size: 20),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.paperCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill(
                  label: 'All',
                  isSelected:
                      _selectedCategoryId == null && provider.selectedFilter == ExpenseFilter.all,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.all);
                  },
                  color: AppTheme.gold,
                ),
                _buildCategoryPill(
                  label: 'Income',
                  icon: Icons.arrow_downward_rounded,
                  isSelected:
                      _selectedCategoryId == null && provider.selectedFilter == ExpenseFilter.income,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.income);
                  },
                  color: AppTheme.emerald,
                ),
                _buildCategoryPill(
                  label: 'Goal',
                  icon: Icons.track_changes_rounded,
                  isSelected:
                      _selectedCategoryId == null && provider.selectedFilter == ExpenseFilter.plan,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                    provider.setSelectedFilter(ExpenseFilter.plan);
                  },
                  color: AppTheme.gold,
                ),
                ...provider.categories.where((category) => category.type == CategoryType.expense).map((category) {
                  final catColor = AppTheme.getCategoryColor(category.id, category.name);
                  return _buildCategoryPill(
                    label: category.name,
                    icon: category.icon,
                    isSelected: _selectedCategoryId == category.id,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                      provider.setSelectedFilter(ExpenseFilter.expense);
                    },
                    color: catColor,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.ink : AppTheme.paper2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.ink : AppTheme.line,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? AppTheme.goldSoft : AppTheme.muted),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? AppTheme.goldSoft : AppTheme.muted,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    } else {
      return DateFormat('EEEE, MMM d').format(date).toUpperCase();
    }
  }

  Widget _buildUpcomingSection(BuildContext context, List<RecurringTransactionSource> sources, {required bool isIncome}) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final currencySymbol = context.watch<SettingsProvider>().currentSymbol;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              isIncome ? 'UPCOMING INCOME' : 'UPCOMING BILLS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.muted,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...sources.map((source) => _buildUpcomingCard(context, source, currencySymbol, isIncome: isIncome)),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, RecurringTransactionSource source, String currencySymbol, {required bool isIncome}) {
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
    } else if (daysDiff <= 7) {
      badgeText = daysDiff == 0 ? 'DUE TODAY' : 'DUE IN $daysDiff DAYS';
      badgeColor = AppTheme.gold.withOpacity(0.15);
      textColor = AppTheme.gold;
    } else {
      badgeText = 'PENDING';
      badgeColor = AppTheme.muted.withOpacity(0.15);
      textColor = AppTheme.muted;
    }

    final formattedAmount = CurrencyFormatter.format(source.expectedAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => EditRecurringTransactionSheet(source: source),
          );
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                source.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${source.frequency.toUpperCase()} • ',
                  style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 12),
                ),
                TextSpan(
                  text: formattedAmount,
                  style: GoogleFonts.inter(
                    color: isIncome ? AppTheme.emerald : AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                  content: Text(isIncome ? 'Income marked as received successfully' : 'Bill marked as paid successfully'),
                  backgroundColor: AppTheme.emerald,
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppTheme.brick,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: (isIncome ? AppTheme.emerald : AppTheme.textDark).withOpacity(0.15),
            foregroundColor: isIncome ? AppTheme.emerald : AppTheme.textDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isIncome ? 'Mark as Received' : 'Mark as Paid',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(BuildContext context, ExpenseProvider expenseProvider) {
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;
    
    // Sum of all accounts balance
    double netWorth = 0.0;
    final List<MapEntry<Account, double>> accountBalances = [];
    
    for (final account in accounts) {
      final balance = Account.calculateBalance(account, expenseProvider.expenses);
      netWorth += balance;
      accountBalances.add(MapEntry(account, balance));
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountsManagementPage()),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NET WORTH',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Manage',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppTheme.gold,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(netWorth),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              if (accountBalances.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: accountBalances.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final entry = accountBalances[index];
                      final account = entry.key;
                      final balance = entry.value;
                      final isNegative = balance < 0;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.paper,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              account.icon,
                              color: account.color,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              account.name,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              CurrencyFormatter.format(balance),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isNegative ? AppTheme.brick : AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
    final catColor = AppTheme.getCategoryColor(widget.category.id, widget.category.name);
    final isPlanLinked = widget.expense.planId != null;

    return GestureDetector(
      onTapDown: (_) => _startTimer(),
      onTapUp: (_) => _cancelTimer(),
      onTapCancel: () => _cancelTimer(),
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.paperCard,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isPlanLinked ? AppTheme.gold : AppTheme.line,
            width: isPlanLinked ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Category icon with 15% opacity circular background
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.category.icon,
                        size: 20,
                        color: catColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.expense.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Category name & optional subcategory
                          Row(
                            children: [
                              Text(
                                widget.category.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.muted,
                                ),
                              ),
                              if (widget.expense.subCategory != null && widget.expense.subCategory!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(color: AppTheme.muted.withOpacity(0.5), fontSize: 12),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.expense.subCategory!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Amount (emerald for income, textDark for expense)
                    Text(
                      (widget.isExpense ? '-' : '+') + CurrencyFormatter.format(widget.expense.amount),
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: widget.isExpense ? AppTheme.textDark : AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPlanLinked)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Icon(
                      Icons.track_changes_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
