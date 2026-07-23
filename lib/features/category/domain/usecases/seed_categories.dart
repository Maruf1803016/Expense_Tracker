import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';

class SeedCategoriesUseCase implements UseCase<void, NoParams> {
  final CategoryRepository repository;

  SeedCategoriesUseCase({required this.repository});

  @override
  Future<void> call(NoParams params) async {
    // Check if collection is empty before seeding
    final isEmpty = await repository.isCollectionEmpty();
    if (!isEmpty) {
      return;
    }

    final initialCategories = [
      // Expense Categories
      const Category(id: 'food', name: 'Food & Drinks', type: CategoryType.expense, icon: 'restaurant'),
      const Category(id: 'health', name: 'Health', type: CategoryType.expense, icon: 'favorite'),
      const Category(id: 'transport', name: 'Transportation', type: CategoryType.expense, icon: 'directions_car'),
      const Category(id: 'shopping', name: 'Shopping', type: CategoryType.expense, icon: 'shopping_bag'),
      const Category(id: 'entertainment', name: 'Entertainment', type: CategoryType.expense, icon: 'movie'),
      const Category(id: 'bills', name: 'Bills', type: CategoryType.expense, icon: 'receipt'),
      const Category(id: 'education', name: 'Education', type: CategoryType.expense, icon: 'school'),
      const Category(id: 'other_exp', name: 'Other', type: CategoryType.expense, icon: 'category'),
      
      // Income Categories
      const Category(id: 'salary', name: 'Salary', type: CategoryType.income, icon: 'account_balance_wallet'),
      const Category(id: 'investments', name: 'Investments', type: CategoryType.income, icon: 'trending_up'),
      const Category(id: 'other_inc', name: 'Other Income', type: CategoryType.income, icon: 'category'),
      
      // Sub-categories
      const Category(id: 'bike', name: 'Bike Expense', type: CategoryType.expense, icon: 'directions_car', parentId: 'transport'),
      const Category(id: 'oil_bill', name: 'Oil Bill', type: CategoryType.expense, icon: 'oil_barrel', parentId: 'bike'),
    ];
    
    // Ensure system categories are up-to-date
    await repository.seedInitialCategories(initialCategories);
  }
}
