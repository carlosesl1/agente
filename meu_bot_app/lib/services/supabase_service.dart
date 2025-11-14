import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Serviço responsável pela autenticação e integração com Supabase
///
/// 📝 INSTRUÇÕES PARA CONFIGURAR SUAS CREDENCIAIS:
/// 1. Acesse seu projeto no Supabase (https://supabase.com/dashboard)
/// 2. Vá em Settings > API
/// 3. Copie a URL do projeto e a chave anon/public
/// 4. Abra lib/config/app_config.dart
/// 5. Substitua os valores de supabaseUrl e supabaseAnonKey
///
/// ⚠️ TODO: Configure suas credenciais em lib/config/app_config.dart
class SupabaseService {
  /// Cliente Supabase singleton
  static final SupabaseClient _client = Supabase.instance.client;

  /// Inicializa o Supabase
  /// Deve ser chamado antes de runApp() no main.dart
  static Future<void> initialize() async {
    // Valida se as configurações foram preenchidas
    if (!AppConfig.isSupabaseConfigured) {
      throw Exception(
        'Supabase não configurado!\n\n'
        'Configure suas credenciais em lib/config/app_config.dart\n'
        'Consulte o README.md para instruções detalhadas.',
      );
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // Recomendado para apps mobile
      ),
    );
  }

  /// Retorna o cliente Supabase
  static SupabaseClient get client => _client;

  /// Retorna o cliente de autenticação
  static GoTrueClient get auth => _client.auth;

  // ========== MÉTODOS DE AUTENTICAÇÃO ==========

  /// Cadastra um novo usuário com email e senha
  ///
  /// Retorna o AuthResponse com dados do usuário ou lança exceção em caso de erro
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   final response = await SupabaseService.signUp('email@example.com', 'senha123');
  ///   print('Usuário criado: ${response.user?.email}');
  /// } catch (e) {
  ///   print('Erro ao cadastrar: $e');
  /// }
  /// ```
  static Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Falha ao criar usuário');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Erro de autenticação: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  /// Faz login com email e senha
  ///
  /// Retorna o AuthResponse com dados do usuário ou lança exceção em caso de erro
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   final response = await SupabaseService.signIn('email@example.com', 'senha123');
  ///   print('Login realizado: ${response.user?.email}');
  /// } catch (e) {
  ///   print('Erro ao fazer login: $e');
  /// }
  /// ```
  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Credenciais inválidas');
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Erro de autenticação: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Faz logout do usuário atual
  ///
  /// Remove a sessão local e do servidor
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   await SupabaseService.signOut();
  ///   print('Logout realizado com sucesso');
  /// } catch (e) {
  ///   print('Erro ao fazer logout: $e');
  /// }
  /// ```
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  /// Retorna o usuário atualmente autenticado
  ///
  /// Retorna null se não houver usuário logado
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final user = SupabaseService.getCurrentUser();
  /// if (user != null) {
  ///   print('Usuário logado: ${user.email}');
  /// } else {
  ///   print('Nenhum usuário logado');
  /// }
  /// ```
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Verifica se existe uma sessão ativa (usuário logado)
  ///
  /// Retorna true se houver usuário autenticado, false caso contrário
  ///
  /// Exemplo de uso:
  /// ```dart
  /// if (SupabaseService.isAuthenticated()) {
  ///   // Usuário está logado
  ///   navigateToChat();
  /// } else {
  ///   // Usuário não está logado
  ///   navigateToLogin();
  /// }
  /// ```
  static bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  /// Retorna a sessão atual
  ///
  /// Útil para verificar tokens e dados da sessão
  static Session? getCurrentSession() {
    return _client.auth.currentSession;
  }

  /// Stream que notifica sobre mudanças no estado de autenticação
  ///
  /// Use para reagir a login/logout em tempo real
  ///
  /// Exemplo de uso:
  /// ```dart
  /// SupabaseService.authStateChanges().listen((event) {
  ///   if (event == AuthChangeEvent.signedIn) {
  ///     print('Usuário fez login');
  ///   } else if (event == AuthChangeEvent.signedOut) {
  ///     print('Usuário fez logout');
  ///   }
  /// });
  /// ```
  static Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }

  /// Recupera senha do usuário via email
  ///
  /// Envia um email com link para redefinir a senha
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   await SupabaseService.resetPassword('email@example.com');
  ///   print('Email de recuperação enviado');
  /// } catch (e) {
  ///   print('Erro ao enviar email: $e');
  /// }
  /// ```
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Erro ao recuperar senha: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao enviar email de recuperação: $e');
    }
  }

  /// Atualiza dados do usuário (email, senha, etc)
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   await SupabaseService.updateUser(
  ///     email: 'novoemail@example.com',
  ///     password: 'novasenha123',
  ///   );
  ///   print('Usuário atualizado');
  /// } catch (e) {
  ///   print('Erro ao atualizar: $e');
  /// }
  /// ```
  static Future<UserResponse> updateUser({
    String? email,
    String? password,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
        ),
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Erro ao atualizar usuário: ${e.message}');
    } catch (e) {
      throw Exception('Erro ao atualizar dados: $e');
    }
  }
}
