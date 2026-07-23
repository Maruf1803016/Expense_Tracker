abstract class SettingsRepository {
  Future<String> getCurrency();
  Future<void> updateCurrency(String currencyCode);
  Future<double> getBudget();
  Future<void> updateBudget(double budget);
}
