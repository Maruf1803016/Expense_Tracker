import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';

class SeedCategoriesUseCase implements UseCase<void, NoParams> {
  final CategoryRepository repository;

  SeedCategoriesUseCase({required this.repository});

  @override
  Future<void> call(NoParams params) async {
    final isEmpty = await repository.isCollectionEmpty();
    
    if (isEmpty) {
      final initialCategories = [
        const Category(id: '', name: 'Food & Drinks', type: CategoryType.expense),
        const Category(id: '', name: 'Transportation', type: CategoryType.expense),
        const Category(id: '', name: 'Shopping', type: CategoryType.expense),
        const Category(id: '', name: 'Entertainment', type: CategoryType.expense),
        const Category(id: '', name: 'Health', type: CategoryType.expense),
        const Category(id: '', name: 'Salary', type: CategoryType.income),
        const Category(id: '', name: 'Investments', type: CategoryType.income),
      ];
      
      await repository.seedInitialCategories(initialCategories);
    }
  }
}
