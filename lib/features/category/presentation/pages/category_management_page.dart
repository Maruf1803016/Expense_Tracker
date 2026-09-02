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
import 'package:expense_tracker/core/utils/haptics_service.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final categories = categoryProvider.categories;

    if (categoryProvider.isLoading && categories.isEmpty) {
      return Scaffold(
        backgroundColor: context.bg,
        body: Center(child: CircularProgressIndicator(color: context.gold)),
      );
    }

    final topLevelCategories = categories;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          title: Text(
            'Categories',
            style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          bottom: TabBar(
            tabs: [
              Tab(child: Text('Expense Categories', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
              Tab(child: Text('Income Categories', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
            ],
            indicatorColor: context.gold,
            indicatorWeight: 2.5,
            labelColor: context.gold,
            unselectedLabelColor: context.textMuted,
            dividerColor: context.line,
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
                  color: context.textMuted,
                ),
              ),
              InkWell(
                onTap: () {
                  HapticsService.selection();
                  _showAddCategorySheet(context, categoryProvider, type);
                },
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: context.gold),
                    const SizedBox(width: 2),
                    Text(
                      'New Category',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.gold,
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
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: context.line, width: 0.8),
      ),
      child: Column(
        children: [
          // Main Category Row
          InkWell(
            onTap: () {
              HapticsService.selection();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailPage(category: category),
                ),
              );
            },
            borderRadius: category.subCategories.isNotEmpty
                ? const BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius))
                : BorderRadius.circular(AppTheme.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(category.icon, color: catColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Title + Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isPermanent ? context.surface2 : context.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isPermanent ? 'Permanent' : 'Custom',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isPermanent ? context.textMuted : context.gold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isIncome
                                    ? '${CurrencyFormatter.format(totalSpent)} earned'
                                    : (budgetStatus.limit > 0
                                        ? '${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(budgetStatus.limit)}'
                                        : '${CurrencyFormatter.format(totalSpent)} spent'),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  color: isIncome ? context.emerald : (budgetStatus.isExceeded ? context.brick : context.textMuted),
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
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: context.textMuted),
                    color: context.cardBg,
                    onSelected: (val) {
                      HapticsService.selection();
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
                      PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename', style: TextStyle(color: ctx.textPrimary)),
                      ),
                      if (!isIncome)
                        PopupMenuItem(
                          value: 'subcat',
                          child: Text('Add Subcategory', style: TextStyle(color: ctx.textPrimary)),
                        ),
                      PopupMenuItem(
                        value: 'merge',
                        child: Text('Merge into...', style: TextStyle(color: ctx.textPrimary)),
                      ),
                      if (!isPermanent)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: ctx.brick)),
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
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.line, width: 0.8)),
                color: context.surface2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: category.subCategories.map((sub) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.line),
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
                            color: context.textPrimary,
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
        backgroundColor: context.cardBg,
        title: Text(
          'Add Subcategory to ${category.name}',
          style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Restaurants, Coffee, Takeout',
            hintStyle: GoogleFonts.inter(color: context.textMuted),
          ),
          style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.gold, foregroundColor: Colors.white),
            onPressed: () async {
              HapticsService.lightImpact();
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
        backgroundColor: context.cardBg,
        title: Text('Rename Category', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: context.textPrimary),
          decoration: InputDecoration(
            labelText: 'Category Name',
            labelStyle: TextStyle(color: context.textMuted),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.gold, foregroundColor: Colors.white),
            onPressed: () async {
              HapticsService.lightImpact();
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
          backgroundColor: context.cardBg,
          title: Text('Merge "${sourceCategory.name}"', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move all past transactions from ${sourceCategory.name} to target category:',
                style: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: targetId,
                dropdownColor: context.cardBg,
                style: GoogleFonts.inter(color: context.textPrimary),
                items: sameTypeCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: TextStyle(color: context.textPrimary)))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => targetId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.gold, foregroundColor: Colors.white),
              onPressed: () async {
                HapticsService.lightImpact();
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
          backgroundColor: context.cardBg,
          title: Text('Category In Use', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary)),
          content: Text(
            '"${category.name}" cannot be deleted because transactions are recorded under it. Please use "Merge into..." to reassign its entries first.',
            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(color: context.gold))),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Delete Category?', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: Text('Delete unused custom category "${category.name}"?', style: TextStyle(color: context.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.brick, foregroundColor: Colors.white),
            onPressed: () async {
              HapticsService.lightImpact();
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
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.line),
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
                    style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                'CATEGORY NAME',
                style: GoogleFonts.inter(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Travel, Rent, Investments',
                  hintStyle: GoogleFonts.inter(color: context.textMuted),
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 18),

              // Select Icon
              Text(
                'SELECT ICON',
                style: GoogleFonts.inter(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
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
                      onTap: () {
                        HapticsService.selection();
                        setState(() => _selectedIconName = name);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? context.gold : context.surface2,
                          border: Border.all(
                            color: isSelected ? context.gold : context.line,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : context.textPrimary, size: 18),
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
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                ),
                onPressed: (_nameController.text.trim().isEmpty || _selectedIconName == null || _isSaving)
                    ? null
                    : () async {
                        HapticsService.lightImpact();
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
                              SnackBar(content: Text('Error: $e'), backgroundColor: context.brick),
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
