import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_search_provider.dart';
import 'package:expense_tracker/features/expense/domain/logic/expense_query_engine.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({super.key});

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late List<String> _tempCategories;
  ExpenseSortType? _tempSort;
  DateTime? _tempStart;
  DateTime? _tempEnd;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExpenseSearchProvider>();
    _tempCategories = List.from(provider.selectedCategoryIds);
    _tempSort = provider.sortType;
    _tempStart = provider.startDate;
    _tempEnd = provider.endDate;
  }

  void _applyFilters() {
    final expenseProvider = context.read<ExpenseProvider>();
    context.read<ExpenseSearchProvider>().updateFilters(
      categoryIds: _tempCategories,
      sortType: _tempSort,
      startDate: _tempStart,
      endDate: _tempEnd,
      allExpenses: expenseProvider.expenses,
      allCategories: expenseProvider.categories,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpenseProvider>().categories;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters & Sorting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  final eProv = context.read<ExpenseProvider>();
                  context.read<ExpenseSearchProvider>().clearFilters(eProv.expenses, eProv.categories);
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _tempCategories.contains(category.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _tempCategories.add(category.id);
                        } else {
                          _tempCategories.remove(category.id);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          const Text('Sorting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseSortType>(
            value: _tempSort,
            items: ExpenseSortType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getSortName(type)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _tempSort = val),
          ),
          const SizedBox(height: 24),

          const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _tempStart ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _tempStart = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_tempStart == null ? 'Start Date' : '${_tempStart!.day}/${_tempStart!.month}/${_tempStart!.year}'),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _tempEnd ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _tempEnd = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_tempEnd == null ? 'End Date' : '${_tempEnd!.day}/${_tempEnd!.month}/${_tempEnd!.year}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Apply Filters'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getSortName(ExpenseSortType type) {
    switch (type) {
      case ExpenseSortType.newest: return 'Newest First';
      case ExpenseSortType.oldest: return 'Oldest First';
      case ExpenseSortType.highestAmount: return 'Highest Amount';
      case ExpenseSortType.lowestAmount: return 'Lowest Amount';
    }
  }
}
