import 'package:equatable/equatable.dart';
import 'package:listillify/features/auth/domain/entities/user_session.dart';

/// PATRÓN DE DISEÑO: State Pattern
/// Modela los estados de autenticación y sesión de usuario en la aplicación.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial mientras se verifica si hay una sesión guardada.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga mientras se procesa el login, verificación o logout.
final class AuthLoading extends AuthState {
  final String message;

  const AuthLoading({this.message = 'Cargando sesión...'});

  @override
  List<Object?> get props => [message];
}

/// Estado cuando el usuario tiene una sesión activa y autenticada.
final class Authenticated extends AuthState {
  final UserSession session;

  const Authenticated(this.session);

  @override
  List<Object?> get props => [session];
}

/// Estado cuando el usuario no está autenticado o cerró sesión.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Estado de error cuando falla el proceso de autenticación o logout.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
