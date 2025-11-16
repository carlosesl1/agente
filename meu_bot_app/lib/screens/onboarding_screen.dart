import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

/// Tela de introdução premium mostrada apenas na primeira vez
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

  /// Widget decorativo para as páginas com animação premium
  Widget _buildImage(String assetName, double size) {
    return Icon(
      _getIconForPage(assetName),
      size: size,
      color: Theme.of(context).primaryColor,
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .then(delay: 200.ms)
        .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3));
  }

  IconData _getIconForPage(String page) {
    switch (page) {
      case 'multiple_assistants':
        return Icons.group_work_rounded;
      case 'ai_powered':
        return Icons.psychology_rounded;
      case 'personalized':
        return Icons.palette_rounded;
      case 'ready':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.chat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const bodyStyle = TextStyle(fontSize: 16.0);

    final pageDecoration = PageDecoration(
      titleTextStyle: const TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: isDark ? Colors.black : Colors.white,
      imagePadding: const EdgeInsets.all(24),
    );

    return IntroductionScreen(
      key: _introKey,
      globalBackgroundColor: isDark ? Colors.black : Colors.white,
      pages: [
        // Página 1: Múltiplos Assistentes
        PageViewModel(
          title: "Múltiplos Assistentes IA",
          body: "Crie assistentes personalizados para diferentes áreas da sua vida: Trabalho, Casa, Finanças, Saúde e muito mais.",
          image: _buildImage('multiple_assistants', 180),
          decoration: pageDecoration,
        ),

        // Página 2: Inteligência Artificial
        PageViewModel(
          title: "Powered by AI",
          body: "Integração com N8N permite conectar seus assistentes aos melhores modelos de IA: GPT-4, Claude, Gemini e outros.",
          image: _buildImage('ai_powered', 180),
          decoration: pageDecoration,
        ),

        // Página 3: Personalização
        PageViewModel(
          title: "Totalmente Personalizável",
          body: "Escolha cores, avatares e configure webhooks únicos para cada assistente. Cada conversa é única e organizada.",
          image: _buildImage('personalized', 180),
          decoration: pageDecoration,
        ),

        // Página 4: Pronto para começar
        PageViewModel(
          title: "Pronto para começar?",
          bodyWidget: Column(
            children: [
              const Text(
                "Crie seu primeiro assistente e experimente o futuro das conversas com IA!",
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              const SizedBox(height: 32),
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    '🚀 Vamos começar!',
                    textStyle: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
              ),
            ],
          ),
          image: _buildImage('ready', 180),
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
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: Theme.of(context).primaryColor,
      ),
      done: Text(
        'Começar',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Colors.grey,
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).primaryColor,
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: ShapeDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
