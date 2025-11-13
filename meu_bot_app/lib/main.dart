import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';

/// Ponto de entrada da aplicação
///
/// IMPORTANTE: A função main() agora é async porque precisamos
/// inicializar o Supabase e Firebase antes de rodar o app
void main() async {
  // Garante que o Flutter esteja inicializado antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // ========== INICIALIZAÇÃO DO SUPABASE ==========
  // Antes de configurar suas credenciais no SupabaseService,
  // este código vai tentar conectar com os valores placeholder.
  //
  // PASSOS PARA CONFIGURAR:
  // 1. Abra lib/services/supabase_service.dart
  // 2. Localize as constantes SUPABASE_URL e SUPABASE_ANON_KEY
  // 3. Substitua pelos valores reais do seu projeto Supabase
  // ================================================

  try {
    await SupabaseService.initialize();
    print('✓ Supabase inicializado com sucesso');
  } catch (e) {
    print('✗ Erro ao inicializar Supabase: $e');
    print('Verifique suas credenciais em lib/services/supabase_service.dart');
  }

  // ========== INICIALIZAÇÃO DO FIREBASE ==========
  // Antes de usar, você precisa adicionar google-services.json
  // Instruções detalhadas em: CONFIGURACAO_FIREBASE.md
  //
  // PASSOS PARA CONFIGURAR:
  // 1. Acesse Firebase Console (https://console.firebase.google.com)
  // 2. Crie/selecione seu projeto
  // 3. Adicione um app Android
  // 4. Baixe o google-services.json
  // 5. Coloque em: meu_bot_app/android/app/google-services.json
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
      // Tela inicial que verifica autenticação
      home: const AuthGate(),
    );
  }
}

/// Widget que verifica se o usuário está autenticado
/// e redireciona para a tela apropriada
///
/// - Se autenticado: vai para ChatScreen
/// - Se não autenticado: vai para LoginScreen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  /// Verifica se existe uma sessão ativa (persistência automática)
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Delay para splash

    // Verifica se há usuário logado
    final isAuth = SupabaseService.isAuthenticated();
    final currentUser = SupabaseService.getCurrentUser();

    if (isAuth && currentUser != null) {
      print('✓ Usuário autenticado: ${currentUser.email}');
    } else {
      print('✗ Nenhum usuário autenticado');
    }

    setState(() {
      _isAuthenticated = isAuth;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostra tela de loading enquanto verifica autenticação
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Verificando autenticação...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Redireciona conforme estado de autenticação
    if (_isAuthenticated) {
      // Usa a tela de chat real
      return const ChatScreen();
    } else {
      // Usa a tela de login real
      return const LoginScreen();
    }
  }
}
