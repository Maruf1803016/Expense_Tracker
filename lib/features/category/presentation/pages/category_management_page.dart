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

    final topLevelCategories = categories.where((category) => category.parentId == null).toList();

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildCategoryGrid(context, categories, expenseProvider),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> categories, ExpenseProvider expenseProvider) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No categories in this section', style: TextStyle(color: Colors.white24))),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = category.type == CategoryType.income ? AppTheme.incomeColor : AppTheme.expenseColor;

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
                  IconUtils.getIcon(category.icon ?? 'category'),
                  color: color,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
