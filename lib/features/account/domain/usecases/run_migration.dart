import 'package:expense_tracker/features/account/domain/repositories/account_repository.dart';

class RunAccountMigrationUseCase {
  final AccountRepository repository;

  RunAccountMigrationUseCase({required this.repository});

  Future<void> call() {
    return repository.runMigration();
  }
}
