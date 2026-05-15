import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class SetBudgetUseCase {
  final BudgetRepository repository;

  SetBudgetUseCase({required this.repository});

  Future<void> call(Budget budget) async {
    return await repository.setBudget(budget);
  }
}
