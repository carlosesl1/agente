import 'package:flutter/material.dart';

/// Design System - Minimalista Premium inspirado na Apple
///
/// Define cores, tipografia, espaçamentos e componentes reutilizáveis
/// para manter consistência visual em todo o app

class AppDesignSystem {
  // ============================================================================
  // CORES
  // ============================================================================

  /// Cores primárias - Azul clean da Apple
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryBlueDark = Color(0xFF0A84FF);

  /// Cores de acento
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentPurple = Color(0xFFAF52DE);

  /// Backgrounds - Light Mode
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSecondaryBackground = Color(0xFFF2F2F7);
  static const Color lightTertiaryBackground = Color(0xFFFFFFFF);
  static const Color lightGroupedBackground = Color(0xFFF2F2F7);

  /// Backgrounds - Dark Mode
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSecondaryBackground = Color(0xFF1C1C1E);
  static const Color darkTertiaryBackground = Color(0xFF2C2C2E);
  static const Color darkGroupedBackground = Color(0xFF000000);

  /// Textos - Light Mode
  static const Color lightPrimaryText = Color(0xFF000000);
  static const Color lightSecondaryText = Color(0xFF3C3C43);
  static const Color lightTertiaryText = Color(0xFF3C3C43);

  /// Textos - Dark Mode
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFEBEBF5);
  static const Color darkTertiaryText = Color(0xFFEBEBF5);

  /// Separadores
  static const Color lightSeparator = Color(0xFFC6C6C8);
  static const Color darkSeparator = Color(0xFF38383A);

  // ============================================================================
  // TIPOGRAFIA
  // ============================================================================

  /// Large Title - Para títulos grandes
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.37,
  );

  /// Title 1
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.36,
  );

  /// Title 2
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.35,
  );

  /// Title 3
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
  );

  /// Headline
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
  );

  /// Body
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
  );

  /// Callout
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
  );

  /// Subhead
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
  );

  /// Footnote
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
  );

  /// Caption 1
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  /// Caption 2
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
  );

  // ============================================================================
  // ESPAÇAMENTOS
  // ============================================================================

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ============================================================================
  // BORDAS
  // ============================================================================

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // ============================================================================
  // ELEVAÇÕES (SOMBRAS)
  // ============================================================================

  /// Sombra suave - Para cards e botões
  static List<BoxShadow> shadowSoft(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra média - Para modals e drawers
  static List<BoxShadow> shadowMedium(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Sombra forte - Para elementos flutuantes
  static List<BoxShadow> shadowStrong(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.5)
              : Colors.black.withOpacity(0.16),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ============================================================================
  // COMPONENTES REUTILIZÁVEIS
  // ============================================================================

  /// Card minimalista com sombra suave
  static Widget card({
    required Widget child,
    required bool isDark,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkSecondaryBackground : lightTertiaryBackground,
        borderRadius: BorderRadius.circular(radiusL),
        boxShadow: shadowSoft(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusL),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(spacingM),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Botão primário
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isDark,
    bool isLoading = false,
    IconData? icon,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? primaryBlueDark : primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingL),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: spacingS),
                  ],
                  Text(
                    text,
                    style: headline.copyWith(color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  /// Botão secundário (outline)
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isDark,
    IconData? icon,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primaryBlueDark : primaryBlue,
          side: BorderSide(
            color: isDark ? primaryBlueDark : primaryBlue,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: spacingS),
            ],
            Text(
              text,
              style: headline.copyWith(
                color: isDark ? primaryBlueDark : primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Input field minimalista
  static InputDecoration inputDecoration({
    required String label,
    required bool isDark,
    String? hint,
    IconData? prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: isDark ? darkSecondaryText : lightSecondaryText,
              size: 20,
            )
          : null,
      labelStyle: body.copyWith(
        color: isDark
            ? darkSecondaryText.withOpacity(0.6)
            : lightSecondaryText.withOpacity(0.6),
      ),
      hintStyle: body.copyWith(
        color: isDark
            ? darkTertiaryText.withOpacity(0.4)
            : lightTertiaryText.withOpacity(0.4),
      ),
      filled: true,
      fillColor: isDark
          ? darkSecondaryBackground
          : lightSecondaryBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(
          color: isDark ? primaryBlueDark : primaryBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(
          color: accentRed,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(
          color: accentRed,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
    );
  }

  /// Divider minimalista
  static Widget divider(bool isDark) {
    return Divider(
      color: isDark ? darkSeparator : lightSeparator,
      height: 1,
      thickness: 0.5,
    );
  }

  /// AppBar minimalista
  static AppBar appBar({
    required String title,
    required bool isDark,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
  }) {
    return AppBar(
      title: Text(
        title,
        style: headline.copyWith(
          color: isDark ? darkPrimaryText : lightPrimaryText,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: isDark ? darkBackground : lightBackground,
      elevation: 0,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(
        color: isDark ? darkPrimaryText : lightPrimaryText,
      ),
    );
  }

  /// Avatar com estilo Apple
  static Widget avatar({
    required String? imageUrl,
    required String fallbackText,
    required Color backgroundColor,
    double radius = 20,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage:
          imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl == null || imageUrl.isEmpty
          ? Text(
              fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  /// Badge de notificação
  static Widget badge({
    required int count,
    double size = 20,
  }) {
    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: accentRed,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: caption2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
