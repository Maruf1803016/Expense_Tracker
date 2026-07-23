import 'package:equatable/equatable.dart';

/// Computed UI-ready entity representing the status of a budget for a category.
/// Contains all calculated data fields for the presentation layer.
class CategoryBudgetStatus extends Equatable {
  final String categoryId;
  final String categoryName;
  final double limit;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final bool isExceeded;
  final int month;
  final int year;

  const CategoryBudgetStatus({
    required this.categoryId,
    required this.categoryName,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.isExceeded,
    required this.month,
    required this.year,
  });

  factory CategoryBudgetStatus.fromAmounts({
    required String categoryId,
    required String categoryName,
    required double limit,
    required double spent,
    required int month,
    required int year,
  }) {
    final remaining = limit - spent;
    final percentageUsed = limit > 0 ? (spent / limit) * 100 : 0.0;
    final isExceeded = spent > limit && limit > 0;

    return CategoryBudgetStatus(
      categoryId: categoryId,
      categoryName: categoryName,
      limit: limit,
      spent: spent,
      remaining: remaining,
      percentageUsed: percentageUsed,
      isExceeded: isExceeded,
      month: month,
      year: year,
    );
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        limit,
        spent,
        remaining,
        percentageUsed,
        isExceeded,
        month,
        year,
      ];
}
