import 'package:equatable/equatable.dart';

/// PATRÓN DE DISEÑO: Value Object / Entity
/// Representa la configuración necesaria para acceder a la API de Spotify.
/// Es inmutable y utiliza Equatable para comparación por valor.
class ApiConfig extends Equatable {
  final String clientId;
  final String? customRedirectUri;

  const ApiConfig({
    required this.clientId,
    this.customRedirectUri,
  });

  /// Instancia vacía o por defecto cuando no hay configuración previa.
  const ApiConfig.empty()
      : clientId = '',
        customRedirectUri = null;

  /// Valida si el Client ID tiene un formato aparentemente válido (no vacío y sin espacios).
  bool get isValid => clientId.trim().isNotEmpty;

  /// Copia inmutable con modificaciones opcionales.
  ApiConfig copyWith({
    String? clientId,
    String? customRedirectUri,
  }) {
    return ApiConfig(
      clientId: clientId ?? this.clientId,
      customRedirectUri: customRedirectUri ?? this.customRedirectUri,
    );
  }

  @override
  List<Object?> get props => [clientId, customRedirectUri];
}
