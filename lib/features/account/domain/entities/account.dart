import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

class Account extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double initialBalance;
  final bool isDefault;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.initialBalance,
    required this.isDefault,
    required this.createdAt,
  });

  static double calculateBalance(Account account, List<Expense> expenses) {
    double balance = account.initialBalance;
    for (var expense in expenses) {
      if (expense.accountId == account.id && !expense.isDeleted) {
        balance += expense.type == CategoryType.income ? expense.amount : -expense.amount;
      }
    }
    return balance;
  }

  @override
  List<Object?> get props => [id, name, icon, color, initialBalance, isDefault, createdAt];
}
