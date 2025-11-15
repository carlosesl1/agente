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
import '../widgets/skeleton_loading.dart';
import '../theme/app_themes.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';

/// Tela principal de chat
///
/// Permite conversar com o bot usando texto, imagens e áudio
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _configureTimeago();
    _loadMessagesFromDatabase();
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

  /// Carrega mensagens do banco de dados
  Future<void> _loadMessagesFromDatabase() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final userId = SupabaseService.getCurrentUser()?.id;

      if (userId == null) {
        print('⚠️ Usuário não autenticado');
        _loadWelcomeMessage();
        return;
      }

      // Carregar últimas 50 mensagens
      final messages = await MessageService.loadMessages(userId, limit: 50);

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });

      // Se não houver mensagens, mostra boas-vindas
      if (_messages.isEmpty) {
        _loadWelcomeMessage();
      }

      print('✓ ${_messages.length} mensagens carregadas do banco');
    } catch (e) {
      print('✗ Erro ao carregar mensagens: $e');
      _loadWelcomeMessage(); // Fallback para mensagem de boas-vindas
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
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

      // Força reload do Supabase (sem usar cache)
      final messages = await MessageService.loadMessages(
        userId,
        limit: 50,
        useCache: false, // Force fetch from Supabase
      );

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });

      _showSuccess('Mensagens atualizadas!');
      print('✓ ${_messages.length} mensagens recarregadas');
    } catch (e) {
      print('✗ Erro ao recarregar mensagens: $e');
      _showError('Erro ao atualizar mensagens');
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
      MessageService.saveMessage(welcomeMessage, userId);
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
    setState(() {
      _messages.insert(0, message);
    });

    // Salvar no banco de dados
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId != null) {
      MessageService.saveMessage(message, userId);
    }
  }

  /// Envia mensagem de texto para o bot via N8N
  Future<void> _sendTextToBot(String text) async {
    setState(() {
      _isLoading = true;
      _botIsTyping = true; // Bot está processando
    });

    try {
      // Envia para o N8N
      final response = await N8nService.sendMessage(
        text,
        _user.id,
      );

      // Se retornou null, significa que foi para fila offline
      if (response == null) {
        _showInfo('Sem conexão. Mensagem será enviada quando conectar.');
        return;
      }

      // Adiciona resposta do bot
      _addBotResponse(response);
    } catch (e) {
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
    setState(() {
      _isLoading = true;
      _botIsTyping = true;
    });

    try {
      // Envia para o N8N (usando base64)
      final response = await N8nService.sendImage(
        imageFile,
        _user.id,
      );

      // Se retornou null, significa que foi para fila offline
      if (response == null) {
        _showInfo('Sem conexão. Imagem será enviada quando conectar.');
        return;
      }

      // Adiciona resposta do bot
      _addBotResponse(response);
      _showSuccess('Imagem enviada com sucesso!');
    } catch (e) {
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
    setState(() {
      _isLoading = true;
      _botIsTyping = true;
    });

    try {
      // Envia para o N8N (usando base64)
      final response = await N8nService.sendAudio(
        audioFile,
        _user.id,
      );

      // Se retornou null, significa que foi para fila offline
      if (response == null) {
        _showInfo('Sem conexão. Áudio será enviado quando conectar.');
        return;
      }

      // Adiciona resposta do bot
      _addBotResponse(response);
      _showSuccess('Áudio enviado com sucesso!');
    } catch (e) {
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

  /// Mostra mensagem de erro
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostra mensagem de informação
  void _showInfo(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostra mensagem de sucesso
  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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

  /// Grava e envia um áudio
  Future<void> _handleAudioRecording() async {
    try {
      // Verifica se já está gravando
      if (AudioService.isRecording) {
        // Para a gravação
        final audioFile = await AudioService.stopRecording();

        if (audioFile != null) {
          // Valida o áudio
          if (!await AudioService.isValidAudio(audioFile)) {
            _showError('Formato de áudio inválido');
            return;
          }

          // Valida tamanho (max 5 MB)
          if (!await AudioService.isAudioSizeValid(audioFile, maxSizeInMB: 5)) {
            _showError('Áudio muito grande. Máximo: 5 MB');
            return;
          }

          // Mostra o áudio no chat
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

          _showInfo('Áudio gravado com sucesso');
        }
      } else {
        // Inicia a gravação
        final started = await AudioService.startRecording();

        if (started) {
          _showInfo('Gravando... Toque novamente para parar');
        } else {
          _showError('Não foi possível iniciar gravação');
        }
      }
    } catch (e) {
      _showError('Erro ao gravar áudio: $e');
      // Cancela gravação em caso de erro
      await AudioService.cancelRecording();
    }
  }

  /// Mostra opções de anexo (imagem ou áudio)
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
              const SizedBox(height: 8),
              // Opção: Áudio
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mic, color: Colors.orange),
                ),
                title: const Text('Áudio'),
                subtitle: const Text('Gravar mensagem de voz'),
                onTap: () {
                  Navigator.pop(context);
                  _handleAudioRecording();
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppThemes.lightPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Meu Bot'),
          ],
        ),
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
          // Toggle de tema
          IconButton(
            icon: Icon(themeProvider.themeIcon),
            tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          // Botão de logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador "digitando..." do bot com skeleton
          if (_botIsTyping)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey[50],
              child: const BotTypingSkeletonLoading(),
            ),
          // Chat principal com Pull to Refresh
          Expanded(
            child: _isLoadingHistory
                ? _buildLoadingState()
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: Chat(
                          messages: _messages,
                          onSendPressed: _handleSendPressed,
                          onAttachmentPressed: _handleAttachmentPressed,
                          user: _user,
                          // Tema personalizado baseado no tema atual
                          theme: DefaultChatTheme(
                            // Cor das mensagens do usuário
                            primaryColor: isDark
                                ? AppThemes.darkUserBubble
                                : AppThemes.lightUserBubble,
                            // Cor das mensagens do bot
                            secondaryColor: isDark
                                ? AppThemes.darkBotBubble
                                : AppThemes.lightBotBubble,
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
