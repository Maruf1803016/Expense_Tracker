import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final String id;
  final String title;
  final double totalBudget;
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final String note;
  final DateTime createdAt;
  final bool isArchived;

  const Plan({
    required this.id,
    required this.title,
    required this.totalBudget,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    required this.note,
    required this.createdAt,
    this.isArchived = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        totalBudget,
        startDate,
        endDate,
        categoryId,
        note,
        createdAt,
        isArchived,
      ];
}
