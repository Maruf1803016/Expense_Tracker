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

  const CategoryBudgetStatus({
    required this.categoryId,
    required this.categoryName,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.isExceeded,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        limit,
        spent,
        remaining,
        percentageUsed,
        isExceeded,
      ];
}
