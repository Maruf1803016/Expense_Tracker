import 'package:expense_tracker/features/account/domain/repositories/account_repository.dart';

class DeleteAccountUseCase {
  final AccountRepository repository;

  DeleteAccountUseCase({required this.repository});

  Future<void> call(String id) {
    return repository.deleteAccount(id);
  }
}
