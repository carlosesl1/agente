import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

/// Serviço de preview de links
///
/// Extrai metadados de URLs (título, descrição, imagem)
class LinkPreviewService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (compatible; ChatBot/1.0; +http://example.com/bot)',
      },
    ),
  );

  /// Cache de previews
  static final Map<String, LinkPreview?> _cache = {};

  /// Extrai preview de uma URL
  ///
  /// Retorna LinkPreview ou null se falhar
  static Future<LinkPreview?> getPreview(String url) async {
    // Verifica cache
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      print('🔗 Buscando preview de: $url');

      final response = await _dio.get(url);

      if (response.statusCode != 200) {
        _cache[url] = null;
        return null;
      }

      final html = response.data as String;
      final document = html_parser.parse(html);

      // Extrai metadados Open Graph ou fallback para tags HTML padrão
      String? title = _extractMetaTag(document, 'og:title') ??
          _extractMetaTag(document, 'twitter:title') ??
          document.querySelector('title')?.text;

      String? description = _extractMetaTag(document, 'og:description') ??
          _extractMetaTag(document, 'twitter:description') ??
          _extractMetaTag(document, 'description');

      String? imageUrl = _extractMetaTag(document, 'og:image') ??
          _extractMetaTag(document, 'twitter:image');

      String? siteName =
          _extractMetaTag(document, 'og:site_name') ?? _extractDomain(url);

      final preview = LinkPreview(
        url: url,
        title: title?.trim(),
        description: description?.trim(),
        imageUrl: imageUrl?.trim(),
        siteName: siteName?.trim(),
      );

      _cache[url] = preview;

      print('✓ Preview extraído: ${preview.title}');

      return preview;
    } catch (e) {
      print('✗ Erro ao buscar preview: $e');
      _cache[url] = null;
      return null;
    }
  }

  /// Extrai meta tag do documento HTML
  static String? _extractMetaTag(dynamic document, String property) {
    // Tenta property primeiro (Open Graph)
    var meta = document.querySelector('meta[property="$property"]');
    if (meta != null) {
      return meta.attributes['content'];
    }

    // Tenta name (Twitter Cards e tags padrão)
    meta = document.querySelector('meta[name="$property"]');
    if (meta != null) {
      return meta.attributes['content'];
    }

    return null;
  }

  /// Extrai domínio da URL
  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      return url;
    }
  }

  /// Detecta URLs em um texto
  ///
  /// Retorna lista de URLs encontradas
  static List<String> detectUrls(String text) {
    final urlRegex = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  /// Limpa cache de previews
  static void clearCache() {
    _cache.clear();
    print('🗑️  Cache de previews limpo');
  }

  /// Pré-carrega previews de múltiplas URLs
  static Future<void> preloadPreviews(List<String> urls) async {
    final futures = urls.map((url) => getPreview(url));
    await Future.wait(futures);
    print('✓ ${urls.length} previews pré-carregados');
  }
}

/// Modelo de preview de link
class LinkPreview {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  const LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  /// Verifica se tem dados suficientes para exibir
  bool get hasData => title != null || description != null || imageUrl != null;

  @override
  String toString() {
    return 'LinkPreview(url: $url, title: $title, siteName: $siteName)';
  }
}
