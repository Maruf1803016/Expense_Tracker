import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/recurring_income/domain/entities/recurring_income_source.dart';
import 'package:expense_tracker/features/recurring_income/domain/repositories/recurring_income_repository.dart';

class GetRecurringIncomeSourcesUseCase {
  final RecurringIncomeRepository repository;

  GetRecurringIncomeSourcesUseCase(this.repository);

  Stream<List<RecurringIncomeSource>> call() {
    return repository.getRecurringIncomeSourcesStream();
  }
}

class AddRecurringIncomeSourceUseCase {
  final RecurringIncomeRepository repository;

  AddRecurringIncomeSourceUseCase(this.repository);

  Future<void> call(RecurringIncomeSource source) {
    return repository.addRecurringIncomeSource(source);
  }
}

class UpdateRecurringIncomeSourceUseCase {
  final RecurringIncomeRepository repository;

  UpdateRecurringIncomeSourceUseCase(this.repository);

  Future<void> call(RecurringIncomeSource source) {
    return repository.updateRecurringIncomeSource(source);
  }
}

class DeleteRecurringIncomeSourceUseCase {
  final RecurringIncomeRepository repository;

  DeleteRecurringIncomeSourceUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteRecurringIncomeSource(id);
  }
}

class MarkRecurringIncomeReceivedUseCase {
  final RecurringIncomeRepository recurringRepository;
  final ExpenseRepository expenseRepository;

  MarkRecurringIncomeReceivedUseCase({
    required this.recurringRepository,
    required this.expenseRepository,
  });

  Future<void> call(RecurringIncomeSource source) async {
    // 1. Calculate next due date using correct calendar arithmetic
    final nextDate = _advanceDueDate(source.nextDueDate, source.frequency);
    final updatedSource = RecurringIncomeSource(
      id: source.id,
      name: source.name,
      expectedAmount: source.expectedAmount,
      frequency: source.frequency,
      nextDueDate: nextDate,
      status: 'pending',
      categoryId: source.categoryId,
      accountId: source.accountId,
      createdAt: source.createdAt,
    );

    // 2. Update recurring income source first (to prevent silent duplicate creation on retry if transaction write fails)
    await recurringRepository.updateRecurringIncomeSource(updatedSource);

    // 3. Create the transaction
    final newTransaction = Expense(
      id: const Uuid().v4(),
      title: source.name,
      amount: source.expectedAmount,
      categoryId: source.categoryId ?? '',
      date: DateTime.now(),
      note: 'Received recurring income',
      accountId: source.accountId ?? '',
      type: CategoryType.income,
    );
    await expenseRepository.addExpense(newTransaction);
  }

  DateTime _advanceDueDate(DateTime date, String frequency) {
    switch (frequency) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'biweekly':
        return date.add(const Duration(days: 14));
      case 'monthly':
        int nextYear = date.year;
        int nextMonth = date.month + 1;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear += 1;
        }
        int nextDay = date.day;
        int daysInNextMonth = _getDaysInMonth(nextYear, nextMonth);
        if (nextDay > daysInNextMonth) {
          nextDay = daysInNextMonth;
        }
        return DateTime(nextYear, nextMonth, nextDay, date.hour, date.minute, date.second);
      default:
        return date;
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      return 31;
    }
    if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    }
    // February
    if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
      return 29;
    }
    return 28;
  }
}
