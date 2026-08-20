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

    test('should calculate transfers correctly for source and destination accounts', () {
      final accountA = Account(
        id: 'accA',
        name: 'Checking',
        icon: Icons.account_balance,
        color: Colors.blue,
        initialBalance: 1000.0,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      final accountB = Account(
        id: 'accB',
        name: 'Savings',
        icon: Icons.savings,
        color: Colors.green,
        initialBalance: 200.0,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      final expenses = [
        Expense(
          id: 't1',
          title: 'Transfer to Savings',
          amount: 300.0,
          categoryId: 'transfer',
          date: DateTime.now(),
          note: 'Emergency fund contribution',
          accountId: 'accA',
          toAccountId: 'accB',
          type: CategoryType.transfer,
        ),
      ];

      final balanceA = Account.calculateBalance(accountA, expenses);
      final balanceB = Account.calculateBalance(accountB, expenses);

      // Source accountA: 1000 - 300 = 700
      expect(balanceA, 700.0);
      // Destination accountB: 200 + 300 = 500
      expect(balanceB, 500.0);
    });
  });

  group('Account new fields and masking', () {
    test('should mask account number correctly', () {
      expect(Account.getMaskedAccountNumber(null), '');
      expect(Account.getMaskedAccountNumber(''), '');
      expect(Account.getMaskedAccountNumber('123'), '•••• 123');
      expect(Account.getMaskedAccountNumber('1234567890123456'), '•••• 3456');
    });

    test('should format subtitle fields with priority order', () {
      final account = Account(
        id: 'acc1',
        name: 'Savings',
        icon: Icons.account_balance,
        color: Colors.blue,
        initialBalance: 1000.0,
        isDefault: false,
        createdAt: DateTime.now(),
        holderName: 'Maruf',
        accountNumber: '1234567890124821',
      );

      final subtitleTokens = [
        if (account.holderName != null && account.holderName!.isNotEmpty) account.holderName!,
        if (account.accountNumber != null && account.accountNumber!.isNotEmpty) Account.getMaskedAccountNumber(account.accountNumber),
        account.isDefault ? 'Primary Account' : 'Custom Account',
      ];

      expect(subtitleTokens.join(' • '), 'Maruf • •••• 4821 • Custom Account');
    });
  });
}
