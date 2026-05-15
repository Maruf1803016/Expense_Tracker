import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';

class DeleteForeverUseCase {
  final ExpenseRepository repository;

  DeleteForeverUseCase({required this.repository});

  Future<void> call(String id) async {
    return await repository.deleteForever(id);
  }
}
