import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Serviço de gravação e gerenciamento de áudio
///
/// Responsável por gravar, processar e gerenciar arquivos de áudio
class AudioService {
  /// Instância do gravador de áudio
  static final AudioRecorder _recorder = AudioRecorder();

  /// Estado de gravação
  static bool _isRecording = false;

  /// Caminho do arquivo de áudio atual
  static String? _currentAudioPath;

  // ========== GRAVAÇÃO DE ÁUDIO ==========

  /// Getter para verificar se está gravando
  ///
  /// Retorna true se uma gravação está em andamento
  ///
  /// Exemplo de uso:
  /// ```dart
  /// if (AudioService.isRecording) {
  ///   print('Gravando...');
  /// }
  /// ```
  static bool get isRecording => _isRecording;

  /// Inicia a gravação de áudio
  ///
  /// Solicita permissão de microfone automaticamente
  ///
  /// Retorna true se a gravação foi iniciada com sucesso
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final started = await AudioService.startRecording();
  /// if (started) {
  ///   print('Gravação iniciada!');
  /// } else {
  ///   print('Erro ao iniciar gravação');
  /// }
  /// ```
  static Future<bool> startRecording() async {
    try {
      // Verifica se já está gravando
      if (_isRecording) {
        print('⚠️  Já existe uma gravação em andamento');
        return false;
      }

      // Solicita permissão de microfone
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception(
          'Permissão de microfone negada. Por favor, permita acesso ao microfone nas configurações.',
        );
      }

      // Obtém diretório temporário para salvar o áudio
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_$timestamp.m4a';
      _currentAudioPath = '${directory.path}/$fileName';

      // Configurações de gravação
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // AAC codec (boa qualidade e compressão)
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // 44.1 kHz (qualidade CD)
        numChannels: 1, // Mono (reduz tamanho)
      );

      // Inicia gravação
      await _recorder.start(
        config,
        path: _currentAudioPath!,
      );

      _isRecording = true;
      print('🎤 Gravação iniciada: $_currentAudioPath');

      return true;
    } catch (e) {
      _isRecording = false;
      _currentAudioPath = null;
      throw Exception('Erro ao iniciar gravação: $e');
    }
  }

  /// Para a gravação de áudio
  ///
  /// Retorna o arquivo de áudio gravado ou null se houver erro
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final audioFile = await AudioService.stopRecording();
  /// if (audioFile != null) {
  ///   print('Áudio salvo em: ${audioFile.path}');
  ///   print('Tamanho: ${await audioFile.length()} bytes');
  /// }
  /// ```
  static Future<File?> stopRecording() async {
    try {
      // Verifica se está gravando
      if (!_isRecording) {
        print('⚠️  Nenhuma gravação em andamento');
        return null;
      }

      // Para a gravação
      final path = await _recorder.stop();

      _isRecording = false;
      print('⏹️  Gravação parada: $path');

      // Verifica se o arquivo foi criado
      if (path == null || !await File(path).exists()) {
        throw Exception('Arquivo de áudio não foi criado');
      }

      final audioFile = File(path);
      final fileSize = await audioFile.length();
      print('📁 Tamanho do áudio: ${fileSize / 1024} KB');

      return audioFile;
    } catch (e) {
      _isRecording = false;
      _currentAudioPath = null;
      throw Exception('Erro ao parar gravação: $e');
    }
  }

  /// Cancela a gravação em andamento
  ///
  /// Remove o arquivo de áudio e limpa o estado
  ///
  /// Exemplo de uso:
  /// ```dart
  /// await AudioService.cancelRecording();
  /// print('Gravação cancelada');
  /// ```
  static Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        // Remove o arquivo criado
        if (_currentAudioPath != null) {
          final file = File(_currentAudioPath!);
          if (await file.exists()) {
            await file.delete();
            print('🗑️  Arquivo de áudio removido');
          }
        }

        _currentAudioPath = null;
        print('❌ Gravação cancelada');
      }
    } catch (e) {
      print('Erro ao cancelar gravação: $e');
    }
  }

  /// Pausa a gravação em andamento
  ///
  /// Nota: Nem todos os dispositivos suportam pausa
  ///
  /// Retorna true se pausado com sucesso
  static Future<bool> pauseRecording() async {
    try {
      if (!_isRecording) {
        print('⚠️  Nenhuma gravação em andamento');
        return false;
      }

      await _recorder.pause();
      print('⏸️  Gravação pausada');
      return true;
    } catch (e) {
      print('Erro ao pausar gravação: $e');
      return false;
    }
  }

  /// Resume a gravação pausada
  ///
  /// Retorna true se resumed com sucesso
  static Future<bool> resumeRecording() async {
    try {
      if (!_isRecording) {
        print('⚠️  Nenhuma gravação em andamento');
        return false;
      }

      await _recorder.resume();
      print('▶️  Gravação resumida');
      return true;
    } catch (e) {
      print('Erro ao resumir gravação: $e');
      return false;
    }
  }

  // ========== INFORMAÇÕES E VALIDAÇÕES ==========

  /// Obtém a duração da gravação atual
  ///
  /// Retorna Duration ou null se não estiver gravando
  static Future<Duration?> getRecordingDuration() async {
    try {
      // O pacote 'record' não fornece duração em tempo real
      // Você precisaria implementar um timer manual
      // Por enquanto, retorna null
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Valida se um arquivo de áudio é válido
  ///
  /// Verifica extensão e se o arquivo existe
  static Future<bool> isValidAudio(File file) async {
    try {
      // Verifica se o arquivo existe
      if (!await file.exists()) {
        return false;
      }

      // Verifica extensão
      final path = file.path.toLowerCase();
      final validExtensions = ['.m4a', '.aac', '.mp3', '.wav', '.ogg'];

      return validExtensions.any((ext) => path.endsWith(ext));
    } catch (e) {
      return false;
    }
  }

  /// Valida se o tamanho do áudio está dentro do limite
  ///
  /// [maxSizeInMB] - Tamanho máximo em megabytes (padrão: 5 MB)
  static Future<bool> isAudioSizeValid(
    File file, {
    int maxSizeInMB = 5,
  }) async {
    try {
      final bytes = await file.length();
      final maxBytes = maxSizeInMB * 1024 * 1024;

      return bytes <= maxBytes;
    } catch (e) {
      return false;
    }
  }

  /// Obtém o tamanho de um arquivo de áudio em bytes
  static Future<int> getAudioSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      throw Exception('Erro ao obter tamanho do áudio: $e');
    }
  }

  /// Obtém o tamanho de um arquivo de áudio formatado (KB, MB)
  static Future<String> getAudioSizeFormatted(File file) async {
    try {
      final bytes = await file.length();

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        final kb = bytes / 1024;
        return '${kb.toStringAsFixed(1)} KB';
      } else {
        final mb = bytes / (1024 * 1024);
        return '${mb.toStringAsFixed(1)} MB';
      }
    } catch (e) {
      throw Exception('Erro ao obter tamanho do áudio: $e');
    }
  }

  // ========== GERENCIAMENTO DE PERMISSÕES ==========

  /// Solicita permissão de acesso ao microfone
  ///
  /// Retorna true se permissão concedida, false caso contrário
  static Future<bool> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      print('Erro ao solicitar permissão de microfone: $e');
      return false;
    }
  }

  /// Verifica se tem permissão de microfone
  ///
  /// Retorna true se tem permissão, false caso contrário
  static Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o dispositivo tem microfone
  ///
  /// Retorna true se tem microfone disponível
  static Future<bool> hasAudioInput() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Abre as configurações do app para o usuário conceder permissões
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // ========== LIMPEZA ==========

  /// Libera recursos e limpa o estado
  ///
  /// Chame este método quando o serviço não for mais necessário
  static Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      await _recorder.dispose();
      print('🧹 AudioService limpo');
    } catch (e) {
      print('Erro ao limpar AudioService: $e');
    }
  }
}
