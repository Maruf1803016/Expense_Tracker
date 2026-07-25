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
        (list) async {
          if (list.isEmpty) {
            _categories = List<Category>.from(Category.defaultCategories);
            // Write them to Firestore so they are persisted permanently
            await seedCategories(const NoParams());
          } else {
            _categories = List<Category>.from(list);
          }
          _isLoading = false;
          debugPrint('[CategoryProvider] loaded ${_categories.length} categories');
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[CategoryProvider] Error loading categories: $e');
          if (_categories.isEmpty) {
            _categories = List<Category>.from(Category.defaultCategories);
          }
          _isLoading = false;
          notifyListeners();
        },
      );
      
      // Auto-seed if empty or missing the new schema after a short delay
      Future.delayed(const Duration(seconds: 1), () async {
        final hasNewSchema = _categories.any((c) => c.id == 'food_dining');
        if ((_categories.isEmpty || !hasNewSchema) && !_isLoading) {
          await seedCategories(const NoParams());
        }
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Category category) async {
    final previousCategories = _categories;
    _categories = List<Category>.from(_categories)..add(category);
    notifyListeners();

    try {
      await addCategory(category);
    } catch (e) {
      _categories = previousCategories;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final previousCategories = _categories;
    _categories = List<Category>.from(_categories)..removeWhere((c) => c.id == id);
    notifyListeners();

    try {
      await deleteCategory(id);
    } catch (e) {
      _categories = previousCategories;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Category category) async {
    final previousCategories = _categories;
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _categories = List<Category>.from(_categories)..[idx] = category;
      notifyListeners();
    }

    try {
      await updateCategory(category);
    } catch (e) {
      _categories = previousCategories;
      notifyListeners();
      rethrow;
    }
  }

  void clear() {
    _categories = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
