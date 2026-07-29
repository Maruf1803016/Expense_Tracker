import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:flutter/material.dart';

void main() {
  group('Account.calculateBalance', () {
    test('should calculate balance correctly including initial balance, income, and expense', () {
      final account = Account(
        id: 'acc1',
        name: 'Savings',
        icon: Icons.account_balance,
        color: Colors.blue,
        initialBalance: 1000.0,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      final expenses = [
        Expense(
          id: '1',
          title: 'Salary',
          amount: 500.0,
          categoryId: 'cat1',
          date: DateTime.now(),
          note: 'Salary payment',
          accountId: 'acc1',
          type: CategoryType.income,
        ),
        Expense(
          id: '2',
          title: 'Grocery',
          amount: 150.0,
          categoryId: 'cat2',
          date: DateTime.now(),
          note: 'Weekly shopping',
          accountId: 'acc1',
          type: CategoryType.expense,
        ),
        Expense(
          id: '3',
          title: 'Deleted Cash',
          amount: 100.0,
          categoryId: 'cat2',
          date: DateTime.now(),
          note: 'Deleted',
          accountId: 'acc1',
          type: CategoryType.expense,
          isDeleted: true,
        ),
        Expense(
          id: '4',
          title: 'Other Account Expense',
          amount: 300.0,
          categoryId: 'cat2',
          date: DateTime.now(),
          note: 'Other',
          accountId: 'acc2',
          type: CategoryType.expense,
        ),
      ];

      final balance = Account.calculateBalance(account, expenses);

      // Expected: 1000 (initial) + 500 (income) - 150 (expense) = 1350
      expect(balance, 1350.0);
    });
  });
}
