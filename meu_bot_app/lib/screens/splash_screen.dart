import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/supabase_service.dart';
import '../theme/theme_provider.dart';
import '../theme/design_system.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'onboarding_screen.dart';

/// Tela de splash minimalista ao iniciar o app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  /// Verifica se o usuário está autenticado e navega para tela correta
  Future<void> _checkAuthAndNavigate() async {
    // Aguarda pelo menos 2 segundos para mostrar a splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Verifica se é a primeira vez
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // Se não completou onboarding, mostra a introdução
    if (!onboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    // Verifica se usuário está autenticado
    final isAuthenticated = SupabaseService.isAuthenticated();

    if (!mounted) return;

    // Navega para a tela apropriada
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isAuthenticated ? const ChatScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppDesignSystem.darkBackground
          : AppDesignSystem.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? AppDesignSystem.primaryBlueDark
                    : AppDesignSystem.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: AppDesignSystem.shadowSoft(isDark),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),

            const SizedBox(height: AppDesignSystem.spacingXL),

            // Nome do app
            Text(
              'Meu Bot',
              style: AppDesignSystem.largeTitle.copyWith(
                color: isDark
                    ? AppDesignSystem.darkPrimaryText
                    : AppDesignSystem.lightPrimaryText,
                fontSize: 38,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: -0.1, end: 0),

            const SizedBox(height: AppDesignSystem.spacingS),

            // Subtítulo
            Text(
              'Seu assistente virtual inteligente',
              style: AppDesignSystem.body.copyWith(
                color: isDark
                    ? AppDesignSystem.darkSecondaryText
                    : AppDesignSystem.lightSecondaryText,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: -0.1, end: 0),

            const SizedBox(height: AppDesignSystem.spacingXXL),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark
                      ? AppDesignSystem.primaryBlueDark
                      : AppDesignSystem.primaryBlue,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
