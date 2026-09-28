import 'package:equatable/equatable.dart';

/// PATRÓN DE DISEÑO: Entity / Aggregate Root
/// Representa la sesión del usuario autenticado con Spotify.
/// Es inmutable y utiliza Equatable para facilitar comparaciones en tests unitarios.
class UserSession extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  const UserSession({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  /// Determina si el token de acceso actual ha expirado.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Determina si la sesión está activa y con token vigente.
  bool get isAuthenticated => accessToken.isNotEmpty && !isExpired;

  /// Crea una copia inmutable actualizando campos opcionales.
  UserSession copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return UserSession(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        email,
        avatarUrl,
        accessToken,
        refreshToken,
        expiresAt,
      ];
}
