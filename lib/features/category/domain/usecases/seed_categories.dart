import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

class SeedCategoriesUseCase implements UseCase<void, NoParams> {
  final CategoryRepository repository;

  SeedCategoriesUseCase({required this.repository});

  @override
  Future<void> call(NoParams params) async {
    await repository.seedInitialCategories(Category.defaultCategories);
  }
}
