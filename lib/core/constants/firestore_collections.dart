/// Centralized Firestore collection paths with user-scoping.
class FirestoreCollections {
  /// Base path for a specific user's document.
  static String userPath(String uid) => 'users/$uid';

  /// Path to user's expenses.
  static String expenses(String uid) => 'users/$uid/expenses';

  /// Path to user's categories.
  static String categories(String uid) => 'users/$uid/categories';

  /// Path to user's budgets.
  static String budgets(String uid) => 'users/$uid/budgets';
}
