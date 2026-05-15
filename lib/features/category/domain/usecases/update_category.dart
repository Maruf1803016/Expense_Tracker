import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';

class UpdateCategoryUseCase implements UseCase<void, Category> {
  final CategoryRepository repository;

  UpdateCategoryUseCase({required this.repository});

  @override
  Future<void> call(Category params) async {
    return await repository.updateCategory(params);
  }
}
