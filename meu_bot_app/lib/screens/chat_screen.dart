import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/n8n_service.dart';
import '../services/media_service.dart';
import '../services/audio_service.dart';
import '../services/connectivity_service.dart';
import '../services/message_service.dart';
import '../controllers/message_lazy_loader.dart';
import '../providers/assistant_provider.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/assistants_drawer.dart';
import '../screens/assistant_edit_screen.dart';
import '../theme/app_themes.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

/// Tela principal de chat
///
/// Permite conversar com o bot usando texto, imagens e áudio
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Lista de mensagens do chat
  final List<types.Message> _messages = [];

  // Usuário atual (você)
  late final types.User _user;

  // Bot
  late final types.User _bot;

  // UUID generator para IDs únicos
  final Uuid _uuid = const Uuid();

  // Loading state
  bool _isLoading = false;

  // Bot está digitando
  bool _botIsTyping = false;

  // Carregando histórico do banco
  bool _isLoadingHistory = true;

  // Carregando mais mensagens (lazy loading)
  bool _isLoadingMore = false;

  // Controller para o campo de texto
  final TextEditingController _textController = TextEditingController();

  // Flag se está gravando áudio
  bool _isRecording = false;

  // Texto atual (para controlar botão de envio)
  String _currentText = '';

  // ID da mensagem de loading temporária
  String? _typingMessageId;

  // Lazy loader para paginação de mensagens
  MessageLazyLoader? _lazyLoader;

  // Stream subscription para mensagens
  StreamSubscription<List<types.Message>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _configureTimeago();
    _loadAssistants();
    _loadMessagesFromDatabase();

    // Listener para o campo de texto
    _textController.addListener(() {
      setState(() {
        _currentText = _textController.text;
      });
    });

    // Listener para mudanças de assistente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assistantProvider = context.read<AssistantProvider>();
      assistantProvider.addListener(_onAssistantChanged);
    });
  }

  /// Carrega os assistentes do usuário
  Future<void> _loadAssistants() async {
    final assistantProvider = context.read<AssistantProvider>();
    await assistantProvider.loadAssistants();
  }

  /// Callback quando o assistente ativo muda
  void _onAssistantChanged() {
    print('🔄 Assistente mudou, recarregando mensagens...');
    _loadMessagesFromDatabase();
  }

  @override
  void dispose() {
    _textController.dispose();
    _messagesSubscription?.cancel();
    _lazyLoader?.dispose();

    // Remove listener de assistente
    try {
      final assistantProvider = context.read<AssistantProvider>();
      assistantProvider.removeListener(_onAssistantChanged);
    } catch (e) {
      // Ignora erro se o provider já foi descartado
    }

    super.dispose();
  }

  /// Configura formatação de timestamps em português
  void _configureTimeago() {
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  }

  /// Inicializa os usuários (você e o bot)
  void _initializeUsers() {
    final currentUser = SupabaseService.getCurrentUser();

    _user = types.User(
      id: currentUser?.id ?? 'user',
      firstName: currentUser?.email?.split('@')[0] ?? 'Você',
      imageUrl: 'https://ui-avatars.com/api/?name=${currentUser?.email?.split('@')[0] ?? 'User'}&background=2196F3&color=fff',
    );

    _bot = const types.User(
      id: 'bot',
      firstName: 'Bot',
      lastName: 'Assistente',
      imageUrl: 'https://ui-avatars.com/api/?name=Bot&background=9E9E9E&color=fff&bold=true',
    );
  }

  /// Carrega mensagens do banco de dados de forma otimizada
  Future<void> _loadMessagesFromDatabase() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final userId = SupabaseService.getCurrentUser()?.id;

      if (userId == null) {
        print('⚠️ Usuário não autenticado');
        _loadWelcomeMessage();
        setState(() {
          _isLoadingHistory = false;
        });
        return;
      }

      print('🔧 Inicializando MessageLazyLoader com pageSize=10');

      // Obtém o assistente atual
      final assistantProvider = context.read<AssistantProvider>();
      final currentAssistant = assistantProvider.currentAssistant;

      // Inicializa o lazy loader com 10 mensagens por página
      _lazyLoader = MessageLazyLoader(
        userId: userId,
        assistantId: currentAssistant?.id, // Filtra por assistente
        pageSize: 10, // Carrega apenas 10 mensagens inicialmente
        scrollThreshold: 300.0,
      );

      // Ouve mudanças nas mensagens
      _messagesSubscription = _lazyLoader!.messagesStream.listen((messages) {
        print('📨 Stream atualizado: ${messages.length} mensagens recebidas');
        // Atualiza apenas se a quantidade mudou para evitar rebuilds desnecessários
        if (mounted && _messages.length != messages.length) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages);
          });
        }
      });

      // Carrega primeira página (10 mensagens)
      print('📥 Iniciando carregamento da primeira página...');
      await _lazyLoader!.initialize(autoLoad: true);

      setState(() {
        _isLoadingHistory = false;
      });

      // Se não houver mensagens, mostra boas-vindas
      if (_messages.isEmpty) {
        _loadWelcomeMessage();
      } else {
        print('✓ ${_messages.length} mensagens carregadas do banco');
      }
    } catch (e) {
      print('✗ Erro ao carregar mensagens: $e');
      setState(() {
        _isLoadingHistory = false;
      });
      _loadWelcomeMessage(); // Fallback para mensagem de boas-vindas
    }
  }

  /// Handle Pull to Refresh (recarrega mensagens)
  Future<void> _handleRefresh() async {
    try {
      final userId = SupabaseService.getCurrentUser()?.id;

      if (userId == null) {
        _showError('Usuário não autenticado');
        return;
      }

      // Recarrega mensagens usando o lazy loader
      if (_lazyLoader != null) {
        await _lazyLoader!.refresh();
        _showSuccess('Mensagens atualizadas!');
        print('✓ ${_messages.length} mensagens recarregadas');
      }
    } catch (e) {
      print('✗ Erro ao recarregar mensagens: $e');
      _showError('Erro ao atualizar mensagens');
    }
  }

  /// Carrega mais mensagens quando o usuário scrolla para o topo
  Future<void> _handleLoadMore() async {
    if (_lazyLoader != null && !_lazyLoader!.isLoading && !_lazyLoader!.hasReachedEnd) {
      setState(() {
        _isLoadingMore = true;
      });

      print('📥 Carregando mais mensagens...');
      await _lazyLoader!.loadMore();

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// Carrega mensagem de boas-vindas (apenas se não houver histórico)
  void _loadWelcomeMessage() {
    final welcomeMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: 'Olá! Sou seu assistente virtual. Como posso ajudá-lo hoje?',
    );

    setState(() {
      _messages.insert(0, welcomeMessage);
    });

    // Salvar mensagem de boas-vindas no banco
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId != null) {
      final assistantProvider = context.read<AssistantProvider>();
      final currentAssistant = assistantProvider.currentAssistant;

      MessageService.saveMessage(
        welcomeMessage,
        userId,
        assistantId: currentAssistant?.id,
      );
    }
  }

  /// Verifica se há conexão com internet
  Future<bool> _checkInternetConnection() async {
    final isConnected = await ConnectivityService.isConnected();

    if (!isConnected) {
      _showError('Sem conexão com a internet. Verifique sua conexão e tente novamente.');
      return false;
    }

    return true;
  }

  /// Chamado quando o usuário envia uma mensagem de texto
  Future<void> _handleSendPressed(types.PartialText message) async {
    // Valida conexão com internet
    if (!await _checkInternetConnection()) {
      return;
    }

    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    await _sendTextToBot(message.text);
  }

  /// Adiciona uma mensagem à lista e salva no banco
  void _addMessage(types.Message message) {
    // Adiciona ao lazy loader se disponível
    if (_lazyLoader != null) {
      _lazyLoader!.addMessage(message);
    } else {
      // Fallback: adiciona diretamente
      setState(() {
        _messages.insert(0, message);
      });
    }

    // Salvar no banco de dados com assistentId
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId != null) {
      final assistantProvider = context.read<AssistantProvider>();
      final currentAssistant = assistantProvider.currentAssistant;

      MessageService.saveMessage(
        message,
        userId,
        assistantId: currentAssistant?.id,
      );
    }
  }

  /// Adiciona mensagem de loading temporária (indicador de digitação)
  void _addTypingMessage() {
    if (_typingMessageId != null) {
      // Já existe uma mensagem de loading, não adiciona outra
      return;
    }

    final loadingId = _uuid.v4();
    _typingMessageId = loadingId;

    final typingMessage = types.CustomMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: loadingId,
      metadata: const {'isTyping': true},
    );

    setState(() {
      _messages.insert(0, typingMessage);
    });
  }

  /// Remove a mensagem de loading temporária
  void _removeTypingMessage() {
    if (_typingMessageId == null) return;

    setState(() {
      _messages.removeWhere((msg) => msg.id == _typingMessageId);
      _typingMessageId = null;
    });
  }

  /// Envia mensagem de texto para o bot via N8N
  Future<void> _sendTextToBot(String text) async {
    // Adiciona mensagem de loading temporária
    _addTypingMessage();

    setState(() {
      _isLoading = true;
      _botIsTyping = true; // Bot está processando
    });

    try {
      // Obtém o webhook do assistente atual
      final assistantProvider = context.read<AssistantProvider>();
      final currentAssistant = assistantProvider.currentAssistant;

      // Envia para o N8N usando webhook do assistente
      final response = await N8nService.sendMessage(
        text,
        _user.id,
        webhookUrl: currentAssistant?.webhookUrl,
      );

      // Remove mensagem de loading
      _removeTypingMessage();

      // Se retornou null, significa que foi para fila offline
      if (response == null) {
        _showInfo('Sem conexão. Mensagem será enviada quando conectar.');
        return;
      }

      // Adiciona resposta do bot
      _addBotResponse(response);
    } catch (e) {
      // Remove mensagem de loading
      _removeTypingMessage();

      // Verifica se é erro de fila offline
      if (e.toString().contains('Sem conexão') || e.toString().contains('fila')) {
        _showInfo('Mensagem adicionada à fila offline');
      } else {
        _showError('Erro ao enviar mensagem: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
        _botIsTyping = false; // Bot terminou de digitar
      });
    }
  }

  /// Envia imagem para o bot via N8N
  Future<void> _sendImageToBot(File imageFile) async {
    // Adiciona mensagem de loading temporária
    _addTypingMessage();

    setState(() {
      _isLoading = true;
      _botIsTyping = true;
    });

    try {
      // Obtém o webhook do assistente atual
      final assistantProvider = context.read<AssistantProvider>();
      final currentAssistant = assistantProvider.currentAssistant;

      // Envia para o N8N como arquivo JPEG (multipart/form-data)
      // para evitar envio de base64 gigante
      final response = await N8nService.sendImageMultipart(
        imageFile,
        _user.id,
        webhookUrl: currentAssistant?.webhookUrl,
      );

      // Remove mensagem de loading
      _removeTypingMessage();

      // Adiciona resposta do bot
      _addBotResponse(response);
      _showSuccess('Imagem enviada com sucesso!');
    } catch (e) {
      // Remove mensagem de loading
      _removeTypingMessage();

      // Verifica se é erro de fila offline
      if (e.toString().contains('Sem conexão') || e.toString().contains('fila')) {
        _showInfo('Imagem adicionada à fila offline');
      } else {
        _showError('Erro ao enviar imagem: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
        _botIsTyping = false;
      });
    }
  }

  /// Envia áudio para o bot via N8N
  Future<void> _sendAudioToBot(File audioFile) async {
    // Adiciona mensagem de loading temporária
    _addTypingMessage();

    setState(() {
      _isLoading = true;
      _botIsTyping = true;
    });

    try {
      // Obtém o webhook do assistente atual
      final assistantProvider = context.read<AssistantProvider>();
      final currentAssistant = assistantProvider.currentAssistant;

      // Envia para o N8N como arquivo MP4 (multipart/form-data)
      // para permitir transcrição no N8N
      final response = await N8nService.sendAudioMultipart(
        audioFile,
        _user.id,
        webhookUrl: currentAssistant?.webhookUrl,
      );

      // Remove mensagem de loading
      _removeTypingMessage();

      // Se retornou null, significa que foi para fila offline
      if (response == null) {
        _showInfo('Sem conexão. Áudio será enviado quando conectar.');
        return;
      }

      // Adiciona resposta do bot
      _addBotResponse(response);
      _showSuccess('Áudio enviado com sucesso!');
    } catch (e) {
      // Remove mensagem de loading
      _removeTypingMessage();

      // Verifica se é erro de fila offline
      if (e.toString().contains('Sem conexão') || e.toString().contains('fila')) {
        _showInfo('Áudio adicionado à fila offline');
      } else {
        _showError('Erro ao enviar áudio: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
        _botIsTyping = false;
      });
    }
  }

  /// Adiciona a resposta do bot à conversa
  void _addBotResponse(N8nResponse response) {
    // Se a resposta for texto
    if (response.isText) {
      final botMessage = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        text: response.text,
      );
      _addMessage(botMessage);
    }
    // Se a resposta for imagem
    else if (response.isImage && response.data != null) {
      final botMessage = types.ImageMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        name: 'response.jpg',
        size: 0,
        uri: response.data!, // URL ou base64
      );
      _addMessage(botMessage);
    }
    // Se a resposta for áudio
    else if (response.isAudio && response.data != null) {
      final botMessage = types.FileMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        name: 'response.m4a',
        size: 0,
        uri: response.data!, // URL ou base64
        mimeType: 'audio/m4a',
      );
      _addMessage(botMessage);
    }
  }

  /// Mostra mensagem de erro no topo da tela
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 72, // AppBar height + padding
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height -
                 (MediaQuery.of(context).padding.top + 72 + 80), // Deixa espaço para a mensagem
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra mensagem de informação no topo da tela
  void _showInfo(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 72, // AppBar height + padding
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height -
                 (MediaQuery.of(context).padding.top + 72 + 80), // Deixa espaço para a mensagem
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra mensagem de sucesso no topo da tela
  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 72, // AppBar height + padding
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height -
                 (MediaQuery.of(context).padding.top + 72 + 80), // Deixa espaço para a mensagem
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Faz logout
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Seleciona e envia uma imagem da galeria
  Future<void> _handleImageSelection() async {
    try {
      // Usa MediaService para selecionar imagem
      final imageFile = await MediaService.pickImageFromGallery();

      if (imageFile != null) {
        // Valida a imagem
        if (!MediaService.isValidImage(imageFile)) {
          _showError('Formato de imagem inválido');
          return;
        }

        // Valida tamanho (max 10 MB)
        if (!await MediaService.isImageSizeValid(imageFile, maxSizeInMB: 10)) {
          _showError('Imagem muito grande. Máximo: 10 MB');
          return;
        }

        // Mostra a imagem no chat
        final imageMessage = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: _uuid.v4(),
          name: imageFile.path.split('/').last,
          size: await imageFile.length(),
          uri: imageFile.path,
        );

        _addMessage(imageMessage);

        // Envia para o bot
        _sendImageToBot(imageFile);
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  /// Tira uma foto com a câmera
  Future<void> _handleCameraCapture() async {
    try {
      // Usa MediaService para capturar foto
      final photoFile = await MediaService.pickImageFromCamera();

      if (photoFile != null) {
        // Valida a foto
        if (!MediaService.isValidImage(photoFile)) {
          _showError('Formato de imagem inválido');
          return;
        }

        // Valida tamanho (max 10 MB)
        if (!await MediaService.isImageSizeValid(photoFile, maxSizeInMB: 10)) {
          _showError('Foto muito grande. Máximo: 10 MB');
          return;
        }

        // Mostra a foto no chat
        final imageMessage = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: _uuid.v4(),
          name: photoFile.path.split('/').last,
          size: await photoFile.length(),
          uri: photoFile.path,
        );

        _addMessage(imageMessage);

        // Envia para o bot
        _sendImageToBot(photoFile);
      }
    } catch (e) {
      _showError('Erro ao tirar foto: $e');
    }
  }

  /// Mostra opções de anexo (apenas imagens)
  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Título
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Opção: Galeria
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Galeria'),
                subtitle: const Text('Escolher foto da galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
              ),
              const SizedBox(height: 8),
              // Opção: Câmera
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('Câmera'),
                subtitle: const Text('Tirar uma foto'),
                onTap: () {
                  Navigator.pop(context);
                  _handleCameraCapture();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final assistantProvider = Provider.of<AssistantProvider>(context);
    final currentAssistant = assistantProvider.currentAssistant;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const AssistantsDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Menu',
          ),
        ),
        title: currentAssistant != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: currentAssistant.primaryColor,
                    backgroundImage: currentAssistant.avatarUrl != null
                        ? NetworkImage(currentAssistant.effectiveAvatarUrl)
                        : null,
                    child: currentAssistant.avatarUrl == null
                        ? Text(
                            currentAssistant.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      currentAssistant.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : const Text('Meu Bot'),
        actions: [
          // Indicador de loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Botão de configurações do assistente
          if (currentAssistant != null)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Configurar Assistente',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssistantEditScreen(
                      assistant: currentAssistant,
                    ),
                  ),
                );
              },
            ),
          // Toggle de tema
          IconButton(
            icon: Icon(themeProvider.themeIcon),
            tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de loading ao carregar mais mensagens
          if (_isLoadingMore && !_isLoadingHistory)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isDark ? Colors.black26 : Colors.white70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Carregando mensagens antigas...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          // Chat principal com Pull to Refresh
          Expanded(
            child: _isLoadingHistory
                ? _buildLoadingState()
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: RepaintBoundary(
                          child: Chat(
                            messages: _messages,
                            onSendPressed: _handleSendPressed,
                            user: _user,
                            // Carregar mais mensagens quando chegar perto do fim
                            onEndReached: _handleLoadMore,
                            onEndReachedThreshold: 0.7, // Carrega quando estiver a 70% do fim
                            // Scroll suave e natural (usa o padrão da plataforma)
                            // Tema personalizado baseado no assistente atual
                          theme: DefaultChatTheme(
                            // Cor das mensagens do usuário - usa cor do assistente
                            primaryColor: currentAssistant?.primaryColor ??
                                (isDark
                                    ? AppThemes.darkUserBubble
                                    : AppThemes.lightUserBubble),
                            // Cor das mensagens do bot - usa cor secundária do assistente
                            secondaryColor: currentAssistant?.secondaryColor ??
                                (isDark
                                    ? AppThemes.darkBotBubble
                                    : AppThemes.lightBotBubble),
                            // Cor de fundo
                            backgroundColor: isDark
                                ? AppThemes.darkBackground
                                : AppThemes.lightBackground,
                            // Cor do texto de entrada
                            inputBackgroundColor: isDark
                                ? AppThemes.darkInputBackground
                                : AppThemes.lightInputBackground,
                            inputTextColor: isDark
                                ? AppThemes.darkInputText
                                : AppThemes.lightInputText,
                            // Bordas arredondadas
                            messageBorderRadius: 20,
                            // Padding das mensagens
                            messageInsetsVertical: 12,
                            messageInsetsHorizontal: 16,
                            // Cor do texto nas mensagens
                            sentMessageBodyTextStyle: TextStyle(
                              color: AppThemes.lightUserText,
                              fontSize: 16,
                            ),
                            receivedMessageBodyTextStyle: TextStyle(
                              color: isDark
                                  ? AppThemes.darkBotText
                                  : AppThemes.lightBotText,
                              fontSize: 16,
                            ),
                          ),
                          // Textos em português
                          l10n: const ChatL10nPt(),
                          // Desabilita swipe to reply (opcional)
                          disableImageGallery: false,
                          // Avatar customizado
                          showUserAvatars: true,
                          showUserNames: true,
                          // Customiza a exibição de cada mensagem para incluir timestamp
                          customDateHeaderText: (DateTime dateTime) {
                            return timeago.format(dateTime, locale: 'pt_BR');
                          },
                          // Builder para mensagens customizadas (loading indicator)
                          customMessageBuilder: (types.CustomMessage message, {required int messageWidth}) {
                            // Verifica se é uma mensagem de loading
                            if (message.metadata?['isTyping'] == true) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppThemes.darkBotBubble
                                      : AppThemes.lightBotBubble,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: BotTypingIndicator(
                                  dotColor: isDark
                                      ? AppThemes.darkBotText
                                      : AppThemes.lightBotText,
                                ),
                              );
                            }
                            // Para outros tipos de mensagens customizadas, retorna widget vazio
                            // (não renderiza nada)
                            return const SizedBox.shrink();
                          },
                          // Input customizado estilo WhatsApp
                          customBottomWidget: _buildCustomInput(isDark),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Widget para o estado de carregamento inicial (com skeleton screens)
  Widget _buildLoadingState() {
    return const ChatHistorySkeletonLoading(
      messageCount: 6, // Mostra 6 mensagens skeleton
    );
  }

  /// Widget para o estado vazio (sem mensagens)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma mensagem ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Envie uma mensagem para começar a conversar com o bot!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o input customizado estilo WhatsApp
  Widget _buildCustomInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppThemes.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16), // Arredonda todos os lados
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppThemes.darkInputBackground
                      : AppThemes.lightInputBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      // Botão de anexo (imagem)
                      IconButton(
                        icon: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: isDark
                              ? AppThemes.darkInputText.withOpacity(0.7)
                              : AppThemes.lightInputText.withOpacity(0.7),
                        ),
                        onPressed: _handleAttachmentPressed,
                        tooltip: 'Enviar imagem',
                      ),
                      // Campo de texto
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: TextStyle(
                            color: isDark
                                ? AppThemes.darkInputText
                                : AppThemes.lightInputText,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Digite uma mensagem',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppThemes.darkInputText.withOpacity(0.5)
                                  : AppThemes.lightInputText.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 10,
                            ),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botão de ação (microfone ou enviar)
            _buildActionButton(isDark),
          ],
        ),
      ),
    );
  }

  /// Constrói o botão de ação (microfone ou enviar)
  Widget _buildActionButton(bool isDark) {
    final assistantProvider = Provider.of<AssistantProvider>(context);
    final currentAssistant = assistantProvider.currentAssistant;
    final buttonColor = currentAssistant?.primaryColor ?? AppThemes.lightPrimary;

    // Se há texto, mostra botão de enviar
    if (_currentText.trim().isNotEmpty) {
      return Material(
        color: buttonColor,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (_currentText.trim().isNotEmpty) {
              // Envia a mensagem
              _handleSendPressed(types.PartialText(text: _currentText.trim()));
              // Limpa o campo
              _textController.clear();
            }
          },
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }

    // Se não há texto, mostra botão de microfone
    return Material(
      color: _isRecording ? Colors.red : buttonColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _handleMicrophonePressed,
        onLongPress: _handleMicrophonePressed,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            _isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  /// Manipula o pressionamento do botão de microfone
  Future<void> _handleMicrophonePressed() async {
    if (_isRecording) {
      // Para a gravação
      await _stopRecordingAndSend();
    } else {
      // Inicia a gravação
      await _startRecording();
    }
  }

  /// Inicia a gravação de áudio
  Future<void> _startRecording() async {
    try {
      // startRecording() já solicita permissão internamente
      final started = await AudioService.startRecording();

      if (!started) {
        _showError('Não foi possível iniciar a gravação');
        return;
      }

      setState(() {
        _isRecording = true;
      });

      _showInfo('Gravando áudio...');
    } catch (e) {
      if (e.toString().contains('Permissão')) {
        _showError('Permissão de microfone necessária');
      } else {
        _showError('Erro ao iniciar gravação: $e');
      }
    }
  }

  /// Para a gravação e envia o áudio
  Future<void> _stopRecordingAndSend() async {
    try {
      setState(() {
        _isRecording = false;
      });

      final audioFile = await AudioService.stopRecording();

      if (audioFile != null) {
        // Valida o áudio
        if (!await AudioService.isValidAudio(audioFile)) {
          _showError('Áudio muito curto (mínimo 1 segundo)');
          return;
        }

        if (!await AudioService.isAudioSizeValid(audioFile, maxSizeInMB: 5)) {
          _showError('Áudio muito grande (máximo 5MB)');
          return;
        }

        // Cria mensagem de áudio
        final audioMessage = types.FileMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: _uuid.v4(),
          name: audioFile.path.split('/').last,
          size: await audioFile.length(),
          uri: audioFile.path,
          mimeType: 'audio/m4a',
        );

        _addMessage(audioMessage);

        // Envia para o bot
        _sendAudioToBot(audioFile);
      } else {
        _showError('Erro ao gravar áudio');
      }
    } catch (e) {
      _showError('Erro ao processar áudio: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }
}

/// Localização em português para o chat
class ChatL10nPt extends ChatL10n {
  const ChatL10nPt()
      : super(
          and: 'e',
          attachmentButtonAccessibilityLabel: 'Enviar mídia',
          emptyChatPlaceholder: 'Nenhuma mensagem ainda',
          fileButtonAccessibilityLabel: 'Arquivo',
          inputPlaceholder: 'Digite uma mensagem',
          isTyping: 'está digitando',
          others: 'outros',
          sendButtonAccessibilityLabel: 'Enviar',
          unreadMessagesLabel: 'Mensagens não lidas',
        );
}
