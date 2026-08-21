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
          bottom: TabBar(
            tabs: [
              Tab(child: Text('Expense', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
              Tab(child: Text('Income', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
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
            _buildGridSection(context, topLevelCategories.where((c) => c.type == CategoryType.expense).toList(), expenseProvider),
            _buildGridSection(context, topLevelCategories.where((c) => c.type == CategoryType.income && c.id != 'other').toList(), expenseProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection(BuildContext context, List<Category> categories, ExpenseProvider expenseProvider) {
    final type = categories.isNotEmpty ? categories.first.type : CategoryType.expense;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _buildCategoryGrid(context, categories, expenseProvider, type),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> categories, ExpenseProvider expenseProvider, CategoryType type) {
    final categoryProvider = context.read<CategoryProvider>();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.paperCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.line, style: BorderStyle.solid),
            ),
            child: InkWell(
              onTap: () => _showAddCategorySheet(context, categoryProvider, type),
              borderRadius: BorderRadius.circular(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppTheme.gold,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add Category',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final category = categories[index];
        final isIncome = category.type == CategoryType.income;
        final catColor = AppTheme.getCategoryColor(category.id, category.name);

        // Calculate this month's spending/income for the category
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

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.paperCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.line),
          ),
          child: InkWell(
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
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isIncome
                        ? '${CurrencyFormatter.format(totalSpent)} earned'
                        : (budgetStatus.limit > 0 
                            ? '${CurrencyFormatter.format(totalSpent)} / ${CurrencyFormatter.format(budgetStatus.limit)}' 
                            : '${CurrencyFormatter.format(totalSpent)} spent'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: isIncome ? AppTheme.emerald : (budgetStatus.isExceeded ? AppTheme.brick : AppTheme.muted),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isIncome && budgetStatus.limit > 0) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (budgetStatus.spent / budgetStatus.limit).clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: AppTheme.paper2,
                        color: budgetStatus.isExceeded ? AppTheme.brick : AppTheme.emerald,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
