import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/supabase_service.dart';
import '../theme/theme_provider.dart';
import '../theme/design_system.dart';
import 'register_screen.dart';

/// Tela de Login Minimalista - Apple Style
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira seu email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira sua senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email ou senha incorretos';
    } else if (error.contains('Email not confirmed')) {
      return 'Por favor, confirme seu email antes de fazer login';
    } else if (error.contains('Too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos';
    } else if (error.contains('Network')) {
      return 'Erro de conexão. Verifique sua internet';
    }
    return 'Erro ao fazer login. Tente novamente';
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppDesignSystem.darkPrimaryBackground
          : AppDesignSystem.lightPrimaryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    _buildLogo(isDark)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: AppDesignSystem.spacing32),

                    // Título
                    Text(
                      'Bem-vindo de volta',
                      style: AppDesignSystem.largeTitle.copyWith(
                        color: isDark
                            ? AppDesignSystem.darkPrimaryLabel
                            : AppDesignSystem.lightPrimaryLabel,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),

                    const SizedBox(height: AppDesignSystem.spacing8),

                    Text(
                      'Entre para continuar',
                      style: AppDesignSystem.body.copyWith(
                        color: isDark
                            ? AppDesignSystem.darkSecondaryLabel
                            : AppDesignSystem.lightSecondaryLabel,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),

                    const SizedBox(height: AppDesignSystem.spacing32),

                    // Mensagem de erro
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                        margin: const EdgeInsets.only(
                            bottom: AppDesignSystem.spacing16),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.systemRed.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.cornerRadius12),
                          border: Border.all(
                            color: AppDesignSystem.systemRed.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppDesignSystem.systemRed,
                              size: 20,
                            ),
                            const SizedBox(width: AppDesignSystem.spacing16),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppDesignSystem.subhead.copyWith(
                                  color: AppDesignSystem.systemRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .shake(),

                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      validator: _validateEmail,
                      style: AppDesignSystem.body.copyWith(
                        color: isDark
                            ? AppDesignSystem.darkPrimaryLabel
                            : AppDesignSystem.lightPrimaryLabel,
                      ),
                      decoration: AppDesignSystem.inputDecoration(
                        label: 'Email',
                        hint: 'seu@email.com',
                        isDark: isDark,
                        prefixIcon: Icons.email_outlined,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: AppDesignSystem.spacing16),

                    // Campo Senha
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      validator: _validatePassword,
                      style: AppDesignSystem.body.copyWith(
                        color: isDark
                            ? AppDesignSystem.darkPrimaryLabel
                            : AppDesignSystem.lightPrimaryLabel,
                      ),
                      decoration: AppDesignSystem.inputDecoration(
                        label: 'Senha',
                        hint: 'Sua senha',
                        isDark: isDark,
                        prefixIcon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark
                                ? AppDesignSystem.darkSecondaryLabel
                                : AppDesignSystem.lightSecondaryLabel,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                    const SizedBox(height: AppDesignSystem.spacing20),

                    // Botão Entrar
                    AppDesignSystem.primaryButton(
                      text: 'Entrar',
                      onPressed: _isLoading ? null : _handleLogin,
                      isDark: isDark,
                      isLoading: _isLoading,
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                    const SizedBox(height: AppDesignSystem.spacing20),

                    // Link para cadastro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem conta? ',
                          style: AppDesignSystem.subhead.copyWith(
                            color: isDark
                                ? AppDesignSystem.darkSecondaryLabel
                                : AppDesignSystem.lightSecondaryLabel,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _navigateToRegister,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.spacing8,
                            ),
                          ),
                          child: Text(
                            'Cadastre-se',
                            style: AppDesignSystem.subhead.copyWith(
                              color: isDark
                                  ? AppDesignSystem.systemBlueDark
                                  : AppDesignSystem.systemBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isDark
              ? AppDesignSystem.systemBlueDark
              : AppDesignSystem.systemBlue,
          shape: BoxShape.circle,
          boxShadow: AppDesignSystem.shadowLevel1(isDark),
        ),
        child: const Icon(
          Icons.chat_bubble_outline,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}
