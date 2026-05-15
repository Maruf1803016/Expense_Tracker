import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';

class GetRecycleBinExpensesStreamUseCase {
  final ExpenseRepository repository;

  GetRecycleBinExpensesStreamUseCase({required this.repository});

  Stream<List<Expense>> call() {
    return repository.getRecycleBinExpensesStream();
  }
}
