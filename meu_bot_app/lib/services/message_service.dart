import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'supabase_service.dart';

/// Serviço de persistência de mensagens no Supabase
///
/// Gerencia salvamento e carregamento do histórico de conversas
class MessageService {
  /// Salva uma mensagem no Supabase
  ///
  /// [message] - Mensagem a ser salva
  /// [userId] - ID do usuário (do Supabase auth)
  static Future<void> saveMessage(types.Message message, String userId) async {
    try {
      final data = _messageToJson(message, userId);

      await SupabaseService.client.from('messages').insert(data);

      print('✓ Mensagem salva: ${message.id}');
    } catch (e) {
      print('✗ Erro ao salvar mensagem: $e');
      // Não lança exceção para não quebrar o fluxo do app
      // O chat continua funcionando mesmo se falhar ao salvar
    }
  }

  /// Carrega mensagens do Supabase
  ///
  /// [userId] - ID do usuário
  /// [limit] - Quantidade de mensagens para carregar (padrão: 50)
  /// [offset] - Offset para paginação (padrão: 0)
  ///
  /// Retorna lista de mensagens ordenadas da mais recente para mais antiga
  static Future<List<types.Message>> loadMessages(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> data = response as List<dynamic>;

      print('✓ Carregadas ${data.length} mensagens');

      return data.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('✗ Erro ao carregar mensagens: $e');
      return [];
    }
  }

  /// Deleta uma mensagem do Supabase
  ///
  /// [messageId] - ID da mensagem
  static Future<void> deleteMessage(String messageId) async {
    try {
      await SupabaseService.client
          .from('messages')
          .delete()
          .eq('message_id', messageId);

      print('✓ Mensagem deletada: $messageId');
    } catch (e) {
      print('✗ Erro ao deletar mensagem: $e');
      rethrow;
    }
  }

  /// Deleta todas as mensagens de um usuário
  ///
  /// [userId] - ID do usuário
  static Future<void> deleteAllMessages(String userId) async {
    try {
      await SupabaseService.client
          .from('messages')
          .delete()
          .eq('user_id', userId);

      print('✓ Todas mensagens deletadas');
    } catch (e) {
      print('✗ Erro ao deletar mensagens: $e');
      rethrow;
    }
  }

  /// Conta total de mensagens de um usuário
  ///
  /// [userId] - ID do usuário
  static Future<int> countMessages(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('messages')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId);

      return response.count ?? 0;
    } catch (e) {
      print('✗ Erro ao contar mensagens: $e');
      return 0;
    }
  }

  /// Converte Message para JSON do Supabase
  static Map<String, dynamic> _messageToJson(
    types.Message message,
    String userId,
  ) {
    final baseData = {
      'user_id': userId,
      'message_id': message.id,
      'author_type': message.author.id == userId ? 'user' : 'bot',
      'created_at': message.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };

    // Adiciona campos específicos por tipo de mensagem
    if (message is types.TextMessage) {
      return {
        ...baseData,
        'message_type': 'text',
        'text_content': message.text,
      };
    } else if (message is types.ImageMessage) {
      return {
        ...baseData,
        'message_type': 'image',
        'media_uri': message.uri,
        'file_name': message.name,
        'file_size': message.size,
      };
    } else if (message is types.FileMessage) {
      // Áudio é tratado como FileMessage
      return {
        ...baseData,
        'message_type': message.mimeType?.contains('audio') == true
            ? 'audio'
            : 'file',
        'media_uri': message.uri,
        'file_name': message.name,
        'file_size': message.size,
        'mime_type': message.mimeType,
      };
    } else {
      // Tipo desconhecido, salva como text vazio
      return {
        ...baseData,
        'message_type': 'text',
        'text_content': '[Mensagem de tipo não suportado]',
      };
    }
  }

  /// Converte JSON do Supabase para Message
  static types.Message _messageFromJson(Map<String, dynamic> json) {
    final authorType = json['author_type'] as String;
    final messageType = json['message_type'] as String;

    // Criar autor
    final author = types.User(
      id: authorType == 'user' ? json['user_id'] as String : 'bot',
      firstName: authorType == 'user' ? 'Você' : 'Bot',
      lastName: authorType == 'bot' ? 'Assistente' : null,
    );

    final createdAt = json['created_at'] as int?;
    final id = json['message_id'] as String;

    // Criar mensagem baseada no tipo
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
        // Tipo desconhecido, retorna como texto
        return types.TextMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          text: '[Mensagem de tipo desconhecido: $messageType]',
        );
    }
  }

  /// Busca mensagens por texto (search)
  ///
  /// [userId] - ID do usuário
  /// [query] - Texto a buscar
  static Future<List<types.Message>> searchMessages(
    String userId,
    String query,
  ) async {
    try {
      final response = await SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .ilike('text_content', '%$query%')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) => _messageFromJson(json)).toList();
    } catch (e) {
      print('✗ Erro ao buscar mensagens: $e');
      return [];
    }
  }

  /// Exporta mensagens para JSON (backup)
  ///
  /// [userId] - ID do usuário
  static Future<List<Map<String, dynamic>>> exportMessages(
    String userId,
  ) async {
    try {
      final response = await SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('✗ Erro ao exportar mensagens: $e');
      return [];
    }
  }
}
