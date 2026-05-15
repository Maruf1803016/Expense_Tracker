import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase {
  final ExpenseRepository repository;

  UpdateExpenseUseCase({required this.repository});

  Future<void> call(Expense expense) async {
    return await repository.updateExpense(expense);
  }
}
