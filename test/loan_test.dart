import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/loan/data/models/loan_model.dart';

void main() {
  group('Loan Domain & Calculation Tests', () {
    test('Loan calculates remaining amount and progress accurately', () {
      final loan = Loan(
        id: 'l1',
        title: 'Office Equipment Loan',
        counterparty: 'TechStore',
        type: LoanType.borrowed,
        originalAmount: 1000.0,
        paidAmount: 250.0,
        createdAt: DateTime(2026, 8, 1),
      );

      expect(loan.remainingAmount, 750.0);
      expect(loan.progress, 0.25);
    });

    test('Loan clamps progress and remaining amount on overpayment', () {
      final loan = Loan(
        id: 'l2',
        title: 'Personal Loan',
        counterparty: 'John',
        type: LoanType.lent,
        originalAmount: 500.0,
        paidAmount: 600.0,
        createdAt: DateTime(2026, 8, 1),
      );

      expect(loan.remainingAmount, 0.0);
      expect(loan.progress, 1.0);
    });

    test('LoanModel round-trips to and from map with repayments cleanly', () {
      final now = DateTime(2026, 8, 20, 10, 0);
      final repayment = LoanRepayment(
        id: 'rep1',
        amount: 200.0,
        date: now,
        accountId: 'acc1',
        note: 'First installment',
      );

      final loan = Loan(
        id: 'l3',
        title: 'Tuition Advance',
        counterparty: 'Student Alex',
        type: LoanType.lent,
        originalAmount: 800.0,
        paidAmount: 200.0,
        dueDate: now.add(const Duration(days: 30)),
        notes: 'Monthly payments',
        isCompleted: false,
        createdAt: now,
        repayments: [repayment],
      );

      final model = LoanModel.fromEntity(loan);
      final map = model.toMap();

      expect(map['title'], 'Tuition Advance');
      expect(map['counterparty'], 'Student Alex');
      expect(map['type'], 'lent');
      expect(map['originalAmount'], 800.0);
      expect(map['paidAmount'], 200.0);
      expect(map['repayments'], isNotEmpty);

      final fromMap = LoanModel.fromMap(map, 'l3');
      expect(fromMap.id, 'l3');
      expect(fromMap.type, LoanType.lent);
      expect(fromMap.repayments.length, 1);
      expect(fromMap.repayments.first.amount, 200.0);
      expect(fromMap.repayments.first.accountId, 'acc1');
      expect(fromMap.remainingAmount, 600.0);
    });
  });
}
