import 'dart:convert';

/// Serviço de validação e sanitização de dados
///
/// Garante segurança e integridade dos dados
class ValidationService {
  // ============================================================================
  // VALIDAÇÕES DE EMAIL
  // ============================================================================

  /// Valida formato de email
  static bool isValidEmail(String email) {
    if (email.trim().isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  /// Normaliza email (lowercase e trim)
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  // ============================================================================
  // VALIDAÇÕES DE SENHA
  // ============================================================================

  /// Valida força da senha
  ///
  /// Retorna lista de problemas encontrados (vazio se válida)
  static List<String> validatePassword(String password) {
    final issues = <String>[];

    if (password.length < 8) {
      issues.add('Senha deve ter pelo menos 8 caracteres');
    }

    if (password.length > 128) {
      issues.add('Senha muito longa (máximo 128 caracteres)');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      issues.add('Senha deve conter pelo menos uma letra maiúscula');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      issues.add('Senha deve conter pelo menos uma letra minúscula');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      issues.add('Senha deve conter pelo menos um número');
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      issues.add('Senha deve conter pelo menos um caractere especial');
    }

    return issues;
  }

  /// Verifica se senha é forte
  static bool isStrongPassword(String password) {
    return validatePassword(password).isEmpty;
  }

  /// Calcula força da senha (0-100)
  static int getPasswordStrength(String password) {
    int strength = 0;

    // Comprimento
    if (password.length >= 8) strength += 20;
    if (password.length >= 12) strength += 10;
    if (password.length >= 16) strength += 10;

    // Complexidade
    if (password.contains(RegExp(r'[A-Z]'))) strength += 15;
    if (password.contains(RegExp(r'[a-z]'))) strength += 15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 15;

    return strength.clamp(0, 100);
  }

  // ============================================================================
  // VALIDAÇÕES DE URL
  // ============================================================================

  /// Valida formato de URL
  static bool isValidUrl(String url) {
    if (url.trim().isEmpty) return false;

    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Valida URL de webhook N8N
  static bool isValidWebhookUrl(String url) {
    if (!isValidUrl(url)) return false;

    final normalizedUrl = url.trim().toLowerCase();

    // Deve ser HTTPS em produção
    if (!normalizedUrl.startsWith('https://') &&
        !normalizedUrl.startsWith('http://localhost') &&
        !normalizedUrl.startsWith('http://127.0.0.1')) {
      return false;
    }

    // Deve conter "webhook" no caminho
    if (!normalizedUrl.contains('/webhook')) {
      return false;
    }

    return true;
  }

  /// Sanitiza URL (remove espaços, adiciona https se necessário)
  static String sanitizeUrl(String url) {
    var sanitized = url.trim();

    // Remove espaços
    sanitized = sanitized.replaceAll(' ', '');

    // Adiciona https:// se não tiver protocolo
    if (!sanitized.startsWith('http://') &&
        !sanitized.startsWith('https://')) {
      sanitized = 'https://$sanitized';
    }

    return sanitized;
  }

  // ============================================================================
  // VALIDAÇÕES DE TEXTO
  // ============================================================================

  /// Sanitiza texto removendo caracteres perigosos
  static String sanitizeText(String text) {
    var sanitized = text.trim();

    // Remove caracteres de controle
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Remove scripts HTML
    sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>',
        caseSensitive: false, multiLine: true), '');

    // Remove eventos inline
    sanitized = sanitized.replaceAll(
        RegExp(r'on\w+\s*=', caseSensitive: false), '');

    return sanitized;
  }

  /// Valida comprimento de texto
  static bool isValidTextLength(
    String text, {
    int minLength = 1,
    int maxLength = 10000,
  }) {
    final length = text.trim().length;
    return length >= minLength && length <= maxLength;
  }

  /// Remove emojis do texto
  static String removeEmojis(String text) {
    return text.replaceAll(
      RegExp(
        r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
      ),
      '',
    );
  }

  // ============================================================================
  // VALIDAÇÕES DE ARQUIVOS
  // ============================================================================

  /// Valida tamanho de arquivo em bytes
  static bool isValidFileSize(
    int bytes, {
    required int maxSizeInMB,
  }) {
    final maxBytes = maxSizeInMB * 1024 * 1024;
    return bytes > 0 && bytes <= maxBytes;
  }

  /// Valida extensão de arquivo
  static bool isValidFileExtension(
    String filename,
    List<String> allowedExtensions,
  ) {
    final extension = filename.toLowerCase().split('.').last;
    return allowedExtensions.contains(extension);
  }

  /// Valida nome de arquivo (remove caracteres perigosos)
  static String sanitizeFilename(String filename) {
    var sanitized = filename.trim();

    // Remove caracteres perigosos
    sanitized =
        sanitized.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '');

    // Remove múltiplos espaços
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Limita tamanho
    if (sanitized.length > 255) {
      final extension = sanitized.split('.').last;
      sanitized =
          '${sanitized.substring(0, 255 - extension.length - 1)}.$extension';
    }

    return sanitized;
  }

  // ============================================================================
  // VALIDAÇÕES DE JSON
  // ============================================================================

  /// Valida se string é JSON válido
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sanitiza JSON (remove campos perigosos)
  static Map<String, dynamic> sanitizeJson(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};

    json.forEach((key, value) {
      // Remove campos que começam com _ (privados)
      if (key.startsWith('_')) return;

      // Sanitiza valores de string
      if (value is String) {
        sanitized[key] = sanitizeText(value);
      }
      // Recursivamente sanitiza objetos aninhados
      else if (value is Map<String, dynamic>) {
        sanitized[key] = sanitizeJson(value);
      }
      // Mantém outros tipos
      else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  // ============================================================================
  // VALIDAÇÕES DE SEGURANÇA
  // ============================================================================

  /// Detecta tentativa de SQL injection
  static bool containsSqlInjection(String text) {
    final sqlKeywords = [
      'select',
      'insert',
      'update',
      'delete',
      'drop',
      'create',
      'alter',
      'exec',
      'execute',
      '--',
      ';--',
      '/*',
      '*/',
      '@@',
      '@',
      'char',
      'nchar',
      'varchar',
      'nvarchar',
      'union',
      'waitfor',
      'delay',
    ];

    final lowerText = text.toLowerCase();

    return sqlKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Detecta tentativa de XSS
  static bool containsXss(String text) {
    final xssPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
    ];

    return xssPatterns.any((pattern) => text.contains(pattern));
  }

  /// Detecta tentativa de path traversal
  static bool containsPathTraversal(String text) {
    final traversalPatterns = [
      '../',
      '..\\',
      '%2e%2e%2f',
      '%2e%2e/',
      '..%2f',
      '%2e%2e%5c',
    ];

    final lowerText = text.toLowerCase();

    return traversalPatterns.any((pattern) => lowerText.contains(pattern));
  }

  /// Valida se texto é seguro (sem injeções)
  static bool isSafeText(String text) {
    return !containsSqlInjection(text) &&
        !containsXss(text) &&
        !containsPathTraversal(text);
  }

  // ============================================================================
  // RATE LIMITING (BÁSICO)
  // ============================================================================

  static final Map<String, List<DateTime>> _rateLimitMap = {};

  /// Verifica rate limit simples
  ///
  /// [key] - Chave única (ex: userId, IP)
  /// [maxRequests] - Máximo de requisições
  /// [windowInSeconds] - Janela de tempo em segundos
  static bool checkRateLimit(
    String key, {
    int maxRequests = 10,
    int windowInSeconds = 60,
  }) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(seconds: windowInSeconds));

    // Remove requisições antigas
    _rateLimitMap[key]?.removeWhere((time) => time.isBefore(windowStart));

    // Cria lista se não existir
    _rateLimitMap[key] ??= [];

    // Verifica limite
    if (_rateLimitMap[key]!.length >= maxRequests) {
      return false; // Limite excedido
    }

    // Adiciona requisição atual
    _rateLimitMap[key]!.add(now);

    return true; // OK
  }

  /// Limpa cache de rate limiting
  static void clearRateLimitCache() {
    _rateLimitMap.clear();
  }
}
