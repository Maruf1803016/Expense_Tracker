import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';
import 'package:flutter/material.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
    required super.icon,
    required super.subCategories,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    final subCategoriesList = (map['subCategories'] as List?)?.map((item) {
      final subMap = Map<String, dynamic>.from(item as Map);
      return SubCategory(
        name: subMap['name'] ?? '',
        icon: IconUtils.getIcon(subMap['icon'] as String?),
      );
    }).toList() ?? <SubCategory>[];

    return CategoryModel(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      icon: IconUtils.getIcon(map['icon'] as String?),
      subCategories: subCategoriesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type == CategoryType.income ? 'income' : 'expense',
      'icon': IconUtils.getIconName(icon),
      'subCategories': subCategories.map((sub) => {
        'name': sub.name,
        'icon': IconUtils.getIconName(sub.icon),
      }).toList(),
    };
  }

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
      icon: category.icon,
      subCategories: category.subCategories,
    );
  }
}
