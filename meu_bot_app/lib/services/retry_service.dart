import 'dart:async';

/// Serviço de retry com exponential backoff
///
/// Usado para operações de rede que podem falhar temporariamente
class RetryService {
  /// Número máximo de tentativas
  static const int maxRetries = 3;

  /// Delay base entre tentativas (em segundos)
  static const int baseDelaySeconds = 2;

  /// Executa uma operação com retry automático
  ///
  /// [operation] - Função a ser executada
  /// [retries] - Número de tentativas restantes (uso interno)
  /// [onRetry] - Callback chamado antes de cada retry
  ///
  /// Retorna o resultado da operação ou lança exceção após esgotar tentativas
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    int retries = maxRetries,
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    final attemptNumber = maxRetries - retries + 1;

    try {
      return await operation();
    } catch (e) {
      // Se não houver mais tentativas, lança exceção
      if (retries <= 1) {
        print('✗ Falha após $maxRetries tentativas: $e');
        rethrow;
      }

      final exception = e is Exception ? e : Exception(e.toString());

      // Callback antes do retry
      if (onRetry != null) {
        onRetry(attemptNumber, exception);
      }

      // Calcular delay com exponential backoff
      final delaySeconds = baseDelaySeconds * attemptNumber;
      final delay = Duration(seconds: delaySeconds);

      print('⚠️ Tentativa $attemptNumber falhou. Tentando novamente em ${delaySeconds}s...');

      // Aguardar antes de tentar novamente
      await Future.delayed(delay);

      // Tentar novamente
      return execute(
        operation: operation,
        retries: retries - 1,
        onRetry: onRetry,
      );
    }
  }

  /// Executa uma operação com retry e timeout
  ///
  /// [operation] - Função a ser executada
  /// [timeoutSeconds] - Timeout em segundos para cada tentativa
  /// [onRetry] - Callback antes de cada retry
  static Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    int timeoutSeconds = 30,
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    return execute(
      operation: () => operation().timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () => throw TimeoutException(
          'Operação excedeu o tempo limite de ${timeoutSeconds}s',
        ),
      ),
      onRetry: onRetry,
    );
  }

  /// Verifica se um erro é recuperável (vale a pena tentar novamente)
  ///
  /// [error] - Erro a ser verificado
  static bool isRecoverable(dynamic error) {
    if (error == null) return false;

    final errorMessage = error.toString().toLowerCase();

    // Erros de rede são recuperáveis
    if (errorMessage.contains('socket')) return true;
    if (errorMessage.contains('network')) return true;
    if (errorMessage.contains('connection')) return true;
    if (errorMessage.contains('timeout')) return true;
    if (errorMessage.contains('failed host lookup')) return true;

    // Erros HTTP 5xx são recuperáveis (problema no servidor)
    if (errorMessage.contains('500')) return true;
    if (errorMessage.contains('502')) return true;
    if (errorMessage.contains('503')) return true;
    if (errorMessage.contains('504')) return true;

    // Erros HTTP 4xx NÃO são recuperáveis (problema no cliente)
    if (errorMessage.contains('400')) return false;
    if (errorMessage.contains('401')) return false;
    if (errorMessage.contains('403')) return false;
    if (errorMessage.contains('404')) return false;

    // Por padrão, assume que não é recuperável
    return false;
  }

  /// Executa operação com retry apenas se erro for recuperável
  ///
  /// [operation] - Função a ser executada
  /// [onRetry] - Callback antes de cada retry
  static Future<T> executeIfRecoverable<T>({
    required Future<T> Function() operation,
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (isRecoverable(e)) {
        print('⚠️ Erro recuperável detectado. Tentando novamente...');
        return execute(operation: operation, onRetry: onRetry);
      } else {
        print('✗ Erro não recuperável. Não tentando novamente.');
        rethrow;
      }
    }
  }
}

/// Timeout personalizado
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}
