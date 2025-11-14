/// EXEMPLOS DE INTEGRAÇÃO DO LOGGING ESTRUTURADO
///
/// Este arquivo mostra como usar o AppLogger nos serviços existentes
///
/// 📝 INSTRUÇÕES:
/// 1. Importe o logger: import 'app_logger.dart';
/// 2. Use a classe global Log para logs rápidos
/// 3. Ou use AppLogger() para mais controle
///
/// ⚠️  IMPORTANTE: Inicialize o logger no main.dart antes de usar:
/// await AppLogger().initialize();

// EXEMPLO 1: N8N Service com logging
/*
import 'app_logger.dart';

class N8nService {
  static Future<N8nResponse?> sendMessage(String message, String userId) async {
    Log.info('Enviando mensagem', metadata: {
      'userId': userId,
      'messageLength': message.length,
    });

    if (!_connectivity.isOnline) {
      Log.warning('Sem conexão, adicionando à fila offline', metadata: {
        'userId': userId,
        'messageType': 'text',
      });

      await _offlineQueue.addToQueue(...);
      return null;
    }

    return RetryService.executeWithTimeout(
      operation: () async {
        try {
          Log.debug('Enviando payload para N8N', metadata: {
            'url': AppConfig.n8nWebhookUrl,
            'userId': userId,
          });

          final response = await _dio.post(...);

          Log.info('Resposta recebida do N8N', metadata: {
            'statusCode': response.statusCode,
            'userId': userId,
          });

          return N8nResponse.fromJson(response.data);
        } on DioException catch (e) {
          Log.error(
            'Erro ao enviar mensagem para N8N',
            error: e,
            metadata: {
              'errorType': e.type.toString(),
              'userId': userId,
              'statusCode': e.response?.statusCode,
            },
          );
          throw _handleDioError(e);
        }
      },
      timeoutSeconds: AppConfig.httpTimeout,
      onRetry: (attempt, error) {
        Log.warning('Tentando reenviar mensagem', metadata: {
          'attempt': attempt,
          'error': error.toString(),
          'userId': userId,
        });
      },
    );
  }
}
*/

// EXEMPLO 2: Message Service com logging
/*
import 'app_logger.dart';

class MessageService {
  static Future<void> saveMessage(types.Message message, String userId) async {
    Log.debug('Salvando mensagem', metadata: {
      'messageId': message.id,
      'userId': userId,
      'messageType': message.runtimeType.toString(),
    });

    await _cache.addMessage(message);

    try {
      final data = _messageToJson(message, userId);
      await SupabaseService.client.from('messages').insert(data);

      Log.info('Mensagem salva com sucesso', metadata: {
        'messageId': message.id,
        'userId': userId,
      });
    } catch (e, stackTrace) {
      Log.error(
        'Falha ao salvar mensagem no Supabase',
        error: e,
        stackTrace: stackTrace,
        metadata: {
          'messageId': message.id,
          'userId': userId,
        },
      );
      // Não lança exceção - mensagem já está no cache
    }
  }

  static Future<List<types.Message>> loadMessages(String userId, {
    int limit = 50,
    int offset = 0,
    bool useCache = true,
  }) async {
    if (useCache && _cache.count > 0 && offset == 0) {
      Log.debug('Carregando mensagens do cache', metadata: {
        'userId': userId,
        'limit': limit,
        'cacheSize': _cache.count,
      });

      final cachedMessages = _cache.getMessages(limit: limit, offset: offset);
      _syncInBackground(userId);
      return cachedMessages;
    }

    try {
      Log.info('Carregando mensagens do Supabase', metadata: {
        'userId': userId,
        'limit': limit,
        'offset': offset,
      });

      final response = await SupabaseService.client
          .from('messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<dynamic> data = response as List<dynamic>;

      Log.info('Mensagens carregadas do Supabase', metadata: {
        'userId': userId,
        'count': data.length,
      });

      return data.map((json) => _messageFromJson(json)).toList();
    } catch (e, stackTrace) {
      Log.error(
        'Erro ao carregar mensagens do Supabase',
        error: e,
        stackTrace: stackTrace,
        metadata: {
          'userId': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      // Fallback para cache
      if (useCache && _cache.count > 0) {
        Log.warning('Usando cache como fallback', metadata: {
          'userId': userId,
          'cacheSize': _cache.count,
        });
        return _cache.getMessages(limit: limit, offset: offset);
      }

      return [];
    }
  }
}
*/

// EXEMPLO 3: Audio Service com logging
/*
import 'app_logger.dart';

class AudioService {
  static Future<bool> startRecording() async {
    Log.info('Iniciando gravação de áudio');

    try {
      if (_isRecording) {
        Log.warning('Tentativa de gravar enquanto já está gravando');
        return false;
      }

      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        Log.warning('Permissão de microfone negada');
        throw Exception('Permissão de microfone negada');
      }

      await _recorder.start(config, path: _currentAudioPath!);
      _isRecording = true;

      Log.info('Gravação iniciada com sucesso', metadata: {
        'path': _currentAudioPath,
        'config': {
          'bitRate': 64000,
          'sampleRate': 22050,
          'channels': 1,
        },
      });

      return true;
    } catch (e, stackTrace) {
      Log.error(
        'Falha ao iniciar gravação',
        error: e,
        stackTrace: stackTrace,
      );
      _isRecording = false;
      _currentAudioPath = null;
      rethrow;
    }
  }

  static Future<File> compressAudio(File audioFile, {int bitrate = 48}) async {
    final originalSize = await audioFile.length();

    Log.info('Iniciando compressão de áudio', metadata: {
      'originalPath': audioFile.path,
      'originalSize': originalSize,
      'targetBitrate': bitrate,
    });

    try {
      final command = '-i "${audioFile.path}" -c:a libopus -b:a ${bitrate}k -ar 16000 -ac 1 -vn -y "$compressedPath"';

      Log.debug('Executando FFmpeg', metadata: {
        'command': command,
      });

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        Log.warning('FFmpeg falhou, usando arquivo original', metadata: {
          'returnCode': returnCode.toString(),
          'originalPath': audioFile.path,
        });
        return audioFile;
      }

      final compressedFile = File(compressedPath);
      final compressedSize = await compressedFile.length();
      final reduction = ((1 - (compressedSize / originalSize)) * 100);

      Log.info('Áudio comprimido com sucesso', metadata: {
        'originalSize': originalSize,
        'compressedSize': compressedSize,
        'reduction': reduction.toStringAsFixed(1),
        'compressedPath': compressedPath,
      });

      await audioFile.delete();
      return compressedFile;
    } catch (e, stackTrace) {
      Log.error(
        'Erro ao comprimir áudio',
        error: e,
        stackTrace: stackTrace,
        metadata: {
          'originalPath': audioFile.path,
        },
      );
      return audioFile;
    }
  }
}
*/

// EXEMPLO 4: Offline Queue com logging
/*
import 'app_logger.dart';

class OfflineQueueService {
  Future<void> processQueue() async {
    if (_isProcessing) {
      Log.debug('Fila já está sendo processada');
      return;
    }

    final queueSize = _queue.length;

    Log.info('Iniciando processamento da fila offline', metadata: {
      'queueSize': queueSize,
    });

    _isProcessing = true;

    int successCount = 0;
    int failureCount = 0;

    for (final message in List.from(_queue)) {
      try {
        Log.debug('Processando mensagem da fila', metadata: {
          'messageId': message.id,
          'attempt': message.retryCount + 1,
          'maxRetries': _maxRetries,
        });

        final success = await _sendCallback(message);

        if (success) {
          _queue.remove(message);
          successCount++;

          Log.info('Mensagem enviada com sucesso', metadata: {
            'messageId': message.id,
            'totalAttempts': message.retryCount + 1,
          });
        } else {
          message.retryCount++;

          if (message.retryCount >= _maxRetries) {
            _queue.remove(message);
            failureCount++;

            Log.error('Mensagem descartada após max tentativas', metadata: {
              'messageId': message.id,
              'retryCount': message.retryCount,
            });
          } else {
            Log.warning('Falha ao enviar, tentará novamente', metadata: {
              'messageId': message.id,
              'currentAttempt': message.retryCount,
              'maxRetries': _maxRetries,
            });
          }
        }
      } catch (e, stackTrace) {
        Log.error(
          'Erro ao processar mensagem da fila',
          error: e,
          stackTrace: stackTrace,
          metadata: {
            'messageId': message.id,
          },
        );
      }
    }

    _isProcessing = false;
    await _saveQueue();

    Log.info('Processamento da fila concluído', metadata: {
      'initialSize': queueSize,
      'successCount': successCount,
      'failureCount': failureCount,
      'remainingInQueue': _queue.length,
    });
  }
}
*/

// EXEMPLO 5: Supabase Auth com logging
/*
import 'app_logger.dart';

class SupabaseService {
  static Future<void> signInWithEmail(String email, String password) async {
    Log.info('Tentando login', metadata: {
      'email': email,
      'method': 'email/password',
    });

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Log.info('Login bem-sucedido', metadata: {
          'userId': response.user!.id,
          'email': response.user!.email,
        });
      } else {
        Log.warning('Login retornou sem usuário');
      }
    } catch (e, stackTrace) {
      Log.error(
        'Falha no login',
        error: e,
        stackTrace: stackTrace,
        metadata: {
          'email': email,
        },
      );
      rethrow;
    }
  }

  static Future<void> signOut() async {
    final currentUser = currentUserId;

    Log.info('Fazendo logout', metadata: {
      'userId': currentUser,
    });

    try {
      await _supabase.auth.signOut();

      Log.info('Logout bem-sucedido', metadata: {
        'userId': currentUser,
      });
    } catch (e, stackTrace) {
      Log.error(
        'Erro ao fazer logout',
        error: e,
        stackTrace: stackTrace,
        metadata: {
          'userId': currentUser,
        },
      );
      rethrow;
    }
  }
}
*/

// EXEMPLO 6: Exportação de logs para debug
/*
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'app_logger.dart';

Future<void> exportLogsToFile() async {
  try {
    final logger = AppLogger();
    final logsText = logger.exportLogsAsText();

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/app_logs_${DateTime.now().millisecondsSinceEpoch}.txt');

    await file.writeAsString(logsText);

    Log.info('Logs exportados', metadata: {
      'path': file.path,
      'size': logsText.length,
    });

    print('✅ Logs salvos em: ${file.path}');
  } catch (e, stackTrace) {
    Log.error('Erro ao exportar logs', error: e, stackTrace: stackTrace);
  }
}

void showLogStatistics() {
  final logger = AppLogger();
  final stats = logger.getLogStatistics();

  Log.info('Estatísticas de logs', metadata: {
    'debug': stats[LogLevel.debug],
    'info': stats[LogLevel.info],
    'warning': stats[LogLevel.warning],
    'error': stats[LogLevel.error],
    'total': logger.getAllLogs().length,
  });
}
*/
