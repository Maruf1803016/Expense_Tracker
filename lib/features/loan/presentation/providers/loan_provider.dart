import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/loan/domain/repositories/loan_repository.dart';

class LoanProvider with ChangeNotifier {
  final LoanRepository repository;

  List<Loan> _loans = [];
  List<Loan> get loans => _loans;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<Loan>>? _loansSubscription;

  LoanProvider({required this.repository});

  void init() {
    _isLoading = true;
    notifyListeners();

    _loansSubscription?.cancel();
    _loansSubscription = repository.getLoansStream().listen(
      (list) {
        _loans = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[LoanProvider] Error loading loans: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  List<Loan> get activeLoans => _loans.where((l) => !l.isCompleted).toList();
  List<Loan> get completedLoans => _loans.where((l) => l.isCompleted).toList();

  double get totalLent => _loans
      .where((l) => l.type == LoanType.lent && !l.isCompleted)
      .fold(0.0, (sum, l) => sum + l.remainingAmount);

  double get totalBorrowed => _loans
      .where((l) => l.type == LoanType.borrowed && !l.isCompleted)
      .fold(0.0, (sum, l) => sum + l.remainingAmount);

  double get netLoanBalance => totalLent - totalBorrowed;

  Future<void> add(Loan loan) async {
    try {
      await repository.addLoan(loan);
    } catch (e) {
      debugPrint('[LoanProvider] Error adding loan: $e');
      rethrow;
    }
  }

  Future<void> update(Loan loan) async {
    try {
      await repository.updateLoan(loan);
    } catch (e) {
      debugPrint('[LoanProvider] Error updating loan: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.deleteLoan(id);
    } catch (e) {
      debugPrint('[LoanProvider] Error deleting loan: $e');
      rethrow;
    }
  }

  Future<void> addRepayment(String loanId, LoanRepayment repayment) async {
    try {
      await repository.addRepayment(loanId, repayment);
    } catch (e) {
      debugPrint('[LoanProvider] Error adding repayment: $e');
      rethrow;
    }
  }

  Future<void> toggleComplete(String loanId, bool isCompleted) async {
    try {
      await repository.toggleLoanComplete(loanId, isCompleted);
    } catch (e) {
      debugPrint('[LoanProvider] Error toggling loan status: $e');
      rethrow;
    }
  }

  void clear() {
    _loansSubscription?.cancel();
    _loansSubscription = null;
    _loans = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _loansSubscription?.cancel();
    super.dispose();
  }
}
