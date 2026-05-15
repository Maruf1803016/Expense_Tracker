import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';

class GetGlobalBudgetUseCase {
  final BudgetRepository repository;

  GetGlobalBudgetUseCase({required this.repository});

  Stream<double> call() {
    return repository.getGlobalMonthlyBudgetStream();
  }
}
