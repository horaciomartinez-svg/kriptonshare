import 'package:flutter/material.dart';

/// Tema institucional de KRIPTONSHARE.
/// Colores de identidad de marca: Zafiro, Platino, Ámbar.
class KriptonTheme {
  // ─── Colores Primarios ───
  static const Color sapphire = Color(0xFF0A2540);   // Zafiro institucional
  static const Color platinum = Color(0xFFE8E8E8);   // Platino premium
  static const Color ember = Color(0xFFFF6B35);      // Ámbar alerta

  // ─── Colores Secundarios ───
  static const Color darkBackground = Color(0xFF0A1929);
  static const Color cardBackground = Color(0xFF112240);
  static const Color divider = Color(0xFF1E3A5F);

  // ─── Tema Material ───
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      primaryColor: sapphire,
      colorScheme: const ColorScheme.dark(
        primary: sapphire,
        secondary: platinum,
        error: ember,
        surface: cardBackground,
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: sapphire,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: platinum, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: platinum),
        bodySmall: TextStyle(color: platinum),
      ),
    );
  }
}
