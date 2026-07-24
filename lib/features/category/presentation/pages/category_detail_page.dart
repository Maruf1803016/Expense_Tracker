import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/features/expense/presentation/pages/expense_detail_page.dart';

class CategoryDetailPage extends StatefulWidget {
  final Category category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final List<IconData> _curatedIcons = const [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.fastfood,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.local_taxi,
    Icons.shopping_bag,
    Icons.checkroom,
    Icons.devices,
    Icons.card_giftcard,
    Icons.add_circle,
  ];

  bool _isDefaultSubCategory(Category category, String subName) {
    final defaultCat = Category.defaultCategories.firstWhere(
      (c) => c.id == category.id,
      orElse: () => const Category(id: '', name: '', type: CategoryType.expense, icon: Icons.category, subCategories: []),
    );
    return defaultCat.subCategories.any((s) => s.name.toLowerCase() == subName.toLowerCase());
  }

  Future<void> _deleteSubCategory(BuildContext context, Category category, SubCategory sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sub-category'),
        content: Text('Are you sure you want to delete "${sub.name}"? This won\'t affect past transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.expenseColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final updatedSubs = List<SubCategory>.from(category.subCategories)
        ..removeWhere((s) => s.name == sub.name);
      final updatedCategory = Category(
        id: category.id,
        name: category.name,
        type: category.type,
        icon: category.icon,
        subCategories: updatedSubs,
      );
      
      await context.read<CategoryProvider>().update(updatedCategory);
    }
  }

  void _showAddCustomSubCategoryDialog(BuildContext context, Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddSubCategorySheet(
          category: category,
          curatedIcons: _curatedIcons,
          onSave: (name, icon) async {
            final newSub = SubCategory(name: name, icon: icon);
            final updatedSubs = List<SubCategory>.from(category.subCategories)..add(newSub);
            final updatedCategory = Category(
              id: category.id,
              name: category.name,
              type: category.type,
              icon: category.icon,
              subCategories: updatedSubs,
            );
            
            await context.read<CategoryProvider>().update(updatedCategory);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    
    // Resolve live category from provider
    final liveCategory = categoryProvider.categories.firstWhere(
      (c) => c.id == widget.category.id,
      orElse: () => widget.category,
    );
    
    // 1. Identify all expenses belonging to this category
    final allExpenses = provider.expenses.where((e) {
      return e.categoryId == liveCategory.id;
    }).toList();

    allExpenses.sort((a, b) => b.date.compareTo(a.date));

    // 2. Group expenses by sub-category
    final Map<String, List<Expense>> groupedExpenses = {};
    for (var e in allExpenses) {
      final subKey = e.subCategory ?? 'General';
      if (!groupedExpenses.containsKey(subKey)) {
        groupedExpenses[subKey] = [];
      }
      groupedExpenses[subKey]!.add(e);
    }

    final totalAmount = allExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final color = liveCategory.type == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(liveCategory.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBackground,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(
                      liveCategory.icon,
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
                    'Total ${liveCategory.type.name.toUpperCase()}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w500, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),

            // Sub-categories Management Row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUB-CATEGORIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...liveCategory.subCategories.map((sub) {
                        final isDefault = _isDefaultSubCategory(liveCategory, sub.name);
                        return Chip(
                          avatar: Icon(sub.icon, size: 14, color: Colors.white54),
                          label: Text(sub.name, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          backgroundColor: Colors.white.withOpacity(0.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.white.withOpacity(0.05)),
                          ),
                          onDeleted: isDefault
                              ? null
                              : () => _deleteSubCategory(context, liveCategory, sub),
                          deleteIcon: const Icon(Icons.cancel, size: 14, color: Colors.white60),
                        );
                      }).toList(),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 14, color: AppTheme.emeraldGreen),
                        label: const Text('Add Custom', style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreen)),
                        backgroundColor: Colors.white.withOpacity(0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppTheme.emeraldGreen, width: 0.5),
                        ),
                        onPressed: () => _showAddCustomSubCategoryDialog(context, liveCategory),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (allExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48.0),
                child: EmptyState(
                  title: 'No Transactions',
                  message: 'Transactions in this category will appear here.',
                  icon: Icons.history,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedExpenses.entries.map((entry) {
                    final isGeneral = entry.key == 'General';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                          child: Row(
                            children: [
                              Icon(
                                isGeneral ? Icons.category : Icons.label_outline,
                                size: 16,
                                color: isGeneral ? Colors.white38 : const Color(0xFF00C896),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isGeneral ? 12 : 13,
                                  fontWeight: isGeneral ? FontWeight.bold : FontWeight.w500,
                                  fontStyle: isGeneral ? FontStyle.normal : FontStyle.italic,
                                  color: isGeneral ? Colors.white38 : const Color(0xFF00C896),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map((expense) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: isGeneral ? null : const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFF00C896), width: 3),
                              ),
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: isGeneral ? null : const Color(0xFF1A2C42),
                              child: ListTile(
                                contentPadding: EdgeInsets.only(
                                  left: isGeneral ? 16 : 40,
                                  right: 16,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    expense.subCategoryIcon != null
                                        ? IconUtils.getIcon(expense.subCategoryIcon)
                                        : liveCategory.icon, 
                                    color: color, 
                                    size: 18
                                  ),
                                ),
                                title: Text(
                                  expense.title.isEmpty ? liveCategory.name : expense.title,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(DateFormatter.format(expense.date), style: const TextStyle(fontSize: 12, color: Colors.white38)),
                                trailing: Text(
                                  CurrencyFormatter.format(expense.amount),
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExpenseDetailPage(expense: expense),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _AddSubCategorySheet extends StatefulWidget {
  final Category category;
  final List<IconData> curatedIcons;
  final Function(String name, IconData icon) onSave;

  const _AddSubCategorySheet({
    required this.category,
    required this.curatedIcons,
    required this.onSave,
  });

  @override
  State<_AddSubCategorySheet> createState() => _AddSubCategorySheetState();
}

class _AddSubCategorySheetState extends State<_AddSubCategorySheet> {
  final _nameController = TextEditingController();
  IconData? _selectedIcon;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Sub-category under ${widget.category.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Sub-category name',
                prefixIcon: Icon(Icons.label_outline),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose Icon',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.curatedIcons.length,
              itemBuilder: (context, index) {
                final icon = widget.curatedIcons[index];
                final isSelected = _selectedIcon == icon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.emeraldGreen : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.emeraldGreen : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (_nameController.text.trim().isEmpty || _selectedIcon == null || _isSaving)
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    await widget.onSave(_nameController.text.trim(), _selectedIcon!);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Sub-category', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
