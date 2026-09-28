import 'package:equatable/equatable.dart';
import 'package:listillify/core/result/result.dart';

/// PATRÓN DE DISEÑO: Command Pattern / Use Case Interactor
/// Representa un caso de uso de negocio en Arquitectura Hexagonal.
/// Cada caso de uso tiene una única responsabilidad y se ejecuta mediante su método `call`.
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Representa parámetros vacíos para casos de uso que no requieren argumentos de entrada.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
