import 'package:flutter/material.dart';

/// Tema claro do app
class AppThemes {
  // ========== CORES PRINCIPAIS ==========

  /// Cores do tema claro
  static const Color lightPrimary = Color(0xFF2196F3); // Azul moderno
  static const Color lightPrimaryDark = Color(0xFF1976D2);
  static const Color lightAccent = Color(0xFF03DAC6); // Teal
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightError = Color(0xFFB00020);

  /// Cores do tema escuro
  static const Color darkPrimary = Color(0xFF2196F3);
  static const Color darkPrimaryDark = Color(0xFF1565C0);
  static const Color darkAccent = Color(0xFF03DAC6);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkError = Color(0xFFCF6679);

  // ========== CORES DO CHAT ==========

  /// Mensagens do usuário (light)
  static const Color lightUserBubble = Color(0xFF2196F3);
  static const Color lightUserText = Colors.white;

  /// Mensagens do bot (light)
  static const Color lightBotBubble = Color(0xFFE3F2FD);
  static const Color lightBotText = Color(0xFF1A1A1A);

  /// Mensagens do usuário (dark)
  static const Color darkUserBubble = Color(0xFF2196F3);
  static const Color darkUserText = Colors.white;

  /// Mensagens do bot (dark)
  static const Color darkBotBubble = Color(0xFF2C2C2C);
  static const Color darkBotText = Color(0xFFE0E0E0);

  /// Input field (light)
  static const Color lightInputBackground = Color(0xFFF0F0F0);
  static const Color lightInputText = Color(0xFF1A1A1A);

  /// Input field (dark)
  static const Color darkInputBackground = Color(0xFF2C2C2C);
  static const Color darkInputText = Color(0xFFE0E0E0);

  // ========== TEMA CLARO ==========

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Cores principais
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,

      // ColorScheme
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightAccent,
        surface: lightSurface,
        error: lightError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: lightPrimary,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
    );
  }

  // ========== TEMA ESCURO ==========

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Cores principais
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,

      // ColorScheme
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkAccent,
        surface: darkSurface,
        error: darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.black,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFFB0B0B0),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: darkPrimary,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
      ),
    );
  }
}
