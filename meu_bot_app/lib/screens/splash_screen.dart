import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'onboarding_screen.dart';

/// Tela de splash exibida ao iniciar o app
///
/// Verifica se o usuário está autenticado e redireciona automaticamente
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configuração da animação
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Aguarda 2 segundos e verifica autenticação
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFF093FB),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone do bot com animações premium
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withOpacity(0.5),
                    )
                    .then()
                    .shake(hz: 0.5, curve: Curves.easeInOut)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 1000.ms,
                    ),

                const SizedBox(height: 48),

                // Nome do app com animação
                const Text(
                  'Meu Bot',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.elasticOut,
                      duration: 1000.ms,
                    ),

                const SizedBox(height: 16),

                // Subtítulo com animação
                Text(
                  'Seu assistente virtual inteligente',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 64),

                // Indicador de loading premium
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.9),
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fade(duration: 1000.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
