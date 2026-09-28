import 'package:flutter/material.dart';

/// Configuración de estilos visuales y tema para Listillify.
/// Sigue Material 3 con paleta oscura inspirada en la identidad de Spotify.
abstract final class AppTheme {
  static const Color spotifyGreen = Color(0xFF1DB954);
  static const Color spotifyBlack = Color(0xFF121212);
  static const Color spotifyDarkGrey = Color(0xFF282828);
  static const Color spotifyLightGrey = Color(0xFFB3B3B3);
  static const Color spotifyWhite = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spotifyBlack,
      colorScheme: const ColorScheme.dark(
        primary: spotifyGreen,
        onPrimary: spotifyBlack,
        surface: spotifyDarkGrey,
        onSurface: spotifyWhite,
        error: Colors.redAccent,
        onError: spotifyWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: spotifyBlack,
        foregroundColor: spotifyWhite,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: spotifyGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: spotifyLightGrey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: spotifyGreen,
          foregroundColor: spotifyBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
