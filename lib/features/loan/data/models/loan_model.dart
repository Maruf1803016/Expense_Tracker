import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/loan/domain/entities/loan.dart';

class LoanRepaymentModel extends LoanRepayment {
  const LoanRepaymentModel({
    required super.id,
    required super.amount,
    required super.date,
    super.accountId,
    super.note,
  });

  factory LoanRepaymentModel.fromMap(Map<String, dynamic> map) {
    return LoanRepaymentModel(
      id: map['id'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      accountId: map['accountId'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      if (accountId != null) 'accountId': accountId,
      if (note != null) 'note': note,
    };
  }

  factory LoanRepaymentModel.fromEntity(LoanRepayment entity) {
    return LoanRepaymentModel(
      id: entity.id,
      amount: entity.amount,
      date: entity.date,
      accountId: entity.accountId,
      note: entity.note,
    );
  }
}

class LoanModel extends Loan {
  const LoanModel({
    required super.id,
    required super.title,
    required super.counterparty,
    required super.type,
    required super.originalAmount,
    super.paidAmount,
    super.dueDate,
    super.notes,
    super.isCompleted,
    required super.createdAt,
    super.repayments,
  });

  factory LoanModel.fromMap(Map<String, dynamic> map, String documentId) {
    final repaymentsList = (map['repayments'] as List<dynamic>? ?? [])
        .map((r) => LoanRepaymentModel.fromMap(r as Map<String, dynamic>))
        .toList();

    return LoanModel(
      id: documentId,
      title: map['title'] ?? '',
      counterparty: map['counterparty'] ?? '',
      type: map['type'] == 'lent' ? LoanType.lent : LoanType.borrowed,
      originalAmount: (map['originalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      notes: map['notes'] as String?,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      repayments: repaymentsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'counterparty': counterparty,
      'type': type == LoanType.lent ? 'lent' : 'borrowed',
      'originalAmount': originalAmount,
      'paidAmount': paidAmount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notes': notes,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'repayments': repayments.map((r) => LoanRepaymentModel.fromEntity(r).toMap()).toList(),
    };
  }

  factory LoanModel.fromEntity(Loan entity) {
    return LoanModel(
      id: entity.id,
      title: entity.title,
      counterparty: entity.counterparty,
      type: entity.type,
      originalAmount: entity.originalAmount,
      paidAmount: entity.paidAmount,
      dueDate: entity.dueDate,
      notes: entity.notes,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      repayments: entity.repayments,
    );
  }
}
