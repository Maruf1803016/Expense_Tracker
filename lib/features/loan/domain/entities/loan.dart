import 'package:equatable/equatable.dart';

enum LoanType {
  borrowed, // Money you owe to someone else (Debt / Liability)
  lent,     // Money someone owes to you (Asset / Receivable)
}

class LoanRepayment extends Equatable {
  final String id;
  final double amount;
  final DateTime date;
  final String? accountId;
  final String? note;

  const LoanRepayment({
    required this.id,
    required this.amount,
    required this.date,
    this.accountId,
    this.note,
  });

  @override
  List<Object?> get props => [id, amount, date, accountId, note];
}

class Loan extends Equatable {
  final String id;
  final String title;
  final String counterparty;
  final LoanType type;
  final double originalAmount;
  final double paidAmount;
  final DateTime? dueDate;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final List<LoanRepayment> repayments;

  const Loan({
    required this.id,
    required this.title,
    required this.counterparty,
    required this.type,
    required this.originalAmount,
    this.paidAmount = 0.0,
    this.dueDate,
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    this.repayments = const [],
  });

  double get remainingAmount => (originalAmount - paidAmount).clamp(0.0, originalAmount);
  double get progress => originalAmount > 0 ? (paidAmount / originalAmount).clamp(0.0, 1.0) : 0.0;

  Loan copyWith({
    String? id,
    String? title,
    String? counterparty,
    LoanType? type,
    double? originalAmount,
    double? paidAmount,
    DateTime? dueDate,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
    List<LoanRepayment>? repayments,
  }) {
    return Loan(
      id: id ?? this.id,
      title: title ?? this.title,
      counterparty: counterparty ?? this.counterparty,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      repayments: repayments ?? this.repayments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        counterparty,
        type,
        originalAmount,
        paidAmount,
        dueDate,
        notes,
        isCompleted,
        createdAt,
        repayments,
      ];
}
