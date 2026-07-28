import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/recurring_income/domain/entities/recurring_income_source.dart';

class RecurringIncomeSourceModel extends RecurringIncomeSource {
  const RecurringIncomeSourceModel({
    required super.id,
    required super.name,
    required super.expectedAmount,
    required super.frequency,
    required super.nextDueDate,
    required super.status,
    super.categoryId,
    super.accountId,
    required super.createdAt,
  });

  factory RecurringIncomeSourceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RecurringIncomeSourceModel(
      id: documentId,
      name: map['name'] ?? '',
      expectedAmount: (map['expectedAmount'] as num?)?.toDouble() ?? 0.0,
      frequency: map['frequency'] ?? 'monthly',
      nextDueDate: (map['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      categoryId: map['categoryId'],
      accountId: map['accountId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'expectedAmount': expectedAmount,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'status': status,
      'categoryId': categoryId,
      'accountId': accountId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RecurringIncomeSourceModel.fromEntity(RecurringIncomeSource source) {
    return RecurringIncomeSourceModel(
      id: source.id,
      name: source.name,
      expectedAmount: source.expectedAmount,
      frequency: source.frequency,
      nextDueDate: source.nextDueDate,
      status: source.status,
      categoryId: source.categoryId,
      accountId: source.accountId,
      createdAt: source.createdAt,
    );
  }
}
