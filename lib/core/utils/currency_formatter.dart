import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

/// Currency formatting utility methods.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Format a double as currency: "$1,234.56"
  static String format(double amount) {
    return _formatter.format(amount);
  }
}
