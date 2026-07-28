import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/account/data/models/account_model.dart';
import 'package:flutter/material.dart';

abstract class AccountRemoteDataSource {
  Stream<List<AccountModel>> getAccounts();
  Future<void> addAccount(AccountModel account);
  Future<void> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);
  Future<void> deleteAccountAndReassign(String id, String fallbackAccountId);
  Future<bool> isMigrationCompleted();
  Future<void> runMigration();
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  AccountRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _accountCollection {
    return _userDoc.collection('accounts');
  }

  CollectionReference get _expenseCollection {
    return _userDoc.collection('expenses');
  }

  @override
  Stream<List<AccountModel>> getAccounts() {
    return _accountCollection.orderBy('createdAt', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addAccount(AccountModel account) async {
    try {
      await _accountCollection.add(account.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to add account: $e');
    }
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    try {
      await _accountCollection.doc(account.id).update(account.toMap()).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to update account: $e');
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await _accountCollection.doc(id).delete().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to delete account: $e');
    }
  }

  @override
  Future<void> deleteAccountAndReassign(String id, String fallbackAccountId) async {
    try {
      final batch = firestore.batch();

      // Fetch all expenses linked to the deleted account
      final expensesSnapshot = await _expenseCollection
          .where('accountId', isEqualTo: id)
          .get()
          .timeout(const Duration(seconds: 15));

      for (var doc in expensesSnapshot.docs) {
        batch.update(doc.reference, {'accountId': fallbackAccountId});
      }

      // Delete the account document
      batch.delete(_accountCollection.doc(id));

      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to delete account with reassignment: $e');
    }
  }

  @override
  Future<bool> isMigrationCompleted() async {
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['accountsMigrated'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> runMigration() async {
    try {
      final userSnapshot = await _userDoc.get().timeout(const Duration(seconds: 15));
      if (!userSnapshot.exists) return;
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final isMigrated = userData?['accountsMigrated'] as bool? ?? false;
      if (isMigrated) return;

      final batch = firestore.batch();

      // Create default account doc
      final defaultAccountRef = _accountCollection.doc();
      final defaultAccountId = defaultAccountRef.id;

      final defaultAccount = AccountModel(
        id: defaultAccountId,
        name: 'Main Account',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF12141A),
        initialBalance: 0.0,
        isDefault: true,
        createdAt: DateTime.now(),
      );

      batch.set(defaultAccountRef, defaultAccount.toMap());

      // Fetch all user expenses
      final expensesSnapshot = await _expenseCollection.get().timeout(const Duration(seconds: 15));
      for (var doc in expensesSnapshot.docs) {
        final expenseData = doc.data() as Map<String, dynamic>?;
        if (expenseData == null || expenseData['accountId'] == null) {
          batch.update(doc.reference, {'accountId': defaultAccountId});
        }
      }

      // Mark user as migrated
      batch.set(_userDoc, {'accountsMigrated': true}, SetOptions(merge: true));

      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to run account migration: $e');
    }
  }
}
