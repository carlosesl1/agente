/// Configurações centralizadas do aplicativo
///
/// Este arquivo contém todas as configurações e credenciais necessárias
/// para o funcionamento do app.
///
/// ⚠️ IMPORTANTE - SEGURANÇA:
/// - Nunca commite credenciais reais neste arquivo!
/// - Para produção, use variáveis de ambiente
/// - Adicione este arquivo ao .gitignore se necessário
///
/// 📝 INSTRUÇÕES DE CONFIGURAÇÃO:
/// Siga os passos no README.md para obter suas credenciais:
/// 1. Supabase: https://app.supabase.com
/// 2. Firebase: https://console.firebase.google.com
/// 3. N8N: Configure seu servidor/workflow
class AppConfig {
  // ============================================================================
  // SUPABASE CONFIGURATION
  // ============================================================================

  /// URL do projeto Supabase
  ///
  /// Onde encontrar:
  /// 1. Acesse https://app.supabase.com
  /// 2. Selecione seu projeto
  /// 3. Vá em Settings → API
  /// 4. Copie a "Project URL"
  ///
  /// Formato: https://[seu-projeto].supabase.co
  ///
  /// TODO: Substituir com a URL real do seu projeto Supabase
  static const String supabaseUrl = 'https://sua-url-aqui.supabase.co';

  /// Chave pública (anon key) do Supabase
  ///
  /// Onde encontrar:
  /// 1. Acesse https://app.supabase.com
  /// 2. Selecione seu projeto
  /// 3. Vá em Settings → API
  /// 4. Copie a "anon public" key
  ///
  /// NOTA: Esta é uma chave pública segura para uso no cliente
  ///
  /// TODO: Substituir com a chave anon do seu projeto Supabase
  static const String supabaseAnonKey = 'sua-chave-anon-aqui';

  // ============================================================================
  // N8N CONFIGURATION
  // ============================================================================

  /// URL do webhook N8N para comunicação com o bot
  ///
  /// Como configurar:
  /// 1. Crie um workflow no N8N
  /// 2. Adicione um nó "Webhook"
  /// 3. Configure para aceitar POST requests
  /// 4. Copie a "Production URL"
  ///
  /// Formato esperado: https://seu-n8n.com/webhook/seu-endpoint
  ///
  /// Formato do payload enviado:
  /// {
  ///   "userId": "id-do-usuario",
  ///   "messageType": "text|image|audio",
  ///   "content": "mensagem ou base64",
  ///   "timestamp": "ISO 8601"
  /// }
  ///
  /// Formato esperado de resposta:
  /// {
  ///   "success": true,
  ///   "response": {
  ///     "type": "text|image|audio",
  ///     "text": "Resposta do bot",
  ///     "data": "URL ou base64 (opcional)"
  ///   }
  /// }
  ///
  /// TODO: Substituir com a URL do seu webhook N8N
  static const String n8nWebhookUrl = 'https://seu-webhook.n8n.com/webhook/bot';

  // ============================================================================
  // FIREBASE CONFIGURATION
  // ============================================================================

  /// Configuração do Firebase
  ///
  /// O Firebase é configurado via arquivo google-services.json
  /// que deve estar localizado em: android/app/google-services.json
  ///
  /// Como obter:
  /// 1. Acesse https://console.firebase.google.com
  /// 2. Selecione seu projeto (ou crie um novo)
  /// 3. Adicione um app Android
  /// 4. Package name: com.example.meu_bot_app
  /// 5. Baixe o google-services.json
  /// 6. Coloque em android/app/google-services.json
  ///
  /// Serviços utilizados:
  /// - Firebase Cloud Messaging (FCM) para notificações push
  ///
  /// TODO: Baixar google-services.json e colocar em android/app/

  // ============================================================================
  // APP CONSTANTS
  // ============================================================================

  /// Nome do aplicativo
  static const String appName = 'Meu Bot App';

  /// Versão do aplicativo
  static const String appVersion = '1.0.0';

  /// Timeout padrão para requisições HTTP (em segundos)
  static const int httpTimeout = 30;

  /// Tamanho máximo de imagem permitido (em MB)
  static const int maxImageSizeMB = 10;

  /// Tamanho máximo de áudio permitido (em MB)
  static const int maxAudioSizeMB = 5;

  /// Formatos de imagem aceitos
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Formatos de áudio aceitos
  static const List<String> allowedAudioFormats = [
    'm4a',
    'aac',
    'mp3',
    'wav',
  ];

  // ============================================================================
  // VALIDATION METHODS
  // ============================================================================

  /// Verifica se as configurações do Supabase estão preenchidas
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('sua-url-aqui') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('sua-chave-anon-aqui');
  }

  /// Verifica se a configuração do N8N está preenchida
  static bool get isN8nConfigured {
    return n8nWebhookUrl.isNotEmpty &&
        !n8nWebhookUrl.contains('seu-webhook');
  }

  /// Verifica se todas as configurações obrigatórias estão preenchidas
  static bool get isFullyConfigured {
    return isSupabaseConfigured && isN8nConfigured;
  }

  /// Retorna uma mensagem descrevendo quais configurações faltam
  static String getMissingConfigurationsMessage() {
    final List<String> missing = [];

    if (!isSupabaseConfigured) {
      missing.add('Supabase (lib/config/app_config.dart)');
    }

    if (!isN8nConfigured) {
      missing.add('N8N webhook (lib/config/app_config.dart)');
    }

    if (missing.isEmpty) {
      return 'Todas as configurações estão OK!';
    }

    return 'Configurações pendentes:\n- ${missing.join('\n- ')}\n\nConsulte o README.md para instruções.';
  }

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  /// Habilitar logs de debug (desabilitar em produção)
  static const bool enableDebugLogs = true;

  /// Habilitar modo de desenvolvimento (mock data, etc)
  static const bool isDevelopmentMode = true;

  /// Habilitar notificações push
  static const bool enablePushNotifications = true;

  /// Habilitar analytics (futuro)
  static const bool enableAnalytics = false;
}
