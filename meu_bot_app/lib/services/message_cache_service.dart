import 'dart:async';
import 'dart:convert';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:shared_preferences/shared_preferences.dart';
import 'message_service.dart';

/// Servi�o de cache de mensagens em mem�ria
///
/// Mant�m as �ltimas mensagens em cache para carregamento instant�neo
/// e reduz consultas ao Supabase
class MessageCacheService {
  /// Inst�ncia singleton
  static final MessageCacheService _instance =
      MessageCacheService._internal();

  factory MessageCacheService() => _instance;

  MessageCacheService._internal();

  /// Chave para persist�ncia no SharedPreferences
  static const String _cacheKey = 'message_cache';

  /// Tamanho m�ximo do cache (�ltimas N mensagens)
  static const int _maxCacheSize = 100;

  /// Cache em mem�ria
  final List<types.Message> _cache = [];

  /// Stream controller para mudan�as no cache
  final StreamController<List<types.Message>> _cacheController =
      StreamController<List<types.Message>>.broadcast();

  /// Stream de mudan�as no cache
  Stream<List<types.Message>> get cacheStream => _cacheController.stream;

  /// Getter do cache atual
  List<types.Message> get messages => List.unmodifiable(_cache);

  /// Quantidade de mensagens em cache
  int get count => _cache.length;

  /// Flag de inicializa��o
  bool _initialized = false;

  /// ID do usu�rio atual
  String? _currentUserId;

  /// Inicializa o cache
  ///
  /// [userId] - ID do usu�rio para carregar cache espec�fico
  /// [preload] - Se deve pr�-carregar do Supabase (padr�o: true)
  Future<void> initialize({
    required String userId,
    bool preload = true,
  }) async {
    if (_initialized && _currentUserId == userId) {
      print('�  MessageCacheService j� inicializado para usu�rio $userId');
      return;
    }

    _currentUserId = userId;

    print('=� Inicializando MessageCacheService...');

    // Carrega cache do SharedPreferences
    await _loadFromDisk();

    // Se pr�-carregamento ativado, busca mensagens do Supabase em background
    if (preload) {
      _preloadFromSupabase(userId);
    }

    _initialized = true;
    print(' MessageCacheService inicializado (${_cache.length} mensagens em cache)');
  }

  /// Adiciona mensagem ao cache
  ///
  /// Automaticamente remove mensagens antigas se exceder limite
  Future<void> addMessage(types.Message message) async {
    // Verifica se mensagem j� existe (evita duplicatas)
    final existingIndex = _cache.indexWhere((m) => m.id == message.id);

    if (existingIndex != -1) {
      // Atualiza mensagem existente
      _cache[existingIndex] = message;
      print('= Mensagem atualizada no cache: ${message.id}');
    } else {
      // Adiciona nova mensagem no in�cio (mais recente)
      _cache.insert(0, message);
      print('� Mensagem adicionada ao cache: ${message.id}');

      // Remove mensagens antigas se exceder limite
      if (_cache.length > _maxCacheSize) {
        final removed = _cache.removeLast();
        print('=�  Mensagem antiga removida do cache: ${removed.id}');
      }
    }

    // Salva no disco
    await _saveToDisk();

    // Emite update
    _cacheController.add(_cache);
  }

  /// Adiciona m�ltiplas mensagens ao cache
  ///
  /// Mais eficiente que adicionar uma por uma
  Future<void> addMessages(List<types.Message> messages) async {
    for (final message in messages) {
      // Verifica se mensagem j� existe
      final existingIndex = _cache.indexWhere((m) => m.id == message.id);

      if (existingIndex == -1) {
        _cache.insert(0, message);
      }
    }

    // Mant�m apenas as mais recentes
    if (_cache.length > _maxCacheSize) {
      _cache.removeRange(_maxCacheSize, _cache.length);
    }

    // Ordena por data (mais recente primeiro)
    _cache.sort((a, b) {
      final aTime = a.createdAt ?? 0;
      final bTime = b.createdAt ?? 0;
      return bTime.compareTo(aTime);
    });

    print('=� ${messages.length} mensagens adicionadas ao cache (total: ${_cache.length})');

    // Salva no disco
    await _saveToDisk();

    // Emite update
    _cacheController.add(_cache);
  }

  /// Remove mensagem do cache
  Future<void> removeMessage(String messageId) async {
    final initialLength = _cache.length;
    _cache.removeWhere((m) => m.id == messageId);
    final removed = initialLength - _cache.length;

    if (removed > 0) {
      print('=�  Mensagem removida do cache: $messageId');

      // Salva no disco
      await _saveToDisk();

      // Emite update
      _cacheController.add(_cache);
    }
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    _cache.clear();
    await _saveToDisk();
    _cacheController.add(_cache);
    print('>� Cache limpo');
  }

  /// Busca mensagem por ID
  types.Message? getMessageById(String messageId) {
    try {
      return _cache.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// Busca mensagens por texto
  List<types.Message> searchMessages(String query) {
    final lowerQuery = query.toLowerCase();

    return _cache.where((message) {
      if (message is types.TextMessage) {
        return message.text.toLowerCase().contains(lowerQuery);
      }
      return false;
    }).toList();
  }

  /// Obt�m mensagens paginadas do cache
  ///
  /// [limit] - Quantidade de mensagens
  /// [offset] - Offset para pagina��o
  List<types.Message> getMessages({int limit = 20, int offset = 0}) {
    final end = (offset + limit).clamp(0, _cache.length);

    if (offset >= _cache.length) {
      return [];
    }

    return _cache.sublist(offset, end);
  }

  /// Carrega cache do SharedPreferences
  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$_currentUserId';
      final jsonString = prefs.getString(cacheKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _cache.clear();

        // Converte JSON para mensagens
        for (final json in jsonList) {
          try {
            final message = _messageFromCacheJson(json as Map<String, dynamic>);
            _cache.add(message);
          } catch (e) {
            print('�  Erro ao deserializar mensagem: $e');
          }
        }

        print('=� Cache carregado do disco (${_cache.length} mensagens)');

        // Emite update inicial
        _cacheController.add(_cache);
      } else {
        print('=� Nenhum cache encontrado no disco');
      }
    } catch (e) {
      print('L Erro ao carregar cache do disco: $e');
    }
  }

  /// Salva cache no SharedPreferences
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$_currentUserId';

      // Converte mensagens para JSON
      final jsonList = _cache.map((m) => _messageToCacheJson(m)).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(cacheKey, jsonString);
      // print('=� Cache salvo no disco (${_cache.length} mensagens)');
    } catch (e) {
      print('L Erro ao salvar cache no disco: $e');
    }
  }

  /// Pr�-carrega mensagens do Supabase em background
  Future<void> _preloadFromSupabase(String userId) async {
    try {
      print('= Pr�-carregando mensagens do Supabase...');

      // Busca as �ltimas 100 mensagens
      final messages = await MessageService.loadMessages(
        userId,
        limit: _maxCacheSize,
      );

      if (messages.isNotEmpty) {
        await addMessages(messages);
        print(' ${messages.length} mensagens pr�-carregadas do Supabase');
      }
    } catch (e) {
      print('L Erro ao pr�-carregar do Supabase: $e');
    }
  }

  /// Sincroniza cache com Supabase
  ///
  /// Busca mensagens mais recentes que n�o est�o no cache
  Future<void> sync(String userId) async {
    try {
      print('= Sincronizando cache com Supabase...');

      // Busca mensagens mais recentes
      final messages = await MessageService.loadMessages(
        userId,
        limit: 20,
      );

      // Adiciona apenas mensagens novas
      final newMessages = messages.where((m) {
        return !_cache.any((cached) => cached.id == m.id);
      }).toList();

      if (newMessages.isNotEmpty) {
        await addMessages(newMessages);
        print(' ${newMessages.length} novas mensagens sincronizadas');
      } else {
        print(' Cache j� est� atualizado');
      }
    } catch (e) {
      print('L Erro ao sincronizar cache: $e');
    }
  }

  /// Converte Message para JSON simples (para cache)
  Map<String, dynamic> _messageToCacheJson(types.Message message) {
    final baseData = {
      'id': message.id,
      'authorId': message.author.id,
      'authorFirstName': message.author.firstName,
      'authorLastName': message.author.lastName,
      'createdAt': message.createdAt,
    };

    if (message is types.TextMessage) {
      return {
        ...baseData,
        'type': 'text',
        'text': message.text,
      };
    } else if (message is types.ImageMessage) {
      return {
        ...baseData,
        'type': 'image',
        'uri': message.uri,
        'name': message.name,
        'size': message.size,
      };
    } else if (message is types.FileMessage) {
      return {
        ...baseData,
        'type': 'file',
        'uri': message.uri,
        'name': message.name,
        'size': message.size,
        'mimeType': message.mimeType,
      };
    } else {
      return {
        ...baseData,
        'type': 'text',
        'text': '[Tipo n�o suportado]',
      };
    }
  }

  /// Converte JSON do cache para Message
  types.Message _messageFromCacheJson(Map<String, dynamic> json) {
    final author = types.User(
      id: json['authorId'] as String,
      firstName: json['authorFirstName'] as String?,
      lastName: json['authorLastName'] as String?,
    );

    final createdAt = json['createdAt'] as int?;
    final id = json['id'] as String;
    final type = json['type'] as String;

    switch (type) {
      case 'text':
        return types.TextMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          text: json['text'] as String,
        );

      case 'image':
        return types.ImageMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          name: json['name'] as String,
          size: (json['size'] as num).toInt(),
          uri: json['uri'] as String,
        );

      case 'file':
        return types.FileMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          name: json['name'] as String,
          size: (json['size'] as num).toInt(),
          uri: json['uri'] as String,
          mimeType: json['mimeType'] as String?,
        );

      default:
        return types.TextMessage(
          author: author,
          createdAt: createdAt,
          id: id,
          text: '[Tipo desconhecido]',
        );
    }
  }

  /// Dispose de recursos
  Future<void> dispose() async {
    await _cacheController.close();
    print('=� MessageCacheService finalizado');
  }
}
