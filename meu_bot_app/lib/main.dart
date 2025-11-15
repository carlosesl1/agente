import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_themes.dart';
import 'theme/theme_provider.dart';
import 'screens/splash_screen.dart';

/// Ponto de entrada da aplicação
///
/// IMPORTANTE: A função main() agora é async porque precisamos
/// inicializar o Supabase e Firebase antes de rodar o app
void main() async {
  // Garante que o Flutter esteja inicializado antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // ========== INICIALIZAÇÃO DO SUPABASE ==========
  // 📝 TODO: Configure suas credenciais do Supabase
  //
  // PASSOS PARA CONFIGURAR:
  // 1. Abra lib/config/app_config.dart
  // 2. Localize supabaseUrl e supabaseAnonKey
  // 3. Substitua pelos valores reais do seu projeto Supabase
  //
  // Consulte o README.md para instruções detalhadas
  // ================================================

  try {
    await SupabaseService.initialize();
    print('✓ Supabase inicializado com sucesso');
  } catch (e) {
    print('✗ Erro ao inicializar Supabase: $e');
    print('📝 Configure suas credenciais em lib/config/app_config.dart');
  }

  // ========== INICIALIZAÇÃO DO FIREBASE ==========
  // 📝 TODO: Adicionar google-services.json do Firebase
  //
  // PASSOS PARA CONFIGURAR:
  // 1. Acesse Firebase Console (https://console.firebase.google.com)
  // 2. Crie/selecione seu projeto
  // 3. Adicione um app Android (package: com.example.meu_bot_app)
  // 4. Baixe o google-services.json
  // 5. Coloque em: meu_bot_app/android/app/google-services.json
  //
  // Consulte o README.md e CONFIGURACAO_FIREBASE.md para detalhes
  // ================================================

  // Registra handler de notificações em background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    // Inicializa notificações
    await NotificationService.initialize(
      onNotificationOpenedApp: (data) {
        print('📱 App aberto via notificação: $data');
        // TODO: Navegar para a tela de chat
        // Você pode usar um GlobalKey<NavigatorState> aqui
      },
    );
    print('✓ Firebase e notificações inicializados');
  } catch (e) {
    print('✗ Erro ao inicializar Firebase: $e');
    print('Verifique se você adicionou o google-services.json');
  }

  // ========== INICIALIZAÇÃO DAS PREFERÊNCIAS ==========
  // Inicializa SharedPreferences para configurações personalizadas
  try {
    await PreferencesService.initialize();
    print('✓ Preferências inicializadas');
  } catch (e) {
    print('✗ Erro ao inicializar preferências: $e');
  }

  // Inicializa o ThemeProvider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MyApp({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeProvider,
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Meu Bot App',
            debugShowCheckedModeBanner: false,

            // Temas customizados
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: theme.themeMode,

            // Tela inicial: Splash Screen com animação
            // O SplashScreen verifica autenticação e redireciona automaticamente
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
