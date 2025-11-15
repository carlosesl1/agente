import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'supabase_service.dart';
import 'message_cache_service.dart';

/// Serviço de persistência de mensagens no Supabase
///
/// Gerencia salvamento e carregamento do histórico de conversas
/// Integrado com cache em memória para performance
class MessageService {
  /// Cache de mensagens
  static final MessageCacheService _cache = MessageCacheService();

  /// Getter do cache (útil para UI monitorar mudanças)
  static MessageCacheService get cache => _cache;

  /// Inicializa o MessageService com cache
  ///
  /// Deve ser chamado no início do app após login
  /// [userId] - ID do usuário logado
  static Future<void> initialize(String userId) async {
    await _cache.initialize(userId: userId, preload: true);
    print('✅ MessageService inicializado com cache');
  }

  /// Salva uma mensagem no Supabase e no cache
  ///
  /// [message] - Mensagem a ser salva
  /// [userId] - ID do usuário (do Supabase auth)
  /// [assistantId] - ID do assistente (opcional)
  static Future<void> saveMessage(
    types.Message message,
    String userId, {
    String? assistantId,
  }) async {
    // Salva no cache imediatamente (UX rápida)
    await _cache.addMessage(message);

    // Salva no Supabase em background
    try {
      final data = _messageToJson(message, userId, assistantId: assistantId);

      await SupabaseService.client.from('messages').insert(data);

      print('✓ Mensagem salva no Supabase: ${message.id}');
    } catch (e) {
      print('✗ Erro ao salvar mensagem no Supabase: $e');
      // Não lança exceção para não quebrar o fluxo do app
      // A mensagem já está no cache e o chat continua funcionando
    }
  }

  /// Carrega mensagens do cache ou Supabase
  ///
  /// [userId] - ID do usuário
  /// [assistantId] - ID do assistente para filtrar (opcional)
  /// [limit] - Quantidade de mensagens para carregar (padrão: 50)
  /// [offset] - Offset para paginação (padrão: 0)
  /// [useCache] - Se deve usar cache (padrão: true)
  ///
  /// Retorna lista de mensagens ordenadas da mais recente para mais antiga
  ///
  /// Estratégia:
  /// 1. Se useCache=true e cache tem mensagens: retorna do cache (instantâneo)
  /// 2. Sincroniza com Supabase em background
  /// 3. Se useCache=false: busca direto do Supabase
  static Future<List<types.Message>> loadMessages(
    String userId, {
    String? assistantId,
    int limit = 50,
    int offset = 0,
    bool useCache = true,
  }) async {
    // Se cache ativo e tem mensagens, retorna do cache
    if (useCache && _cache.count > 0 && offset == 0) {
      print('⚡ Carregando ${limit} mensagens do cache (instantâneo)');

      final cachedMessages = _cache.getMessages(limit: limit, offset: offset);

      // Sincroniza com Supabase em background (não aguarda)
      _syncInBackground(userId);

      return cachedMessages;
    }

    // Se não tem cache ou paginação > 0, busca do Supabase
    try {
      print('🔄 Carregando mensagens do Supabase...');

      var query = SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId);

      // Filtra por assistente se fornecido
      if (assistantId != null) {
        query = query.eq('assistant_id', assistantId);
        print('📌 Filtrando por assistente: $assistantId');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> data = response as List<dynamic>;

      print('✓ Carregadas ${data.length} mensagens do Supabase');

      final messages = data.map((json) => _messageFromJson(json)).toList();

      // Atualiza cache se for primeira página
      if (offset == 0 && messages.isNotEmpty) {
        await _cache.addMessages(messages);
      }

      return messages;
    } catch (e) {
      print('✗ Erro ao carregar mensagens do Supabase: $e');

      // Se falhar, tenta retornar do cache como fallback
      if (useCache && _cache.count > 0) {
        print('⚠️  Retornando mensagens do cache (fallback)');
        return _cache.getMessages(limit: limit, offset: offset);
      }

      return [];
    }
  }

  /// Sincroniza cache com Supabase em background
  static Future<void> _syncInBackground(String userId) async {
    try {
      await _cache.sync(userId);
    } catch (e) {
      print('⚠️  Erro na sincronização em background: $e');
    }
  }

  /// Deleta uma mensagem do Supabase e do cache
  ///
  /// [messageId] - ID da mensagem
  static Future<void> deleteMessage(String messageId) async {
    // Remove do cache imediatamente
    await _cache.removeMessage(messageId);

    // Remove do Supabase
    try {
      await SupabaseService.client
          .from('messages')
          .delete()
          .eq('message_id', messageId);

      print('✓ Mensagem deletada do Supabase: $messageId');
    } catch (e) {
      print('✗ Erro ao deletar mensagem do Supabase: $e');
      rethrow;
    }
  }

  /// Deleta todas as mensagens de um usuário do Supabase e do cache
  ///
  /// [userId] - ID do usuário
  static Future<void> deleteAllMessages(String userId) async {
    // Limpa cache imediatamente
    await _cache.clear();

    // Remove do Supabase
    try {
      await SupabaseService.client
          .from('messages')
          .delete()
          .eq('user_id', userId);

      print('✓ Todas mensagens deletadas do Supabase');
    } catch (e) {
      print('✗ Erro ao deletar mensagens do Supabase: $e');
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
          .select()
          .eq('user_id', userId);

      final List<dynamic> data = response as List<dynamic>;
      return data.length;
    } catch (e) {
      print('✗ Erro ao contar mensagens: $e');
      return 0;
    }
  }

  /// Converte Message para JSON do Supabase
  static Map<String, dynamic> _messageToJson(
    types.Message message,
    String userId, {
    String? assistantId,
  }) {
    final baseData = {
      'user_id': userId,
      'message_id': message.id,
      'author_type': message.author.id == userId ? 'user' : 'bot',
      'created_at': message.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      if (assistantId != null) 'assistant_id': assistantId,
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
