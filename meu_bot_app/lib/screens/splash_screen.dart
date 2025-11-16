import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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
      backgroundColor: Colors.blue,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone do bot
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              // Nome do app
              const Text(
                'Meu Bot',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtítulo
              Text(
                'Seu assistente virtual inteligente',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 48),
              // Indicador de loading
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
