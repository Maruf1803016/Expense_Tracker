import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/domain/repositories/account_repository.dart';

class AddAccountUseCase {
  final AccountRepository repository;

  AddAccountUseCase({required this.repository});

  Future<void> call(Account account) {
    return repository.addAccount(account);
  }
}
