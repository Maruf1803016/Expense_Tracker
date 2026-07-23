import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.categoryId,
    required super.date,
    required super.note,
    super.type,
    super.isDeleted,
    super.deletedAt,
    super.subCategory,
    super.subCategoryIcon,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExpenseModel(
      id: documentId,
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
      type: map['type'] == 'income' ? CategoryType.income : CategoryType.expense,
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: map['deletedAt'] != null ? (map['deletedAt'] as Timestamp).toDate() : null,
      subCategory: map['subCategory'],
      subCategoryIcon: map['subCategoryIcon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'note': note,
      'type': type.name,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'subCategory': subCategory,
      'subCategoryIcon': subCategoryIcon,
    };
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      categoryId: expense.categoryId,
      date: expense.date,
      note: expense.note,
      type: expense.type,
      isDeleted: expense.isDeleted,
      deletedAt: expense.deletedAt,
      subCategory: expense.subCategory,
      subCategoryIcon: expense.subCategoryIcon,
    );
  }
}
