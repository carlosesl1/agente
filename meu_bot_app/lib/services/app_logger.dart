import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de logging estruturado
///
/// Sistema centralizado de logs com níveis, persistência e exportação
/// Facilita debugging em produção e desenvolvimento
class AppLogger {
  /// Instância singleton
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() => _instance;

  AppLogger._internal();

  /// Logger instance
  late Logger _logger;

  /// Chave para persistência no SharedPreferences
  static const String _logsKey = 'app_logs';

  /// Tamanho máximo de logs armazenados (últimos N logs)
  static const int _maxLogsStored = 500;

  /// Flag de inicialização
  bool _initialized = false;

  /// Lista de logs armazenados
  final List<LogEntry> _storedLogs = [];

  /// Callback opcional para logs (útil para enviar para analytics)
  Function(LogEntry)? onLog;

  /// Inicializa o logger
  ///
  /// [enablePersistence] - Se deve persistir logs em disco (padrão: true)
  /// [level] - Nível mínimo de log (padrão: Level.debug)
  Future<void> initialize({
    bool enablePersistence = true,
    Level level = Level.debug,
  }) async {
    if (_initialized) {
      print('⚠️  AppLogger já inicializado');
      return;
    }

    print('🚀 Inicializando AppLogger...');

    // Configura o logger com custom printer
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Número de métodos na stack trace
        errorMethodCount: 8, // Stack trace maior para erros
        lineLength: 120, // Largura da linha
        colors: true, // Cores no console
        printEmojis: true, // Emojis nos logs
        printTime: true, // Timestamp
      ),
      level: level,
    );

    // Carrega logs salvos do disco
    if (enablePersistence) {
      await _loadLogsFromDisk();
    }

    _initialized = true;
    print('✅ AppLogger inicializado (${_storedLogs.length} logs em cache)');
  }

  // ========== MÉTODOS DE LOGGING ==========

  /// Log de debug (informações técnicas detalhadas)
  ///
  /// Exemplo:
  /// ```dart
  /// AppLogger().debug('Valor da variável: $value');
  /// ```
  void debug(
    String message, {
    Map<String, dynamic>? metadata,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.debug,
      message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de informação (eventos normais do app)
  ///
  /// Exemplo:
  /// ```dart
  /// AppLogger().info('Usuário fez login', metadata: {'userId': '123'});
  /// ```
  void info(
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.info,
      message,
      metadata: metadata,
    );
  }

  /// Log de warning (situações suspeitas mas não críticas)
  ///
  /// Exemplo:
  /// ```dart
  /// AppLogger().warning('Cache está cheio, removendo itens antigos');
  /// ```
  void warning(
    String message, {
    Map<String, dynamic>? metadata,
    dynamic error,
  }) {
    _log(
      LogLevel.warning,
      message,
      metadata: metadata,
      error: error,
    );
  }

  /// Log de erro (erros que afetam funcionalidade)
  ///
  /// Exemplo:
  /// ```dart
  /// AppLogger().error(
  ///   'Falha ao carregar mensagens',
  ///   error: e,
  ///   stackTrace: stackTrace,
  ///   metadata: {'userId': userId},
  /// );
  /// ```
  void error(
    String message, {
    Map<String, dynamic>? metadata,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log interno que processa e armazena
  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? metadata,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // Cria entrada de log
    final logEntry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    // Adiciona aos logs armazenados
    _storedLogs.insert(0, logEntry);

    // Mantém apenas os últimos N logs
    if (_storedLogs.length > _maxLogsStored) {
      _storedLogs.removeLast();
    }

    // Salva em disco em background
    _saveLogsToDisk();

    // Callback opcional (para analytics, por exemplo)
    onLog?.call(logEntry);

    // Imprime no console usando logger
    switch (level) {
      case LogLevel.debug:
        _logger.d(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.info:
        _logger.i(message);
        break;
      case LogLevel.warning:
        _logger.w(message, error: error);
        break;
      case LogLevel.error:
        _logger.e(message, error: error, stackTrace: stackTrace);
        break;
    }
  }

  // ========== PERSISTÊNCIA ==========

  /// Carrega logs do disco
  Future<void> _loadLogsFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_logsKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _storedLogs.clear();

        for (final json in jsonList) {
          try {
            final logEntry = LogEntry.fromJson(json as Map<String, dynamic>);
            _storedLogs.add(logEntry);
          } catch (e) {
            print('⚠️  Erro ao deserializar log: $e');
          }
        }

        print('📂 Logs carregados do disco (${_storedLogs.length} logs)');
      }
    } catch (e) {
      print('❌ Erro ao carregar logs do disco: $e');
    }
  }

  /// Salva logs no disco
  Future<void> _saveLogsToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Converte logs para JSON
      final jsonList = _storedLogs.map((log) => log.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(_logsKey, jsonString);
    } catch (e) {
      // Silenciosamente falha (não queremos quebrar o app por causa de logs)
      print('❌ Erro ao salvar logs no disco: $e');
    }
  }

  // ========== CONSULTAS E EXPORTAÇÃO ==========

  /// Obtém todos os logs armazenados
  List<LogEntry> getAllLogs() {
    return List.unmodifiable(_storedLogs);
  }

  /// Obtém logs filtrados por nível
  ///
  /// Exemplo:
  /// ```dart
  /// final errors = AppLogger().getLogsByLevel(LogLevel.error);
  /// ```
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _storedLogs.where((log) => log.level == level).toList();
  }

  /// Obtém logs filtrados por período
  ///
  /// Exemplo:
  /// ```dart
  /// final today = AppLogger().getLogsSince(DateTime.now().subtract(Duration(days: 1)));
  /// ```
  List<LogEntry> getLogsSince(DateTime since) {
    return _storedLogs.where((log) => log.timestamp.isAfter(since)).toList();
  }

  /// Busca logs por texto
  ///
  /// Exemplo:
  /// ```dart
  /// final results = AppLogger().searchLogs('erro ao carregar');
  /// ```
  List<LogEntry> searchLogs(String query) {
    final lowerQuery = query.toLowerCase();
    return _storedLogs.where((log) {
      return log.message.toLowerCase().contains(lowerQuery) ||
          (log.error?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Exporta logs como JSON
  ///
  /// Útil para debug ou enviar para suporte
  String exportLogsAsJson() {
    final jsonList = _storedLogs.map((log) => log.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Exporta logs como texto formatado
  ///
  /// Exemplo:
  /// ```dart
  /// final logsText = AppLogger().exportLogsAsText();
  /// // Salvar em arquivo ou compartilhar
  /// ```
  String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('========== APP LOGS ==========');
    buffer.writeln('Gerado em: ${DateTime.now()}');
    buffer.writeln('Total de logs: ${_storedLogs.length}');
    buffer.writeln('==============================\n');

    for (final log in _storedLogs) {
      buffer.writeln(log.toFormattedString());
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Obtém estatísticas dos logs
  ///
  /// Retorna contagem por nível
  Map<LogLevel, int> getLogStatistics() {
    final stats = <LogLevel, int>{
      LogLevel.debug: 0,
      LogLevel.info: 0,
      LogLevel.warning: 0,
      LogLevel.error: 0,
    };

    for (final log in _storedLogs) {
      stats[log.level] = (stats[log.level] ?? 0) + 1;
    }

    return stats;
  }

  /// Limpa todos os logs armazenados
  Future<void> clearLogs() async {
    _storedLogs.clear();
    await _saveLogsToDisk();
    print('🗑️  Logs limpos');
  }

  /// Limpa logs antigos (mais velhos que X dias)
  ///
  /// Exemplo:
  /// ```dart
  /// await AppLogger().clearOldLogs(days: 7); // Remove logs > 7 dias
  /// ```
  Future<void> clearOldLogs({int days = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final initialCount = _storedLogs.length;

    _storedLogs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));

    final removedCount = initialCount - _storedLogs.length;
    await _saveLogsToDisk();

    print('🗑️  $removedCount logs antigos removidos (>${days} dias)');
  }
}

/// Níveis de log
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Entrada de log estruturada
class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.metadata,
    this.error,
    this.stackTrace,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'error': error,
      'stackTrace': stackTrace,
    };
  }

  /// Cria a partir de JSON
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      stackTrace: json['stackTrace'] as String?,
    );
  }

  /// Converte para string formatada
  String toFormattedString() {
    final buffer = StringBuffer();

    // Emoji baseado no nível
    final emoji = _getLevelEmoji();

    // Cabeçalho
    buffer.writeln('$emoji [${level.toString().split('.').last.toUpperCase()}] ${_formatTimestamp(timestamp)}');
    buffer.writeln('Mensagem: $message');

    // Metadata
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.writeln('Metadata: $metadata');
    }

    // Erro
    if (error != null) {
      buffer.writeln('Erro: $error');
    }

    // Stack trace (limitado a primeiras 5 linhas)
    if (stackTrace != null) {
      final lines = stackTrace!.split('\n').take(5).join('\n');
      buffer.writeln('Stack Trace:\n$lines');
    }

    return buffer.toString();
  }

  /// Retorna emoji baseado no nível
  String _getLevelEmoji() {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  /// Formata timestamp
  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

/// Classe auxiliar para logging global
///
/// Uso simplificado em qualquer lugar do app:
/// ```dart
/// Log.info('Usuário fez login');
/// Log.error('Falha ao carregar', error: e);
/// ```
class Log {
  static final AppLogger _logger = AppLogger();

  static void debug(
    String message, {
    Map<String, dynamic>? metadata,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.debug(message, metadata: metadata, error: error, stackTrace: stackTrace);
  }

  static void info(
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    _logger.info(message, metadata: metadata);
  }

  static void warning(
    String message, {
    Map<String, dynamic>? metadata,
    dynamic error,
  }) {
    _logger.warning(message, metadata: metadata, error: error);
  }

  static void error(
    String message, {
    Map<String, dynamic>? metadata,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.error(message, metadata: metadata, error: error, stackTrace: stackTrace);
  }
}
