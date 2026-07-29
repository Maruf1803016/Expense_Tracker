import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/recurring_transaction_usecases.dart';

class FakeRecurringTransactionRepository implements RecurringTransactionRepository {
  RecurringTransactionSource? lastUpdatedSource;

  @override
  Stream<List<RecurringTransactionSource>> getRecurringTransactionSourcesStream() => const Stream.empty();

  @override
  Future<void> addRecurringTransactionSource(RecurringTransactionSource source) async {}

  @override
  Future<void> updateRecurringTransactionSource(RecurringTransactionSource source) async {
    lastUpdatedSource = source;
  }

  @override
  Future<void> deleteRecurringTransactionSource(String id) async {}
}

class FakeExpenseRepository implements ExpenseRepository {
  Expense? lastAddedExpense;

  @override
  Stream<List<Expense>> getExpensesStream() => const Stream.empty();

  @override
  Stream<List<Expense>> getRecycleBinExpensesStream() => const Stream.empty();

  @override
  Future<void> addExpense(Expense expense) async {
    lastAddedExpense = expense;
  }

  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Future<void> restoreExpense(String id) async {}

  @override
  Future<void> deleteForever(String id) async {}

  @override
  Future<void> emptyRecycleBin() async {}

  @override
  Future<void> updateExpense(Expense expense) async {}
}

void main() {
  group('MarkRecurringTransactionCompleteUseCase & Date Arithmetic', () {
    late FakeRecurringTransactionRepository fakeRecurringRepo;
    late FakeExpenseRepository fakeExpenseRepo;
    late MarkRecurringTransactionCompleteUseCase useCase;

    setUp(() {
      fakeRecurringRepo = FakeRecurringTransactionRepository();
      fakeExpenseRepo = FakeExpenseRepository();
      useCase = MarkRecurringTransactionCompleteUseCase(
        recurringRepository: fakeRecurringRepo,
        expenseRepository: fakeExpenseRepo,
      );
    });

    test('should advance weekly income by exactly 7 days and create income transaction', () async {
      final baseDate = DateTime(2026, 1, 1); // Thursday
      final source = RecurringTransactionSource(
        id: '1',
        name: 'Weekly Salary',
        expectedAmount: 500.0,
        frequency: 'weekly',
        nextDueDate: baseDate,
        status: 'pending',
        type: 'income',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2026, 1, 8));
      expect(fakeExpenseRepo.lastAddedExpense!.amount, 500.0);
      expect(fakeExpenseRepo.lastAddedExpense!.title, 'Weekly Salary');
      expect(fakeExpenseRepo.lastAddedExpense!.type, CategoryType.income);
    });

    test('should advance weekly expense by exactly 7 days and create expense transaction', () async {
      final baseDate = DateTime(2026, 1, 1); // Thursday
      final source = RecurringTransactionSource(
        id: '2',
        name: 'Weekly Rent',
        expectedAmount: 350.0,
        frequency: 'weekly',
        nextDueDate: baseDate,
        status: 'pending',
        type: 'expense',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2026, 1, 8));
      expect(fakeExpenseRepo.lastAddedExpense!.amount, 350.0);
      expect(fakeExpenseRepo.lastAddedExpense!.title, 'Weekly Rent');
      expect(fakeExpenseRepo.lastAddedExpense!.type, CategoryType.expense);
    });

    test('should advance biweekly by exactly 14 days', () async {
      final baseDate = DateTime(2026, 1, 1);
      final source = RecurringTransactionSource(
        id: '3',
        name: 'Biweekly Rent Payment',
        expectedAmount: 1000.0,
        frequency: 'biweekly',
        nextDueDate: baseDate,
        status: 'pending',
        type: 'expense',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2026, 1, 15));
      expect(fakeExpenseRepo.lastAddedExpense!.type, CategoryType.expense);
    });

    test('should advance monthly by exactly 1 calendar month and clamp overflow days (Jan 31 -> Feb 28)', () async {
      final baseDate = DateTime(2026, 1, 31); // Jan 31, 2026 (non-leap year)
      final source = RecurringTransactionSource(
        id: '4',
        name: 'Monthly Rent',
        expectedAmount: 2000.0,
        frequency: 'monthly',
        nextDueDate: baseDate,
        status: 'pending',
        type: 'expense',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2026, 2, 28));
      expect(fakeExpenseRepo.lastAddedExpense!.type, CategoryType.expense);
    });

    test('should advance monthly by exactly 1 calendar month on leap years (Jan 31, 2024 -> Feb 29)', () async {
      final baseDate = DateTime(2024, 1, 31); // Jan 31, 2024 (leap year)
      final source = RecurringTransactionSource(
        id: '5',
        name: 'Monthly Freelance',
        expectedAmount: 2000.0,
        frequency: 'monthly',
        nextDueDate: baseDate,
        status: 'pending',
        type: 'income',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2024, 2, 29));
      expect(fakeExpenseRepo.lastAddedExpense!.type, CategoryType.income);
    });
  });
}
