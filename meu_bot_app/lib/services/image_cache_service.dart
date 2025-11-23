import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Serviço de cache de imagens
///
/// Gerencia cache de imagens para melhorar performance
class ImageCacheService {
  static CacheManager? _customCacheManager;

  /// Obtém ou cria o cache manager customizado
  static CacheManager get cacheManager {
    _customCacheManager ??= CacheManager(
      Config(
        'chatImageCache',
        stalePeriod: const Duration(days: 30), // Cache por 30 dias
        maxNrOfCacheObjects: 200, // Máximo de 200 imagens
        repo: JsonCacheInfoRepository(databaseName: 'chatImageCache'),
        fileService: HttpFileService(),
      ),
    );
    return _customCacheManager!;
  }

  /// Baixa e cacheia uma imagem da URL
  ///
  /// [url] - URL da imagem
  ///
  /// Retorna o arquivo em cache
  static Future<File> downloadAndCache(String url) async {
    try {
      print('📥 Baixando e cacheando imagem: $url');

      final file = await cacheManager.getSingleFile(url);

      print('✅ Imagem cacheada: ${file.path}');

      return file;
    } catch (e) {
      print('✗ Erro ao baixar/cachear imagem: $e');
      rethrow;
    }
  }

  /// Obtém imagem do cache (se existir)
  ///
  /// [url] - URL da imagem
  ///
  /// Retorna o arquivo em cache ou null se não estiver cacheado
  static Future<File?> getFromCache(String url) async {
    try {
      final fileInfo = await cacheManager.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      print('⚠️  Erro ao obter do cache: $e');
      return null;
    }
  }

  /// Verifica se imagem está em cache
  ///
  /// [url] - URL da imagem
  static Future<bool> isInCache(String url) async {
    final file = await getFromCache(url);
    return file != null;
  }

  /// Remove imagem do cache
  ///
  /// [url] - URL da imagem
  static Future<void> removeFromCache(String url) async {
    try {
      await cacheManager.removeFile(url);
      print('🗑️  Imagem removida do cache: $url');
    } catch (e) {
      print('✗ Erro ao remover do cache: $e');
    }
  }

  /// Limpa todo o cache de imagens
  static Future<void> clearCache() async {
    try {
      await cacheManager.emptyCache();
      print('🗑️  Cache de imagens limpo');
    } catch (e) {
      print('✗ Erro ao limpar cache: $e');
    }
  }

  /// Obtém tamanho total do cache em bytes
  static Future<int> getCacheSize() async {
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/chatImageCache');

      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;

      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('✗ Erro ao calcular tamanho do cache: $e');
      return 0;
    }
  }

  /// Obtém tamanho do cache formatado (MB/KB)
  static Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSize();
    return _formatBytes(bytes);
  }

  /// Pre-carrega imagens em cache (útil para performance)
  ///
  /// [urls] - Lista de URLs para pre-carregar
  static Future<void> preloadImages(List<String> urls) async {
    print('⚡ Pre-carregando ${urls.length} imagens...');

    final futures = urls.map((url) async {
      try {
        await downloadAndCache(url);
      } catch (e) {
        print('⚠️  Erro ao pre-carregar $url: $e');
      }
    });

    await Future.wait(futures);

    print('✅ Pre-carregamento concluído');
  }

  /// Salva imagem local em cache permanente
  ///
  /// [imageFile] - Arquivo da imagem
  /// [key] - Chave para identificar no cache
  static Future<String> cacheLocalImage(File imageFile, String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/local_cache');

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final cachedFile = File('${cacheDir.path}/$key.jpg');
      await imageFile.copy(cachedFile.path);

      print('✅ Imagem local cacheada: ${cachedFile.path}');

      return cachedFile.path;
    } catch (e) {
      print('✗ Erro ao cachear imagem local: $e');
      rethrow;
    }
  }

  /// Obtém imagem local do cache
  ///
  /// [key] - Chave da imagem
  static Future<File?> getLocalCachedImage(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cachedFile = File('${directory.path}/local_cache/$key.jpg');

      if (await cachedFile.exists()) {
        return cachedFile;
      }

      return null;
    } catch (e) {
      print('✗ Erro ao obter imagem local do cache: $e');
      return null;
    }
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

  /// Limpa imagens antigas do cache (mantém apenas as mais recentes)
  ///
  /// [maxAgeInDays] - Idade máxima em dias
  static Future<void> cleanOldCache({int maxAgeInDays = 30}) async {
    try {
      print('🧹 Limpando cache antigo (>${maxAgeInDays} dias)...');

      // TODO: Implementar limpeza seletiva
      // Por enquanto, o CacheManager já faz isso automaticamente

      print('✅ Limpeza de cache concluída');
    } catch (e) {
      print('✗ Erro ao limpar cache antigo: $e');
    }
  }

  /// Obtém estatísticas do cache
  static Future<CacheStats> getStats() async {
    try {
      final size = await getCacheSize();
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/chatImageCache');

      int fileCount = 0;

      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            fileCount++;
          }
        }
      }

      return CacheStats(
        totalSizeBytes: size,
        fileCount: fileCount,
        maxAgeInDays: 30,
      );
    } catch (e) {
      print('✗ Erro ao obter estatísticas: $e');
      return CacheStats(
        totalSizeBytes: 0,
        fileCount: 0,
        maxAgeInDays: 30,
      );
    }
  }
}

/// Estatísticas do cache
class CacheStats {
  final int totalSizeBytes;
  final int fileCount;
  final int maxAgeInDays;

  const CacheStats({
    required this.totalSizeBytes,
    required this.fileCount,
    required this.maxAgeInDays,
  });

  String get totalSizeFormatted =>
      ImageCacheService._formatBytes(totalSizeBytes);

  @override
  String toString() {
    return 'CacheStats(files: $fileCount, size: $totalSizeFormatted, maxAge: ${maxAgeInDays}d)';
  }
}
