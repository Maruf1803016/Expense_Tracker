import 'package:expense_tracker/features/loan/domain/entities/loan.dart';

abstract class LoanRepository {
  Stream<List<Loan>> getLoansStream();
  Future<void> addLoan(Loan loan);
  Future<void> updateLoan(Loan loan);
  Future<void> deleteLoan(String id);
  Future<void> addRepayment(String loanId, LoanRepayment repayment);
  Future<void> toggleLoanComplete(String loanId, bool isCompleted);
}
