import 'package:equatable/equatable.dart';

class TripPlan extends Equatable {
  final String id;
  final String title;
  final double budgetAmount;
  final String? categoryId;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const TripPlan({
    required this.id,
    required this.title,
    required this.budgetAmount,
    this.categoryId,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  TripPlan copyWith({
    String? id,
    String? title,
    double? budgetAmount,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return TripPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        budgetAmount,
        categoryId,
        startDate,
        endDate,
        createdAt,
      ];
}
