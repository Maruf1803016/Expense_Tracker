import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/loan/data/models/loan_model.dart';

abstract class LoanRemoteDataSource {
  Stream<List<LoanModel>> getLoans();
  Future<void> addLoan(LoanModel loan);
  Future<void> updateLoan(LoanModel loan);
  Future<void> deleteLoan(String id);
  Future<void> addRepayment(String loanId, LoanRepaymentModel repayment);
  Future<void> toggleLoanComplete(String loanId, bool isCompleted);
}

class LoanRemoteDataSourceImpl implements LoanRemoteDataSource {
  final FirebaseFirestore firestore;
  final AuthRemoteDataSource authDataSource;

  LoanRemoteDataSourceImpl({
    required this.firestore,
    required this.authDataSource,
  });

  DocumentReference get _userDoc {
    final userId = authDataSource.currentUserId;
    if (userId == null) throw const ServerException('User not authenticated');
    return firestore.collection('users').doc(userId);
  }

  CollectionReference get _loanCollection {
    return _userDoc.collection('loans');
  }

  Future<T> _executeWithRetry<T>(Future<T> Function(Duration timeout) operation) async {
    try {
      return await operation(const Duration(seconds: 8));
    } catch (e1) {
      debugPrint('[LoanRemoteDataSource] First attempt failed: $e1. Retrying in 1 second...');
      await Future.delayed(const Duration(seconds: 1));
      try {
        return await operation(const Duration(seconds: 8));
      } catch (e2) {
        if (e2 is TimeoutException) {
          throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          );
        }
        rethrow;
      }
    }
  }

  @override
  Stream<List<LoanModel>> getLoans() {
    return _loanCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LoanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addLoan(LoanModel loan) async {
    try {
      await _executeWithRetry((timeout) {
        return _loanCollection.doc(loan.id).set(loan.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to add loan: $e');
    }
  }

  @override
  Future<void> updateLoan(LoanModel loan) async {
    try {
      await _executeWithRetry((timeout) {
        return _loanCollection.doc(loan.id).update(loan.toMap()).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to update loan: $e');
    }
  }

  @override
  Future<void> deleteLoan(String id) async {
    try {
      await _executeWithRetry((timeout) {
        return _loanCollection.doc(id).delete().timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to delete loan: $e');
    }
  }

  @override
  Future<void> addRepayment(String loanId, LoanRepaymentModel repayment) async {
    try {
      await _executeWithRetry((timeout) async {
        final docRef = _loanCollection.doc(loanId);
        return firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) {
            throw const ServerException('Loan not found');
          }
          final data = snapshot.data() as Map<String, dynamic>;
          final currentPaid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
          final originalAmount = (data['originalAmount'] as num).toDouble();
          final newPaid = currentPaid + repayment.amount;
          final isCompleted = newPaid >= originalAmount;

          final repayments = (data['repayments'] as List<dynamic>? ?? [])
              .map((r) => r as Map<String, dynamic>)
              .toList();
          repayments.add(repayment.toMap());

          transaction.update(docRef, {
            'paidAmount': newPaid,
            'isCompleted': isCompleted,
            'repayments': repayments,
          });
        }).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to add repayment: $e');
    }
  }

  @override
  Future<void> toggleLoanComplete(String loanId, bool isCompleted) async {
    try {
      await _executeWithRetry((timeout) {
        return _loanCollection.doc(loanId).update({'isCompleted': isCompleted}).timeout(
          timeout,
          onTimeout: () => throw const ServerException(
            'Request timed out. Please check your connection and try again.',
          ),
        );
      });
    } catch (e) {
      throw ServerException('Failed to update loan status: $e');
    }
  }
}
