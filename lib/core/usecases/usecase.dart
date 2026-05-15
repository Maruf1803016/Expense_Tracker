/// Base use case interface.
/// Every use case in the domain layer implements this contract.
///
/// [Type] is the return type, [Params] is the input parameter type.
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Use when a use case takes no parameters.
class NoParams {
  const NoParams();
}
