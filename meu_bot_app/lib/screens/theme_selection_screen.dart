import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme_provider.dart';
import '../theme/design_system.dart';

/// Tela de seleção de tema
///
/// Permite escolher entre tema claro, escuro ou automático
class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppDesignSystem.darkPrimaryBackground
          : AppDesignSystem.lightGroupedBackground,
      appBar: AppDesignSystem.appBar(
        title: 'Aparência',
        isDark: isDark,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppDesignSystem.spacing16),
        children: [
          // Descrição
          Padding(
            padding: EdgeInsets.only(
              left: AppDesignSystem.spacing16,
              right: AppDesignSystem.spacing16,
              bottom: AppDesignSystem.spacing16,
            ),
            child: Text(
              'Escolha como o app deve aparecer',
              style: AppDesignSystem.subheadline.copyWith(
                color: isDark
                    ? AppDesignSystem.darkSecondaryLabel
                    : AppDesignSystem.lightSecondaryLabel,
              ),
            ),
          ),

          // Opções de tema
          ...themeProvider.availableThemes.map((option) {
            final isSelected = themeProvider.themeMode == option.mode;
            final index = themeProvider.availableThemes.indexOf(option);

            return _buildThemeOption(
              context,
              option,
              isSelected,
              isDark,
              index,
            );
          }).toList(),

          SizedBox(height: AppDesignSystem.spacing24),

          // Preview
          _buildPreviewSection(isDark),
        ],
      ),
    );
  }

  /// Opção de tema
  Widget _buildThemeOption(
    BuildContext context,
    ThemeModeOption option,
    bool isSelected,
    bool isDark,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? AppDesignSystem.systemBlueDark.withOpacity(0.2)
                : AppDesignSystem.systemBlue.withOpacity(0.1))
            : (isDark
                ? AppDesignSystem.darkSecondaryBackground
                : AppDesignSystem.lightGroupedSecondaryBackground),
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
        border: Border.all(
          color: isSelected
              ? (isDark
                  ? AppDesignSystem.systemBlueDark
                  : AppDesignSystem.systemBlue)
              : (isDark
                  ? AppDesignSystem.darkSeparator
                  : AppDesignSystem.lightSeparator),
          width: isSelected ? 2 : 0.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: (isDark
                          ? AppDesignSystem.systemBlueDark
                          : AppDesignSystem.systemBlue)
                      .withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : AppDesignSystem.shadowLevel1(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
          onTap: () {
            final themeProvider = Provider.of<ThemeProvider>(
              context,
              listen: false,
            );
            themeProvider.setThemeMode(option.mode);
          },
          child: Padding(
            padding: EdgeInsets.all(AppDesignSystem.spacing16),
            child: Row(
              children: [
                // Ícone
                Container(
                  padding: EdgeInsets.all(AppDesignSystem.spacing12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppDesignSystem.systemBlueDark
                            : AppDesignSystem.systemBlue)
                        : (isDark
                            ? AppDesignSystem.darkFillTertiary
                            : AppDesignSystem.lightFillTertiary),
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.cornerRadius12),
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppDesignSystem.darkSecondaryLabel
                            : AppDesignSystem.lightSecondaryLabel),
                    size: 28,
                  ),
                ),

                SizedBox(width: AppDesignSystem.spacing16),

                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: AppDesignSystem.headline.copyWith(
                          color: isSelected
                              ? (isDark
                                  ? AppDesignSystem.systemBlueDark
                                  : AppDesignSystem.systemBlue)
                              : (isDark
                                  ? AppDesignSystem.darkPrimaryLabel
                                  : AppDesignSystem.lightPrimaryLabel),
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      SizedBox(height: AppDesignSystem.spacing4),
                      Text(
                        option.description,
                        style: AppDesignSystem.caption1.copyWith(
                          color: isDark
                              ? AppDesignSystem.darkSecondaryLabel
                              : AppDesignSystem.lightSecondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: isDark
                        ? AppDesignSystem.systemBlueDark
                        : AppDesignSystem.systemBlue,
                    size: 24,
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        curve: Curves.easeOut,
                      ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100), duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  /// Seção de preview
  Widget _buildPreviewSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing16,
            vertical: AppDesignSystem.spacing8,
          ),
          child: Text(
            'Preview',
            style: AppDesignSystem.footnote.copyWith(
              color: isDark
                  ? AppDesignSystem.darkSecondaryLabel
                  : AppDesignSystem.lightSecondaryLabel,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ).copyWith(
              textTransform: TextTransform.uppercase,
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.all(AppDesignSystem.spacing20),
          decoration: BoxDecoration(
            color: isDark
                ? AppDesignSystem.darkSecondaryBackground
                : AppDesignSystem.lightGroupedSecondaryBackground,
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius16),
            boxShadow: AppDesignSystem.shadowLevel1(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exemplo de mensagem do usuário
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing16,
                    vertical: AppDesignSystem.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDesignSystem.systemBlueDark
                        : AppDesignSystem.systemBlue,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.cornerRadius20),
                  ),
                  child: Text(
                    'Olá! Como você está?',
                    style: AppDesignSystem.body.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppDesignSystem.spacing12),

              // Exemplo de mensagem do bot
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacing16,
                    vertical: AppDesignSystem.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDesignSystem.darkFillTertiary
                        : AppDesignSystem.lightFillTertiary,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.cornerRadius20),
                  ),
                  child: Text(
                    'Estou bem, obrigado! 😊',
                    style: AppDesignSystem.body.copyWith(
                      color: isDark
                          ? AppDesignSystem.darkPrimaryLabel
                          : AppDesignSystem.lightPrimaryLabel,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
