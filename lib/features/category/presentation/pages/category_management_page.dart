import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/features/category/presentation/providers/category_provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/presentation/pages/category_detail_page.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final categories = categoryProvider.categories;

    if (categoryProvider.isLoading && categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.emeraldGreen));
    }

    final topLevelCategories = categories;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Income'),
            ],
            indicatorColor: AppTheme.emeraldGreen,
            labelColor: AppTheme.emeraldGreen,
            unselectedLabelColor: Colors.white54,
          ),
        ),
        body: TabBarView(
          children: [
            _buildGridSection(context, topLevelCategories.where((c) => c.type == CategoryType.expense).toList(), expenseProvider),
            _buildGridSection(context, topLevelCategories.where((c) => c.type == CategoryType.income).toList(), expenseProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection(BuildContext context, List<Category> categories, ExpenseProvider expenseProvider) {
    final type = categories.isNotEmpty ? categories.first.type : CategoryType.expense;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.35,
      ),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return Card(
            color: AppTheme.secondaryBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.05), style: BorderStyle.dashed),
            ),
            child: InkWell(
              onTap: () => _showAddCategorySheet(context, categoryProvider, type),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final category = categories[index];
        final color = category.type == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor;

        // Calculate this month's spending/income for the category
        final now = DateTime.now();
        final thisMonthExpenses = expenseProvider.expenses.where((e) {
          return e.categoryId == category.id &&
              !e.isDeleted &&
              e.date.month == now.month &&
              e.date.year == now.year;
        });
        final totalSpent = thisMonthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

        return Card(
          color: AppTheme.secondaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.1)),
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
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(totalSpent),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
      builder: (context) => _CreateCategorySheet(categoryProvider: categoryProvider, type: type),
    );
  }
}

class _CreateCategorySheet extends StatefulWidget {
  final CategoryProvider categoryProvider;
  final CategoryType type;

  const _CreateCategorySheet({
    required this.categoryProvider,
    required this.type,
  });

  @override
  State<_CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<_CreateCategorySheet> {
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
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Custom ${widget.type == CategoryType.expense ? 'Expense' : 'Income'} Category',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              // Name
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text('Category Name', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Travel, Rent, Investments',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 20),

              // Select Icon
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Select Icon', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              SizedBox(
                height: 180,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: IconUtils.availableIconNames.length,
                  itemBuilder: (context, index) {
                    final name = IconUtils.availableIconNames[index];
                    final icon = IconUtils.getIcon(name);
                    final isSelected = _selectedIconName == name;
                    return InkWell(
                      onTap: () => setState(() => _selectedIconName = name),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.emeraldGreen.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                          border: Border.all(
                            color: isSelected ? AppTheme.emeraldGreen : Colors.white10,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: isSelected ? AppTheme.emeraldGreen : Colors.white60, size: 20),
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
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          setState(() => _isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
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
                    : const Text('Save Category', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
