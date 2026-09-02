import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/currency_data.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository repository;

  SettingsProvider({required this.repository});

  String _selectedCurrency = 'BDT';
  String get selectedCurrency => _selectedCurrency;

  String? _customSymbol;
  String? get customSymbol => _customSymbol;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

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

  bool _hideAmounts = false;
  bool get hideAmounts => _hideAmounts;

  bool _hapticFeedbackEnabled = true;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get hapticsEnabled => _hapticFeedbackEnabled;

  String get currentSymbol {
    if (_customSymbol != null && _customSymbol!.trim().isNotEmpty) {
      return _customSymbol!;
    }
    final match = kWorldCurrencies.where((c) => c.code == _selectedCurrency).firstOrNull;
    if (match != null) return match.symbol;
    return '\$';
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final currency = await repository.getCurrency();
      _selectedCurrency = currency.isNotEmpty ? currency : 'BDT';

      final prefs = await SharedPreferences.getInstance();
      _customSymbol = prefs.getString('custom_currency_symbol');
      _hideAmounts = prefs.getBool('hide_amounts') ?? false;
      _isDailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      _hapticFeedbackEnabled = prefs.getBool('haptic_feedback_enabled') ?? true;
      HapticsService.isEnabled = _hapticFeedbackEnabled;
      
      final themeModeStr = prefs.getString('theme_mode') ?? 'light';
      if (themeModeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (themeModeStr == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }

      final reminderHour = prefs.getInt('reminder_hour');
      final reminderMinute = prefs.getInt('reminder_minute');
      if (reminderHour != null && reminderMinute != null) {
        _reminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
      }

      CurrencyFormatter.setSymbol(currentSymbol);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SettingsProvider: Error loading settings: $e');
      CurrencyFormatter.setSymbol(currentSymbol);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'light';
      if (mode == ThemeMode.dark) modeStr = 'dark';
      if (mode == ThemeMode.system) modeStr = 'system';
      await prefs.setString('theme_mode', modeStr);
    } catch (e) {
      debugPrint('Error saving theme_mode: $e');
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> updateCurrency(String currencyCode, {String? customSymbol}) async {
    final previousCurrency = _selectedCurrency;
    final previousCustomSymbol = _customSymbol;
    
    _selectedCurrency = currencyCode;
    _customSymbol = customSymbol;
    CurrencyFormatter.setSymbol(currentSymbol);
    notifyListeners();
    
    try {
      await repository.updateCurrency(currencyCode);
      final prefs = await SharedPreferences.getInstance();
      if (customSymbol != null && customSymbol.isNotEmpty) {
        await prefs.setString('custom_currency_symbol', customSymbol);
      } else {
        await prefs.remove('custom_currency_symbol');
      }
    } catch (e) {
      _selectedCurrency = previousCurrency;
      _customSymbol = previousCustomSymbol;
      CurrencyFormatter.setSymbol(currentSymbol);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setCustomCurrencySymbol(String symbol) async {
    _customSymbol = symbol.trim().isEmpty ? null : symbol.trim();
    CurrencyFormatter.setSymbol(currentSymbol);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_customSymbol != null) {
      await prefs.setString('custom_currency_symbol', _customSymbol!);
    } else {
      await prefs.remove('custom_currency_symbol');
    }
  }

  Future<void> toggleHapticFeedback(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    HapticsService.isEnabled = enabled;
    notifyListeners();
    if (enabled) {
      HapticsService.selection();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptic_feedback_enabled', enabled);
  }

  Future<void> toggleHaptics(bool enabled) => toggleHapticFeedback(enabled);

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

  Future<void> toggleDailyReminder(bool enabled) async {
    _isDailyReminderEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', enabled);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);
  }

  Future<void> toggleHideAmounts([bool? hide]) async {
    _hideAmounts = hide ?? !_hideAmounts;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_amounts', _hideAmounts);
  }
}
