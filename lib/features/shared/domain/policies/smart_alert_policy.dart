class SmartAlertPolicy {
  static const double spikeThreshold = 0.3; // 30% increase
  static const double anomalyMultiplier = 3.0; // 3x average
  static const int trendWindow = 3; // 3 consecutive months
}
