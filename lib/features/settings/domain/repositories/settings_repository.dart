abstract class SettingsRepository {
  Future<String> getCurrency();
  Future<void> updateCurrency(String currencyCode);
}
