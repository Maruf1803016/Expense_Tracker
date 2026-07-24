import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/plan/domain/entities/plan.dart';

class PlanModel extends Plan {
  const PlanModel({
    required super.id,
    required super.title,
    required super.totalBudget,
    required super.startDate,
    required super.endDate,
    super.categoryIds,
    required super.note,
    required super.createdAt,
    super.isArchived,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map, String documentId) {
    List<String> resolvedCategoryIds = [];
    if (map['categoryIds'] != null) {
      resolvedCategoryIds = List<String>.from(map['categoryIds']);
    } else if (map['categoryId'] != null) {
      resolvedCategoryIds = [map['categoryId'] as String];
    }

    return PlanModel(
      id: documentId,
      title: map['title'] ?? '',
      totalBudget: (map['totalBudget'] as num?)?.toDouble() ?? 0.0,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      categoryIds: resolvedCategoryIds,
      note: map['note'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isArchived: map['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'totalBudget': totalBudget,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'categoryIds': categoryIds,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'isArchived': isArchived,
    };
  }

  factory PlanModel.fromEntity(Plan plan) {
    return PlanModel(
      id: plan.id,
      title: plan.title,
      totalBudget: plan.totalBudget,
      startDate: plan.startDate,
      endDate: plan.endDate,
      categoryIds: plan.categoryIds,
      note: plan.note,
      createdAt: plan.createdAt,
      isArchived: plan.isArchived,
    );
  }
}
