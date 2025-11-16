import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/design_system.dart';
import 'chat_screen.dart';

/// Tela de introdução minimalista mostrada apenas na primeira vez
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  /// Marca que o onboarding foi concluído
  Future<void> _onIntroEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
  }

  /// Widget decorativo para as páginas com ícone
  Widget _buildImage(String assetName, double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignSystem.darkSecondaryBackground
            : AppDesignSystem.lightSecondaryBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIconForPage(assetName),
        size: size * 0.5,
        color: isDark
            ? AppDesignSystem.systemBlueDark
            : AppDesignSystem.systemBlue,
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.8, 0.8),
          curve: Curves.easeOut,
        );
  }

  IconData _getIconForPage(String page) {
    switch (page) {
      case 'multiple_assistants':
        return Icons.group_work_outlined;
      case 'ai_powered':
        return Icons.psychology_outlined;
      case 'personalized':
        return Icons.palette_outlined;
      case 'ready':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.chat_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final pageDecoration = PageDecoration(
      titleTextStyle: AppDesignSystem.title1.copyWith(
        color: isDark
            ? AppDesignSystem.darkPrimaryLabel
            : AppDesignSystem.lightPrimaryLabel,
      ),
      bodyTextStyle: AppDesignSystem.body.copyWith(
        color: isDark
            ? AppDesignSystem.darkSecondaryLabel
            : AppDesignSystem.lightSecondaryLabel,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        AppDesignSystem.spacing20,
        0.0,
        AppDesignSystem.spacing20,
        AppDesignSystem.spacing20,
      ),
      pageColor: isDark
          ? AppDesignSystem.darkPrimaryBackground
          : AppDesignSystem.lightPrimaryBackground,
      imagePadding: const EdgeInsets.all(AppDesignSystem.spacing32),
      titlePadding: const EdgeInsets.only(top: AppDesignSystem.spacing20),
      bodyAlignment: Alignment.center,
      imageAlignment: Alignment.center,
    );

    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: isDark
          ? AppDesignSystem.darkPrimaryBackground
          : AppDesignSystem.lightPrimaryBackground,
      pages: [
        // Página 1: Múltiplos Assistentes
        PageViewModel(
          title: "Múltiplos Assistentes",
          body:
              "Crie assistentes personalizados para diferentes áreas da sua vida: Trabalho, Casa, Finanças e muito mais.",
          image: _buildImage('multiple_assistants', 160, isDark),
          decoration: pageDecoration,
        ),

        // Página 2: Inteligência Artificial
        PageViewModel(
          title: "Powered by AI",
          body:
              "Conecte seus assistentes aos melhores modelos de IA através do N8N: GPT-4, Claude, Gemini e outros.",
          image: _buildImage('ai_powered', 160, isDark),
          decoration: pageDecoration,
        ),

        // Página 3: Personalização
        PageViewModel(
          title: "Personalizável",
          body:
              "Escolha cores, avatares e webhooks únicos para cada assistente. Organize suas conversas do seu jeito.",
          image: _buildImage('personalized', 160, isDark),
          decoration: pageDecoration,
        ),

        // Página 4: Pronto para começar
        PageViewModel(
          title: "Pronto para começar",
          body:
              "Crie seu primeiro assistente e comece a conversar com IA de forma organizada e eficiente.",
          image: _buildImage('ready', 160, isDark),
          decoration: pageDecoration,
        ),
      ],
      onDone: _onIntroEnd,
      onSkip: _onIntroEnd,
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      skip: Text(
        'Pular',
        style: AppDesignSystem.headline.copyWith(
          color: isDark
              ? AppDesignSystem.systemBlueDark
              : AppDesignSystem.systemBlue,
        ),
      ),
      next: Icon(
        Icons.arrow_forward_ios,
        color: isDark
            ? AppDesignSystem.systemBlueDark
            : AppDesignSystem.systemBlue,
        size: 20,
      ),
      done: Text(
        'Começar',
        style: AppDesignSystem.headline.copyWith(
          color: isDark
              ? AppDesignSystem.systemBlueDark
              : AppDesignSystem.systemBlue,
        ),
      ),
      curve: Curves.easeInOut,
      controlsMargin: const EdgeInsets.all(AppDesignSystem.spacing16),
      controlsPadding: const EdgeInsets.all(AppDesignSystem.spacing8),
      dotsDecorator: DotsDecorator(
        size: const Size(8.0, 8.0),
        color: isDark
            ? AppDesignSystem.darkSeparator
            : AppDesignSystem.lightSeparator,
        activeSize: const Size(24.0, 8.0),
        activeColor: isDark
            ? AppDesignSystem.systemBlueDark
            : AppDesignSystem.systemBlue,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      ),
      dotsContainerDecorator: ShapeDecoration(
        color: isDark
            ? AppDesignSystem.darkSecondaryBackground
            : AppDesignSystem.lightSecondaryBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDesignSystem.cornerRadius8),
          ),
        ),
      ),
    );
  }
}
