import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/expense_list_item.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

enum HistoryRangeMode { month, threeMonths, sixMonths, year }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryRangeMode _rangeMode = HistoryRangeMode.month;
  DateTime _currentAnchor = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _selectedTypeFilter = 'all'; // 'all', 'expense', 'income', 'transfer'

  DateTime get _startDate {
    switch (_rangeMode) {
      case HistoryRangeMode.month:
        return DateTime(_currentAnchor.year, _currentAnchor.month, 1);
      case HistoryRangeMode.threeMonths:
        return DateTime(_currentAnchor.year, _currentAnchor.month - 2, 1);
      case HistoryRangeMode.sixMonths:
        return DateTime(_currentAnchor.year, _currentAnchor.month - 5, 1);
      case HistoryRangeMode.year:
        return DateTime(_currentAnchor.year, 1, 1);
    }
  }

  DateTime get _endDate {
    switch (_rangeMode) {
      case HistoryRangeMode.month:
        return DateTime(_currentAnchor.year, _currentAnchor.month + 1, 0, 23, 59, 59);
      case HistoryRangeMode.threeMonths:
        return DateTime(_currentAnchor.year, _currentAnchor.month + 1, 0, 23, 59, 59);
      case HistoryRangeMode.sixMonths:
        return DateTime(_currentAnchor.year, _currentAnchor.month + 1, 0, 23, 59, 59);
      case HistoryRangeMode.year:
        return DateTime(_currentAnchor.year, 12, 31, 23, 59, 59);
    }
  }

  String get _rangeLabel {
    final monthFmt = DateFormat('MMM yyyy');
    switch (_rangeMode) {
      case HistoryRangeMode.month:
        return DateFormat('MMMM yyyy').format(_currentAnchor);
      case HistoryRangeMode.threeMonths:
        return '${monthFmt.format(_startDate)} – ${monthFmt.format(_endDate)}';
      case HistoryRangeMode.sixMonths:
        return '${monthFmt.format(_startDate)} – ${monthFmt.format(_endDate)}';
      case HistoryRangeMode.year:
        return '${_currentAnchor.year}';
    }
  }

  void _stepPrevious() {
    setState(() {
      switch (_rangeMode) {
        case HistoryRangeMode.month:
          _currentAnchor = DateTime(_currentAnchor.year, _currentAnchor.month - 1, 1);
          break;
        case HistoryRangeMode.threeMonths:
          _currentAnchor = DateTime(_currentAnchor.year, _currentAnchor.month - 3, 1);
          break;
        case HistoryRangeMode.sixMonths:
          _currentAnchor = DateTime(_currentAnchor.year, _currentAnchor.month - 6, 1);
          break;
        case HistoryRangeMode.year:
          _currentAnchor = DateTime(_currentAnchor.year - 1, 1, 1);
          break;
      }
    });
  }

  void _stepNext() {
    setState(() {
      switch (_rangeMode) {
        case HistoryRangeMode.month:
          _currentAnchor = DateTime(_currentAnchor.year, _currentAnchor.month + 1, 1);
          break;
        case HistoryRangeMode.threeMonths:
          _currentAnchor = DateTime(_currentAnchor.year, _currentAnchor.month + 3, 1);
          break;
        case HistoryRangeMode.sixMonths:
          _currentAnchor = DateTime(_currentAnchor.year, _currentAnchor.month + 6, 1);
          break;
        case HistoryRangeMode.year:
          _currentAnchor = DateTime(_currentAnchor.year + 1, 1, 1);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final allExpenses = expenseProvider.expenses.where((e) => !e.isDeleted).toList();

    // Filter by selected range
    final rangeExpenses = allExpenses.where((e) {
      return !e.date.isBefore(_startDate) && !e.date.isAfter(_endDate);
    }).toList();

    // Metrics
    final totalIncome = rangeExpenses
        .where((e) => e.type == CategoryType.income)
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalExpense = rangeExpenses
        .where((e) => e.type == CategoryType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);

    final netSavings = totalIncome - totalExpense;

    // Search and Category Filter
    final filteredExpenses = rangeExpenses.where((e) {
      final isTransfer = e.toAccountId != null && e.toAccountId!.isNotEmpty;
      if (_selectedTypeFilter == 'expense' && (e.type != CategoryType.expense || isTransfer)) return false;
      if (_selectedTypeFilter == 'income' && (e.type != CategoryType.income || isTransfer)) return false;
      if (_selectedTypeFilter == 'transfer' && !isTransfer) return false;

      if (_selectedCategoryId != null && e.categoryId != _selectedCategoryId) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matches = e.title.toLowerCase().contains(query) ||
            e.note.toLowerCase().contains(query) ||
            (e.subCategory ?? '').toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          'Historical Ledger',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.bold),
        ),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Mode Selector
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.line),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildModePill('Month', HistoryRangeMode.month),
                  _buildModePill('3M', HistoryRangeMode.threeMonths),
                  _buildModePill('6M', HistoryRangeMode.sixMonths),
                  _buildModePill('Year', HistoryRangeMode.year),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Date Range Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: context.textPrimary),
                    onPressed: () {
                      HapticsService.selection();
                      _stepPrevious();
                    },
                  ),
                  Expanded(
                    child: Text(
                      _rangeLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: context.textPrimary),
                    onPressed: () {
                      HapticsService.selection();
                      _stepNext();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Summary Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: context.line),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL INFLOW',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
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
                              'TOTAL OUTFLOW',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
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
                  const SizedBox(height: 16),
                  Divider(height: 1, color: context.line),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Balance for Range',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textMuted,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(netSavings),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: netSavings >= 0 ? context.emerald : context.brick,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              style: GoogleFonts.inter(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search in $_rangeLabel...',
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                filled: true,
                fillColor: context.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),

            // Search Categories Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSearchCategoryChip('All', 'all', Icons.apps_rounded),
                  const SizedBox(width: 8),
                  _buildSearchCategoryChip('Expense', 'expense', Icons.arrow_upward_rounded),
                  const SizedBox(width: 8),
                  _buildSearchCategoryChip('Income', 'income', Icons.arrow_downward_rounded),
                  const SizedBox(width: 8),
                  _buildSearchCategoryChip('Transfer', 'transfer', Icons.swap_horiz_rounded),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Records Header
            Text(
              'LEDGER ENTRIES (${filteredExpenses.length})',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: context.textMuted,
              ),
            ),
            const SizedBox(height: 12),

            if (filteredExpenses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: context.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No transactions recorded for $_rangeLabel.',
                  style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExpenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, idx) {
                  final expense = filteredExpenses[idx];
                  final category = categoryProvider.categories.firstWhere(
                    (c) => c.id == expense.categoryId,
                    orElse: () => const Category(id: '', name: 'Uncategorized', type: CategoryType.expense, icon: Icons.category, subCategories: []),
                  );
                  return ExpenseListItem(
                    expense: expense,
                    category: category,
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildModePill(String label, HistoryRangeMode mode) {
    final isSelected = _rangeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticsService.selection();
          setState(() {
            _rangeMode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : context.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCategoryChip(String label, String value, IconData icon) {
    final isSelected = _selectedTypeFilter == value;
    return GestureDetector(
      onTap: () {
        HapticsService.selection();
        setState(() {
          _selectedTypeFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? context.gold : context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? context.gold : context.line,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : context.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
