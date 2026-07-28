import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/domain/repositories/account_repository.dart';

class GetAccountsUseCase {
  final AccountRepository repository;

  GetAccountsUseCase({required this.repository});

  Stream<List<Account>> call() {
    return repository.getAccountsStream();
  }
}
