import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_indicator.dart';
import 'package:expense_tracker/shared/presentation/widgets/empty_state.dart';
import 'package:expense_tracker/shared/presentation/widgets/loading_skeleton.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_provider.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    CategoryType selectedType = CategoryType.expense;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Groceries, Salary',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CategoryType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: CategoryType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final category = Category(
                  id: const Uuid().v4(),
                  name: name,
                  type: selectedType,
                );

                try {
                  await Provider.of<ExpenseProvider>(context, listen: false)
                      .addCategory(category);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  // Error handled by Provider
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ... (confirmDelete remains the same, I'll provide the full file if needed but focusing on changes)
  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<ExpenseProvider>(context, listen: false)
                    .deleteCategory(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final provider = Provider.of<ExpenseProvider>(context, listen: false);
                  final message = provider.errorMessage ?? 'Failed to delete category';
                  
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cannot Delete'),
                      content: Text(message),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.categories;

    return Scaffold(
      body: provider.isLoading && categories.isEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LoadingSkeleton(height: 70),
              ),
            )
          : _buildCategoryList(context, categories),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddCategoryDialog(context),
        heroTag: 'addCategory',
        child: const Icon(Icons.category),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      return const EmptyState(
        title: 'No Categories',
        message: 'Add your first category to start tracking expenses.',
        icon: Icons.category_outlined,
      );
    }

    final incomeCategories = categories.where((c) => c.type == CategoryType.income).toList();
    final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (expenseCategories.isNotEmpty) ...[
          _buildHeader('Expense Categories'),
          ...expenseCategories.map((c) => _buildCategoryTile(context, c)),
          const SizedBox(height: 24),
        ],
        if (incomeCategories.isNotEmpty) ...[
          _buildHeader('Income Categories'),
          ...incomeCategories.map((c) => _buildCategoryTile(context, c)),
          const SizedBox(height: 80), // Space for FAB
        ],
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: category.type == CategoryType.income
              ? AppTheme.incomeColor.withOpacity(0.08)
              : AppTheme.expenseColor.withOpacity(0.08),
          child: Icon(
            category.type == CategoryType.income ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: category.type == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[400]),
          onPressed: () => _confirmDelete(context, category),
        ),
      ),
    );
  }
}
