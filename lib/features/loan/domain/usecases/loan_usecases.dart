import 'package:expense_tracker/features/loan/domain/entities/loan.dart';
import 'package:expense_tracker/features/loan/domain/repositories/loan_repository.dart';

class GetLoansStreamUseCase {
  final LoanRepository repository;
  GetLoansStreamUseCase(this.repository);

  Stream<List<Loan>> call() {
    return repository.getLoansStream();
  }
}

class AddLoanUseCase {
  final LoanRepository repository;
  AddLoanUseCase(this.repository);

  Future<void> call(Loan loan) {
    return repository.addLoan(loan);
  }
}

class UpdateLoanUseCase {
  final LoanRepository repository;
  UpdateLoanUseCase(this.repository);

  Future<void> call(Loan loan) {
    return repository.updateLoan(loan);
  }
}

class DeleteLoanUseCase {
  final LoanRepository repository;
  DeleteLoanUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteLoan(id);
  }
}

class AddLoanRepaymentUseCase {
  final LoanRepository repository;
  AddLoanRepaymentUseCase(this.repository);

  Future<void> call(String loanId, LoanRepayment repayment) {
    return repository.addRepayment(loanId, repayment);
  }
}

class ToggleLoanCompleteUseCase {
  final LoanRepository repository;
  ToggleLoanCompleteUseCase(this.repository);

  Future<void> call(String loanId, bool isCompleted) {
    return repository.toggleLoanComplete(loanId, isCompleted);
  }
}
