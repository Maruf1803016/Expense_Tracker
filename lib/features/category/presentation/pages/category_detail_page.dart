import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/budget/domain/entities/category_budget_status.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/features/expense/presentation/pages/transaction_detail_page.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

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

  void _showSetCategoryBudgetDialog(
    BuildContext context, 
    ExpenseProvider provider, 
    Category category, 
    double currentLimit,
  ) {
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Set Budget for ${category.name}', style: TextStyle(color: context.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: context.textMuted),
            border: const UnderlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              HapticsService.lightImpact();
              final amount = double.tryParse(controller.text.trim()) ?? 0.0;
              try {
                await provider.setBudget(category.id, amount);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Budget for ${category.name} updated successfully'),
                      backgroundColor: context.emerald,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save budget: $e'),
                      backgroundColor: context.brick,
                    ),
                  );
                }
              }
            },
            child: Text('Save', style: TextStyle(color: context.gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
        backgroundColor: context.cardBg,
        title: Text('Delete Sub-category', style: TextStyle(color: context.textPrimary)),
        content: Text('Are you sure you want to delete "${sub.name}"? This won\'t affect past transactions.', style: TextStyle(color: context.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.brick),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticsService.lightImpact();
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
    final color = liveCategory.type == CategoryType.income ? context.emerald : context.brick;
    final budgetStatus = provider.rolledUpBudgetStatuses.firstWhere(
      (b) => b.categoryId == liveCategory.id,
      orElse: () => CategoryBudgetStatus.fromAmounts(
        categoryId: liveCategory.id,
        categoryName: liveCategory.name,
        limit: 0.0,
        spent: totalAmount,
        month: provider.selectedMonth.month,
        year: provider.selectedMonth.year,
      ),
    );

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text(liveCategory.name, style: TextStyle(color: context.textPrimary)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                border: Border(bottom: BorderSide(color: context.line)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.getCategoryColor(liveCategory.id, liveCategory.name).withValues(alpha: 0.15),
                    child: Icon(
                      liveCategory.icon,
                      size: 40,
                      color: AppTheme.getCategoryColor(liveCategory.id, liveCategory.name),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    CurrencyFormatter.format(totalAmount),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  Text(
                    'Total ${liveCategory.type.name.toUpperCase()}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                  ),
                  if (liveCategory.type == CategoryType.expense) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          budgetStatus.limit > 0 
                              ? 'Budget: ${CurrencyFormatter.format(budgetStatus.limit)}' 
                              : 'No budget set',
                          style: TextStyle(
                            fontSize: 14, 
                            color: budgetStatus.isExceeded ? context.brick : context.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticsService.selection();
                            _showSetCategoryBudgetDialog(context, provider, liveCategory, budgetStatus.limit);
                          },
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: context.gold,
                          ),
                        ),
                      ],
                    ),
                    if (budgetStatus.limit > 0) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (budgetStatus.spent / budgetStatus.limit).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: context.surface2,
                            color: budgetStatus.isExceeded ? context.brick : context.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budgetStatus.isExceeded 
                            ? 'Over by ${CurrencyFormatter.format(budgetStatus.spent - budgetStatus.limit)}' 
                            : '${((budgetStatus.spent / budgetStatus.limit) * 100).toStringAsFixed(0)}% used',
                        style: TextStyle(
                          fontSize: 11, 
                          color: budgetStatus.isExceeded ? context.brick : context.textMuted,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // Sub-categories Management Row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUB-CATEGORIES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.textMuted,
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
                          avatar: Icon(sub.icon, size: 14, color: context.textMuted),
                          label: Text(sub.name, style: TextStyle(fontSize: 12, color: context.textPrimary)),
                          backgroundColor: context.surface2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: context.line),
                          ),
                          onDeleted: isDefault
                              ? null
                              : () => _deleteSubCategory(context, liveCategory, sub),
                          deleteIcon: Icon(Icons.cancel, size: 14, color: context.textMuted),
                        );
                      }).toList(),
                      ActionChip(
                        avatar: Icon(Icons.add, size: 14, color: context.gold),
                        label: Text('Add Custom', style: TextStyle(fontSize: 12, color: context.gold)),
                        backgroundColor: context.surface2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: context.gold, width: 0.5),
                        ),
                        onPressed: () {
                          HapticsService.selection();
                          _showAddCustomSubCategoryDialog(context, liveCategory);
                        },
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
                                color: isGeneral ? context.textMuted : context.gold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isGeneral ? 12 : 13,
                                  fontWeight: isGeneral ? FontWeight.bold : FontWeight.w500,
                                  fontStyle: isGeneral ? FontStyle.normal : FontStyle.italic,
                                  color: isGeneral ? context.textMuted : context.gold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map((expense) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.line),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  expense.subCategoryIcon != null
                                      ? IconUtils.getIcon(expense.subCategoryIcon, categoryName: expense.subCategory)
                                      : liveCategory.icon, 
                                  color: color, 
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                expense.title.isEmpty ? liveCategory.name : expense.title,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary, fontSize: 13),
                              ),
                              subtitle: Text(DateFormatter.format(expense.date), style: GoogleFonts.inter(fontSize: 11, color: context.textMuted)),
                              trailing: Text(
                                CurrencyFormatter.format(expense.amount),
                                style: GoogleFonts.spaceGrotesk(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              onTap: () {
                                HapticsService.selection();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionDetailPage(expenseId: expense.id),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
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
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Sub-category under ${widget.category.name}',
            style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.line),
            ),
            child: TextFormField(
              controller: _nameController,
              style: GoogleFonts.inter(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Sub-category name',
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                prefixIcon: Icon(Icons.label_outline, color: context.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Icon',
            style: TextStyle(color: context.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
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
                  onTap: () {
                    HapticsService.selection();
                    setState(() => _selectedIcon = icon);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? context.gold : context.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? context.gold : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : context.textPrimary,
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
              backgroundColor: context.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (_nameController.text.trim().isEmpty || _selectedIcon == null || _isSaving)
                ? null
                : () async {
                    HapticsService.lightImpact();
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
