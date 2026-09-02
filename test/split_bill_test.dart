import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/features/expense/domain/entities/split_details.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';

void main() {
  group('SplitDetails & SplitItem Domain Tests', () {
    test('Calculates myShare and pendingReceivableAmount accurately when paid by me', () {
      final split = SplitDetails(
        isSplit: true,
        paidBy: 'me',
        totalBillAmount: 3000.0,
        amountOwedToPayer: 0.0,
        splits: [
          SplitItem(name: 'Alice', amount: 1000.0, isSettled: false),
          SplitItem(name: 'Bob', amount: 1000.0, isSettled: true),
        ],
      );

      expect(split.isPaidByMe, isTrue);
      expect(split.myShare, 1000.0);
      expect(split.pendingReceivableAmount, 1000.0);
      expect(split.isFullySettled, isFalse);
    });

    test('Identifies fully settled splits', () {
      final split = SplitDetails(
        isSplit: true,
        paidBy: 'me',
        totalBillAmount: 2000.0,
        amountOwedToPayer: 0.0,
        splits: [
          SplitItem(name: 'Alice', amount: 1000.0, isSettled: true),
        ],
      );

      expect(split.isFullySettled, isTrue);
      expect(split.pendingReceivableAmount, 0.0);
      expect(split.myShare, 1000.0);
    });

    test('Calculates myShare when paid by someone else', () {
      final split = SplitDetails(
        isSplit: true,
        paidBy: 'Charlie',
        totalBillAmount: 4500.0,
        amountOwedToPayer: 1500.0,
        splits: [],
      );

      expect(split.isPaidByMe, isFalse);
      expect(split.myShare, 1500.0);
      expect(split.pendingReceivableAmount, 0.0);
    });

    test('ExpenseModel round-trips splitDetails toMap and fromMap cleanly', () {
      final split = SplitDetails(
        isSplit: true,
        paidBy: 'me',
        totalBillAmount: 150.0,
        amountOwedToPayer: 0.0,
        splits: [
          SplitItem(name: 'Dave', amount: 75.0, isSettled: false),
        ],
      );

      final model = ExpenseModel(
        id: 'exp-123',
        title: 'Team Lunch',
        amount: 75.0,
        categoryId: 'food',
        date: DateTime(2026, 9, 2),
        note: 'Split with Dave',
        accountId: 'acc-1',
        splitDetails: split,
      );

      final map = model.toMap();
      expect(map['splitDetails'], isNotNull);
      expect(map['splitDetails']['isSplit'], isTrue);
      expect(map['splitDetails']['totalBillAmount'], 150.0);
      expect((map['splitDetails']['splits'] as List).length, 1);

      final reconstructed = ExpenseModel.fromMap(map, 'exp-123');
      expect(reconstructed.splitDetails, isNotNull);
      expect(reconstructed.splitDetails!.totalBillAmount, 150.0);
      expect(reconstructed.splitDetails!.splits.first.name, 'Dave');
      expect(reconstructed.splitDetails!.splits.first.amount, 75.0);
    });
  });
}
