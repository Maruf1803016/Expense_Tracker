import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/plan/domain/entities/goal.dart';

class GoalModel extends Goal {
  const GoalModel({
    required super.id,
    required super.title,
    required super.totalBudget,
    required super.startDate,
    required super.endDate,
    super.categoryIds,
    required super.note,
    required super.createdAt,
    super.isArchived,
    super.financedAmount,
  });

  factory GoalModel.fromMap(Map<String, dynamic> map, String documentId) {
    List<String> resolvedCategoryIds = [];
    if (map['categoryIds'] != null) {
      resolvedCategoryIds = List<String>.from(map['categoryIds']);
    } else if (map['categoryId'] != null) {
      resolvedCategoryIds = [map['categoryId'] as String];
    }

    return GoalModel(
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
      financedAmount: (map['financedAmount'] as num?)?.toDouble(),
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
      if (financedAmount != null) 'financedAmount': financedAmount,
    };
  }

  factory GoalModel.fromEntity(Goal goal) {
    return GoalModel(
      id: goal.id,
      title: goal.title,
      totalBudget: goal.totalBudget,
      startDate: goal.startDate,
      endDate: goal.endDate,
      categoryIds: goal.categoryIds,
      note: goal.note,
      createdAt: goal.createdAt,
      isArchived: goal.isArchived,
      financedAmount: goal.financedAmount,
    );
  }
}
