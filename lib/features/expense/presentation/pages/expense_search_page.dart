import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_skeleton.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_search_provider.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/expense_list_item.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/search_filter_sheet.dart';

class ExpenseSearchPage extends StatefulWidget {
  const ExpenseSearchPage({super.key});

  @override
  State<ExpenseSearchPage> createState() => _ExpenseSearchPageState();
}

class _ExpenseSearchPageState extends State<ExpenseSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial search to populate list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eProv = context.read<ExpenseProvider>();
      context.read<ExpenseSearchProvider>().updateQuery('', eProv.expenses, eProv.categories);
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final searchProvider = context.watch<ExpenseSearchProvider>();
    final results = searchProvider.results;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search expenses, notes...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      searchProvider.updateQuery('', expenseProvider.expenses, expenseProvider.categories);
                    },
                  )
                : null,
            ),
            onChanged: (val) {
              searchProvider.updateQuery(val, expenseProvider.expenses, expenseProvider.categories);
              setState(() {}); // For clear button visibility
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: searchProvider.selectedCategoryIds.isNotEmpty || searchProvider.startDate != null,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: searchProvider.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 8,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LoadingSkeleton(height: 80),
              ),
            )
          : results.isEmpty
              ? const EmptyState(
                  title: 'No matching expenses',
                  message: 'Try adjusting your filters or search keywords.',
                  icon: Icons.search_off_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final expense = results[index];
                    final category = expenseProvider.getCategoryById(expense.categoryId);
                    return ExpenseListItem(expense: expense, category: category);
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
