import 'package:expense_tracker/features/account/domain/repositories/account_repository.dart';

class DeleteAccountAndReassignUseCase {
  final AccountRepository repository;

  DeleteAccountAndReassignUseCase({required this.repository});

  Future<void> call(String id, String fallbackAccountId) {
    return repository.deleteAccountAndReassign(id, fallbackAccountId);
  }
}
