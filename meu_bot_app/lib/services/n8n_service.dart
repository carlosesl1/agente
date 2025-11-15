import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import 'retry_service.dart';
import 'offline_queue_service.dart';
import 'connectivity_service.dart';
import 'preferences_service.dart';

/// Serviço de integração com N8N
///
/// Responsável por enviar mensagens ao webhook do N8N e processar respostas
///
/// 📝 INSTRUÇÕES PARA CONFIGURAR:
/// 1. Acesse seu N8N
/// 2. Crie um workflow com um nó "Webhook"
/// 3. Configure para aceitar POST requests
/// 4. Copie a URL do webhook (Production URL)
/// 5. Abra lib/config/app_config.dart
/// 6. Substitua o valor de n8nWebhookUrl
///
/// ⚠️ TODO: Configure a URL do webhook em lib/config/app_config.dart
class N8nService {
  /// Cliente HTTP Dio para requisições
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: AppConfig.httpTimeout),
      receiveTimeout: Duration(seconds: AppConfig.httpTimeout),
      sendTimeout: Duration(seconds: AppConfig.httpTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  /// Serviço de fila offline
  static final OfflineQueueService _offlineQueue = OfflineQueueService();

  /// Serviço de conectividade
  static final ConnectivityService _connectivity = ConnectivityService();

  /// UUID generator
  static const Uuid _uuid = Uuid();

  /// Flag de inicialização
  static bool _initialized = false;

  /// Getter para acessar a fila offline (útil para UI mostrar status)
  static OfflineQueueService get offlineQueue => _offlineQueue;

  /// Getter para acessar conectividade
  static ConnectivityService get connectivity => _connectivity;

  /// Obtém a URL do webhook N8N (usa configuração personalizada se existir)
  ///
  /// Retorna a URL configurada pelo usuário nas preferências,
  /// ou a URL padrão do AppConfig se nenhuma personalização existir
  static Future<String> _getWebhookUrl() async {
    return await PreferencesService.getN8nWebhookUrl();
  }

  /// Inicializa o N8nService com suporte offline
  ///
  /// Deve ser chamado no início do app
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚠️  N8nService já inicializado');
      return;
    }

    print('🚀 Inicializando N8nService...');

    // Inicializa conectividade
    await _connectivity.initialize();

    // Inicializa fila offline com callback de envio
    await _offlineQueue.initialize(
      sendCallback: _sendQueuedMessage,
    );

    _initialized = true;
    print('✅ N8nService inicializado com suporte offline');
  }

  /// Callback para enviar mensagem da fila
  static Future<bool> _sendQueuedMessage(QueuedMessage message) async {
    try {
      // Monta payload
      final Map<String, dynamic> payload = {
        'userId': message.userId,
        'messageType': message.mediaType ?? 'text',
        'content': message.mediaBase64 ?? message.content,
        'timestamp': message.timestamp.toIso8601String(),
      };

      // Se tiver mídia, adiciona metadados
      if (message.mediaBase64 != null) {
        payload['metadata'] = {
          'mimeType': message.mediaType == 'image' ? 'image/jpeg' : 'audio/m4a',
        };
      }

      print('📤 Enviando mensagem da fila: ${message.id}');

      final webhookUrl = await _getWebhookUrl();
      final response = await _dio.post(
        webhookUrl,
        data: payload,
      );

      print('📥 Resposta recebida: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erro ao enviar mensagem da fila: $e');
      return false;
    }
  }

  /// Envia uma mensagem de texto para o N8N
  ///
  /// [message] - Texto da mensagem
  /// [userId] - ID do usuário que está enviando
  ///
  /// Retorna a resposta do bot ou adiciona à fila offline se sem conexão
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   final response = await N8nService.sendMessage('Olá!', 'user123');
  ///   if (response != null) {
  ///     print('Bot respondeu: ${response.text}');
  ///   } else {
  ///     print('Mensagem adicionada à fila offline');
  ///   }
  /// } catch (e) {
  ///   print('Erro: $e');
  /// }
  /// ```
  static Future<N8nResponse?> sendMessage(String message, String userId) async {
    // Verifica conectividade
    if (!_connectivity.isOnline) {
      print('📵 Sem conexão. Adicionando mensagem à fila offline...');

      // Adiciona à fila
      await _offlineQueue.addToQueue(
        QueuedMessage(
          id: _uuid.v4(),
          userId: userId,
          content: message,
          timestamp: DateTime.now(),
        ),
      );

      return null; // Retorna null indicando que foi para fila
    }

    // Se online, tenta enviar
    return RetryService.executeWithTimeout(
      operation: () async {
        try {
          final payload = {
            'userId': userId,
            'messageType': 'text',
            'content': message,
            'timestamp': DateTime.now().toIso8601String(),
          };

          print('📤 Enviando mensagem para N8N: $message');

          final webhookUrl = await _getWebhookUrl();
          final response = await _dio.post(
            webhookUrl,
            data: payload,
          );

          print('📥 Resposta recebida do N8N: ${response.data}');

          return N8nResponse.fromJson(response.data);
        } on DioException catch (e) {
          // Se erro de conexão, adiciona à fila
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout) {
            print('📵 Erro de conexão. Adicionando à fila offline...');

            await _offlineQueue.addToQueue(
              QueuedMessage(
                id: _uuid.v4(),
                userId: userId,
                content: message,
                timestamp: DateTime.now(),
              ),
            );

            throw Exception('Sem conexão. Mensagem salva na fila');
          }

          throw _handleDioError(e);
        } catch (e) {
          throw Exception('Erro ao enviar mensagem: $e');
        }
      },
      timeoutSeconds: AppConfig.httpTimeout,
      onRetry: (attempt, error) {
        print('🔄 Tentando enviar mensagem novamente (tentativa $attempt)...');
      },
    );
  }

  /// Envia uma imagem para o N8N
  ///
  /// [imageFile] - Arquivo da imagem
  /// [userId] - ID do usuário que está enviando
  ///
  /// A imagem é convertida para base64 e enviada no payload
  /// ou adicionada à fila offline se sem conexão
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   final file = File('/path/to/image.jpg');
  ///   final response = await N8nService.sendImage(file, 'user123');
  ///   if (response != null) {
  ///     print('Bot respondeu: ${response.text}');
  ///   }
  /// } catch (e) {
  ///   print('Erro: $e');
  /// }
  /// ```
  static Future<N8nResponse?> sendImage(File imageFile, String userId) async {
    try {
      // Lê o arquivo e converte para base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Verifica conectividade
      if (!_connectivity.isOnline) {
        print('📵 Sem conexão. Adicionando imagem à fila offline...');

        await _offlineQueue.addToQueue(
          QueuedMessage(
            id: _uuid.v4(),
            userId: userId,
            content: 'Imagem',
            mediaBase64: base64Image,
            mediaType: 'image',
            timestamp: DateTime.now(),
          ),
        );

        return null;
      }

      final payload = {
        'userId': userId,
        'messageType': 'image',
        'content': base64Image,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {
          'fileName': imageFile.path.split('/').last,
          'mimeType': 'image/jpeg',
        },
      };

      print('📤 Enviando imagem para N8N (${bytes.length} bytes)');

      final webhookUrl = await _getWebhookUrl();
      final response = await _dio.post(
        webhookUrl,
        data: payload,
      );

      print('📥 Resposta recebida do N8N: ${response.data}');

      return N8nResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Se erro de conexão, adiciona à fila
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        print('📵 Erro de conexão. Adicionando imagem à fila offline...');

        await _offlineQueue.addToQueue(
          QueuedMessage(
            id: _uuid.v4(),
            userId: userId,
            content: 'Imagem',
            mediaBase64: base64Image,
            mediaType: 'image',
            timestamp: DateTime.now(),
          ),
        );

        throw Exception('Sem conexão. Imagem salva na fila');
      }

      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Erro ao enviar imagem: $e');
    }
  }

  /// Envia uma imagem usando multipart/form-data (alternativa)
  ///
  /// Use este método se preferir enviar a imagem como arquivo
  /// em vez de base64
  static Future<N8nResponse> sendImageMultipart(
    File imageFile,
    String userId,
  ) async {
    try {
      final formData = FormData.fromMap({
        'userId': userId,
        'messageType': 'image',
        'timestamp': DateTime.now().toIso8601String(),
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      print('📤 Enviando imagem (multipart) para N8N');

      final webhookUrl = await _getWebhookUrl();
      final response = await _dio.post(
        webhookUrl,
        data: formData,
      );

      print('📥 Resposta recebida do N8N: ${response.data}');

      return N8nResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Erro ao enviar imagem: $e');
    }
  }

  /// Envia um áudio para o N8N
  ///
  /// [audioFile] - Arquivo de áudio
  /// [userId] - ID do usuário que está enviando
  ///
  /// O áudio é convertido para base64 e enviado no payload
  /// ou adicionado à fila offline se sem conexão
  ///
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   final file = File('/path/to/audio.m4a');
  ///   final response = await N8nService.sendAudio(file, 'user123');
  ///   if (response != null) {
  ///     print('Bot respondeu: ${response.text}');
  ///   }
  /// } catch (e) {
  ///   print('Erro: $e');
  /// }
  /// ```
  static Future<N8nResponse?> sendAudio(File audioFile, String userId) async {
    try {
      // Lê o arquivo e converte para base64
      final bytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(bytes);

      // Verifica conectividade
      if (!_connectivity.isOnline) {
        print('📵 Sem conexão. Adicionando áudio à fila offline...');

        await _offlineQueue.addToQueue(
          QueuedMessage(
            id: _uuid.v4(),
            userId: userId,
            content: 'Áudio',
            mediaBase64: base64Audio,
            mediaType: 'audio',
            timestamp: DateTime.now(),
          ),
        );

        return null;
      }

      final payload = {
        'userId': userId,
        'messageType': 'audio',
        'content': base64Audio,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {
          'fileName': audioFile.path.split('/').last,
          'mimeType': 'audio/m4a',
          'duration': 0, // Pode calcular a duração se necessário
        },
      };

      print('📤 Enviando áudio para N8N (${bytes.length} bytes)');

      final webhookUrl = await _getWebhookUrl();
      final response = await _dio.post(
        webhookUrl,
        data: payload,
      );

      print('📥 Resposta recebida do N8N: ${response.data}');

      return N8nResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Se erro de conexão, adiciona à fila
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        final bytes = await audioFile.readAsBytes();
        final base64Audio = base64Encode(bytes);

        print('📵 Erro de conexão. Adicionando áudio à fila offline...');

        await _offlineQueue.addToQueue(
          QueuedMessage(
            id: _uuid.v4(),
            userId: userId,
            content: 'Áudio',
            mediaBase64: base64Audio,
            mediaType: 'audio',
            timestamp: DateTime.now(),
          ),
        );

        throw Exception('Sem conexão. Áudio salvo na fila');
      }

      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Erro ao enviar áudio: $e');
    }
  }

  /// Envia um áudio usando multipart/form-data (alternativa)
  ///
  /// Use este método se preferir enviar o áudio como arquivo
  /// em vez de base64
  static Future<N8nResponse> sendAudioMultipart(
    File audioFile,
    String userId,
  ) async {
    try {
      final formData = FormData.fromMap({
        'userId': userId,
        'messageType': 'audio',
        'timestamp': DateTime.now().toIso8601String(),
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
          contentType: MediaType('audio', 'm4a'),
        ),
      });

      print('📤 Enviando áudio (multipart) para N8N');

      final webhookUrl = await _getWebhookUrl();
      final response = await _dio.post(
        webhookUrl,
        data: formData,
      );

      print('📥 Resposta recebida do N8N: ${response.data}');

      return N8nResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Erro ao enviar áudio: $e');
    }
  }

  /// Trata erros do Dio e retorna mensagens amigáveis
  static Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Timeout: Não foi possível conectar ao servidor');

      case DioExceptionType.sendTimeout:
        return Exception('Timeout: Tempo esgotado ao enviar dados');

      case DioExceptionType.receiveTimeout:
        return Exception('Timeout: Tempo esgotado ao receber resposta');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return Exception(
          'Erro do servidor (${statusCode}): ${e.response?.data}',
        );

      case DioExceptionType.cancel:
        return Exception('Requisição cancelada');

      case DioExceptionType.connectionError:
        return Exception(
          'Erro de conexão: Verifique sua internet',
        );

      case DioExceptionType.badCertificate:
        return Exception('Erro de certificado SSL');

      case DioExceptionType.unknown:
      default:
        if (e.error is SocketException) {
          return Exception('Sem conexão com a internet');
        }
        return Exception('Erro desconhecido: ${e.message}');
    }
  }

  /// Testa a conexão com o webhook N8N
  ///
  /// Retorna true se o webhook está respondendo
  ///
  /// Útil para verificar se a configuração está correta
  static Future<bool> testConnection() async {
    try {
      print('🔍 Testando conexão com N8N...');

      final webhookUrl = await _getWebhookUrl();
      final response = await _dio.post(
        webhookUrl,
        data: {
          'userId': 'test',
          'messageType': 'text',
          'content': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✓ Conexão com N8N OK (status: ${response.statusCode})');
      return response.statusCode == 200;
    } catch (e) {
      print('✗ Erro ao conectar com N8N: $e');
      return false;
    }
  }
}

/// Modelo de resposta do N8N
class N8nResponse {
  /// Texto da resposta do bot
  final String response;

  /// Tipo de resposta (text, image, audio)
  final String type;

  /// Dados adicionais (URL ou base64 se for mídia)
  final String? data;

  /// Metadados extras
  final Map<String, dynamic>? metadata;

  N8nResponse({
    required this.response,
    required this.type,
    this.data,
    this.metadata,
  });

  /// Cria a partir do JSON retornado pelo N8N
  factory N8nResponse.fromJson(Map<String, dynamic> json) {
    return N8nResponse(
      response: json['response'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      data: json['data'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Retorna o texto da resposta (útil para mensagens de texto)
  String get text => response;

  /// Verifica se a resposta é uma imagem
  bool get isImage => type == 'image';

  /// Verifica se a resposta é um áudio
  bool get isAudio => type == 'audio';

  /// Verifica se a resposta é texto
  bool get isText => type == 'text';

  @override
  String toString() {
    return 'N8nResponse(type: $type, response: ${response.substring(0, response.length > 50 ? 50 : response.length)}...)';
  }
}
