import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

void main() {
  group('Expense & ExpenseModel serialization and new fields', () {
    test('should construct Expense with default paymentStatus and optional fields', () {
      final expense = Expense(
        id: 'e1',
        title: 'Dinner with Client',
        amount: 85.50,
        categoryId: 'food_dining',
        date: DateTime(2026, 8, 20),
        note: 'Quarterly review dinner',
        accountId: 'acc1',
        type: CategoryType.expense,
        paymentStatus: PaymentStatus.pending,
        paymentMethod: 'Credit Card',
        payerPayee: 'Acme Corp',
      );

      expect(expense.paymentStatus, PaymentStatus.pending);
      expect(expense.paymentMethod, 'Credit Card');
      expect(expense.payerPayee, 'Acme Corp');
      expect(expense.type, CategoryType.expense);
    });

    test('ExpenseModel.toMap and fromMap should round-trip cleanly', () {
      final now = DateTime(2026, 8, 20, 19, 30);
      final model = ExpenseModel(
        id: 'e2',
        title: 'Transfer to Savings',
        amount: 250.0,
        categoryId: 'transfer',
        date: now,
        note: 'Monthly saving',
        accountId: 'acc1',
        toAccountId: 'acc2',
        type: CategoryType.transfer,
        paymentStatus: PaymentStatus.settled,
        paymentMethod: 'Bank Transfer',
        payerPayee: 'Myself',
      );

      final map = model.toMap();
      expect(map['title'], 'Transfer to Savings');
      expect(map['amount'], 250.0);
      expect(map['type'], 'transfer');
      expect(map['paymentStatus'], 'settled');
      expect(map['paymentMethod'], 'Bank Transfer');
      expect(map['payerPayee'], 'Myself');
      expect(map['toAccountId'], 'acc2');

      final fromMap = ExpenseModel.fromMap(map, 'e2');
      expect(fromMap.id, 'e2');
      expect(fromMap.type, CategoryType.transfer);
      expect(fromMap.paymentStatus, PaymentStatus.settled);
      expect(fromMap.toAccountId, 'acc2');
      expect(fromMap.paymentMethod, 'Bank Transfer');
      expect(fromMap.payerPayee, 'Myself');
    });

    test('ExpenseModel.fromMap should fallback gracefully when payment fields are absent', () {
      final rawMap = {
        'title': 'Legacy Coffee',
        'amount': 4.50,
        'categoryId': 'food_dining',
        'date': Timestamp.fromDate(DateTime(2026, 8, 1)),
        'note': 'Latte',
        'accountId': 'acc1',
        'type': 'expense',
      };

      final parsed = ExpenseModel.fromMap(rawMap, 'leg1');
      expect(parsed.paymentStatus, PaymentStatus.settled);
      expect(parsed.paymentMethod, isNull);
      expect(parsed.payerPayee, isNull);
      expect(parsed.toAccountId, isNull);
    });
  });
}
