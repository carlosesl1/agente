import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

/// Modelo de mensagem para o chat
///
/// Representa uma mensagem enviada ou recebida no chat
class MessageModel {
  /// ID único da mensagem
  final String id;

  /// Conteúdo da mensagem (texto, URL da imagem, caminho do áudio)
  final String content;

  /// Tipo da mensagem
  final MessageType type;

  /// Remetente da mensagem
  final MessageSender sender;

  /// Timestamp da mensagem
  final DateTime timestamp;

  /// Metadados adicionais (opcional)
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.metadata,
  });

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'sender': sender.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Cria a partir de JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      sender: MessageSender.values.firstWhere(
        (e) => e.toString().split('.').last == json['sender'],
        orElse: () => MessageSender.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converte para o tipo de mensagem do flutter_chat_ui
  types.Message toChatMessage(types.User author) {
    switch (type) {
      case MessageType.text:
        return types.TextMessage(
          author: author,
          createdAt: timestamp.millisecondsSinceEpoch,
          id: id,
          text: content,
        );

      case MessageType.image:
        return types.ImageMessage(
          author: author,
          createdAt: timestamp.millisecondsSinceEpoch,
          id: id,
          name: 'image.jpg',
          size: 0,
          uri: content,
        );

      case MessageType.audio:
        return types.FileMessage(
          author: author,
          createdAt: timestamp.millisecondsSinceEpoch,
          id: id,
          name: 'audio.m4a',
          size: 0,
          uri: content,
          mimeType: 'audio/m4a',
        );

      default:
        return types.TextMessage(
          author: author,
          createdAt: timestamp.millisecondsSinceEpoch,
          id: id,
          text: content,
        );
    }
  }

  /// Cria uma mensagem de texto
  factory MessageModel.text({
    required String id,
    required String text,
    required MessageSender sender,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      content: text,
      type: MessageType.text,
      sender: sender,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Cria uma mensagem de imagem
  factory MessageModel.image({
    required String id,
    required String imageUrl,
    required MessageSender sender,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      content: imageUrl,
      type: MessageType.image,
      sender: sender,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Cria uma mensagem de áudio
  factory MessageModel.audio({
    required String id,
    required String audioPath,
    required MessageSender sender,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      content: audioPath,
      type: MessageType.audio,
      sender: sender,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, type: $type, sender: $sender, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}

/// Tipo de mensagem
enum MessageType {
  /// Mensagem de texto
  text,

  /// Mensagem com imagem
  image,

  /// Mensagem com áudio
  audio,
}

/// Remetente da mensagem
enum MessageSender {
  /// Mensagem do usuário
  user,

  /// Mensagem do bot
  bot,
}
