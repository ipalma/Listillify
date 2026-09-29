import 'package:equatable/equatable.dart';

/// PATRÓN DE DISEÑO: Value Object / Entity
/// Representa la configuración necesaria para acceder a la API de Spotify (Client ID y Client Secret).
/// Es inmutable y utiliza Equatable para comparación por valor.
class ApiConfig extends Equatable {
  final String clientId;
  final String clientSecret;
  final String? customRedirectUri;

  const ApiConfig({
    required this.clientId,
    this.clientSecret = '',
    this.customRedirectUri,
  });

  /// Instancia vacía o por defecto cuando no hay configuración previa.
  const ApiConfig.empty()
      : clientId = '',
        clientSecret = '',
        customRedirectUri = null;

  /// Valida si el Client ID y el Client Secret tienen valores válidos no vacíos.
  bool get isValid => clientId.trim().isNotEmpty && clientSecret.trim().isNotEmpty;

  /// Copia inmutable con modificaciones opcionales.
  ApiConfig copyWith({
    String? clientId,
    String? clientSecret,
    String? customRedirectUri,
  }) {
    return ApiConfig(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      customRedirectUri: customRedirectUri ?? this.customRedirectUri,
    );
  }

  @override
  List<Object?> get props => [clientId, clientSecret, customRedirectUri];
}
