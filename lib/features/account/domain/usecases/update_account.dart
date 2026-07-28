import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/domain/repositories/account_repository.dart';

class UpdateAccountUseCase {
  final AccountRepository repository;

  UpdateAccountUseCase({required this.repository});

  Future<void> call(Account account) {
    return repository.updateAccount(account);
  }
}
