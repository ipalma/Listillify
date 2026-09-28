import 'package:equatable/equatable.dart';

/// PATRÓN DE DISEÑO: Value Object
/// Representa el resultado de procesar una línea de texto introducida por el usuario.
class ParsedQuery extends Equatable {
  final String rawText;
  final String query;
  final String? directUri;
  final int lineNumber;

  const ParsedQuery({
    required this.rawText,
    required this.query,
    this.directUri,
    required this.lineNumber,
  });

  /// Indica si la línea corresponde directamente a un URI o enlace oficial de Spotify.
  bool get isDirectUri => directUri != null && directUri!.isNotEmpty;

  @override
  List<Object?> get props => [rawText, query, directUri, lineNumber];
}
