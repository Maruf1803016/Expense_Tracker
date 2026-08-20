import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/expense_list_item.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final allExpenses = expenseProvider.expenses;

    // Filter by selected month
    final monthExpenses = allExpenses.where((e) {
      return e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month;
    }).toList();

    // Calculate metrics
    final totalIncome = monthExpenses
        .where((e) => e.type == CategoryType.income)
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalExpense = monthExpenses
        .where((e) => e.type == CategoryType.expense)
        .fold(0.0, (sum, e) => sum + e.amount);

    final netSavings = totalIncome - totalExpense;

    // Apply search and category filters
    final filteredExpenses = monthExpenses.where((e) {
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

    final format = DateFormat('MMMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        title: Text(
          'Historical Ledger',
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.paperCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                      });
                    },
                  ),
                  Text(
                    format.format(_selectedMonth),
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                      if (nextMonth.isBefore(DateTime.now().add(const Duration(days: 31)))) {
                        setState(() {
                          _selectedMonth = nextMonth;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Monthly Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppTheme.ink,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.goldLine),
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
                                color: AppTheme.goldSoft.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalIncome),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppTheme.goldLine),
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
                                color: AppTheme.goldSoft.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(totalExpense),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.goldLine),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Monthly Balance',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.goldSoft,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(netSavings),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: netSavings >= 0 ? AppTheme.goldSoft : AppTheme.brick,
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
              decoration: InputDecoration(
                hintText: 'Search in ${format.format(_selectedMonth)}...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 20),

            // Records Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MONTHLY LEDGER (${filteredExpenses.length})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (filteredExpenses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: AppTheme.paperCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppTheme.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No transactions recorded for ${format.format(_selectedMonth)}.',
                  style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 13),
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
    );
  }
}
