import 'package:flutter/material.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/category/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/category/domain/usecases/seed_categories.dart';
import 'package:expense_tracker/features/category/domain/usecases/add_category.dart';
import 'package:expense_tracker/features/category/domain/usecases/delete_category.dart';
import 'package:expense_tracker/features/category/domain/usecases/update_category.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';

class CategoryProvider with ChangeNotifier {
  final GetCategoriesStreamUseCase getCategoriesStream;
  final SeedCategoriesUseCase seedCategories;
  final AddCategoryUseCase addCategory;
  final DeleteCategoryUseCase deleteCategory;
  final UpdateCategoryUseCase updateCategory;

  CategoryProvider({
    required this.getCategoriesStream,
    required this.seedCategories,
    required this.addCategory,
    required this.deleteCategory,
    required this.updateCategory,
  });

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    debugPrint('[CategoryProvider] init called');
    _isLoading = true;
    notifyListeners();

    try {
      // Subscribe to categories stream
      getCategoriesStream().listen(
        (list) {
          _categories = list;
          _isLoading = false;
          debugPrint('[CategoryProvider] loaded ${_categories.length} categories');
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[CategoryProvider] Error loading categories: $e');
          _isLoading = false;
          notifyListeners();
        },
      );
      
      // Auto-seed if empty after a short delay
      Future.delayed(const Duration(seconds: 1), () async {
        if (_categories.isEmpty && !_isLoading) {
          await seedCategories(const NoParams());
        }
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Category category) async {
    await addCategory(category);
  }

  Future<void> remove(String id) async {
    await deleteCategory(id);
  }

  Future<void> update(Category category) async {
    await updateCategory(category);
  }
}
