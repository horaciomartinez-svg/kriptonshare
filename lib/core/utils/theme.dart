import 'package:flutter/material.dart';

class KriptonTheme {
  // Colores Institucionales según documento Imagen Institucional
  static const Color kryptonGreen = Color(0xFF4E9B47);
  static const Color kryptonGreenVariant = Color(0xFF4A8D4B);
  static const Color electricLime = Color(0xFF39FF14);
  static const Color neonGreen = Color(0xFFC7F000);
  
  static const Color charcoalBlack = Color(0xFF0A0A0F);
  static const Color inkDeep = Color(0xFF1A1A2E);
  static const Color surfaceElevated = Color(0xFF16213E);
  static const Color ink = Color(0xFF2B2B2B);
  static const Color cardBorder = Color(0xFF3A3A3A);
  
  static const Color platinum = Color(0xFFE8E8E8);
  static const Color silver = Color(0xFFA0A0A0);
  static const Color graphite = Color(0xFF6B6B6B);
  static const Color platinumGrey = Color(0xFFE0E0E0);
  static const Color mutedSilver = Color(0xFFA0A0A0);
  
  static const Color alertRed = Color(0xFFFF3860);
  static const Color cryptoGreen = Color(0xFF00E676);
  static const Color amber = Color(0xFFFFB300);
  static const Color cyanTelemetry = Color(0xFF03DAC6);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: charcoalBlack,
      colorScheme: const ColorScheme.dark(
        primary: kryptonGreen,
        onPrimary: platinum,
        secondary: electricLime,
        onSecondary: charcoalBlack,
        surface: ink,
        onSurface: platinum,
        error: alertRed,
        onError: platinum,
        background: charcoalBlack,
        onBackground: platinum,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 28,
          color: platinum,
          letterSpacing: -0.02,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: platinum,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: platinum,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: platinumGrey,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: silver,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: mutedSilver,
        ),
        labelSmall: TextStyle(
          fontFamily: 'SFMono',
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: cyanTelemetry,
          fontFeatures: [FontFeature.tabularFigures()],
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
          letterSpacing: -0.02,
        ),
      ),
      cardTheme: CardThemeData(
        color: ink,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricLime,
          foregroundColor: charcoalBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: platinum,
          side: const BorderSide(color: cardBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inkDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kryptonGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: silver),
        hintStyle: const TextStyle(color: graphite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: inkDeep,
        selectedItemColor: electricLime,
        unselectedItemColor: graphite,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: electricLime,
        foregroundColor: charcoalBlack,
        elevation: 4,
      ),
    );
  }

  // Gradientes permitidos
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kryptonGreen, kryptonGreenVariant],
  );

  // Glow effects
  static BoxShadow kryptonGlow = BoxShadow(
    color: kryptonGreen.withOpacity(0.15),
    blurRadius: 24,
    spreadRadius: 0,
  );
}
