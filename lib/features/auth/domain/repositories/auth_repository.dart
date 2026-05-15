import '../entities/user.dart';

/// Abstract repository interface for authentication.
abstract class AuthRepository {
  /// Stream of the current user.
  Stream<User?> get userStateStream;

  /// Signs up with email and password.
  Future<User> signUp(String email, String password);

  /// Signs in with email and password.
  Future<User> signIn(String email, String password);

  /// Signs out the current user.
  Future<void> signOut();

  /// Gets the current user ID, if any.
  String? getCurrentUserId();

  /// Updates the user's profile info (display name, photo url).
  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Changes the user's password.
  Future<void> changePassword(String currentPassword, String newPassword);
}
