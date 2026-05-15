import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Update profile.
  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Change password.
  Future<void> changePassword(String currentPassword, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

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
      
      // Initialize Firestore document
      await firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': '',
        'photoUrl': '',
        'monthlyBudget': 0.0,
      });

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

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw ServerException('User not authenticated');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
        await firestore.collection('users').doc(user.uid).update({'displayName': displayName});
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        await firestore.collection('users').doc(user.uid).update({'photoUrl': photoUrl});
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Failed to update profile');
    } catch (e) {
      throw ServerException('Unexpected error updating profile: $e');
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw ServerException('User not authenticated');

      // Re-authenticate user first (required by Firebase for sensitive actions)
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Failed to change password');
    } catch (e) {
      throw ServerException('Unexpected error changing password: $e');
    }
  }
}
