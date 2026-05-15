import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';

class EmptyRecycleBinUseCase {
  final ExpenseRepository repository;

  EmptyRecycleBinUseCase({required this.repository});

  Future<void> call() async {
    return await repository.emptyRecycleBin();
  }
}
