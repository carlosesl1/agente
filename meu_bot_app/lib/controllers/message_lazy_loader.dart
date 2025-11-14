import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../services/message_service.dart';

/// Controller para lazy loading de mensagens
///
/// Gerencia carregamento paginado de mensagens com detecção automática
/// de scroll para carregar mais mensagens quando usuário rola para cima
class MessageLazyLoader {
  /// ID do usuário para carregar mensagens
  final String userId;

  /// Quantidade de mensagens por página
  final int pageSize;

  /// Threshold de scroll (em pixels) para iniciar carregamento
  /// Quando estiver a X pixels do topo, inicia carregamento
  final double scrollThreshold;

  /// Lista de mensagens carregadas
  final List<types.Message> _messages = [];

  /// Stream controller para mudanças nas mensagens
  final StreamController<List<types.Message>> _messagesController =
      StreamController<List<types.Message>>.broadcast();

  /// Stream de mensagens
  Stream<List<types.Message>> get messagesStream => _messagesController.stream;

  /// Getter da lista de mensagens
  List<types.Message> get messages => List.unmodifiable(_messages);

  /// Quantidade de mensagens carregadas
  int get count => _messages.length;

  /// Flag de carregamento em andamento
  bool _isLoading = false;

  /// Getter do estado de carregamento
  bool get isLoading => _isLoading;

  /// Flag indicando se todas as mensagens foram carregadas
  bool _hasReachedEnd = false;

  /// Getter se chegou ao fim
  bool get hasReachedEnd => _hasReachedEnd;

  /// Offset atual para paginação
  int _currentOffset = 0;

  /// ScrollController para detecção automática
  ScrollController? _scrollController;

  /// Flag de inicialização
  bool _initialized = false;

  MessageLazyLoader({
    required this.userId,
    this.pageSize = 20,
    this.scrollThreshold = 300.0,
  });

  /// Inicializa o lazy loader
  ///
  /// Carrega primeira página de mensagens do cache/Supabase
  /// [autoLoad] - Se deve carregar automaticamente a primeira página
  Future<void> initialize({bool autoLoad = true}) async {
    if (_initialized) {
      print('   MessageLazyLoader já inicializado');
      return;
    }

    print('=€ Inicializando MessageLazyLoader (pageSize: $pageSize)...');

    if (autoLoad) {
      await loadInitialMessages();
    }

    _initialized = true;
    print(' MessageLazyLoader inicializado (${_messages.length} mensagens)');
  }

  /// Carrega primeira página de mensagens
  Future<void> loadInitialMessages() async {
    if (_isLoading) return;

    _isLoading = true;
    _currentOffset = 0;
    _hasReachedEnd = false;

    try {
      print('=å Carregando página inicial (${pageSize} mensagens)...');

      final newMessages = await MessageService.loadMessages(
        userId,
        limit: pageSize,
        offset: 0,
        useCache: true, // Usa cache para primeira carga (rápido!)
      );

      _messages.clear();
      _messages.addAll(newMessages);

      // Se retornou menos que pageSize, chegou ao fim
      if (newMessages.length < pageSize) {
        _hasReachedEnd = true;
        print(' Fim da lista alcançado');
      }

      _currentOffset = newMessages.length;

      print(' ${newMessages.length} mensagens carregadas');

      _messagesController.add(_messages);
    } catch (e) {
      print('L Erro ao carregar mensagens iniciais: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Carrega próxima página de mensagens
  ///
  /// Chamado automaticamente quando usuário rola para cima
  /// ou pode ser chamado manualmente
  Future<void> loadMore() async {
    // Não carrega se já está carregando ou se chegou ao fim
    if (_isLoading || _hasReachedEnd) {
      if (_hasReachedEnd) {
        print('9  Todas as mensagens já foram carregadas');
      }
      return;
    }

    _isLoading = true;

    try {
      print('=å Carregando mais mensagens (offset: $_currentOffset)...');

      final newMessages = await MessageService.loadMessages(
        userId,
        limit: pageSize,
        offset: _currentOffset,
        useCache: false, // Páginas antigas não usam cache
      );

      if (newMessages.isEmpty) {
        _hasReachedEnd = true;
        print(' Fim da lista alcançado (sem mais mensagens)');
        return;
      }

      // Adiciona apenas mensagens que não existem (evita duplicatas)
      int addedCount = 0;
      for (final message in newMessages) {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          addedCount++;
        }
      }

      // Se retornou menos que pageSize, chegou ao fim
      if (newMessages.length < pageSize) {
        _hasReachedEnd = true;
        print(' Fim da lista alcançado');
      }

      _currentOffset += newMessages.length;

      print(' $addedCount novas mensagens carregadas (total: ${_messages.length})');

      _messagesController.add(_messages);
    } catch (e) {
      print('L Erro ao carregar mais mensagens: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Adiciona uma nova mensagem no início da lista
  ///
  /// Usado quando usuário envia uma mensagem ou recebe do bot
  void addMessage(types.Message message) {
    // Verifica se mensagem já existe
    final existingIndex = _messages.indexWhere((m) => m.id == message.id);

    if (existingIndex != -1) {
      // Atualiza mensagem existente
      _messages[existingIndex] = message;
    } else {
      // Adiciona nova mensagem no início
      _messages.insert(0, message);
      _currentOffset++; // Incrementa offset
    }

    _messagesController.add(_messages);
  }

  /// Remove uma mensagem da lista
  void removeMessage(String messageId) {
    final removed = _messages.removeWhere((m) => m.id == messageId);

    if (removed > 0) {
      _currentOffset--; // Decrementa offset
      _messagesController.add(_messages);
    }
  }

  /// Limpa todas as mensagens
  void clear() {
    _messages.clear();
    _currentOffset = 0;
    _hasReachedEnd = false;
    _messagesController.add(_messages);
  }

  /// Recarrega todas as mensagens (pull to refresh)
  Future<void> refresh() async {
    print('= Recarregando mensagens...');
    await loadInitialMessages();
  }

  /// Anexa ScrollController para detecção automática de scroll
  ///
  /// Quando usuário rolar até o topo, carrega mais mensagens automaticamente
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final scrollController = ScrollController();
  /// lazyLoader.attachScrollController(scrollController);
  ///
  /// // No widget:
  /// ListView(
  ///   controller: scrollController,
  ///   children: messages,
  /// )
  /// ```
  void attachScrollController(ScrollController controller) {
    _scrollController = controller;
    _scrollController!.addListener(_onScroll);
    print('=Ü ScrollController anexado (threshold: ${scrollThreshold}px)');
  }

  /// Desanexa ScrollController
  void detachScrollController() {
    _scrollController?.removeListener(_onScroll);
    _scrollController = null;
    print('=Ü ScrollController desanexado');
  }

  /// Listener de scroll para detecção automática
  void _onScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final position = _scrollController!.position;

    // Verifica se está próximo do topo (scroll up)
    // maxScrollExtent - pixels < threshold
    // Nota: No chat, mensagens antigas ficam no "topo" (scroll up)
    final distanceFromEnd = position.maxScrollExtent - position.pixels;

    if (distanceFromEnd < scrollThreshold && !_isLoading && !_hasReachedEnd) {
      print('=Ü Threshold atingido, carregando mais mensagens...');
      loadMore();
    }
  }

  /// Busca mensagem por ID
  types.Message? getMessageById(String messageId) {
    try {
      return _messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      return null;
    }
  }

  /// Dispose de recursos
  void dispose() {
    detachScrollController();
    _messagesController.close();
    print('=Ñ MessageLazyLoader finalizado');
  }
}

/// Widget helper para exibir indicador de carregamento
///
/// Exibe um CircularProgressIndicator quando está carregando
class LazyLoadingIndicator extends StatelessWidget {
  final MessageLazyLoader loader;
  final Widget? child;

  const LazyLoadingIndicator({
    Key? key,
    required this.loader,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!loader.isLoading) {
      return child ?? const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Carregando mais mensagens...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget helper para exibir mensagem de fim da lista
class EndOfListIndicator extends StatelessWidget {
  final MessageLazyLoader loader;

  const EndOfListIndicator({
    Key? key,
    required this.loader,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!loader.hasReachedEnd || loader.count == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          '    Início da conversa    ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ),
    );
  }
}
