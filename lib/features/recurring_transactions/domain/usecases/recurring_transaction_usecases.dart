import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/category/domain/entities/category.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class GetRecurringTransactionSourcesUseCase {
  final RecurringTransactionRepository repository;

  GetRecurringTransactionSourcesUseCase(this.repository);

  Stream<List<RecurringTransactionSource>> call() {
    return repository.getRecurringTransactionSourcesStream();
  }
}

class AddRecurringTransactionSourceUseCase {
  final RecurringTransactionRepository repository;

  AddRecurringTransactionSourceUseCase(this.repository);

  Future<void> call(RecurringTransactionSource source) {
    return repository.addRecurringTransactionSource(source);
  }
}

class UpdateRecurringTransactionSourceUseCase {
  final RecurringTransactionRepository repository;

  UpdateRecurringTransactionSourceUseCase(this.repository);

  Future<void> call(RecurringTransactionSource source) {
    return repository.updateRecurringTransactionSource(source);
  }
}

class DeleteRecurringTransactionSourceUseCase {
  final RecurringTransactionRepository repository;

  DeleteRecurringTransactionSourceUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteRecurringTransactionSource(id);
  }
}

class MarkRecurringTransactionCompleteUseCase {
  final RecurringTransactionRepository recurringRepository;
  final ExpenseRepository expenseRepository;

  MarkRecurringTransactionCompleteUseCase({
    required this.recurringRepository,
    required this.expenseRepository,
  });

  Future<void> call(RecurringTransactionSource source) async {
    // 1. Calculate next due date using correct calendar arithmetic
    final nextDate = _advanceDueDate(source.nextDueDate, source.frequency);
    final updatedSource = RecurringTransactionSource(
      id: source.id,
      name: source.name,
      expectedAmount: source.expectedAmount,
      frequency: source.frequency,
      nextDueDate: nextDate,
      status: 'pending',
      type: source.type,
      categoryId: source.categoryId,
      accountId: source.accountId,
      createdAt: source.createdAt,
    );

    // 2. Update recurring source first (to prevent silent duplicate creation on retry if transaction write fails)
    await recurringRepository.updateRecurringTransactionSource(updatedSource);

    // 3. Create the transaction
    final newTransaction = Expense(
      id: const Uuid().v4(),
      title: source.name,
      amount: source.expectedAmount,
      categoryId: source.categoryId ?? '',
      date: DateTime.now(),
      note: source.type == 'income' ? 'Received recurring income' : 'Paid recurring bill',
      accountId: source.accountId ?? '',
      type: source.type == 'income' ? CategoryType.income : CategoryType.expense,
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
