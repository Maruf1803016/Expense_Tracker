import 'package:expense_tracker/features/account/data/datasources/account_remote_data_source.dart';
import 'package:expense_tracker/features/account/data/models/account_model.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;

  AccountRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Account>> getAccountsStream() {
    return remoteDataSource.getAccounts();
  }

  @override
  Future<void> addAccount(Account account) {
    return remoteDataSource.addAccount(AccountModel.fromEntity(account));
  }

  @override
  Future<void> updateAccount(Account account) {
    return remoteDataSource.updateAccount(AccountModel.fromEntity(account));
  }

  @override
  Future<void> deleteAccount(String id) {
    return remoteDataSource.deleteAccount(id);
  }

  @override
  Future<void> deleteAccountAndReassign(String id, String fallbackAccountId) {
    return remoteDataSource.deleteAccountAndReassign(id, fallbackAccountId);
  }

  @override
  Future<bool> isMigrationCompleted() {
    return remoteDataSource.isMigrationCompleted();
  }

  @override
  Future<void> runMigration() {
    return remoteDataSource.runMigration();
  }
}
