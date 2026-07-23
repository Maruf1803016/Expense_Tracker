import '../entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get userStateStream;
  Future<User> signUp(String email, String password);
  Future<User> signIn(String email, String password);
  Future<void> signOut();
  String? getCurrentUserId();
  Future<void> updateProfile({String? displayName, String? photoUrl});
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> verifyPassword(String password);
}
