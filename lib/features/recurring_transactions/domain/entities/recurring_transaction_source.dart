import 'package:equatable/equatable.dart';

class RecurringTransactionSource extends Equatable {
  final String id;
  final String name;
  final double expectedAmount;
  final String frequency; // 'weekly' | 'biweekly' | 'monthly'
  final DateTime nextDueDate;
  final String status; // 'pending' | 'received' | 'paid'
  final String type; // 'income' | 'expense'
  final String? categoryId;
  final String? accountId;
  final DateTime createdAt;

  const RecurringTransactionSource({
    required this.id,
    required this.name,
    required this.expectedAmount,
    required this.frequency,
    required this.nextDueDate,
    required this.status,
    required this.type,
    this.categoryId,
    this.accountId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        expectedAmount,
        frequency,
        nextDueDate,
        status,
        type,
        categoryId,
        accountId,
        createdAt,
      ];
}
