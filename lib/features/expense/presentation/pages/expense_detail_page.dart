import 'package:flutter/material.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/pages/transaction_detail_page.dart';

/// Backward-compatible wrapper delegating to [TransactionDetailPage].
class ExpenseDetailPage extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailPage({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return TransactionDetailPage(expenseId: expense.id);
  }
}
