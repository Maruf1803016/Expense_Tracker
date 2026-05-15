import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';

class RestoreExpenseUseCase {
  final ExpenseRepository repository;

  RestoreExpenseUseCase({required this.repository});

  Future<void> call(String id) async {
    return await repository.restoreExpense(id);
  }
}
