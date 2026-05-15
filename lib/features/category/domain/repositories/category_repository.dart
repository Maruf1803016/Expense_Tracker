import '../entities/category.dart';

/// Abstract repository interface for category operations.
/// Defined in domain layer; implemented in data layer.
abstract class CategoryRepository {
  /// Returns a stream of categories.
  Stream<List<Category>> getCategoriesStream();

  /// Adds a new category.
  Future<void> addCategory(Category category);

  /// Deletes a category by its ID.
  Future<void> deleteCategory(String id);

  /// Updates an existing category.
  Future<void> updateCategory(Category category);

  /// Checks if the collection is empty.
  Future<bool> isCollectionEmpty();

  /// Seeds initial categories.
  Future<void> seedInitialCategories(List<Category> categories);
}
