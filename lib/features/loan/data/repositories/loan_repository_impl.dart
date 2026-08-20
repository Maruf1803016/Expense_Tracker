import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/loan/domain/repositories/loan_repository.dart';
import 'package:expense_tracker/features/loan/data/datasources/loan_remote_data_source.dart';
import 'package:expense_tracker/features/loan/data/models/loan_model.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoanRemoteDataSource remoteDataSource;

  LoanRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<Loan>> getLoansStream() {
    return remoteDataSource.getLoans();
  }

  @override
  Future<void> addLoan(Loan loan) {
    return remoteDataSource.addLoan(LoanModel.fromEntity(loan));
  }

  @override
  Future<void> updateLoan(Loan loan) {
    return remoteDataSource.updateLoan(LoanModel.fromEntity(loan));
  }

  @override
  Future<void> deleteLoan(String id) {
    return remoteDataSource.deleteLoan(id);
  }

  @override
  Future<void> addRepayment(String loanId, LoanRepayment repayment) {
    return remoteDataSource.addRepayment(loanId, LoanRepaymentModel.fromEntity(repayment));
  }

  @override
  Future<void> toggleLoanComplete(String loanId, bool isCompleted) {
    return remoteDataSource.toggleLoanComplete(loanId, isCompleted);
  }
}
