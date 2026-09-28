import 'package:listillify/core/result/result.dart';
import 'package:listillify/core/usecases/usecase.dart';
import 'package:listillify/features/auth/domain/repositories/auth_repository.dart';

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Caso de uso que cierra la sesión activa y elimina las credenciales del dispositivo.
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Result<void>> call(NoParams params) async {
    return await repository.logout();
  }
}
