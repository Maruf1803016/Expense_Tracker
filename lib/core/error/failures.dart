import 'package:equatable/equatable.dart';

/// Base failure class for error handling across layers.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure from Firestore operations
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

/// Failure from invalid input data
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input data.']);
}
/// Failure when trying to delete a category used by expenses
class CategoryInUseFailure extends Failure {
  const CategoryInUseFailure([super.message = 'This category is in use by expenses and cannot be deleted.']);
}
