import '../../../../core/error/failures.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../repositories/category_repository.dart';

class DeleteCategoryUseCase {
  final CategoryRepository categoryRepository;
  final ExpenseRepository expenseRepository;

  DeleteCategoryUseCase({
    required this.categoryRepository,
    required this.expenseRepository,
  });

  /// Deletes a category only if it's not being used by any expenses.
  Future<void> call(String categoryId) async {
    // 1. Get current expenses
    // Note: Since everything is stream-based, we get the current snapshot
    // of the expenses stream to check for usage.
    final expensesStream = expenseRepository.getExpensesStream();
    final currentExpenses = await expensesStream.first;

    // 2. Check if any expense uses this categoryId
    final isUsed = currentExpenses.any((expense) => expense.categoryId == categoryId);

    if (isUsed) {
      throw const CategoryInUseFailure();
    }

    // 3. If not used, proceed with deletion
    return await categoryRepository.deleteCategory(categoryId);
  }
}
