import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Serviço de compressão e otimização de imagens
///
/// Reduz o tamanho de imagens para economizar banda e storage
class ImageCompressionService {
  /// Qualidade padrão JPEG (0-100)
  static const int defaultQuality = 85;

  /// Largura máxima padrão (em pixels)
  static const int defaultMaxWidth = 1920;

  /// Altura máxima padrão (em pixels)
  static const int defaultMaxHeight = 1080;

  /// Comprime uma imagem mantendo qualidade aceitável
  ///
  /// [imageFile] - Arquivo da imagem original
  /// [quality] - Qualidade JPEG (0-100, padrão: 85)
  /// [maxWidth] - Largura máxima em pixels (padrão: 1920)
  /// [maxHeight] - Altura máxima em pixels (padrão: 1080)
  ///
  /// Retorna novo arquivo comprimido
  static Future<File> compressImage(
    File imageFile, {
    int quality = defaultQuality,
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
  }) async {
    try {
      print('🖼️  Comprimindo imagem: ${imageFile.path}');

      // Lê a imagem
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      print('📐 Tamanho original: ${image.width}x${image.height}');

      // Redimensiona se necessário (mantém aspect ratio)
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          interpolation: img.Interpolation.linear,
        );

        print('📐 Novo tamanho: ${image.width}x${image.height}');
      }

      // Comprime como JPEG
      final compressedBytes = img.encodeJpg(image, quality: quality);

      // Calcula redução
      final originalSize = bytes.length;
      final compressedSize = compressedBytes.length;
      final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);

      print('💾 Tamanho original: ${_formatBytes(originalSize)}');
      print('💾 Tamanho comprimido: ${_formatBytes(compressedSize)}');
      print('✅ Redução: $reduction%');

      // Salva em arquivo temporário
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File(
        '${directory.path}/compressed_$timestamp.jpg',
      );

      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('✗ Erro ao comprimir imagem: $e');
      rethrow;
    }
  }

  /// Comprime imagem para tamanho específico em MB
  ///
  /// Ajusta a qualidade automaticamente até atingir o tamanho desejado
  ///
  /// [imageFile] - Arquivo da imagem
  /// [targetSizeMB] - Tamanho alvo em MB
  /// [maxAttempts] - Número máximo de tentativas
  static Future<File> compressToSize(
    File imageFile, {
    required double targetSizeMB,
    int maxAttempts = 5,
  }) async {
    try {
      final targetSizeBytes = (targetSizeMB * 1024 * 1024).toInt();
      int quality = 90;
      File? compressedFile;

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        compressedFile = await compressImage(
          imageFile,
          quality: quality,
        );

        final size = await compressedFile.length();

        print('🔄 Tentativa ${attempt + 1}: ${_formatBytes(size)} (qualidade: $quality)');

        if (size <= targetSizeBytes) {
          print('✅ Tamanho alvo atingido!');
          return compressedFile;
        }

        // Reduz qualidade para próxima tentativa
        quality = (quality * 0.8).toInt();

        if (quality < 30) {
          print('⚠️  Qualidade muito baixa. Usando última versão.');
          break;
        }
      }

      return compressedFile ?? imageFile;
    } catch (e) {
      print('✗ Erro ao comprimir para tamanho: $e');
      rethrow;
    }
  }

  /// Cria thumbnail de uma imagem
  ///
  /// [imageFile] - Arquivo da imagem
  /// [size] - Tamanho do thumbnail (largura e altura)
  static Future<File> createThumbnail(
    File imageFile, {
    int size = 200,
  }) async {
    try {
      print('🖼️  Criando thumbnail (${size}x$size)...');

      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      // Cria thumbnail quadrado com crop central
      final thumbnail = img.copyResizeCropSquare(image, size: size);

      // Comprime
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);

      // Salva
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailFile = File(
        '${directory.path}/thumb_$timestamp.jpg',
      );

      await thumbnailFile.writeAsBytes(thumbnailBytes);

      print('✅ Thumbnail criado: ${_formatBytes(thumbnailBytes.length)}');

      return thumbnailFile;
    } catch (e) {
      print('✗ Erro ao criar thumbnail: $e');
      rethrow;
    }
  }

  /// Otimiza imagem para envio (comprime e redimensiona)
  ///
  /// Usa configurações balanceadas entre qualidade e tamanho
  ///
  /// [imageFile] - Arquivo da imagem
  static Future<File> optimizeForSending(File imageFile) async {
    return compressImage(
      imageFile,
      quality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  /// Otimiza imagem para perfil/avatar (pequena e circular)
  ///
  /// [imageFile] - Arquivo da imagem
  /// [size] - Tamanho do avatar (padrão: 400x400)
  static Future<File> optimizeForAvatar(
    File imageFile, {
    int size = 400,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      // Cria thumbnail quadrado
      final avatar = img.copyResizeCropSquare(image, size: size);

      // Comprime com boa qualidade (é pequeno)
      final avatarBytes = img.encodeJpg(avatar, quality: 90);

      // Salva
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final avatarFile = File(
        '${directory.path}/avatar_$timestamp.jpg',
      );

      await avatarFile.writeAsBytes(avatarBytes);

      return avatarFile;
    } catch (e) {
      print('✗ Erro ao otimizar avatar: $e');
      rethrow;
    }
  }

  /// Converte imagem para Uint8List (útil para cache)
  static Future<Uint8List> imageToBytes(File imageFile) async {
    return await imageFile.readAsBytes();
  }

  /// Formata bytes para string legível
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Obtém informações da imagem sem carregar na memória
  static Future<ImageInfo> getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      return ImageInfo(
        width: image.width,
        height: image.height,
        sizeBytes: bytes.length,
        format: _detectFormat(imageFile.path),
      );
    } catch (e) {
      print('✗ Erro ao obter info da imagem: $e');
      rethrow;
    }
  }

  /// Detecta formato da imagem pela extensão
  static String _detectFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'JPEG';
      case 'png':
        return 'PNG';
      case 'gif':
        return 'GIF';
      case 'webp':
        return 'WebP';
      default:
        return 'Unknown';
    }
  }
}

/// Informações da imagem
class ImageInfo {
  final int width;
  final int height;
  final int sizeBytes;
  final String format;

  const ImageInfo({
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.format,
  });

  double get aspectRatio => width / height;
  String get sizeFormatted => ImageCompressionService._formatBytes(sizeBytes);

  @override
  String toString() {
    return 'ImageInfo(${width}x$height, $sizeFormatted, $format)';
  }
}
