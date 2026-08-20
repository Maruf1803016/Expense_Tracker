import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

import 'package:expense_tracker/features/category/domain/entities/category.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.categoryId,
    required super.date,
    required super.note,
    required super.accountId,
    super.type,
    super.isDeleted,
    super.deletedAt,
    super.subCategory,
    super.subCategoryIcon,
    super.planId,
    super.paymentStatus,
    super.paymentMethod,
    super.payerPayee,
    super.toAccountId,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    CategoryType resolvedType;
    if (map['type'] == 'income') {
      resolvedType = CategoryType.income;
    } else if (map['type'] == 'transfer') {
      resolvedType = CategoryType.transfer;
    } else {
      resolvedType = CategoryType.expense;
    }

    return ExpenseModel(
      id: documentId,
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] ?? '',
      accountId: map['accountId'] ?? '',
      type: resolvedType,
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: map['deletedAt'] != null ? (map['deletedAt'] as Timestamp).toDate() : null,
      subCategory: map['subCategory'],
      subCategoryIcon: map['subCategoryIcon'],
      planId: map['planId'],
      paymentStatus: map['paymentStatus'] == 'pending' ? PaymentStatus.pending : PaymentStatus.settled,
      paymentMethod: map['paymentMethod'] as String?,
      payerPayee: map['payerPayee'] as String?,
      toAccountId: map['toAccountId'] as String?,
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
      'planId': planId,
      'accountId': accountId,
      'paymentStatus': paymentStatus.name,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (payerPayee != null) 'payerPayee': payerPayee,
      if (toAccountId != null) 'toAccountId': toAccountId,
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
      accountId: expense.accountId,
      type: expense.type,
      isDeleted: expense.isDeleted,
      deletedAt: expense.deletedAt,
      subCategory: expense.subCategory,
      subCategoryIcon: expense.subCategoryIcon,
      planId: expense.planId,
      paymentStatus: expense.paymentStatus,
      paymentMethod: expense.paymentMethod,
      payerPayee: expense.payerPayee,
      toAccountId: expense.toAccountId,
    );
  }
}
