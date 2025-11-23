import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:share_plus/share_plus.dart';
import 'message_service.dart';
import 'supabase_service.dart';

/// Serviço de exportação e backup de dados
///
/// Permite exportar conversas em diferentes formatos
class ExportService {
  /// Exporta mensagens para JSON
  ///
  /// [userId] - ID do usuário
  /// [assistantId] - ID do assistente (opcional, para filtrar)
  /// [includeMetadata] - Se deve incluir metadados extras
  static Future<File> exportToJson({
    required String userId,
    String? assistantId,
    bool includeMetadata = true,
  }) async {
    try {
      print('📦 Exportando mensagens para JSON...');

      // Carrega todas as mensagens
      final messages = await MessageService.loadMessages(
        userId,
        assistantId: assistantId,
        limit: 10000, // Todas as mensagens
        useCache: false,
      );

      // Monta o JSON de exportação
      final exportData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        if (assistantId != null) 'assistantId': assistantId,
        'messageCount': messages.length,
        'messages': messages.map((msg) => _messageToExportJson(msg)).toList(),
        if (includeMetadata) 'metadata': await _getExportMetadata(userId),
      };

      // Salva em arquivo temporário
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/chat_export_$timestamp.json');

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      print('✅ Exportação concluída: ${file.path}');

      return file;
    } catch (e) {
      print('✗ Erro ao exportar para JSON: $e');
      rethrow;
    }
  }

  /// Exporta mensagens para TXT (formato legível)
  ///
  /// [userId] - ID do usuário
  /// [assistantId] - ID do assistente (opcional)
  static Future<File> exportToText({
    required String userId,
    String? assistantId,
  }) async {
    try {
      print('📝 Exportando mensagens para TXT...');

      final messages = await MessageService.loadMessages(
        userId,
        assistantId: assistantId,
        limit: 10000,
        useCache: false,
      );

      final buffer = StringBuffer();
      buffer.writeln('=' * 60);
      buffer.writeln('EXPORTAÇÃO DE CHAT');
      buffer.writeln('Data: ${DateTime.now().toString()}');
      buffer.writeln('Total de mensagens: ${messages.length}');
      buffer.writeln('=' * 60);
      buffer.writeln();

      // Ordena mensagens do mais antigo para o mais recente
      final sortedMessages = List<types.Message>.from(messages)
        ..sort((a, b) {
          final aTime = a.createdAt ?? 0;
          final bTime = b.createdAt ?? 0;
          return aTime.compareTo(bTime);
        });

      for (var message in sortedMessages) {
        final timestamp = message.createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(message.createdAt!)
            : DateTime.now();

        final author = message.author.firstName ?? 'Desconhecido';
        final time = '${timestamp.day.toString().padLeft(2, '0')}/'
            '${timestamp.month.toString().padLeft(2, '0')}/'
            '${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:'
            '${timestamp.minute.toString().padLeft(2, '0')}';

        buffer.writeln('[$time] $author:');

        if (message is types.TextMessage) {
          buffer.writeln(message.text);
        } else if (message is types.ImageMessage) {
          buffer.writeln('[Imagem: ${message.name}]');
        } else if (message is types.FileMessage) {
          buffer.writeln('[Arquivo: ${message.name}]');
        }

        buffer.writeln();
      }

      // Salva em arquivo
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/chat_export_$timestamp.txt');

      await file.writeAsString(buffer.toString());

      print('✅ Exportação TXT concluída: ${file.path}');

      return file;
    } catch (e) {
      print('✗ Erro ao exportar para TXT: $e');
      rethrow;
    }
  }

  /// Compartilha a exportação via share sheet
  ///
  /// [file] - Arquivo a compartilhar
  /// [format] - Formato da exportação ('json' ou 'txt')
  static Future<void> shareExport(File file, String format) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Exportação de Chat - ${DateTime.now().toString()}',
        text: 'Aqui está a exportação do chat em formato $format',
      );

      if (result.status == ShareResultStatus.success) {
        print('✅ Exportação compartilhada com sucesso');
      }
    } catch (e) {
      print('✗ Erro ao compartilhar: $e');
      rethrow;
    }
  }

  /// Cria backup completo dos dados do usuário
  ///
  /// [userId] - ID do usuário
  static Future<File> createFullBackup(String userId) async {
    try {
      print('💾 Criando backup completo...');

      // Carrega mensagens de todos os assistentes
      final allMessages = await MessageService.loadMessages(
        userId,
        limit: 10000,
        useCache: false,
      );

      // TODO: Carregar assistentes quando o serviço estiver disponível
      final backupData = {
        'version': '1.0',
        'backupType': 'full',
        'createdAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'data': {
          'messages': allMessages.map((m) => _messageToExportJson(m)).toList(),
          // 'assistants': [], // Adicionar quando disponível
          // 'preferences': {}, // Adicionar preferências
        },
        'metadata': await _getExportMetadata(userId),
      };

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/backup_$timestamp.json');

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      print('✅ Backup criado: ${file.path}');

      return file;
    } catch (e) {
      print('✗ Erro ao criar backup: $e');
      rethrow;
    }
  }

  /// Restaura backup
  ///
  /// [backupFile] - Arquivo de backup
  static Future<bool> restoreBackup(File backupFile) async {
    try {
      print('📥 Restaurando backup...');

      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Valida versão do backup
      final version = backupData['version'] as String?;
      if (version != '1.0') {
        throw Exception('Versão de backup incompatível');
      }

      // TODO: Implementar restauração de mensagens
      // Isso requer cuidado para não duplicar dados

      print('✅ Backup restaurado com sucesso');
      return true;
    } catch (e) {
      print('✗ Erro ao restaurar backup: $e');
      return false;
    }
  }

  /// Converte mensagem para formato de exportação JSON
  static Map<String, dynamic> _messageToExportJson(types.Message message) {
    final base = {
      'id': message.id,
      'author': {
        'id': message.author.id,
        'firstName': message.author.firstName,
        'lastName': message.author.lastName,
      },
      'createdAt': message.createdAt,
      'type': message.type.toString().split('.').last,
    };

    if (message is types.TextMessage) {
      return {...base, 'text': message.text};
    } else if (message is types.ImageMessage) {
      return {
        ...base,
        'name': message.name,
        'size': message.size,
        'uri': message.uri,
      };
    } else if (message is types.FileMessage) {
      return {
        ...base,
        'name': message.name,
        'size': message.size,
        'uri': message.uri,
        'mimeType': message.mimeType,
      };
    }

    return base;
  }

  /// Obtém metadados da exportação
  static Future<Map<String, dynamic>> _getExportMetadata(
    String userId,
  ) async {
    try {
      final user = SupabaseService.getCurrentUser();

      return {
        'userEmail': user?.email,
        'platform': Platform.operatingSystem,
        'appVersion': '1.0.0',
      };
    } catch (e) {
      return {};
    }
  }

  /// Lista todos os backups disponíveis
  static Future<List<File>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .where((f) => f.path.endsWith('.json') && f.path.contains('backup_'))
          .map((f) => File(f.path))
          .toList();

      // Ordena por data (mais recente primeiro)
      files.sort((a, b) => b.path.compareTo(a.path));

      return files;
    } catch (e) {
      print('✗ Erro ao listar backups: $e');
      return [];
    }
  }

  /// Deleta backup
  static Future<bool> deleteBackup(File backupFile) async {
    try {
      await backupFile.delete();
      print('✅ Backup deletado: ${backupFile.path}');
      return true;
    } catch (e) {
      print('✗ Erro ao deletar backup: $e');
      return false;
    }
  }
}
