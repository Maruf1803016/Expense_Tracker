import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String note;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.note,
  });

  @override
  List<Object?> get props => [id, amount, categoryId, date, note];
}
