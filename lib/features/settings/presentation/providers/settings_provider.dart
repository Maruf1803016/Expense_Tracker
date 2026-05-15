import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository repository;

  SettingsProvider({required this.repository});

  String _selectedCurrency = 'USD';
  String get selectedCurrency => _selectedCurrency;

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'BDT': '৳',
    'INR': '₹',
    'JPY': '¥',
  };

  String get currentSymbol => currencySymbols[_selectedCurrency] ?? '\$';

  Future<void> loadSettings() async {
    try {
      _selectedCurrency = await repository.getCurrency();
      CurrencyFormatter.setSymbol(currentSymbol);
      notifyListeners();
    } catch (e) {
      // Default to USD if error
      _selectedCurrency = 'USD';
      CurrencyFormatter.setSymbol('\$');
    }
  }

  Future<void> updateCurrency(String currencyCode) async {
    if (_selectedCurrency == currencyCode) return;
    
    _selectedCurrency = currencyCode;
    CurrencyFormatter.setSymbol(currentSymbol);
    notifyListeners();
    
    try {
      await repository.updateCurrency(currencyCode);
    } catch (e) {
      // Log error or handle
    }
  }
}
