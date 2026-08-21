import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository repository;

  SettingsProvider({required this.repository});

  String _selectedCurrency = 'USD';
  String get selectedCurrency => _selectedCurrency;

  bool _is24HourTime = false;
  bool get is24HourTime => _is24HourTime;

  int _startDayOfWeek = DateTime.monday; // 1 = Monday ... 7 = Sunday
  int get startDayOfWeek => _startDayOfWeek;

  int _financialYearStartMonth = 1; // 1 = January
  int get financialYearStartMonth => _financialYearStartMonth;

  bool _isDailyReminderEnabled = false;
  bool get isDailyReminderEnabled => _isDailyReminderEnabled;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay get reminderTime => _reminderTime;

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'BDT': '৳',
    'INR': '₹',
    'CAD': 'CA\$',
    'AUD': 'AU\$',
    'JPY': '¥',
    'SAR': '﷼',
    'AED': 'د.إ',
    'CHF': 'CHF',
    'CNY': '¥',
    'SGD': 'S\$',
    'MYR': 'RM',
    'PKR': '₨',
    'NGN': '₦',
    'BRL': 'R\$',
    'ZAR': 'R',
    'TRY': '₺',
    'KRW': '₩',
  };

  String get currentSymbol => currencySymbols[_selectedCurrency] ?? '\$';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final currency = await repository.getCurrency();
      _selectedCurrency = currency;
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
    
    final previousCurrency = _selectedCurrency;
    _selectedCurrency = currencyCode;
    CurrencyFormatter.setSymbol(currentSymbol);
    notifyListeners();
    
    try {
      await repository.updateCurrency(currencyCode);
    } catch (e) {
      _selectedCurrency = previousCurrency;
      CurrencyFormatter.setSymbol(currentSymbol);
      notifyListeners();
      rethrow;
    }
  }

  void toggleTimeFormat(bool is24Hour) {
    _is24HourTime = is24Hour;
    notifyListeners();
  }

  void setStartDayOfWeek(int day) {
    _startDayOfWeek = day;
    notifyListeners();
  }

  void setFinancialYearStartMonth(int month) {
    _financialYearStartMonth = month;
    notifyListeners();
  }

  void toggleDailyReminder(bool enabled) {
    _isDailyReminderEnabled = enabled;
    notifyListeners();
  }

  void setReminderTime(TimeOfDay time) {
    _reminderTime = time;
    notifyListeners();
  }
}
