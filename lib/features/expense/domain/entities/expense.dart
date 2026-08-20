import 'package:equatable/equatable.dart';

import 'package:expense_tracker/features/category/domain/entities/category.dart';

enum PaymentStatus {
  settled,
  pending,
}

class Expense extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String note;
  final CategoryType type;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? subCategory;
  final String? subCategoryIcon;
  final String? planId;
  final String accountId;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? payerPayee;
  final String? toAccountId;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.note,
    required this.accountId,
    this.type = CategoryType.expense,
    this.isDeleted = false,
    this.deletedAt,
    this.subCategory,
    this.subCategoryIcon,
    this.planId,
    this.paymentStatus = PaymentStatus.settled,
    this.paymentMethod,
    this.payerPayee,
    this.toAccountId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        categoryId,
        date,
        note,
        type,
        isDeleted,
        deletedAt,
        subCategory,
        subCategoryIcon,
        planId,
        accountId,
        paymentStatus,
        paymentMethod,
        payerPayee,
        toAccountId,
      ];
}
