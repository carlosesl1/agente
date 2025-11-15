import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'supabase_service.dart';
import 'message_service.dart';

/// Serviço de notificações push com Firebase Cloud Messaging
///
/// Responsável por gerenciar notificações push do bot
class NotificationService {
  /// Instância do Firebase Messaging
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Plugin de notificações locais (para mostrar notificações no Android)
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Token FCM do dispositivo
  static String? _deviceToken;

  /// Callback para quando receber notificação e abrir o app
  static Function(Map<String, dynamic>)? _onNotificationOpenedApp;

  // ========== INICIALIZAÇÃO ==========

  /// Inicializa o serviço de notificações
  ///
  /// Deve ser chamado no main.dart antes de runApp()
  ///
  /// [onNotificationOpenedApp] - Callback quando usuário toca na notificação
  ///
  /// Exemplo de uso:
  /// ```dart
  /// await NotificationService.initialize(
  ///   onNotificationOpenedApp: (data) {
  ///     // Navegar para a tela de chat
  ///     print('Notificação clicada: $data');
  ///   },
  /// );
  /// ```
  static Future<void> initialize({
    Function(Map<String, dynamic>)? onNotificationOpenedApp,
  }) async {
    try {
      _onNotificationOpenedApp = onNotificationOpenedApp;

      // Inicializa Firebase (se ainda não foi inicializado)
      // NOTA: Antes de usar, você precisa adicionar google-services.json
      // Instruções em: CONFIGURACAO_FIREBASE.md
      await Firebase.initializeApp();

      print('✓ Firebase inicializado');

      // Solicita permissão de notificações
      await _requestNotificationPermission();

      // Inicializa notificações locais
      await _initializeLocalNotifications();

      // Configura handlers de mensagens
      _setupMessageHandlers();

      // Obtém token do dispositivo
      await getDeviceToken();

      print('✓ Serviço de notificações inicializado');
    } catch (e) {
      print('✗ Erro ao inicializar notificações: $e');
      print('Verifique se você adicionou o google-services.json');
    }
  }

  /// Inicializa notificações locais (Android/iOS)
  static Future<void> _initializeLocalNotifications() async {
    // Configurações Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurações iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurações gerais
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializa com callback quando notificação é clicada
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Quando usuário clica na notificação
        if (response.payload != null && _onNotificationOpenedApp != null) {
          // Parse do payload JSON
          try {
            final data = <String, dynamic>{'payload': response.payload};
            _onNotificationOpenedApp!(data);
          } catch (e) {
            print('Erro ao processar payload: $e');
          }
        }
      },
    );

    print('✓ Notificações locais inicializadas');
  }

  /// Configura handlers para diferentes estados do app
  static void _setupMessageHandlers() {
    // Handler para notificação em FOREGROUND (app aberto)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handler para notificação em BACKGROUND (app minimizado)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handler para notificação quando app estava TERMINATED (fechado)
    // Verifica se há mensagem inicial
    _checkInitialMessage();
  }

  /// Verifica se o app foi aberto por uma notificação
  static Future<void> _checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _handleTerminatedMessage(message);
    }
  }

  // ========== HANDLERS DE MENSAGENS ==========

  /// Handler para mensagens quando app está em FOREGROUND (aberto)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Notificação recebida (app aberto)');
    print('Título: ${message.notification?.title}');
    print('Corpo: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Processa e salva a mensagem no banco
    await _processIncomingMessage(message);

    // Mostra notificação local (mesmo com app aberto)
    await _showLocalNotification(message);
  }

  /// Handler para mensagens quando app está em BACKGROUND (minimizado)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📩 Notificação clicada (app em background)');
    print('Data: ${message.data}');

    // Processa e salva a mensagem no banco
    await _processIncomingMessage(message);

    // Abre o chat
    if (_onNotificationOpenedApp != null) {
      _onNotificationOpenedApp!(message.data);
    }
  }

  /// Handler para mensagens quando app estava TERMINATED (fechado)
  static Future<void> _handleTerminatedMessage(RemoteMessage message) async {
    print('📩 App aberto via notificação (app estava fechado)');
    print('Data: ${message.data}');

    // Processa e salva a mensagem no banco
    await _processIncomingMessage(message);

    // Abre o chat
    if (_onNotificationOpenedApp != null) {
      _onNotificationOpenedApp!(message.data);
    }
  }

  /// Processa mensagem recebida via push e salva no banco
  static Future<void> _processIncomingMessage(RemoteMessage message) async {
    try {
      print('⚙️  Processando mensagem recebida...');

      // Extrai dados da mensagem
      final data = message.data;
      final messageText = data['message'] ?? message.notification?.body ?? '';
      final messageType = data['type'] ?? 'text';
      final userId = data['userId'];

      if (messageText.isEmpty) {
        print('⚠️  Mensagem vazia, ignorando');
        return;
      }

      // Salva mensagem no Supabase
      final user = SupabaseService.getCurrentUser();
      if (user != null) {
        print('💾 Salvando mensagem no banco...');

        // Cria mensagem do bot
        final botMessage = {
          'user_id': user.id,
          'text': messageText,
          'type': messageType,
          'author_id': 'bot',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Salva no Supabase
        await SupabaseService.client
            .from('messages')
            .insert(botMessage);

        print('✓ Mensagem salva no banco');
      } else {
        print('⚠️  Usuário não autenticado, mensagem não salva');
      }
    } catch (e) {
      print('❌ Erro ao processar mensagem: $e');
    }
  }

  /// Mostra uma notificação local (Android/iOS)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      // Configurações Android
      const androidDetails = AndroidNotificationDetails(
        'chat_channel', // ID do canal
        'Chat Notifications', // Nome do canal
        channelDescription: 'Notificações de mensagens do bot',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      // Configurações iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Detalhes da notificação
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Mostra a notificação
      await _localNotifications.show(
        message.hashCode, // ID único
        message.notification?.title ?? 'Nova mensagem',
        message.notification?.body ?? 'Você recebeu uma mensagem do bot',
        details,
        payload: message.data.toString(),
      );

      print('✓ Notificação local exibida');
    } catch (e) {
      print('Erro ao mostrar notificação local: $e');
    }
  }

  // ========== TOKEN ==========

  /// Obtém o token FCM do dispositivo
  ///
  /// Este token deve ser enviado ao backend (N8N) para que ele
  /// possa enviar notificações para este dispositivo
  ///
  /// Retorna o token ou null se houver erro
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final token = await NotificationService.getDeviceToken();
  /// if (token != null) {
  ///   await NotificationService.saveTokenToBackend(token);
  /// }
  /// ```
  static Future<String?> getDeviceToken() async {
    try {
      // Obtém o token
      _deviceToken = await _messaging.getToken();

      if (_deviceToken != null) {
        print('📱 Token FCM: $_deviceToken');
        return _deviceToken;
      } else {
        print('⚠️  Token FCM não disponível');
        return null;
      }
    } catch (e) {
      print('Erro ao obter token FCM: $e');
      return null;
    }
  }

  /// Retorna o token FCM salvo (se houver)
  static String? get currentToken => _deviceToken;

  /// Listener para quando o token é atualizado
  ///
  /// O token pode mudar quando:
  /// - App é reinstalado
  /// - Usuário limpa dados do app
  /// - Token expira
  ///
  /// Exemplo de uso:
  /// ```dart
  /// NotificationService.onTokenRefresh((newToken) {
  ///   print('Novo token: $newToken');
  ///   NotificationService.saveTokenToBackend(newToken);
  /// });
  /// ```
  static void onTokenRefresh(Function(String) callback) {
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔄 Token FCM atualizado: $newToken');
      _deviceToken = newToken;
      callback(newToken);
    });
  }

  // ========== BACKEND ==========

  /// Salva o token FCM no backend (Supabase)
  ///
  /// Este método deve ser chamado após o usuário fazer login
  /// para associar o token ao usuário
  ///
  /// [token] - Token FCM do dispositivo
  /// [userId] - ID do usuário (do Supabase)
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final token = await NotificationService.getDeviceToken();
  /// if (token != null) {
  ///   await NotificationService.saveTokenToBackend(
  ///     token,
  ///     userId: currentUser.id,
  ///   );
  /// }
  /// ```
  static Future<void> saveTokenToBackend(
    String token, {
    required String userId,
  }) async {
    try {
      print('💾 Salvando token FCM no backend...');
      print('Token: $token');
      print('UserID: $userId');

      // Salva o token no Supabase (tabela fcm_tokens)
      await SupabaseService.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✓ Token FCM salvo no Supabase');
    } catch (e) {
      print('❌ Erro ao salvar token no backend: $e');
      throw Exception('Erro ao salvar token no backend: $e');
    }
  }

  /// Remove o token FCM do backend
  ///
  /// Deve ser chamado quando usuário faz logout
  static Future<void> removeTokenFromBackend({
    required String userId,
  }) async {
    try {
      print('🗑️  Removendo token FCM do backend...');

      // Remove token do Supabase
      await SupabaseService.client
          .from('fcm_tokens')
          .delete()
          .eq('user_id', userId);

      print('✓ Token removido do backend');
    } catch (e) {
      print('❌ Erro ao remover token: $e');
    }
  }

  // ========== PERMISSÕES ==========

  /// Solicita permissão para mostrar notificações
  ///
  /// Retorna true se permissão concedida
  static Future<bool> _requestNotificationPermission() async {
    try {
      // Solicita permissão no Firebase Messaging
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✓ Permissão de notificações concedida');
        return true;
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️  Permissão de notificações provisória');
        return true;
      } else {
        print('✗ Permissão de notificações negada');
        return false;
      }
    } catch (e) {
      print('Erro ao solicitar permissão de notificações: $e');
      return false;
    }
  }

  /// Verifica se tem permissão de notificações
  static Future<bool> hasNotificationPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  /// Abre as configurações do app para o usuário conceder permissões
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // ========== INSCRIÇÃO EM TÓPICOS ==========

  /// Inscreve o dispositivo em um tópico
  ///
  /// Útil para enviar notificações para grupos de usuários
  ///
  /// Exemplo: inscrever em "all_users" para enviar para todos
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✓ Inscrito no tópico: $topic');
    } catch (e) {
      print('Erro ao inscrever no tópico: $e');
    }
  }

  /// Desinscreve o dispositivo de um tópico
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✓ Desinscrito do tópico: $topic');
    } catch (e) {
      print('Erro ao desinscrever do tópico: $e');
    }
  }

  // ========== BADGE (iOS) ==========

  /// Define o número do badge no ícone do app (iOS)
  ///
  /// [count] - Número a ser mostrado (0 para remover)
  static Future<void> setBadgeCount(int count) async {
    try {
      if (Platform.isIOS) {
        await _messaging.setAutoInitEnabled(true);
        // O badge é gerenciado automaticamente pelo Firebase no iOS
        print('✓ Badge count definido: $count');
      }
    } catch (e) {
      print('Erro ao definir badge count: $e');
    }
  }

  // ========== LIMPEZA ==========

  /// Remove todas as notificações
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('✓ Notificações limpas');
    } catch (e) {
      print('Erro ao limpar notificações: $e');
    }
  }

  /// Deleta o token FCM (útil para logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _deviceToken = null;
      print('✓ Token FCM deletado');
    } catch (e) {
      print('Erro ao deletar token: $e');
    }
  }
}

/// Handler para notificações em background (top-level function)
///
/// Esta função é chamada quando uma notificação chega com o app
/// em background. Precisa ser uma função top-level (não pode estar
/// dentro de uma classe).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa Firebase se necessário
  await Firebase.initializeApp();

  print('📩 Notificação em background: ${message.messageId}');
  print('Título: ${message.notification?.title}');
  print('Corpo: ${message.notification?.body}');
  print('Data: ${message.data}');

  // Processa e salva a mensagem no banco
  try {
    final data = message.data;
    final messageText = data['message'] ?? message.notification?.body ?? '';
    final messageType = data['type'] ?? 'text';
    final userId = data['userId'];

    if (messageText.isNotEmpty && userId != null) {
      // Salva mensagem no Supabase
      await SupabaseService.client.from('messages').insert({
        'user_id': userId,
        'text': messageText,
        'type': messageType,
        'author_id': 'bot',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✓ Mensagem salva no banco (background)');
    }
  } catch (e) {
    print('❌ Erro ao processar mensagem em background: $e');
  }
}
