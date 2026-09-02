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
          final consolidated = _consolidateCategories(list);
          _categories = consolidated;
          _isLoading = false;
          debugPrint('[CategoryProvider] loaded and consolidated ${_categories.length} categories');
          notifyListeners();

          // If there are obsolete categories in firestore, clean them in background
          _cleanupObsoleteCategories(list);
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

  List<Category> _consolidateCategories(List<Category> rawList) {
    if (rawList.isEmpty) return List<Category>.from(Category.defaultCategories);

    final Map<String, Category> map = {};

    // 1. First populate with standard defaults
    for (final def in Category.defaultCategories) {
      map[def.id] = def;
    }

    // 2. Merge incoming categories
    for (final cat in rawList) {
      final normName = cat.name.trim().toLowerCase();
      
      // Check if this matches a default category by ID or Name
      String? targetCanonicalId;
      if (map.containsKey(cat.id)) {
        targetCanonicalId = cat.id;
      } else if (normName == 'food & dining' || normName == 'food and dining' || normName == 'food') {
        targetCanonicalId = 'food_dining';
      } else if (normName == 'home') {
        targetCanonicalId = 'home';
      } else if (normName == 'bills & utilities' || normName == 'bills' || normName == 'utilities' || normName == 'bills and utilities') {
        targetCanonicalId = 'bills_utilities';
      } else if (normName == 'transport & travel' || normName == 'transport' || normName == 'travel') {
        targetCanonicalId = 'transport_travel';
      } else if (normName == 'shopping') {
        targetCanonicalId = 'shopping';
      } else if (normName == 'health & personal care' || normName == 'health') {
        targetCanonicalId = 'health_personal_care';
      } else if (normName == 'entertainment') {
        targetCanonicalId = 'entertainment';
      } else if (normName == 'finance & other' || normName == 'finance' || normName == 'other expense') {
        targetCanonicalId = 'finance_other';
      } else if (normName == 'salary') {
        targetCanonicalId = 'salary';
      } else if (normName == 'freelance' || normName == 'freelance income') {
        targetCanonicalId = 'freelance';
      } else if (normName == 'investment' || normName == 'interest & dividends') {
        targetCanonicalId = 'investment';
      } else if (normName == 'gift' || normName == 'gifts & support') {
        targetCanonicalId = 'gift';
      } else if (normName == 'other income') {
        targetCanonicalId = 'other_income';
      }

      if (targetCanonicalId != null && map.containsKey(targetCanonicalId)) {
        final existing = map[targetCanonicalId]!;
        // Merge subcategories
        final existingSubNames = existing.subCategories.map((s) => s.name.toLowerCase()).toSet();
        final List<SubCategory> mergedSubs = List.from(existing.subCategories);
        for (final sub in cat.subCategories) {
          if (!existingSubNames.contains(sub.name.toLowerCase())) {
            mergedSubs.add(sub);
            existingSubNames.add(sub.name.toLowerCase());
          }
        }
        map[targetCanonicalId] = Category(
          id: existing.id,
          name: existing.name,
          type: existing.type,
          icon: existing.icon,
          subCategories: mergedSubs,
        );
      } else {
        // Check if this is one of the obsolete top-level categories that should NOT exist as top-level
        final obsoleteNames = [
          'fees & taxes', 'insurance & protection', 'finance & other (dup)', 'other expense',
          'gifts & giving', 'delivery & takeaway', 'groceries', 'home cooking', 'restaurants & cafes',
          'home & bills', 'phone & internet', 'repairs & maintenance', 'rent & mortgage',
          'rent bills & internet', 'household supplies', 'home & utilities',
          'personal', 'personal care', 'fitness & wellbeing', 'health & pharmacy',
          'personal & lifestyle', 'shopping & personal care', 'entertainment & subscriptions',
          'fuel transit & rides', 'trips & stays', 'flights & tickets', 'transport & stays',
          'business sales', 'rental income'
        ];

        if (!obsoleteNames.contains(normName)) {
          // Custom category created by user
          map[cat.id] = cat;
        }
      }
    }

    return map.values.toList();
  }

  Future<void> _cleanupObsoleteCategories(List<Category> rawList) async {
    final obsoleteNames = [
      'fees & taxes', 'insurance & protection', 'finance & other (dup)', 'other expense',
      'gifts & giving', 'delivery & takeaway', 'groceries', 'home cooking', 'restaurants & cafes',
      'home & bills', 'phone & internet', 'repairs & maintenance', 'rent & mortgage',
      'rent bills & internet', 'household supplies', 'home & utilities',
      'personal', 'personal care', 'fitness & wellbeing', 'health & pharmacy',
      'personal & lifestyle', 'shopping & personal care', 'entertainment & subscriptions',
      'fuel transit & rides', 'trips & stays', 'flights & tickets', 'transport & stays',
      'business sales', 'rental income', 'freelance income', 'gifts & support'
    ];

    for (final cat in rawList) {
      final normName = cat.name.trim().toLowerCase();
      // If it is a duplicate custom category of a default, delete the extra doc
      final isCanonical = Category.defaultCategories.any((d) => d.id == cat.id);
      if (!isCanonical) {
        if (obsoleteNames.contains(normName) ||
            normName == 'food & dining' ||
            normName == 'salary' ||
            normName == 'bills & utilities') {
          try {
            await deleteCategory(cat.id);
          } catch (_) {}
        }
      }
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
