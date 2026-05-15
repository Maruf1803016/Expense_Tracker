import 'package:expense_tracker/core/error/exceptions.dart';
import 'package:expense_tracker/core/error/failures.dart';
import 'package:expense_tracker/features/auth/domain/entities/user.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<User?> get userStateStream {
    return remoteDataSource.userStream.map((fbUser) {
      if (fbUser == null) return null;
      return User(id: fbUser.uid, email: fbUser.email ?? '');
    });
  }

  @override
  String? getCurrentUserId() {
    return remoteDataSource.currentUserId;
  }

  @override
  Future<User> signUp(String email, String password) async {
    try {
      final fbUser = await remoteDataSource.signUp(email, password);
      return User(id: fbUser.uid, email: fbUser.email ?? '');
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<User> signIn(String email, String password) async {
    try {
      final fbUser = await remoteDataSource.signIn(email, password);
      return User(id: fbUser.uid, email: fbUser.email ?? '');
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
