class AnomalyDetector {
  /// Detects if spending has spiked significantly above a threshold.
  bool isAboveThreshold(double current, double previous, double threshold) {
    if (previous == 0) return false;
    return current > (previous * (1 + threshold));
  }

  /// Detects if a value is an outlier compared to an average.
  bool isOutlier(double value, double average, double multiplier) {
    if (average == 0) return false;
    return value > (average * multiplier);
  }
}
