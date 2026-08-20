import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/plan/domain/entities/trip_plan.dart';

class TripPlanModel extends TripPlan {
  const TripPlanModel({
    required super.id,
    required super.title,
    required super.budgetAmount,
    super.categoryId,
    required super.startDate,
    super.endDate,
    required super.createdAt,
  });

  factory TripPlanModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TripPlanModel(
      id: documentId,
      title: map['title'] ?? '',
      budgetAmount: (map['budgetAmount'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] as String?,
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'budgetAmount': budgetAmount,
      'categoryId': categoryId,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TripPlanModel.fromEntity(TripPlan entity) {
    return TripPlanModel(
      id: entity.id,
      title: entity.title,
      budgetAmount: entity.budgetAmount,
      categoryId: entity.categoryId,
      startDate: entity.startDate,
      endDate: entity.endDate,
      createdAt: entity.createdAt,
    );
  }
}
