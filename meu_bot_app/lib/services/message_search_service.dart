import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'supabase_service.dart';
import 'message_service.dart';

/// Serviço avançado de busca de mensagens
///
/// Oferece busca por texto, filtros, e organização de resultados
class MessageSearchService {
  /// Busca mensagens por texto
  ///
  /// [userId] - ID do usuário
  /// [query] - Texto a buscar
  /// [assistantId] - Filtrar por assistente específico (opcional)
  /// [limit] - Limite de resultados (padrão: 50)
  static Future<List<types.Message>> searchMessages({
    required String userId,
    required String query,
    String? assistantId,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      var dbQuery = SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .ilike('text_content', '%${query.trim()}%');

      // Filtrar por assistente se fornecido
      if (assistantId != null) {
        dbQuery = dbQuery.eq('assistant_id', assistantId);
      }

      final response = await dbQuery
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('✗ Erro ao buscar mensagens: $e');
      return [];
    }
  }

  /// Busca mensagens por data
  ///
  /// [userId] - ID do usuário
  /// [startDate] - Data inicial
  /// [endDate] - Data final
  /// [assistantId] - Filtrar por assistente específico (opcional)
  static Future<List<types.Message>> searchByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? assistantId,
  }) async {
    try {
      var query = SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .gte('created_at', startDate.millisecondsSinceEpoch)
          .lte('created_at', endDate.millisecondsSinceEpoch);

      if (assistantId != null) {
        query = query.eq('assistant_id', assistantId);
      }

      final response = await query.order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('✗ Erro ao buscar por data: $e');
      return [];
    }
  }

  /// Busca apenas mensagens de mídia (imagens/áudios)
  ///
  /// [userId] - ID do usuário
  /// [mediaType] - Tipo de mídia ('image' ou 'audio')
  /// [assistantId] - Filtrar por assistente específico (opcional)
  static Future<List<types.Message>> searchMediaMessages({
    required String userId,
    required String mediaType,
    String? assistantId,
  }) async {
    try {
      var query = SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .eq('message_type', mediaType);

      if (assistantId != null) {
        query = query.eq('assistant_id', assistantId);
      }

      final response = await query.order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('✗ Erro ao buscar mídias: $e');
      return [];
    }
  }

  /// Obtém estatísticas de uso
  ///
  /// [userId] - ID do usuário
  /// [assistantId] - Filtrar por assistente específico (opcional)
  static Future<MessageStats> getStats({
    required String userId,
    String? assistantId,
  }) async {
    try {
      var query = SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId);

      if (assistantId != null) {
        query = query.eq('assistant_id', assistantId);
      }

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      int totalMessages = data.length;
      int userMessages = 0;
      int botMessages = 0;
      int imageMessages = 0;
      int audioMessages = 0;

      for (var item in data) {
        final authorType = item['author_type'] as String;
        final messageType = item['message_type'] as String;

        if (authorType == 'user') {
          userMessages++;
        } else {
          botMessages++;
        }

        if (messageType == 'image') {
          imageMessages++;
        } else if (messageType == 'audio') {
          audioMessages++;
        }
      }

      return MessageStats(
        totalMessages: totalMessages,
        userMessages: userMessages,
        botMessages: botMessages,
        imageMessages: imageMessages,
        audioMessages: audioMessages,
      );
    } catch (e) {
      print('✗ Erro ao obter estatísticas: $e');
      return MessageStats(
        totalMessages: 0,
        userMessages: 0,
        botMessages: 0,
        imageMessages: 0,
        audioMessages: 0,
      );
    }
  }

  /// Converte JSON do Supabase para Message
  static types.Message _messageFromJson(Map<String, dynamic> json) {
    final authorType = json['author_type'] as String;
    final messageType = json['message_type'] as String;

    final author = types.User(
      id: authorType == 'user' ? json['user_id'] as String : 'bot',
      firstName: authorType == 'user' ? 'Você' : 'Bot',
      lastName: authorType == 'bot' ? 'Assistente' : null,
    );

    final createdAt = json['created_at'] as int?;
    final id = json['message_id'] as String;

    switch (messageType) {
      case 'text':
        return types.TextMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          text: json['text_content'] as String? ?? '',
        );

      case 'image':
        return types.ImageMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          name: json['file_name'] as String,
          size: (json['file_size'] as num?)?.toInt() ?? 0,
          uri: json['media_uri'] as String,
        );

      case 'audio':
      case 'file':
        return types.FileMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          name: json['file_name'] as String,
          size: (json['file_size'] as num?)?.toInt() ?? 0,
          uri: json['media_uri'] as String,
          mimeType: json['mime_type'] as String?,
        );

      default:
        return types.TextMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          text: '[Mensagem de tipo desconhecido: $messageType]',
        );
    }
  }
}

/// Estatísticas de mensagens
class MessageStats {
  final int totalMessages;
  final int userMessages;
  final int botMessages;
  final int imageMessages;
  final int audioMessages;

  const MessageStats({
    required this.totalMessages,
    required this.userMessages,
    required this.botMessages,
    required this.imageMessages,
    required this.audioMessages,
  });

  int get textMessages =>
      totalMessages - imageMessages - audioMessages;
}
