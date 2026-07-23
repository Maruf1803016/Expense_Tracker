import 'package:intl/intl.dart';

/// Currency formatting utility methods.
class CurrencyFormatter {
  CurrencyFormatter._();

  static String _currentSymbol = '\$';

  /// Sets the current currency symbol.
  static void setSymbol(String symbol) {
    _currentSymbol = symbol;
  }

  /// Gets the current currency symbol.
  static String get currentSymbol => _currentSymbol;

  /// Format a double as currency: "$1,234.56"
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      symbol: _currentSymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format a double as compact currency: "$1.2K"
  static String formatCompact(double amount) {
    final formatter = NumberFormat.compactCurrency(symbol: _currentSymbol);
    return formatter.format(amount);
  }
}
