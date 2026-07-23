import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase({required this.repository});

  Future<void> call(String currentPassword, String newPassword) async {
    return await repository.changePassword(currentPassword, newPassword);
  }
}
