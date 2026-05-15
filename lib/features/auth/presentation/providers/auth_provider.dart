import 'dart:async';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/auth/domain/entities/user.dart';
import 'package:expense_tracker/features/auth/domain/usecases/auth_usecases.dart';
import 'package:expense_tracker/features/auth/domain/usecases/update_profile.dart';
import 'package:expense_tracker/features/auth/domain/usecases/change_password.dart';
import 'package:expense_tracker/core/utils/messenger_utils.dart';

class AuthProvider with ChangeNotifier {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final AuthStateStreamUseCase _authStateStream;
  final UpdateProfileUseCase _updateProfile;
  final ChangePasswordUseCase _changePassword;

  AuthProvider({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required AuthStateStreamUseCase authStateStream,
    required UpdateProfileUseCase updateProfile,
    required ChangePasswordUseCase changePassword,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _authStateStream = authStateStream,
        _updateProfile = updateProfile,
        _changePassword = changePassword;
// ... (omitted lines)
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    _setLoading(true);
    try {
      await _updateProfile(displayName: displayName, photoUrl: photoUrl);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      await _changePassword(currentPassword, newPassword);
      MessengerUtils.showSnackBar('Password updated successfully');
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  User? _user;
  User? get user => _user;

  bool _isLoading = true; 
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<User?>? _authStateSubscription;

  void init() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authStateStream().listen((user) {
      // 🕵️ System Hardening: If user becomes null, it means we logged out.
      // The AuthWrapper handles the navigation, but we ensure state is local.
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _signIn(email, password);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _signUp(email, password);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔐 Hardened SignOut
  /// Resets local user state immediately to avoid UI delay.
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _signOut();
      _user = null; // Guard against stream latency
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message.replaceAll('ServerFailure: ', '');
    MessengerUtils.showErrorSnackBar(_errorMessage!);
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
