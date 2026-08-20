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
