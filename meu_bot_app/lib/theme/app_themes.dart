import 'package:flutter/material.dart';
import 'design_system.dart';

/// Temas do app baseados 100% no iOS Design System
///
/// Este arquivo cria ThemeData compatível com Material para uso no MaterialApp,
/// mas usando todas as cores, tipografia e espaçamentos do iOS Human Interface Guidelines.
///
/// IMPORTANTE: Este arquivo serve como bridge entre MaterialApp e o design system iOS.
/// Para componentes customizados, use AppDesignSystem diretamente.
class AppThemes {
  // ========== CORES EXPORTADAS DO DESIGN SYSTEM iOS ==========
  // Mantidas para compatibilidade com código existente

  /// Cores do tema claro (iOS)
  static const Color lightPrimary = AppDesignSystem.systemBlue;
  static const Color lightPrimaryDark = AppDesignSystem.systemBlue;
  static const Color lightAccent = AppDesignSystem.systemTeal;
  static const Color lightBackground = AppDesignSystem.lightSecondaryBackground;
  static const Color lightSurface = AppDesignSystem.lightGroupedSecondaryBackground;
  static const Color lightError = AppDesignSystem.systemRed;

  /// Cores do tema escuro (iOS)
  static const Color darkPrimary = AppDesignSystem.systemBlueDark;
  static const Color darkPrimaryDark = AppDesignSystem.systemBlueDark;
  static const Color darkAccent = AppDesignSystem.systemTeal;
  static const Color darkBackground = AppDesignSystem.darkPrimaryBackground;
  static const Color darkSurface = AppDesignSystem.darkSecondaryBackground;
  static const Color darkError = AppDesignSystem.systemRed;

  // ========== CORES DO CHAT (iOS) ==========

  /// Mensagens do usuário (light)
  static const Color lightUserBubble = AppDesignSystem.systemBlue;
  static const Color lightUserText = Colors.white;

  /// Mensagens do bot (light)
  static const Color lightBotBubble = AppDesignSystem.lightSecondaryBackground;
  static const Color lightBotText = AppDesignSystem.lightPrimaryLabel;

  /// Mensagens do usuário (dark)
  static const Color darkUserBubble = AppDesignSystem.systemBlueDark;
  static const Color darkUserText = Colors.white;

  /// Mensagens do bot (dark)
  static const Color darkBotBubble = AppDesignSystem.darkTertiaryBackground;
  static const Color darkBotText = AppDesignSystem.darkPrimaryLabel;

  /// Input field (light)
  static const Color lightInputBackground = AppDesignSystem.lightFillTertiary;
  static const Color lightInputText = AppDesignSystem.lightPrimaryLabel;

  /// Input field (dark)
  static const Color darkInputBackground = AppDesignSystem.darkFillTertiary;
  static const Color darkInputText = AppDesignSystem.darkPrimaryLabel;

  // ========== TEMA CLARO (iOS-based) ==========

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Cores principais (iOS)
      primaryColor: AppDesignSystem.systemBlue,
      scaffoldBackgroundColor: AppDesignSystem.lightSecondaryBackground,

      // ColorScheme (iOS colors)
      colorScheme: const ColorScheme.light(
        primary: AppDesignSystem.systemBlue,
        secondary: AppDesignSystem.systemTeal,
        surface: AppDesignSystem.lightGroupedSecondaryBackground,
        error: AppDesignSystem.systemRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppDesignSystem.lightPrimaryLabel,
        onError: Colors.white,
      ),

      // AppBar (iOS style - sem elevation, divider sutil)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDesignSystem.lightPrimaryBackground,
        foregroundColor: AppDesignSystem.systemBlue,
        elevation: 0, // iOS não usa elevation
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false, // iOS mantém título à esquerda
        titleTextStyle: AppDesignSystem.headline,
        iconTheme: IconThemeData(
          color: AppDesignSystem.systemBlue,
          size: 22,
        ),
      ),

      // Cards (iOS style)
      cardTheme: CardThemeData(
        color: AppDesignSystem.lightGroupedSecondaryBackground,
        elevation: 0, // iOS usa sombras sutis via boxShadow, não elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
        ),
        margin: const EdgeInsets.all(AppDesignSystem.spacing8),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppDesignSystem.systemBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Input Decoration (iOS style)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesignSystem.lightFillTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: const BorderSide(
            color: AppDesignSystem.systemBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: const BorderSide(
            color: AppDesignSystem.systemRed,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing16,
          vertical: AppDesignSystem.spacing12,
        ),
        labelStyle: AppDesignSystem.callout.copyWith(
          color: AppDesignSystem.lightSecondaryLabel,
        ),
        hintStyle: AppDesignSystem.callout.copyWith(
          color: AppDesignSystem.lightTertiaryLabel,
        ),
      ),

      // Text Theme (SF Pro typography)
      textTheme: const TextTheme(
        displayLarge: AppDesignSystem.largeTitle,
        displayMedium: AppDesignSystem.title1,
        displaySmall: AppDesignSystem.title2,
        headlineMedium: AppDesignSystem.title3,
        headlineSmall: AppDesignSystem.headline,
        titleLarge: AppDesignSystem.headline,
        titleMedium: AppDesignSystem.callout,
        titleSmall: AppDesignSystem.subheadline,
        bodyLarge: AppDesignSystem.body,
        bodyMedium: AppDesignSystem.callout,
        bodySmall: AppDesignSystem.footnote,
        labelLarge: AppDesignSystem.headline,
        labelMedium: AppDesignSystem.subheadline,
        labelSmall: AppDesignSystem.caption1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppDesignSystem.systemBlue,
        size: 22,
      ),

      // Divider (iOS style - muito fino)
      dividerTheme: const DividerThemeData(
        color: AppDesignSystem.lightSeparator,
        thickness: 0.5,
        space: 0.5,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDesignSystem.lightPrimaryBackground,
        selectedItemColor: AppDesignSystem.systemBlue,
        unselectedItemColor: AppDesignSystem.lightSecondaryLabel,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: AppDesignSystem.lightGroupedSecondaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
        ),
      ),

      // Elevated Button (iOS style)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignSystem.systemBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing20,
            vertical: AppDesignSystem.spacing12,
          ),
          textStyle: AppDesignSystem.headline,
        ),
      ),

      // Outlined Button (iOS style)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignSystem.systemBlue,
          side: const BorderSide(
            color: AppDesignSystem.systemBlue,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing20,
            vertical: AppDesignSystem.spacing12,
          ),
          textStyle: AppDesignSystem.headline,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDesignSystem.systemBlue,
          textStyle: AppDesignSystem.body,
        ),
      ),
    );
  }

  // ========== TEMA ESCURO (iOS-based) ==========

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Cores principais (iOS Dark)
      primaryColor: AppDesignSystem.systemBlueDark,
      scaffoldBackgroundColor: AppDesignSystem.darkPrimaryBackground,

      // ColorScheme (iOS dark colors)
      colorScheme: const ColorScheme.dark(
        primary: AppDesignSystem.systemBlueDark,
        secondary: AppDesignSystem.systemTeal,
        surface: AppDesignSystem.darkSecondaryBackground,
        error: AppDesignSystem.systemRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppDesignSystem.darkPrimaryLabel,
        onError: Colors.white,
      ),

      // AppBar (iOS dark style)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDesignSystem.darkPrimaryBackground,
        foregroundColor: AppDesignSystem.systemBlueDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppDesignSystem.headline,
        iconTheme: IconThemeData(
          color: AppDesignSystem.systemBlueDark,
          size: 22,
        ),
      ),

      // Cards (iOS dark style)
      cardTheme: CardThemeData(
        color: AppDesignSystem.darkSecondaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
        ),
        margin: const EdgeInsets.all(AppDesignSystem.spacing8),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppDesignSystem.systemBlueDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Input Decoration (iOS dark style)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesignSystem.darkFillTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: const BorderSide(
            color: AppDesignSystem.systemBlueDark,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius10),
          borderSide: const BorderSide(
            color: AppDesignSystem.systemRed,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing16,
          vertical: AppDesignSystem.spacing12,
        ),
        labelStyle: AppDesignSystem.callout.copyWith(
          color: AppDesignSystem.darkSecondaryLabel,
        ),
        hintStyle: AppDesignSystem.callout.copyWith(
          color: AppDesignSystem.darkTertiaryLabel,
        ),
      ),

      // Text Theme (SF Pro typography)
      textTheme: const TextTheme(
        displayLarge: AppDesignSystem.largeTitle,
        displayMedium: AppDesignSystem.title1,
        displaySmall: AppDesignSystem.title2,
        headlineMedium: AppDesignSystem.title3,
        headlineSmall: AppDesignSystem.headline,
        titleLarge: AppDesignSystem.headline,
        titleMedium: AppDesignSystem.callout,
        titleSmall: AppDesignSystem.subheadline,
        bodyLarge: AppDesignSystem.body,
        bodyMedium: AppDesignSystem.callout,
        bodySmall: AppDesignSystem.footnote,
        labelLarge: AppDesignSystem.headline,
        labelMedium: AppDesignSystem.subheadline,
        labelSmall: AppDesignSystem.caption1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppDesignSystem.systemBlueDark,
        size: 22,
      ),

      // Divider (iOS dark style)
      dividerTheme: const DividerThemeData(
        color: AppDesignSystem.darkSeparator,
        thickness: 0.5,
        space: 0.5,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDesignSystem.darkPrimaryBackground,
        selectedItemColor: AppDesignSystem.systemBlueDark,
        unselectedItemColor: AppDesignSystem.darkSecondaryLabel,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: AppDesignSystem.darkSecondaryBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
        ),
      ),

      // Elevated Button (iOS dark style)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignSystem.systemBlueDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing20,
            vertical: AppDesignSystem.spacing12,
          ),
          textStyle: AppDesignSystem.headline,
        ),
      ),

      // Outlined Button (iOS dark style)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignSystem.systemBlueDark,
          side: const BorderSide(
            color: AppDesignSystem.systemBlueDark,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing20,
            vertical: AppDesignSystem.spacing12,
          ),
          textStyle: AppDesignSystem.headline,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDesignSystem.systemBlueDark,
          textStyle: AppDesignSystem.body,
        ),
      ),
    );
  }
}
