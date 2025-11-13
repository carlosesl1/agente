import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../models/message_model.dart';
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

  // Image picker para selecionar imagens
  final ImagePicker _imagePicker = ImagePicker();

  // UUID generator para IDs únicos
  final Uuid _uuid = const Uuid();

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _loadWelcomeMessage();
  }

  /// Inicializa os usuários (você e o bot)
  void _initializeUsers() {
    final currentUser = SupabaseService.getCurrentUser();

    _user = types.User(
      id: currentUser?.id ?? 'user',
      firstName: currentUser?.email?.split('@')[0] ?? 'Você',
    );

    _bot = const types.User(
      id: 'bot',
      firstName: 'Bot',
      lastName: 'Assistente',
    );
  }

  /// Carrega mensagem de boas-vindas
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
  }

  /// Chamado quando o usuário envia uma mensagem de texto
  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    _sendToBot(message.text, MessageType.text);
  }

  /// Adiciona uma mensagem à lista
  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  /// Envia mensagem para o bot/N8N e recebe resposta
  Future<void> _sendToBot(String content, MessageType type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Integrar com N8N aqui
      // Por enquanto, simula uma resposta do bot
      await Future.delayed(const Duration(seconds: 1));

      // Resposta simulada do bot
      final botResponse = types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: _uuid.v4(),
        text: _generateBotResponse(content, type),
      );

      _addMessage(botResponse);
    } catch (e) {
      // Tratamento de erro
      _showError('Erro ao enviar mensagem: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Gera uma resposta simulada do bot
  /// TODO: Substituir por integração real com N8N
  String _generateBotResponse(String userMessage, MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'Você disse: "$userMessage". Esta é uma resposta simulada. '
            'A integração com o N8N será implementada em breve.';
      case MessageType.image:
        return 'Recebi sua imagem! Análise de imagem será implementada em breve.';
      case MessageType.audio:
        return 'Recebi seu áudio! Transcrição será implementada em breve.';
      default:
        return 'Mensagem recebida!';
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

  /// Seleciona e envia uma imagem
  Future<void> _handleImageSelection() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final imageMessage = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: _uuid.v4(),
          name: image.name,
          size: await image.length(),
          uri: image.path,
        );

        _addMessage(imageMessage);
        _sendToBot(image.path, MessageType.image);
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  /// Tira uma foto com a câmera
  Future<void> _handleCameraCapture() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        final imageMessage = types.ImageMessage(
          author: _user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: _uuid.v4(),
          name: photo.name,
          size: await photo.length(),
          uri: photo.path,
        );

        _addMessage(imageMessage);
        _sendToBot(photo.path, MessageType.image);
      }
    } catch (e) {
      _showError('Erro ao tirar foto: $e');
    }
  }

  /// Grava e envia um áudio
  Future<void> _handleAudioRecording() async {
    // TODO: Implementar gravação de áudio com o pacote 'record'
    _showInfo('Gravação de áudio será implementada em breve');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Bot'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Indicador de loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          // Botão de logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        onAttachmentPressed: _handleAttachmentPressed,
        user: _user,
        // Tema personalizado
        theme: DefaultChatTheme(
          // Cor das mensagens do usuário (azul)
          primaryColor: Colors.blue,
          // Cor das mensagens do bot (cinza)
          secondaryColor: Colors.grey[200]!,
          // Cor de fundo
          backgroundColor: Colors.white,
          // Cor do texto de entrada
          inputBackgroundColor: Colors.grey[100]!,
          inputTextColor: Colors.black87,
          // Bordas arredondadas
          messageBorderRadius: 20,
          // Padding das mensagens
          messageInsetsVertical: 12,
          messageInsetsHorizontal: 16,
        ),
        // Textos em português
        l10n: const ChatL10nPt(),
        // Desabilita swipe to reply (opcional)
        disableImageGallery: false,
        // Avatar customizado
        showUserAvatars: true,
        showUserNames: true,
      ),
    );
  }
}

/// Localização em português para o chat
class ChatL10nPt extends ChatL10n {
  const ChatL10nPt({
    super.attachmentButtonAccessibilityLabel = 'Enviar mídia',
    super.emptyChatPlaceholder = 'Nenhuma mensagem ainda',
    super.fileButtonAccessibilityLabel = 'Arquivo',
    super.inputPlaceholder = 'Digite uma mensagem',
    super.sendButtonAccessibilityLabel = 'Enviar',
    super.unreadMessagesLabel = 'Mensagens não lidas',
  });
}
