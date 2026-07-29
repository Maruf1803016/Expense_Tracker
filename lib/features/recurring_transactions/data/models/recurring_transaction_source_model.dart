import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';

class RecurringTransactionSourceModel extends RecurringTransactionSource {
  const RecurringTransactionSourceModel({
    required super.id,
    required super.name,
    required super.expectedAmount,
    required super.frequency,
    required super.nextDueDate,
    required super.status,
    required super.type,
    super.categoryId,
    super.accountId,
    required super.createdAt,
  });

  factory RecurringTransactionSourceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RecurringTransactionSourceModel(
      id: documentId,
      name: map['name'] ?? '',
      expectedAmount: (map['expectedAmount'] as num?)?.toDouble() ?? 0.0,
      frequency: map['frequency'] ?? 'monthly',
      nextDueDate: (map['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      type: (map['type'] as String?) ?? 'income',
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
      'type': type,
      'categoryId': categoryId,
      'accountId': accountId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RecurringTransactionSourceModel.fromEntity(RecurringTransactionSource source) {
    return RecurringTransactionSourceModel(
      id: source.id,
      name: source.name,
      expectedAmount: source.expectedAmount,
      frequency: source.frequency,
      nextDueDate: source.nextDueDate,
      status: source.status,
      type: source.type,
      categoryId: source.categoryId,
      accountId: source.accountId,
      createdAt: source.createdAt,
    );
  }
}
