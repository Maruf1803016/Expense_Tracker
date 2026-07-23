import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository repository;

  SettingsProvider({required this.repository});

  String _selectedCurrency = 'USD';
  String get selectedCurrency => _selectedCurrency;

  double _budget = 0.0;
  double get budget => _budget;

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'BDT': '৳',
    'INR': '₹',
    'JPY': '¥',
  };

  String get currentSymbol => currencySymbols[_selectedCurrency] ?? '\$';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final currency = await repository.getCurrency();
      final budget = await repository.getBudget();
      
      _selectedCurrency = currency;
      _budget = budget;
      CurrencyFormatter.setSymbol(currentSymbol);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SettingsProvider: Error loading settings: $e');
      _isLoading = false;
      notifyListeners();
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
      // Log error
    }
  }

  Future<void> setBudget(double amount) async {
    _budget = amount;
    notifyListeners();
    
    try {
      await repository.updateBudget(amount);
    } catch (e) {
      // Log error
    }
  }
}
