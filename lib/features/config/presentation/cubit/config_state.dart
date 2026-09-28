import 'package:equatable/equatable.dart';
import 'package:listillify/features/config/domain/entities/api_config.dart';

/// PATRÓN DE DISEÑO: State Pattern
/// Representa los diferentes estados posibles de la interfaz de configuración.
sealed class ConfigState extends Equatable {
  const ConfigState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial al iniciar la pantalla o cubit.
final class ConfigInitial extends ConfigState {
  const ConfigInitial();
}

/// Estado de carga mientras se lee o guarda la configuración.
final class ConfigLoading extends ConfigState {
  const ConfigLoading();
}

/// Estado con la configuración cargada exitosamente.
final class ConfigLoaded extends ConfigState {
  final ApiConfig config;

  const ConfigLoaded(this.config);

  @override
  List<Object?> get props => [config];
}

/// Estado emitido tras guardar satisfactoriamente la configuración.
final class ConfigSavedSuccess extends ConfigState {
  final ApiConfig config;

  const ConfigSavedSuccess(this.config);

  @override
  List<Object?> get props => [config];
}

/// Estado cuando ocurre un error de validación o persistencia.
final class ConfigError extends ConfigState {
  final String message;

  const ConfigError(this.message);

  @override
  List<Object?> get props => [message];
}
