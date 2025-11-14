import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';

/// Status de uma mensagem na fila
enum MessageStatus {
  pending, // Aguardando envio
  sending, // Sendo enviada
  sent, // Enviada com sucesso
  failed, // Falha no envio
}

/// Item da fila offline
class QueuedMessage {
  final String id;
  final String userId;
  final String content;
  final String? mediaBase64;
  final String? mediaType;
  final DateTime timestamp;
  MessageStatus status;
  int retryCount;
  String? errorMessage;

  QueuedMessage({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaBase64,
    this.mediaType,
    required this.timestamp,
    this.status = MessageStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  /// Converte para JSON para persistência
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'content': content,
        'mediaBase64': mediaBase64,
        'mediaType': mediaType,
        'timestamp': timestamp.toIso8601String(),
        'status': status.index,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
      };

  /// Cria a partir de JSON
  factory QueuedMessage.fromJson(Map<String, dynamic> json) => QueuedMessage(
        id: json['id'] as String,
        userId: json['userId'] as String,
        content: json['content'] as String,
        mediaBase64: json['mediaBase64'] as String?,
        mediaType: json['mediaType'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: MessageStatus.values[json['status'] as int],
        retryCount: json['retryCount'] as int? ?? 0,
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Serviço de fila offline para mensagens
///
/// Armazena mensagens quando offline e envia automaticamente quando voltar online
class OfflineQueueService {
  /// Instância singleton
  static final OfflineQueueService _instance =
      OfflineQueueService._internal();

  factory OfflineQueueService() => _instance;

  OfflineQueueService._internal();

  /// Chave para persistência no SharedPreferences
  static const String _queueKey = 'offline_message_queue';

  /// Fila de mensagens
  final List<QueuedMessage> _queue = [];

  /// Stream controller para updates da fila
  final StreamController<List<QueuedMessage>> _queueController =
      StreamController<List<QueuedMessage>>.broadcast();

  /// Stream de mudanças na fila
  Stream<List<QueuedMessage>> get queueStream => _queueController.stream;

  /// Getter da fila atual
  List<QueuedMessage> get queue => List.unmodifiable(_queue);

  /// Contador de mensagens pendentes
  int get pendingCount =>
      _queue.where((m) => m.status == MessageStatus.pending).length;

  /// Serviço de conectividade
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Callback para enviar mensagem (será setado pelo N8nService)
  Future<bool> Function(QueuedMessage)? _sendCallback;

  /// Flag de processamento
  bool _isProcessing = false;

  /// Inicializa o serviço
  Future<void> initialize({
    required Future<bool> Function(QueuedMessage) sendCallback,
  }) async {
    _sendCallback = sendCallback;

    // Carrega fila do armazenamento local
    await _loadQueue();

    // Registra callback para processar fila quando voltar online
    _connectivityService.addOnlineCallback(() {
      print('= Conectividade restaurada, processando fila offline...');
      processQueue();
    });

    // Se já estiver online, processa fila imediatamente
    if (_connectivityService.isOnline && _queue.isNotEmpty) {
      print('=ä Processando fila existente (${_queue.length} mensagens)...');
      processQueue();
    }

    print('=Ë OfflineQueueService inicializado (${_queue.length} mensagens na fila)');
  }

  /// Adiciona mensagem à fila
  Future<void> addToQueue(QueuedMessage message) async {
    _queue.add(message);
    print('• Mensagem adicionada à fila: ${message.id}');

    // Salva fila
    await _saveQueue();

    // Emite update
    _queueController.add(_queue);

    // Se estiver online, tenta processar imediatamente
    if (_connectivityService.isOnline) {
      processQueue();
    }
  }

  /// Processa a fila de mensagens
  Future<void> processQueue() async {
    if (_isProcessing) {
      print('ø  Fila já está sendo processada');
      return;
    }

    if (_sendCallback == null) {
      print('L Callback de envio não configurado');
      return;
    }

    if (!_connectivityService.isOnline) {
      print('=õ Sem conexão. Aguardando conectividade...');
      return;
    }

    _isProcessing = true;

    try {
      // Filtra apenas mensagens pendentes ou com falha (para retry)
      final messagesToSend = _queue
          .where((m) =>
              m.status == MessageStatus.pending ||
              (m.status == MessageStatus.failed && m.retryCount < 3))
          .toList();

      if (messagesToSend.isEmpty) {
        print(' Fila vazia ou todas mensagens processadas');
        return;
      }

      print('=ä Processando ${messagesToSend.length} mensagens da fila...');

      for (final message in messagesToSend) {
        // Verifica conectividade antes de cada envio
        if (!_connectivityService.isOnline) {
          print('=õ Conexão perdida durante processamento');
          break;
        }

        try {
          // Atualiza status
          message.status = MessageStatus.sending;
          _queueController.add(_queue);

          print('=è Enviando mensagem ${message.id} (tentativa ${message.retryCount + 1})...');

          // Tenta enviar
          final success = await _sendCallback!(message);

          if (success) {
            message.status = MessageStatus.sent;
            message.errorMessage = null;
            print(' Mensagem ${message.id} enviada com sucesso');

            // Remove da fila após alguns segundos (para dar feedback visual)
            Future.delayed(const Duration(seconds: 2), () {
              _queue.remove(message);
              _saveQueue();
              _queueController.add(_queue);
            });
          } else {
            message.status = MessageStatus.failed;
            message.retryCount++;
            message.errorMessage = 'Erro ao enviar';
            print('L Falha ao enviar mensagem ${message.id}');
          }
        } catch (e) {
          message.status = MessageStatus.failed;
          message.retryCount++;
          message.errorMessage = e.toString();
          print('L Erro ao processar mensagem ${message.id}: $e');
        }

        // Salva estado após cada mensagem
        await _saveQueue();
        _queueController.add(_queue);

        // Pequeno delay entre envios
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print(' Processamento da fila concluído');
    } finally {
      _isProcessing = false;
    }
  }

  /// Remove mensagem da fila
  Future<void> removeFromQueue(String messageId) async {
    _queue.removeWhere((m) => m.id == messageId);
    await _saveQueue();
    _queueController.add(_queue);
    print('=Ñ  Mensagem $messageId removida da fila');
  }

  /// Limpa todas as mensagens enviadas
  Future<void> clearSentMessages() async {
    _queue.removeWhere((m) => m.status == MessageStatus.sent);
    await _saveQueue();
    _queueController.add(_queue);
    print('>ù Mensagens enviadas removidas da fila');
  }

  /// Limpa toda a fila
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    _queueController.add(_queue);
    print('>ù Fila limpa completamente');
  }

  /// Salva fila no SharedPreferences
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _queue.map((m) => m.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_queueKey, jsonString);
      print('=¾ Fila salva (${_queue.length} mensagens)');
    } catch (e) {
      print('L Erro ao salvar fila: $e');
    }
  }

  /// Carrega fila do SharedPreferences
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_queueKey);

      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        _queue.clear();
        _queue.addAll(
          jsonList.map((json) => QueuedMessage.fromJson(json as Map<String, dynamic>)),
        );
        print('=Â Fila carregada (${_queue.length} mensagens)');

        // Remove mensagens muito antigas (mais de 7 dias)
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        _queue.removeWhere((m) => m.timestamp.isBefore(weekAgo));

        // Emite update inicial
        _queueController.add(_queue);
      }
    } catch (e) {
      print('L Erro ao carregar fila: $e');
    }
  }

  /// Retorna status de uma mensagem específica
  MessageStatus? getMessageStatus(String messageId) {
    final message = _queue.where((m) => m.id == messageId).firstOrNull;
    return message?.status;
  }

  /// Dispose de recursos
  Future<void> dispose() async {
    await _queueController.close();
    print('=Ñ OfflineQueueService finalizado');
  }
}
