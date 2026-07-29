import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:flutter/material.dart';

void main() {
  group('Category and SubCategory Domain Models', () {
    test('should construct category with subcategories', () {
      final category = Category(
        id: 'test_cat',
        name: 'Test Category',
        type: CategoryType.expense,
        icon: Icons.home,
        subCategories: const [
          SubCategory(name: 'Sub 1', icon: Icons.star),
          SubCategory(name: 'Sub 2', icon: Icons.star_border),
        ],
      );

      expect(category.id, 'test_cat');
      expect(category.subCategories.length, 2);
      expect(category.subCategories.first.name, 'Sub 1');
    });

    test('should equate subcategories and categories correctly', () {
      const sub1 = SubCategory(name: 'Sub 1', icon: Icons.star);
      const sub2 = SubCategory(name: 'Sub 1', icon: Icons.star);
      const sub3 = SubCategory(name: 'Sub 2', icon: Icons.star);

      expect(sub1, sub2);
      expect(sub1 == sub3, false);
    });
  });
}
