import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  final ExpenseRepository repository;

  DeleteExpenseUseCase({required this.repository});

  Future<void> call(String id) async {
    return await repository.deleteExpense(id);
  }
}
