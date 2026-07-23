import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

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
      Category(
        id: 'food_dining',
        name: 'Food & Dining',
        type: CategoryType.expense,
        icon: IconUtils.getIcon('restaurant'),
        subCategories: [
          SubCategory(name: 'Groceries', icon: IconUtils.getIcon('groceries')),
          SubCategory(name: 'Restaurant', icon: IconUtils.getIcon('restaurant')),
          SubCategory(name: 'Coffee', icon: IconUtils.getIcon('coffee')),
          SubCategory(name: 'Fast Food', icon: IconUtils.getIcon('fast_food')),
        ],
      ),
      Category(
        id: 'transport',
        name: 'Transport',
        type: CategoryType.expense,
        icon: IconUtils.getIcon('car'),
        subCategories: [
          SubCategory(name: 'Fuel', icon: IconUtils.getIcon('fuel')),
          SubCategory(name: 'Public Transit', icon: IconUtils.getIcon('public_transit')),
          SubCategory(name: 'Taxi/Rideshare', icon: IconUtils.getIcon('taxi')),
          SubCategory(name: 'Parking', icon: IconUtils.getIcon('parking')),
        ],
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        type: CategoryType.expense,
        icon: IconUtils.getIcon('bag'),
        subCategories: [
          SubCategory(name: 'Clothing', icon: IconUtils.getIcon('clothing')),
          SubCategory(name: 'Electronics', icon: IconUtils.getIcon('electronics')),
          SubCategory(name: 'Gifts', icon: IconUtils.getIcon('gifts')),
        ],
      ),
      Category(
        id: 'bills_utilities',
        name: 'Bills & Utilities',
        type: CategoryType.expense,
        icon: IconUtils.getIcon('receipt'),
        subCategories: [
          SubCategory(name: 'Electricity', icon: IconUtils.getIcon('electricity')),
          SubCategory(name: 'Water', icon: IconUtils.getIcon('water')),
          SubCategory(name: 'Internet', icon: IconUtils.getIcon('internet')),
          SubCategory(name: 'Phone', icon: IconUtils.getIcon('phone')),
        ],
      ),
      Category(
        id: 'health',
        name: 'Health',
        type: CategoryType.expense,
        icon: IconUtils.getIcon('medical'),
        subCategories: [
          SubCategory(name: 'Pharmacy', icon: IconUtils.getIcon('pharmacy')),
          SubCategory(name: 'Doctor', icon: IconUtils.getIcon('doctor')),
          SubCategory(name: 'Insurance', icon: IconUtils.getIcon('insurance')),
        ],
      ),
      Category(
        id: 'home',
        name: 'Home',
        type: CategoryType.expense,
        icon: IconUtils.getIcon('home'),
        subCategories: [
          SubCategory(name: 'Rent', icon: IconUtils.getIcon('rent')),
          SubCategory(name: 'Maintenance', icon: IconUtils.getIcon('maintenance')),
          SubCategory(name: 'Furniture', icon: IconUtils.getIcon('furniture')),
        ],
      ),

      // Income Categories
      Category(
        id: 'salary',
        name: 'Salary',
        type: CategoryType.income,
        icon: IconUtils.getIcon('briefcase'),
        subCategories: const [],
      ),
      Category(
        id: 'freelance',
        name: 'Freelance',
        type: CategoryType.income,
        icon: IconUtils.getIcon('laptop'),
        subCategories: const [],
      ),
      Category(
        id: 'investment',
        name: 'Investment',
        type: CategoryType.income,
        icon: IconUtils.getIcon('trending-up'),
        subCategories: const [],
      ),
      Category(
        id: 'gift',
        name: 'Gift',
        type: CategoryType.income,
        icon: IconUtils.getIcon('gift'),
        subCategories: const [],
      ),
      Category(
        id: 'other',
        name: 'Other',
        type: CategoryType.income,
        icon: IconUtils.getIcon('plus-circle'),
        subCategories: const [],
      ),
    ];

    // Ensure system categories are up-to-date
    await repository.seedInitialCategories(initialCategories);
  }
}
