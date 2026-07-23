import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase({required this.repository});

  Future<void> call({String? displayName, String? photoUrl}) async {
    return await repository.updateProfile(displayName: displayName, photoUrl: photoUrl);
  }
}
