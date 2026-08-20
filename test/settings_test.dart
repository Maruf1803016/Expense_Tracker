import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/providers/settings_provider.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/shared/presentation/widgets/currency_picker_sheet.dart';

class MockSettingsRepository implements SettingsRepository {
  String _currency = 'USD';

  @override
  Future<String> getCurrency() async => _currency;

  @override
  Future<void> updateCurrency(String currencyCode) async {
    _currency = currencyCode;
  }
}

void main() {
  group('Settings & Currency Tests', () {
    test('SettingsProvider updates currency and symbol correctly', () async {
      final repo = MockSettingsRepository();
      final provider = SettingsProvider(repository: repo);

      await provider.loadSettings();
      expect(provider.selectedCurrency, 'USD');
      expect(provider.currentSymbol, '\$');

      await provider.updateCurrency('BDT');
      expect(provider.selectedCurrency, 'BDT');
      expect(provider.currentSymbol, '৳');

      await provider.updateCurrency('EUR');
      expect(provider.selectedCurrency, 'EUR');
      expect(provider.currentSymbol, '€');
    });

    test('CurrencyPickerSheet list contains supported global currencies', () {
      final codes = CurrencyPickerSheet.allCurrencies.map((c) => c.code).toSet();
      expect(codes.contains('USD'), true);
      expect(codes.contains('EUR'), true);
      expect(codes.contains('BDT'), true);
      expect(codes.contains('INR'), true);
      expect(codes.contains('GBP'), true);
      expect(codes.contains('SAR'), true);
      expect(codes.contains('AED'), true);
    });

    test('SettingsProvider handles preferences correctly', () {
      final repo = MockSettingsRepository();
      final provider = SettingsProvider(repository: repo);

      expect(provider.is24HourTime, false);
      provider.toggleTimeFormat(true);
      expect(provider.is24HourTime, true);

      expect(provider.startDayOfWeek, 1); // Monday
      provider.setStartDayOfWeek(7); // Sunday
      expect(provider.startDayOfWeek, 7);

      expect(provider.financialYearStartMonth, 1); // January
      provider.setFinancialYearStartMonth(4); // April
      expect(provider.financialYearStartMonth, 4);
    });
  });
}
