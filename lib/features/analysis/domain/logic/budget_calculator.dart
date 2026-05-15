class BudgetCalculator {
  /// Calculates properties for a category budget status.
  (double remaining, double percentage, bool isExceeded) calculateStatusProps(
    double spent,
    double limit,
  ) {
    final remaining = limit - spent;
    final percentage = limit > 0 ? (spent / limit) : 0.0;
    final isExceeded = limit > 0 && spent > limit;
    return (remaining, percentage, isExceeded);
  }

  /// Calculates the ratio of successful budgets to total budgeted categories.
  double calculateAdherenceRatio(int successfulCount, int totalCount) {
    if (totalCount == 0) return 1.0;
    return successfulCount / totalCount;
  }
}
