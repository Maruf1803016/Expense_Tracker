import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  /// Stream of current auth user.
  Stream<firebase_auth.User?> get userStream;

  /// Sign up with email/password.
  Future<firebase_auth.User> signUp(String email, String password);

  /// Sign in with email/password.
  Future<firebase_auth.User> signIn(String email, String password);

  /// Sign out.
  Future<void> signOut();

  /// Get current user ID.
  String? get currentUserId;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({required this.firebaseAuth});

  @override
  Stream<firebase_auth.User?> get userStream => firebaseAuth.authStateChanges();

  @override
  String? get currentUserId => firebaseAuth.currentUser?.uid;

  @override
  Future<firebase_auth.User> signUp(String email, String password) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('Failed to create user account.');
      }
      return credential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'An error occurred during registration.');
    } catch (e) {
      throw ServerException('Unexpected registration error: ${e.toString()}');
    }
  }

  @override
  Future<firebase_auth.User> signIn(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('Failed to sign in.');
      }
      return credential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'An error occurred during login.');
    } catch (e) {
      throw ServerException('Unexpected login error: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw ServerException('Failed to sign out: ${e.toString()}');
    }
  }
}
