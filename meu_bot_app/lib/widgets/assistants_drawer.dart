import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/assistant_model.dart';
import '../providers/assistant_provider.dart';
import '../screens/assistant_edit_screen.dart';
import '../screens/settings_general_screen.dart';
import '../theme/theme_provider.dart';
import '../theme/design_system.dart';

/// Drawer lateral minimalista com lista de assistentes
class AssistantsDrawer extends StatelessWidget {
  const AssistantsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Drawer(
      backgroundColor: isDark
          ? AppDesignSystem.darkPrimaryBackground
          : AppDesignSystem.lightPrimaryBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            AppDesignSystem.divider(isDark),

            // Lista de assistentes
            Expanded(
              child: _buildAssistantsList(context),
            ),

            AppDesignSystem.divider(isDark),

            const SizedBox(height: AppDesignSystem.spacing8),

            // Botão Novo Assistente
            _buildNewAssistantButton(context, isDark),

            const SizedBox(height: AppDesignSystem.spacing8),

            // Botão Configurações
            _buildSettingsButton(context, isDark),

            const SizedBox(height: AppDesignSystem.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 28,
            color: isDark
                ? AppDesignSystem.systemBlueDark
                : AppDesignSystem.systemBlue,
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.easeOut,
              ),
          const SizedBox(width: AppDesignSystem.spacing16),
          Expanded(
            child: Text(
              'Meus Assistentes',
              style: AppDesignSystem.title3.copyWith(
                color: isDark
                    ? AppDesignSystem.darkPrimaryLabel
                    : AppDesignSystem.lightPrimaryLabel,
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideX(begin: -0.1, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantsList(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer<AssistantProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark
                    ? AppDesignSystem.systemBlueDark
                    : AppDesignSystem.systemBlue,
              ),
            ),
          );
        }

        if (provider.assistants.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDesignSystem.spacing32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: isDark
                        ? AppDesignSystem.darkSecondaryLabel.withOpacity(0.5)
                        : AppDesignSystem.lightSecondaryLabel.withOpacity(0.5),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(curve: Curves.easeOut),
                  const SizedBox(height: AppDesignSystem.spacing16),
                  Text(
                    'Nenhum assistente criado.\nToque em "+" para criar um.',
                    textAlign: TextAlign.center,
                    style: AppDesignSystem.subhead.copyWith(
                      color: isDark
                          ? AppDesignSystem.darkSecondaryLabel
                          : AppDesignSystem.lightSecondaryLabel,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDesignSystem.spacing8),
          itemCount: provider.assistants.length,
          itemBuilder: (context, index) {
            final assistant = provider.assistants[index];
            final isSelected = provider.currentAssistant?.id == assistant.id;

            return _buildAssistantTile(
              context,
              assistant,
              isSelected,
              provider,
              index,
              isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildAssistantTile(
    BuildContext context,
    AssistantModel assistant,
    bool isSelected,
    AssistantProvider provider,
    int index,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacing8,
        vertical: AppDesignSystem.spacing4,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                ? AppDesignSystem.darkSecondaryBackground
                : AppDesignSystem.lightSecondaryBackground)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
        border: isSelected
            ? Border.all(
                color: assistant.primaryColor.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
          onTap: () {
            provider.selectAssistant(assistant);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    AppDesignSystem.avatar(
                      imageUrl: assistant.avatarUrl,
                      fallbackText: assistant.name,
                      backgroundColor: assistant.primaryColor,
                      radius: 22,
                    ),
                    // Badge de mensagens não lidas
                    if (assistant.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: AppDesignSystem.badge(
                          count: assistant.unreadCount,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppDesignSystem.spacing16),
                // Nome e subtítulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assistant.name,
                        style: AppDesignSystem.headline.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark
                              ? AppDesignSystem.darkPrimaryLabel
                              : AppDesignSystem.lightPrimaryLabel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (assistant.unreadCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${assistant.unreadCount} ${assistant.unreadCount == 1 ? 'nova' : 'novas'}',
                          style: AppDesignSystem.caption1.copyWith(
                            color: AppDesignSystem.systemRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Ícone de selecionado
                if (isSelected)
                  Icon(
                    Icons.check_circle_outline,
                    color: assistant.primaryColor,
                    size: 20,
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        curve: Curves.easeOut,
                      ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms, duration: 300.ms);
  }

  Widget _buildNewAssistantButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
      child: SizedBox(
        width: double.infinity,
        child: AppDesignSystem.primaryButton(
          text: 'Novo Assistente',
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AssistantEditScreen(),
              ),
            );
          },
          isDark: isDark,
          icon: Icons.add_rounded,
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
    );
  }

  Widget _buildSettingsButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
      child: SizedBox(
        width: double.infinity,
        child: AppDesignSystem.secondaryButton(
          text: 'Configurações',
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsGeneralScreen(),
              ),
            );
          },
          isDark: isDark,
          icon: Icons.settings_outlined,
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
    );
  }
}
