import 'package:equatable/equatable.dart';

import 'package:expense_tracker/features/category/domain/entities/category.dart';

class Expense extends Equatable {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String note;
  final CategoryType type;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.note,
    this.type = CategoryType.expense,
    this.isDeleted = false,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [id, amount, categoryId, date, note, type, isDeleted, deletedAt];
}
