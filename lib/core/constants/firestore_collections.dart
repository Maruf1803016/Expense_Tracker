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

  /// Path to user's goals/plans.
  static String plans(String uid) => 'users/$uid/plans';

  /// Path to user's trip plans.
  static String tripPlans(String uid) => 'users/$uid/tripPlans';

  /// Path to user's debt and loans.
  static String loans(String uid) => 'users/$uid/loans';

  /// Path to user's accounts.
  static String accounts(String uid) => 'users/$uid/accounts';

  /// Path to user's recurring transaction sources.
  static String recurring(String uid) => 'users/$uid/recurringIncomeSources';

  /// Path to user's work routines.
  static String workRoutines(String uid) => 'users/$uid/workRoutines';

  /// Path to user's notification inbox.
  static String notifications(String uid) => 'users/$uid/notifications';
}
