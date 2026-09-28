import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';
import 'package:listillify/features/auth/domain/repositories/auth_repository.dart';

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Caso de uso que recupera la sesión activa persistida en almacenamiento seguro.
class GetCurrentSessionUseCase implements UseCase<UserSession?, NoParams> {
  final AuthRepository repository;

  GetCurrentSessionUseCase(this.repository);

  @override
  Future<Result<UserSession?>> call(NoParams params) async {
    return await repository.getCurrentSession();
  }
}
