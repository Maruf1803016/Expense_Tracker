import 'package:expense_tracker/features/account/domain/entities/account.dart';

abstract class AccountRepository {
  Stream<List<Account>> getAccountsStream();
  Future<void> addAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);
  Future<void> deleteAccountAndReassign(String id, String fallbackAccountId);
  Future<bool> isMigrationCompleted();
  Future<void> runMigration();
}
