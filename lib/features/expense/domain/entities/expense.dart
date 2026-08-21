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
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentType;

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
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType,
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    CategoryType? type,
    bool? isDeleted,
    DateTime? deletedAt,
    String? subCategory,
    String? subCategoryIcon,
    String? planId,
    String? accountId,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? payerPayee,
    String? toAccountId,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentType,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      subCategory: subCategory ?? this.subCategory,
      subCategoryIcon: subCategoryIcon ?? this.subCategoryIcon,
      planId: planId ?? this.planId,
      accountId: accountId ?? this.accountId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payerPayee: payerPayee ?? this.payerPayee,
      toAccountId: toAccountId ?? this.toAccountId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }

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
        attachmentUrl,
        attachmentName,
        attachmentType,
      ];
}
