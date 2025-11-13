import 'package:flutter/material.dart';
import 'services/supabase_service.dart';

/// Ponto de entrada da aplicação
///
/// IMPORTANTE: A função main() agora é async porque precisamos
/// inicializar o Supabase antes de rodar o app
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
/// - Se autenticado: vai para ChatScreen (ainda não criada)
/// - Se não autenticado: vai para LoginScreen (ainda não criada)
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
      // TODO: Substituir por ChatScreen quando criar a tela
      return const PlaceholderChatScreen();
    } else {
      // TODO: Substituir por LoginScreen quando criar a tela
      return const PlaceholderLoginScreen();
    }
  }
}

// ========== TELAS PLACEHOLDER (TEMPORÁRIAS) ==========
// Essas telas serão substituídas pelas telas reais posteriormente

/// Tela placeholder para o chat (será substituída)
class PlaceholderChatScreen extends StatelessWidget {
  const PlaceholderChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) {
                // Recarrega o app para voltar à tela de login
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Tela de Chat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Usuário: ${user?.email ?? "Desconhecido"}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Esta é uma tela temporária.\nA tela real de chat será criada posteriormente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela placeholder para login (será substituída)
class PlaceholderLoginScreen extends StatelessWidget {
  const PlaceholderLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Tela de Login',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Esta é uma tela temporária.\nA tela real de login será criada posteriormente.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Simula um login (apenas para teste)
                // Na tela real, isso será substituído pelo formulário
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Informação'),
                    content: const Text(
                      'A funcionalidade de login será implementada posteriormente.\n\n'
                      'Para testar, você precisará:\n'
                      '1. Configurar as credenciais do Supabase\n'
                      '2. Criar a tela de login real\n'
                      '3. Implementar os formulários de autenticação',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Info sobre Login'),
            ),
          ],
        ),
      ),
    );
  }
}
