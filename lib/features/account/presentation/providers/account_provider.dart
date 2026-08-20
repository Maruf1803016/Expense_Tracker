import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/features/account/domain/usecases/get_accounts.dart';
import 'package:expense_tracker/features/account/domain/usecases/add_account.dart';
import 'package:expense_tracker/features/account/domain/usecases/update_account.dart';
import 'package:expense_tracker/features/account/domain/usecases/delete_account_and_reassign.dart';
import 'package:expense_tracker/features/account/domain/usecases/run_migration.dart';

class AccountProvider with ChangeNotifier {
  final GetAccountsUseCase getAccounts;
  final AddAccountUseCase addAccountUseCase;
  final UpdateAccountUseCase updateAccountUseCase;
  final DeleteAccountAndReassignUseCase deleteAccountAndReassignUseCase;
  final RunAccountMigrationUseCase runAccountMigration;

  AccountProvider({
    required this.getAccounts,
    required this.addAccountUseCase,
    required this.updateAccountUseCase,
    required this.deleteAccountAndReassignUseCase,
    required this.runAccountMigration,
  });

  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  Account? getAccountById(String id) {
    return _accounts.where((a) => a.id == id).firstOrNull;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _accountsSubscription;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Run the Firestore migration first
      await runAccountMigration();
    } catch (e) {
      // Migration failure shouldn't block the user from seeing/using existing accounts.
      _errorMessage = e.toString();
    }

    _accountsSubscription?.cancel();
    _accountsSubscription = getAccounts().listen(
      (list) {
        _accounts = List<Account>.from(list);
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void clear() {
    _accountsSubscription?.cancel();
    _accountsSubscription = null;
    _accounts = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> add(Account account) async {
    try {
      await addAccountUseCase(account);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Account account) async {
    try {
      await updateAccountUseCase(account);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String id, String fallbackAccountId) async {
    try {
      await deleteAccountAndReassignUseCase(id, fallbackAccountId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    super.dispose();
  }
}
