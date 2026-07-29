// lib/app/config/theme/app_theme.dart
// Design System KRIPTONSHARE — Dark-first, WCAG 2.1 AA/AAA.

import 'package:flutter/material.dart';

class AppTheme {
  // Tokens cromáticos
  static const Color charcoalDeep = Color(0xFF0A0A0F);
  static const Color charcoalBlack = Color(0xFF121212);
  static const Color ink = Color(0xFF2B2B2B);
  static const Color inkDeep = Color(0xFF1A1A2E);
  static const Color electricLime = Color(0xFF39FF14);
  static const Color mutedGreen = Color(0xFF4E9B47);
  static const Color platinum = Color(0xFFE8E8E8);
  static const Color silver = Color(0xFFA0A0A0);
  static const Color crimsonRed = Color(0xFFFF3B30);

  // Espaciados
  static const double gridBase = 8.0;
  static const double radiusCard = 8.0;
  static const double radiusInput = 12.0;
  static const double radiusModal = 20.0;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: charcoalDeep,
      cardColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: electricLime,
        onPrimary: charcoalBlack,
        secondary: mutedGreen,
        onSecondary: platinum,
        surface: ink,
        onSurface: platinum,
        error: crimsonRed,
        onError: platinum,
        background: charcoalDeep,
        onBackground: platinum,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: platinum,
          height: 1.33,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: platinum,
          height: 1.33,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: platinum,
          height: 1.43,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: platinum,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: silver,
          height: 1.33,
        ),
        labelSmall: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontWeight: FontWeight.w400,
          fontSize: 11,
          color: silver,
          height: 1.27,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: platinum,
        ),
      ),
      cardTheme: CardThemeData(
        color: ink,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricLime,
          foregroundColor: charcoalBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inkDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: mutedGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: silver),
        hintStyle: const TextStyle(color: silver),
      ),
    );
  }
}
