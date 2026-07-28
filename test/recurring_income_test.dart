import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/recurring_income/domain/entities/recurring_income_source.dart';
import 'package:expense_tracker/features/recurring_income/domain/repositories/recurring_income_repository.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/recurring_income/domain/usecases/recurring_income_usecases.dart';

class FakeRecurringIncomeRepository implements RecurringIncomeRepository {
  RecurringIncomeSource? lastUpdatedSource;

  @override
  Stream<List<RecurringIncomeSource>> getRecurringIncomeSourcesStream() => const Stream.empty();

  @override
  Future<void> addRecurringIncomeSource(RecurringIncomeSource source) async {}

  @override
  Future<void> updateRecurringIncomeSource(RecurringIncomeSource source) async {
    lastUpdatedSource = source;
  }

  @override
  Future<void> deleteRecurringIncomeSource(String id) async {}
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
  group('MarkRecurringIncomeReceivedUseCase & Date Arithmetic', () {
    late FakeRecurringIncomeRepository fakeRecurringRepo;
    late FakeExpenseRepository fakeExpenseRepo;
    late MarkRecurringIncomeReceivedUseCase useCase;

    setUp(() {
      fakeRecurringRepo = FakeRecurringIncomeRepository();
      fakeExpenseRepo = FakeExpenseRepository();
      useCase = MarkRecurringIncomeReceivedUseCase(
        recurringRepository: fakeRecurringRepo,
        expenseRepository: fakeExpenseRepo,
      );
    });

    test('should advance weekly by exactly 7 days', () async {
      final baseDate = DateTime(2026, 1, 1); // Thursday
      final source = RecurringIncomeSource(
        id: '1',
        name: 'Weekly Salary',
        expectedAmount: 500.0,
        frequency: 'weekly',
        nextDueDate: baseDate,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2026, 1, 8));
      expect(fakeExpenseRepo.lastAddedExpense!.amount, 500.0);
      expect(fakeExpenseRepo.lastAddedExpense!.title, 'Weekly Salary');
    });

    test('should advance biweekly by exactly 14 days', () async {
      final baseDate = DateTime(2026, 1, 1);
      final source = RecurringIncomeSource(
        id: '2',
        name: 'Biweekly Salary',
        expectedAmount: 1000.0,
        frequency: 'biweekly',
        nextDueDate: baseDate,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2026, 1, 15));
    });

    test('should advance monthly by exactly 1 calendar month and clamp overflow days (Jan 31 -> Feb 28)', () async {
      final baseDate = DateTime(2026, 1, 31); // Jan 31, 2026 (non-leap year)
      final source = RecurringIncomeSource(
        id: '3',
        name: 'Monthly Freelance',
        expectedAmount: 2000.0,
        frequency: 'monthly',
        nextDueDate: baseDate,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2026, 2, 28));
    });

    test('should advance monthly by exactly 1 calendar month on leap years (Jan 31, 2024 -> Feb 29)', () async {
      final baseDate = DateTime(2024, 1, 31); // Jan 31, 2024 (leap year)
      final source = RecurringIncomeSource(
        id: '4',
        name: 'Monthly Freelance',
        expectedAmount: 2000.0,
        frequency: 'monthly',
        nextDueDate: baseDate,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await useCase(source);

      expect(fakeRecurringRepo.lastUpdatedSource!.nextDueDate, DateTime(2024, 2, 29));
    });
  });
}
