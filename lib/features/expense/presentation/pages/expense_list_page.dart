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

  Widget _buildFilterTabs(BuildContext context, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ExpenseFilter.values.map((filter) {
          final isSelected = provider.selectedFilter == filter;
          String label;
          IconData icon;
          switch (filter) {
            case ExpenseFilter.all:
              label = 'All';
              icon = Icons.all_inclusive_rounded;
              break;
            case ExpenseFilter.expense:
              label = 'Expense';
              icon = Icons.remove_circle_outline;
              break;
            case ExpenseFilter.income:
              label = 'Income';
              icon = Icons.add_circle_outline;
              break;
            case ExpenseFilter.plan:
              label = 'Goal';
              icon = Icons.track_changes_rounded;
              break;
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  provider.setSelectedFilter(filter);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.ink : AppTheme.paper2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.gold : AppTheme.line,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected ? AppTheme.goldSoft : AppTheme.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.goldSoft : AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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

    return Column(
      children: [
        _buildBalanceSummary(context, provider),
        _buildSearchAndFilters(context, provider),
        const SizedBox(height: 16),
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
                  isSelected: _selectedCategoryId == null,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  },
                  color: AppTheme.gold,
                ),
                ...provider.categories.map((category) {
                  final catColor = AppTheme.getCategoryColor(category.id, category.name);
                  return _buildCategoryPill(
                    label: category.name,
                    icon: category.icon,
                    isSelected: _selectedCategoryId == category.id,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
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
