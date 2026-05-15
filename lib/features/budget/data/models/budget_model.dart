import 'package:expense_tracker/features/budget/domain/entities/budget.dart';

class BudgetModel extends Budget {
  const BudgetModel({
    required super.categoryId,
    required super.monthlyLimit,
    required super.month,
    required super.year,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      categoryId: map['categoryId'] as String,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'monthlyLimit': monthlyLimit,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      categoryId: entity.categoryId,
      monthlyLimit: entity.monthlyLimit,
      month: entity.month,
      year: entity.year,
    );
  }
}
