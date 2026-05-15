import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/core/error/failures.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/category/data/datasources/category_remote_data_source.dart';
import 'package:expense_tracker/features/category/data/models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Category>> getCategoriesStream() {
    return remoteDataSource.getCategories();
  }

  @override
  Future<void> addCategory(Category category) async {
    try {
      final model = CategoryModel.fromEntity(category);
      await remoteDataSource.addCategory(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while adding category.');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await remoteDataSource.deleteCategory(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while deleting category.');
    }
  }

  @override
  Future<bool> isCollectionEmpty() async {
    try {
      return await remoteDataSource.isCollectionEmpty();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while checking collection status.');
    }
  }

  @override
  Future<void> seedInitialCategories(List<Category> categories) async {
    try {
      final models = categories.map((e) => CategoryModel.fromEntity(e)).toList();
      await remoteDataSource.seedCategories(models);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw const ServerFailure('An unexpected error occurred while seeding categories.');
    }
  }
}
