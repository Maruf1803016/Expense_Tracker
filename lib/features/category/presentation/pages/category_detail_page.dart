import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';

class CategoryDetailPage extends StatefulWidget {
  final Category category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIcon = widget.category.icon ?? 'category';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _isEditing = false);
      return;
    }

    final updatedCategory = Category(
      id: widget.category.id,
      name: newName,
      type: widget.category.type,
      icon: _selectedIcon,
      parentId: widget.category.parentId,
    );

    await context.read<ExpenseProvider>().updateCategory(updatedCategory);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final categoryExpenses = provider.expenses.where((e) => e.categoryId == widget.category.id).toList();
    
    // Sort expenses by date descending
    categoryExpenses.sort((a, b) => b.date.compareTo(a.date));

    final totalAmount = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final color = widget.category.type == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(border: InputBorder.none),
                onSubmitted: (_) => _saveCategory(),
              )
            : Text(widget.category.name),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveCategory();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                if (_isEditing)
                  SizedBox(
                    height: 100,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: IconUtils.availableIconNames.length,
                      itemBuilder: (context, index) {
                        final iconName = IconUtils.availableIconNames[index];
                        final isSelected = _selectedIcon == iconName;
                        return InkWell(
                          onTap: () => setState(() => _selectedIcon = iconName),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.emeraldGreen.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconUtils.getIcon(iconName),
                              color: isSelected ? AppTheme.emeraldGreen : Colors.white70,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(
                      IconUtils.getIcon(_selectedIcon),
                      size: 40,
                      color: color,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  CurrencyFormatter.format(totalAmount),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total ${widget.category.type.name.toUpperCase()}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w500, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TRANSACTION HISTORY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
              ),
            ),
          ),

          Expanded(
            child: categoryExpenses.isEmpty
                ? const EmptyState(
                    title: 'No Transactions',
                    message: 'Transactions in this category will appear here.',
                    icon: Icons.history,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categoryExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = categoryExpenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(expense.note.isEmpty ? 'No Note' : expense.note),
                          subtitle: Text(DateFormatter.format(expense.date)),
                          trailing: Text(
                            CurrencyFormatter.format(expense.amount),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
