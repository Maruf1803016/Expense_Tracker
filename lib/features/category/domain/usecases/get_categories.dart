import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesStreamUseCase {
  final CategoryRepository repository;

  GetCategoriesStreamUseCase({required this.repository});

  Stream<List<Category>> call() {
    return repository.getCategoriesStream();
  }
}
