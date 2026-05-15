import 'package:intl/intl.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

/// Date formatting utility methods.
class DateFormatter {
  DateFormatter._();

  /// Format date for display: "Jan 15, 2026"
  static String format(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  /// Format as month/year: "January 2026"
  static String monthYear(DateTime date) {
    return DateFormat(AppConstants.monthYearFormat).format(date);
  }

  /// Get the start of a month.
  static DateTime startOfMonth(int year, int month) {
    return DateTime(year, month, 1);
  }

  /// Get the end of a month.
  static DateTime endOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }
}
