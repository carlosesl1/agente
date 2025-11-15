import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Serviço de gerenciamento de preferências do aplicativo
///
/// Responsável por armazenar configurações personalizáveis do usuário,
/// como a URL do webhook N8N.
class PreferencesService {
  // Chaves para armazenamento
  static const String _keyN8nWebhookUrl = 'n8n_webhook_url';

  /// Instância do SharedPreferences
  static SharedPreferences? _prefs;

  /// Inicializa o serviço de preferências
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Garante que o serviço está inicializado
  static Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  // ==========================================================================
  // N8N WEBHOOK URL
  // ==========================================================================

  /// Obtém a URL do webhook N8N
  ///
  /// Retorna a URL personalizada se existir, caso contrário retorna
  /// a URL padrão configurada em AppConfig
  static Future<String> getN8nWebhookUrl() async {
    final prefs = await _getPrefs();
    final customUrl = prefs.getString(_keyN8nWebhookUrl);

    // Se existe URL customizada, retorna ela
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }

    // Caso contrário, retorna a URL padrão do AppConfig
    return AppConfig.n8nWebhookUrl;
  }

  /// Define uma URL customizada para o webhook N8N
  ///
  /// Permite que o usuário configure sua própria automação N8N
  static Future<bool> setN8nWebhookUrl(String url) async {
    try {
      final prefs = await _getPrefs();
      return await prefs.setString(_keyN8nWebhookUrl, url);
    } catch (e) {
      print('Erro ao salvar webhook URL: $e');
      return false;
    }
  }

  /// Remove a URL customizada do webhook N8N
  ///
  /// Volta a usar a URL padrão do AppConfig
  static Future<bool> clearN8nWebhookUrl() async {
    try {
      final prefs = await _getPrefs();
      return await prefs.remove(_keyN8nWebhookUrl);
    } catch (e) {
      print('Erro ao limpar webhook URL: $e');
      return false;
    }
  }

  /// Verifica se existe uma URL customizada configurada
  static Future<bool> hasCustomN8nWebhookUrl() async {
    final prefs = await _getPrefs();
    final customUrl = prefs.getString(_keyN8nWebhookUrl);
    return customUrl != null && customUrl.isNotEmpty;
  }

  /// Obtém a URL padrão do webhook (do AppConfig)
  static String getDefaultN8nWebhookUrl() {
    return AppConfig.n8nWebhookUrl;
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Limpa todas as preferências
  ///
  /// Use com cuidado! Remove todas as configurações personalizadas.
  static Future<bool> clearAll() async {
    try {
      final prefs = await _getPrefs();
      return await prefs.clear();
    } catch (e) {
      print('Erro ao limpar todas as preferências: $e');
      return false;
    }
  }

  /// Valida se uma URL de webhook é válida
  static bool isValidWebhookUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
}
