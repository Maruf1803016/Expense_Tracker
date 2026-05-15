/// Firestore collection names and app-wide constants
class AppConstants {
  AppConstants._();

  // Firestore Collections
  static const String expensesCollection = 'expenses';
  static const String categoriesCollection = 'categories';

  // Default currency
  static const String defaultCurrency = 'USD';
  static const String currencySymbol = '\$';

  // Date formats
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String monthYearFormat = 'MMMM yyyy';
}
