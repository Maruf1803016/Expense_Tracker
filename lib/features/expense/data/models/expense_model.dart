import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.amount,
    required super.categoryId,
    required super.date,
    required super.note,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExpenseModel(
      id: documentId,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      amount: expense.amount,
      categoryId: expense.categoryId,
      date: expense.date,
      note: expense.note,
    );
  }
}
