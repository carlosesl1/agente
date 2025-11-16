import 'package:flutter/material.dart';

/// Design System - Apple-inspired Premium Minimalist
///
/// Baseado nos iOS Human Interface Guidelines 2024
/// Foco em clareza, deferência ao conteúdo e profundidade

class AppDesignSystem {
  // ============================================================================
  // CORES - iOS System Colors
  // ============================================================================

  /// Cores primárias - iOS Blue
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemBlueDark = Color(0xFF0A84FF);

  /// Cores de acento iOS
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemTeal = Color(0xFF5AC8FA);

  /// Backgrounds - Light Mode (iOS style)
  static const Color lightPrimaryBackground = Color(0xFFFFFFFF);
  static const Color lightSecondaryBackground = Color(0xFFF2F2F7);
  static const Color lightTertiaryBackground = Color(0xFFFFFFFF);
  static const Color lightGroupedBackground = Color(0xFFF2F2F7);
  static const Color lightGroupedSecondaryBackground = Color(0xFFFFFFFF);

  /// Backgrounds - Dark Mode (iOS style)
  static const Color darkPrimaryBackground = Color(0xFF000000);
  static const Color darkSecondaryBackground = Color(0xFF1C1C1E);
  static const Color darkTertiaryBackground = Color(0xFF2C2C2E);
  static const Color darkGroupedBackground = Color(0xFF000000);
  static const Color darkGroupedSecondaryBackground = Color(0xFF1C1C1E);

  /// Labels - Light Mode
  static const Color lightPrimaryLabel = Color(0xFF000000);
  static const Color lightSecondaryLabel = Color(0x993C3C43);
  static const Color lightTertiaryLabel = Color(0x4C3C3C43);
  static const Color lightQuaternaryLabel = Color(0x2D3C3C43);

  /// Labels - Dark Mode
  static const Color darkPrimaryLabel = Color(0xFFFFFFFF);
  static const Color darkSecondaryLabel = Color(0x99EBEBF5);
  static const Color darkTertiaryLabel = Color(0x4CEBEBF5);
  static const Color darkQuaternaryLabel = Color(0x28EBEBF5);

  /// Fills (para botões e controles) - Light
  static const Color lightFillPrimary = Color(0x33787880);
  static const Color lightFillSecondary = Color(0x28787880);
  static const Color lightFillTertiary = Color(0x1E767680);
  static const Color lightFillQuaternary = Color(0x14747480);

  /// Fills - Dark
  static const Color darkFillPrimary = Color(0x5C787880);
  static const Color darkFillSecondary = Color(0x52787880);
  static const Color darkFillTertiary = Color(0x3D767680);
  static const Color darkFillQuaternary = Color(0x2E747480);

  /// Separadores
  static const Color lightSeparator = Color(0x4C3C3C43);
  static const Color darkSeparator = Color(0x99545458);

  // ============================================================================
  // TIPOGRAFIA - SF Pro Style
  // ============================================================================

  /// Large Title - iOS Display (34pt)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.374,
    height: 1.176, // 40/34
  );

  /// Title 1 - iOS Display (28pt)
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.364,
    height: 1.214, // 34/28
  );

  /// Title 2 - iOS Display (22pt)
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.352,
    height: 1.273, // 28/22
  );

  /// Title 3 - iOS Text (20pt)
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    height: 1.2, // 24/20
  );

  /// Headline - iOS Text (17pt semibold)
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.408,
    height: 1.294, // 22/17
  );

  /// Body - iOS Text (17pt regular)
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.408,
    height: 1.294, // 22/17
  );

  /// Callout - iOS Text (16pt)
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 1.313, // 21/16
  );

  /// Subheadline - iOS Text (15pt)
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 1.333, // 20/15
  );

  /// Footnote - iOS Text (13pt)
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.078,
    height: 1.385, // 18/13
  );

  /// Caption 1 - iOS Text (12pt)
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.333, // 16/12
  );

  /// Caption 2 - iOS Text (11pt)
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.066,
    height: 1.182, // 13/11
  );

  // ============================================================================
  // ESPAÇAMENTOS - iOS Guidelines
  // ============================================================================

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing44 = 44.0; // Minimum touch target
  static const double spacing64 = 64.0;

  // ============================================================================
  // CORNER RADIUS - iOS Style
  // ============================================================================

  static const double cornerRadius8 = 8.0;
  static const double cornerRadius10 = 10.0;
  static const double cornerRadius12 = 12.0;
  static const double cornerRadius16 = 16.0;
  static const double cornerRadius20 = 20.0;

  // ============================================================================
  // ELEVAÇÃO - iOS Shadows (muito sutis)
  // ============================================================================

  /// Sombra iOS - Nível 1 (muito sutil)
  static List<BoxShadow> shadowLevel1(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Sombra iOS - Nível 2 (cards)
  static List<BoxShadow> shadowLevel2(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra iOS - Nível 3 (modals)
  static List<BoxShadow> shadowLevel3(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.5)
              : Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ============================================================================
  // COMPONENTES REUTILIZÁVEIS
  // ============================================================================

  /// Card iOS com material blur
  static Widget card({
    required Widget child,
    required bool isDark,
    EdgeInsets? padding,
    VoidCallback? onTap,
    bool useBlur = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (useBlur ? darkSecondaryBackground.withOpacity(0.7) : darkSecondaryBackground)
            : (useBlur ? lightGroupedSecondaryBackground.withOpacity(0.9) : lightGroupedSecondaryBackground),
        borderRadius: BorderRadius.circular(cornerRadius12),
        boxShadow: shadowLevel1(isDark),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cornerRadius12),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(spacing16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Botão primário iOS
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isDark,
    bool isLoading = false,
    IconData? icon,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? systemRed : (isDark ? systemBlueDark : systemBlue);

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacing20),
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
                    Icon(icon, size: 18),
                    const SizedBox(width: spacing8),
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

  /// Input field iOS
  static InputDecoration inputDecoration({
    required String label,
    required bool isDark,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: isDark ? darkTertiaryLabel : lightTertiaryLabel,
              size: 20,
            )
          : null,
      labelStyle: callout.copyWith(
        color: isDark ? darkSecondaryLabel : lightSecondaryLabel,
      ),
      hintStyle: callout.copyWith(
        color: isDark ? darkTertiaryLabel : lightTertiaryLabel,
      ),
      filled: true,
      fillColor: isDark ? darkFillTertiary : lightFillTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cornerRadius10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cornerRadius10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cornerRadius10),
        borderSide: BorderSide(
          color: isDark ? systemBlueDark : systemBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cornerRadius10),
        borderSide: const BorderSide(
          color: systemRed,
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
    );
  }

  /// Divider iOS
  static Widget divider(bool isDark) {
    return Divider(
      color: isDark ? darkSeparator : lightSeparator,
      height: 0.5,
      thickness: 0.5,
    );
  }

  /// AppBar iOS
  static AppBar appBar({
    required String title,
    required bool isDark,
    List<Widget>? actions,
    Widget? leading,
  }) {
    return AppBar(
      title: Text(
        title,
        style: headline,
      ),
      centerTitle: false,
      backgroundColor: isDark ? darkPrimaryBackground : lightPrimaryBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(
        color: isDark ? systemBlueDark : systemBlue,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: divider(isDark),
      ),
    );
  }

  /// Avatar iOS
  static Widget avatar({
    required String? imageUrl,
    required String fallbackText,
    required Color backgroundColor,
    double radius = 20,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage:
            imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Text(
                fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  /// Badge iOS
  static Widget badge({
    required int count,
    double size = 18,
  }) {
    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: systemRed,
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

  /// Section Header iOS
  static Widget sectionHeader(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        left: spacing20,
        right: spacing20,
        top: spacing24,
        bottom: spacing8,
      ),
      child: Text(
        text.toUpperCase(),
        style: footnote.copyWith(
          color: isDark ? darkSecondaryLabel : lightSecondaryLabel,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
