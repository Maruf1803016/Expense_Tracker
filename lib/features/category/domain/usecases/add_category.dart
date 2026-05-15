import '../entities/category.dart';
import '../repositories/category_repository.dart';

class AddCategoryUseCase {
  final CategoryRepository repository;

  AddCategoryUseCase({required this.repository});

  Future<void> call(Category category) async {
    return await repository.addCategory(category);
  }
}
