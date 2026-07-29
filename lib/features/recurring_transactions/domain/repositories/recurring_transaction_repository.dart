import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_transaction_source.dart';

abstract class RecurringTransactionRepository {
  Stream<List<RecurringTransactionSource>> getRecurringTransactionSourcesStream();
  Future<void> addRecurringTransactionSource(RecurringTransactionSource source);
  Future<void> updateRecurringTransactionSource(RecurringTransactionSource source);
  Future<void> deleteRecurringTransactionSource(String id);
}
