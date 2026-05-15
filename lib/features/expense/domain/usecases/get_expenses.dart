import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesStreamUseCase {
  final ExpenseRepository repository;

  GetExpensesStreamUseCase({required this.repository});

  Stream<List<Expense>> call() {
    return repository.getExpensesStream();
  }
}
