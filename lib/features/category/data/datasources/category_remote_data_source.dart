import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/category/data/models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Stream<List<CategoryModel>> getCategories();
  Future<void> addCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Future<bool> isCollectionEmpty();
  Future<void> seedCategories(List<CategoryModel> categories);
  Future<void> updateCategory(CategoryModel category);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  CategoryRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  CollectionReference get _categoryCollection {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId).collection('categories');
  }

  @override
  Stream<List<CategoryModel>> getCategories() {
    return _categoryCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _categoryCollection.add(category.toMap());
    } catch (e) {
      throw ServerException('Failed to add category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _categoryCollection.doc(id).delete();
    } catch (e) {
      throw ServerException('Failed to delete category: $e');
    }
  }

  @override
  Future<bool> isCollectionEmpty() async {
    try {
      final snapshot = await _categoryCollection.limit(1).get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      throw ServerException('Failed to check collection: $e');
    }
  }

  @override
  Future<void> seedCategories(List<CategoryModel> categories) async {
    try {
      final batch = firestore.batch();
      for (var category in categories) {
        if (category.id.isEmpty) continue;
        final docRef = _categoryCollection.doc(category.id);
        batch.set(docRef, category.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to seed categories: $e');
    }
  }
  @override
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _categoryCollection.doc(category.id).update(category.toMap());
    } catch (e) {
      throw ServerException('Failed to update category: $e');
    }
  }
}
