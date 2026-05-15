import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;
  SignInUseCase({required this.repository});

  Future<User> call(String email, String password) async {
    return await repository.signIn(email, password);
  }
}

class SignUpUseCase {
  final AuthRepository repository;
  SignUpUseCase({required this.repository});

  Future<User> call(String email, String password) async {
    return await repository.signUp(email, password);
  }
}

class SignOutUseCase {
  final AuthRepository repository;
  SignOutUseCase({required this.repository});

  Future<void> call() async {
    return await repository.signOut();
  }
}

class AuthStateStreamUseCase {
  final AuthRepository repository;
  AuthStateStreamUseCase({required this.repository});

  Stream<User?> call() {
    return repository.userStateStream;
  }
}

class GetCurrentUserIdUseCase {
  final AuthRepository repository;
  GetCurrentUserIdUseCase({required this.repository});

  String? call() {
    return repository.getCurrentUserId();
  }
}
