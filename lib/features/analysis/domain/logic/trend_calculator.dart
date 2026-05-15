class TrendCalculator {
  /// Calculates the raw percentage change between two values.
  double calculatePercentageChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  /// Calculates the delta between two values.
  double calculateDelta(double current, double previous) {
    return current - previous;
  }
}
