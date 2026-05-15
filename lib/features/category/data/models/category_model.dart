import 'package:expense_tracker/features/category/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type == CategoryType.income ? 'income' : 'expense',
    };
  }

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
    );
  }
}
