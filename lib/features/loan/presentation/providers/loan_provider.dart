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
        if (list.isEmpty) {
          final sampleLoan = Loan(
            id: 'loan_1',
            title: 'Equipment Loan',
            counterparty: 'Tech Supplies Co',
            type: LoanType.borrowed,
            originalAmount: 5000.0,
            paidAmount: 2000.0,
            dueDate: DateTime(2026, 12, 31),
            notes: '0% interest 12-month installment',
            createdAt: DateTime(2026, 6, 1),
            repayments: [
              LoanRepayment(
                id: 'rep_1',
                amount: 2000.0,
                date: DateTime(2026, 7, 15),
                note: 'Initial installment',
              ),
            ],
          );
          repository.addLoan(sampleLoan);
        }
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
