import '../../../../core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class AddExpenseUseCase implements UseCase<void, Expense> {
  final ExpenseRepository repository;

  AddExpenseUseCase({required this.repository});

  @override
  Future<void> call(Expense expense) async {
    return await repository.addExpense(expense);
  }
}
