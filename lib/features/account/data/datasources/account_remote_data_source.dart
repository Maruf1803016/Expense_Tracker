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

  CollectionReference get _recurringCollection {
    return _userDoc.collection('recurringIncomeSources');
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

  Future<void> _commitInChunks(List<void Function(WriteBatch)> writes) async {
    const chunkSize = 450;
    for (var i = 0; i < writes.length; i += chunkSize) {
      final batch = firestore.batch();
      final chunk = writes.sublist(i, i + chunkSize > writes.length ? writes.length : i + chunkSize);
      for (final write in chunk) {
        write(batch);
      }
      await batch.commit().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw const ServerException(
          'Request timed out. Please check your connection and try again.',
        ),
      );
    }
  }

  @override
  Future<void> deleteAccountAndReassign(String id, String fallbackAccountId) async {
    try {
      final writes = <void Function(WriteBatch)>[];

      // Fetch all expenses linked to the deleted account
      final expensesSnapshot = await _expenseCollection
          .where('accountId', isEqualTo: id)
          .get()
          .timeout(const Duration(seconds: 15));

      for (var doc in expensesSnapshot.docs) {
        writes.add((batch) => batch.update(doc.reference, {'accountId': fallbackAccountId}));
      }

      // Fetch all recurring sources linked to the deleted account
      final recurringSnapshot = await _recurringCollection
          .where('accountId', isEqualTo: id)
          .get()
          .timeout(const Duration(seconds: 15));

      for (var doc in recurringSnapshot.docs) {
        writes.add((batch) => batch.update(doc.reference, {'accountId': fallbackAccountId}));
      }

      // Delete the account document
      writes.add((batch) => batch.delete(_accountCollection.doc(id)));

      await _commitInChunks(writes);
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

      // Find-or-create: reuse an existing default account if a prior partial run already made one.
      final existingDefault = await _accountCollection
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 15));

      final String defaultAccountId;
      final writes = <void Function(WriteBatch)>[];

      if (existingDefault.docs.isNotEmpty) {
        defaultAccountId = existingDefault.docs.first.id;
      } else {
        final defaultAccountRef = _accountCollection.doc();
        defaultAccountId = defaultAccountRef.id;
        final defaultAccount = AccountModel(
          id: defaultAccountId,
          name: 'Main Account',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF12141A),
          initialBalance: 0.0,
          isDefault: true,
          createdAt: DateTime.now(),
        );
        writes.add((batch) => batch.set(defaultAccountRef, defaultAccount.toMap()));
      }

      // Fetch all user expenses
      final expensesSnapshot = await _expenseCollection.get().timeout(const Duration(seconds: 15));
      for (var doc in expensesSnapshot.docs) {
        final expenseData = doc.data() as Map<String, dynamic>?;
        if (expenseData == null || expenseData['accountId'] == null) {
          writes.add((batch) => batch.update(doc.reference, {'accountId': defaultAccountId}));
        }
      }

      // Mark user as migrated
      writes.add((batch) => batch.set(_userDoc, {'accountsMigrated': true}, SetOptions(merge: true)));

      await _commitInChunks(writes);
    } catch (e) {
      throw ServerException('Failed to run account migration: $e');
    }
  }
}
