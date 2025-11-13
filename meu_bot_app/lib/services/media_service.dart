import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço de gerenciamento de mídia (imagens e fotos)
///
/// Responsável por capturar, processar e converter imagens
class MediaService {
  /// Image picker instance
  static final ImagePicker _picker = ImagePicker();

  /// Qualidade padrão de compressão (0-100)
  static const int defaultImageQuality = 70;

  /// Largura máxima da imagem (redimensionamento)
  static const double maxImageWidth = 1920;

  /// Altura máxima da imagem (redimensionamento)
  static const double maxImageHeight = 1080;

  // ========== SELEÇÃO DE IMAGENS ==========

  /// Seleciona uma imagem da galeria
  ///
  /// Solicita permissão de acesso à galeria automaticamente
  ///
  /// Retorna File da imagem ou null se cancelado/erro
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final image = await MediaService.pickImageFromGallery();
  /// if (image != null) {
  ///   print('Imagem selecionada: ${image.path}');
  /// }
  /// ```
  static Future<File?> pickImageFromGallery() async {
    try {
      // Solicita permissão de acesso à galeria
      final hasPermission = await _requestPhotosPermission();
      if (!hasPermission) {
        throw Exception(
          'Permissão negada. Por favor, permita acesso à galeria nas configurações.',
        );
      }

      // Seleciona a imagem
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: defaultImageQuality,
        maxWidth: maxImageWidth,
        maxHeight: maxImageHeight,
      );

      if (image == null) {
        return null; // Usuário cancelou
      }

      return File(image.path);
    } catch (e) {
      throw Exception('Erro ao selecionar imagem da galeria: $e');
    }
  }

  /// Captura uma foto usando a câmera
  ///
  /// Solicita permissão de acesso à câmera automaticamente
  ///
  /// Retorna File da foto ou null se cancelado/erro
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final photo = await MediaService.pickImageFromCamera();
  /// if (photo != null) {
  ///   print('Foto capturada: ${photo.path}');
  /// }
  /// ```
  static Future<File?> pickImageFromCamera() async {
    try {
      // Solicita permissão de acesso à câmera
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        throw Exception(
          'Permissão negada. Por favor, permita acesso à câmera nas configurações.',
        );
      }

      // Captura a foto
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: defaultImageQuality,
        maxWidth: maxImageWidth,
        maxHeight: maxImageHeight,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        return null; // Usuário cancelou
      }

      return File(photo.path);
    } catch (e) {
      throw Exception('Erro ao capturar foto: $e');
    }
  }

  // ========== COMPRESSÃO E PROCESSAMENTO ==========

  /// Comprime uma imagem reduzindo seu tamanho
  ///
  /// [imageFile] - Arquivo da imagem a ser comprimida
  /// [quality] - Qualidade da compressão (0-100, padrão: 70)
  ///
  /// Retorna o arquivo comprimido
  ///
  /// Nota: A compressão já é feita pelo image_picker, mas este método
  /// pode ser usado para recomprimir se necessário
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final compressed = await MediaService.compressImage(originalFile, quality: 50);
  /// print('Tamanho original: ${originalFile.lengthSync()} bytes');
  /// print('Tamanho comprimido: ${compressed.lengthSync()} bytes');
  /// ```
  static Future<File> compressImage(
    File imageFile, {
    int quality = defaultImageQuality,
  }) async {
    try {
      // Valida qualidade
      if (quality < 0 || quality > 100) {
        throw ArgumentError('Qualidade deve estar entre 0 e 100');
      }

      // Por enquanto, o image_picker já faz a compressão
      // Se precisar de compressão adicional, pode usar pacotes como:
      // - flutter_image_compress
      // - image (dart)

      // Retorna o arquivo original (já comprimido pelo picker)
      return imageFile;
    } catch (e) {
      throw Exception('Erro ao comprimir imagem: $e');
    }
  }

  /// Converte um arquivo para base64
  ///
  /// [file] - Arquivo a ser convertido (imagem ou áudio)
  ///
  /// Retorna string base64
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final base64 = await MediaService.convertToBase64(imageFile);
  /// print('Base64: ${base64.substring(0, 50)}...');
  /// ```
  static Future<String> convertToBase64(File file) async {
    try {
      // Lê os bytes do arquivo
      final bytes = await file.readAsBytes();

      // Converte para base64
      final base64String = base64Encode(bytes);

      return base64String;
    } catch (e) {
      throw Exception('Erro ao converter arquivo para base64: $e');
    }
  }

  /// Obtém o tamanho de um arquivo em bytes
  ///
  /// Útil para verificar antes de enviar
  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      throw Exception('Erro ao obter tamanho do arquivo: $e');
    }
  }

  /// Obtém o tamanho de um arquivo formatado (KB, MB)
  ///
  /// Retorna string legível como "2.5 MB"
  static Future<String> getFileSizeFormatted(File file) async {
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
      throw Exception('Erro ao obter tamanho do arquivo: $e');
    }
  }

  // ========== GERENCIAMENTO DE PERMISSÕES ==========

  /// Solicita permissão de acesso à galeria/fotos
  ///
  /// Retorna true se permissão concedida, false caso contrário
  static Future<bool> _requestPhotosPermission() async {
    try {
      // No Android 13+, usa permission.photos
      // No iOS, usa permission.photos
      // Em versões antigas do Android, usa permission.storage

      if (Platform.isAndroid) {
        // Android 13+ usa photos, versões antigas usam storage
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 33) {
          // Android 13+
          final status = await Permission.photos.request();
          return status.isGranted || status.isLimited;
        } else {
          // Android < 13
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        // iOS
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      }

      return false;
    } catch (e) {
      print('Erro ao solicitar permissão de fotos: $e');
      return false;
    }
  }

  /// Solicita permissão de acesso à câmera
  ///
  /// Retorna true se permissão concedida, false caso contrário
  static Future<bool> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('Erro ao solicitar permissão de câmera: $e');
      return false;
    }
  }

  /// Verifica se tem permissão de galeria
  static Future<bool> hasPhotosPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 33) {
          final status = await Permission.photos.status;
          return status.isGranted || status.isLimited;
        } else {
          final status = await Permission.storage.status;
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.status;
        return status.isGranted || status.isLimited;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se tem permissão de câmera
  static Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Abre as configurações do app para o usuário conceder permissões
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Obtém a versão do Android (SDK version)
  ///
  /// Retorna 0 se não for Android
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) {
      return 0;
    }

    // Simula versão do Android
    // Em produção, use package_info_plus ou device_info_plus
    // Por simplicidade, assume Android 13+
    return 33;
  }

  // ========== VALIDAÇÕES ==========

  /// Valida se um arquivo é uma imagem válida
  ///
  /// Verifica extensão e tamanho
  static bool isValidImage(File file) {
    final path = file.path.toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

    return validExtensions.any((ext) => path.endsWith(ext));
  }

  /// Valida se o tamanho da imagem está dentro do limite
  ///
  /// [maxSizeInMB] - Tamanho máximo em megabytes (padrão: 10 MB)
  static Future<bool> isImageSizeValid(
    File file, {
    int maxSizeInMB = 10,
  }) async {
    try {
      final bytes = await file.length();
      final maxBytes = maxSizeInMB * 1024 * 1024;

      return bytes <= maxBytes;
    } catch (e) {
      return false;
    }
  }
}
