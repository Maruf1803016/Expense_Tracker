import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';

class SetGlobalBudgetUseCase {
  final BudgetRepository repository;

  SetGlobalBudgetUseCase({required this.repository});

  Future<void> call(double amount) async {
    return await repository.setGlobalMonthlyBudget(amount);
  }
}
