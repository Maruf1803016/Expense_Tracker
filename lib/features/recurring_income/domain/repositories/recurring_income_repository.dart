import 'package:expense_tracker/features/recurring_income/domain/entities/recurring_income_source.dart';

abstract class RecurringIncomeRepository {
  Stream<List<RecurringIncomeSource>> getRecurringIncomeSourcesStream();
  Future<void> addRecurringIncomeSource(RecurringIncomeSource source);
  Future<void> updateRecurringIncomeSource(RecurringIncomeSource source);
  Future<void> deleteRecurringIncomeSource(String id);
}
