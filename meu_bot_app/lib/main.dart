import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Bot App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Tela inicial: Splash Screen com animação
      // O SplashScreen verifica autenticação e redireciona automaticamente
      home: const SplashScreen(),
    );
  }
}
