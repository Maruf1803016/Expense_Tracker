import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_detail_page.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/budget/domain/entities/category_budget_status.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final categories = categoryProvider.categories;

    if (categoryProvider.isLoading && categories.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.paper,
        body: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      );
    }

    final topLevelCategories = categories;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.paper,
        appBar: AppBar(
          backgroundColor: AppTheme.paper,
          title: Text(
            'Categories',
            style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.gold),
              tooltip: 'Add Category',
              onPressed: () => _showAddCategorySheet(context, categoryProvider, CategoryType.expense),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(child: Text('Expense Categories', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
              Tab(child: Text('Income Categories', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
            ],
            indicatorColor: AppTheme.ink,
            indicatorWeight: 2.5,
            labelColor: AppTheme.ink,
            unselectedLabelColor: AppTheme.muted,
            dividerColor: AppTheme.line,
          ),
        ),
        body: TabBarView(
          children: [
            _buildLedgerSection(context, topLevelCategories.where((c) => c.type == CategoryType.expense).toList(), expenseProvider, CategoryType.expense),
            _buildLedgerSection(context, topLevelCategories.where((c) => c.type == CategoryType.income && c.id != 'other').toList(), expenseProvider, CategoryType.income),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerSection(BuildContext context, List<Category> categories, ExpenseProvider expenseProvider, CategoryType type) {
    final categoryProvider = context.read<CategoryProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Category Header / Kicker
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2.0, top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${categories.length} ${type == CategoryType.expense ? 'EXPENSE' : 'INCOME'} CATEGORIES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.muted,
                ),
              ),
              InkWell(
                onTap: () => _showAddCategorySheet(context, categoryProvider, type),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: AppTheme.gold),
                    const SizedBox(width: 2),
                    Text(
                      'New Category',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...categories.map((cat) => _buildCategoryLedgerCard(context, cat, expenseProvider, categoryProvider)),
      ],
    );
  }

  Widget _buildCategoryLedgerCard(BuildContext context, Category category, ExpenseProvider expenseProvider, CategoryProvider categoryProvider) {
    final isIncome = category.type == CategoryType.income;
    final catColor = AppTheme.getCategoryColor(category.id, category.name);

    // Calculate this month's spending
    final now = DateTime.now();
    final thisMonthExpenses = expenseProvider.expenses.where((e) {
      return e.categoryId == category.id &&
          !e.isDeleted &&
          e.date.month == now.month &&
          e.date.year == now.year;
    });
    final totalSpent = thisMonthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    final budgetStatus = expenseProvider.rolledUpBudgetStatuses.firstWhere(
      (b) => b.categoryId == category.id,
      orElse: () => CategoryBudgetStatus.fromAmounts(
        categoryId: category.id,
        categoryName: category.name,
        limit: 0.0,
        spent: totalSpent,
        month: now.month,
        year: now.year,
      ),
    );

    final isPermanent = Category.defaultCategories.any((c) => c.id == category.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.paperCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Parent Category Row
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailPage(category: category),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        IconUtils.getIcon(IconUtils.getIconName(category.icon), categoryName: category.name),
                        color: catColor,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isPermanent ? AppTheme.paper2 : AppTheme.goldSoft.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isPermanent ? 'Permanent' : 'Custom',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isPermanent ? AppTheme.muted : AppTheme.gold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isIncome
                                    ? '${CurrencyFormatter.format(totalSpent)} earned'
                                    : (budgetStatus.limit > 0
                                        ? '${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(budgetStatus.limit)}'
                                        : '${CurrencyFormatter.format(totalSpent)} spent'),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  color: isIncome ? AppTheme.emerald : (budgetStatus.isExceeded ? AppTheme.brick : AppTheme.muted),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Category Actions Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.muted),
                    color: AppTheme.paperCard,
                    onSelected: (val) {
                      if (val == 'rename') {
                        _showRenameCategoryDialog(context, categoryProvider, category);
                      } else if (val == 'subcat') {
                        _showAddSubCategoryDialog(context, categoryProvider, category);
                      } else if (val == 'merge') {
                        _showMergeCategoryDialog(context, categoryProvider, expenseProvider, category);
                      } else if (val == 'delete') {
                        _confirmDeleteCategory(context, categoryProvider, expenseProvider, category);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: 'subcat',
                        child: Text('Add Subcategory'),
                      ),
                      const PopupMenuItem(
                        value: 'merge',
                        child: Text('Merge into...'),
                      ),
                      if (!isPermanent)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: AppTheme.brick)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Subcategories Child Ledger Rows
          if (category.subCategories.isNotEmpty) ...[
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.line, width: 0.8)),
                color: AppTheme.paper,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: category.subCategories.map((sub) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.paperCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          sub.name,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSubCategoryDialog(BuildContext context, CategoryProvider categoryProvider, Category category) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.paperCard,
        title: Text(
          'Add Subcategory to ${category.name}',
          style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Restaurants, Coffee, Takeout',
          ),
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.white),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newSub = SubCategory(
                  name: name,
                  icon: Icons.circle,
                );
                final updatedCategory = Category(
                  id: category.id,
                  name: category.name,
                  type: category.type,
                  icon: category.icon,
                  subCategories: [...category.subCategories, newSub],
                );
                await categoryProvider.update(updatedCategory);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(BuildContext context, CategoryProvider categoryProvider, Category category) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.paperCard,
        title: Text('Rename Category', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: AppTheme.textDark),
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.white),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != category.name) {
                final updated = Category(
                  id: category.id,
                  name: newName,
                  type: category.type,
                  icon: category.icon,
                  subCategories: category.subCategories,
                );
                await categoryProvider.update(updated);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMergeCategoryDialog(BuildContext context, CategoryProvider categoryProvider, ExpenseProvider expenseProvider, Category sourceCategory) {
    final sameTypeCategories = categoryProvider.categories
        .where((c) => c.type == sourceCategory.type && c.id != sourceCategory.id)
        .toList();

    if (sameTypeCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other categories available to merge into.')),
      );
      return;
    }

    String? targetId = sameTypeCategories.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.paperCard,
          title: Text('Merge "${sourceCategory.name}"', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move all past transactions from ${sourceCategory.name} to target category:',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: targetId,
                dropdownColor: AppTheme.paperCard,
                items: sameTypeCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => targetId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.white),
              onPressed: () async {
                if (targetId != null) {
                  // Reassign expenses
                  final affected = expenseProvider.expenses.where((e) => e.categoryId == sourceCategory.id).toList();
                  for (final exp in affected) {
                    await expenseProvider.updateExpense(exp.copyWith(categoryId: targetId));
                  }
                  // Remove merged source if not permanent
                  final isPermanent = Category.defaultCategories.any((c) => c.id == sourceCategory.id);
                  if (!isPermanent) {
                    await categoryProvider.remove(sourceCategory.id);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Merge & Reassign'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryProvider categoryProvider, ExpenseProvider expenseProvider, Category category) {
    final hasExpenses = expenseProvider.expenses.any((e) => e.categoryId == category.id);
    if (hasExpenses) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.paperCard,
          title: Text('Category In Use', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
          content: Text(
            '"${category.name}" cannot be deleted because transactions are recorded under it. Please use "Merge into..." to reassign its entries first.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.paperCard,
        title: Text('Delete Category?', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold)),
        content: Text('Delete unused custom category "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brick, foregroundColor: Colors.white),
            onPressed: () async {
              await categoryProvider.remove(category.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, CategoryProvider categoryProvider, CategoryType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCategorySheet(categoryProvider: categoryProvider, type: type),
    );
  }
}

class CreateCategorySheet extends StatefulWidget {
  final CategoryProvider categoryProvider;
  final CategoryType type;
  final Function(String categoryId)? onSave;

  const CreateCategorySheet({
    super.key,
    required this.categoryProvider,
    required this.type,
    this.onSave,
  });

  @override
  State<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedIconName;
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
        color: AppTheme.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Custom ${widget.type == CategoryType.expense ? 'Expense' : 'Income'} Category',
                    style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.muted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                'CATEGORY NAME',
                style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(color: AppTheme.textDark, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g. Travel, Rent, Investments',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 18),

              // Select Icon
              Text(
                'SELECT ICON',
                style: GoogleFonts.inter(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: IconUtils.availableIconNames.length,
                  itemBuilder: (context, index) {
                    final name = IconUtils.availableIconNames[index];
                    final icon = IconUtils.getIcon(name);
                    final isSelected = _selectedIconName == name;
                    return InkWell(
                      onTap: () => setState(() => _selectedIconName = name),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.ink : AppTheme.paperCard,
                          border: Border.all(
                            color: isSelected ? AppTheme.ink : AppTheme.line,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: isSelected ? AppTheme.goldSoft : AppTheme.textDark, size: 18),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                ),
                onPressed: (_nameController.text.trim().isEmpty || _selectedIconName == null || _isSaving)
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSaving = true);

                        try {
                          final newCategory = Category(
                            id: const Uuid().v4(),
                            name: _nameController.text.trim(),
                            type: widget.type,
                            icon: IconUtils.getIcon(_selectedIconName),
                            subCategories: const [],
                          );
                          await widget.categoryProvider.add(newCategory);
                          if (widget.onSave != null) {
                            widget.onSave!(newCategory.id);
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          setState(() => _isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.brick),
                            );
                          }
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save Category', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
