import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/link_preview_service.dart';
import '../theme/design_system.dart';

/// Widget de preview de link
///
/// Exibe preview com imagem, título e descrição
class LinkPreviewWidget extends StatefulWidget {
  final String url;
  final bool isDark;

  const LinkPreviewWidget({
    super.key,
    required this.url,
    required this.isDark,
  });

  @override
  State<LinkPreviewWidget> createState() => _LinkPreviewWidgetState();
}

class _LinkPreviewWidgetState extends State<LinkPreviewWidget> {
  LinkPreview? _preview;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await LinkPreviewService.getPreview(widget.url);

      if (mounted) {
        setState(() {
          _preview = preview;
          _isLoading = false;
          _hasError = preview == null || !preview.hasData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _openUrl() async {
    try {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Erro ao abrir URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError || _preview == null || !_preview!.hasData) {
      return _buildSimpleLinkCard();
    }

    return _buildPreviewCard();
  }

  /// Card de loading
  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppDesignSystem.spacing8),
      padding: EdgeInsets.all(AppDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppDesignSystem.darkFillTertiary
            : AppDesignSystem.lightFillTertiary,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isDark
                    ? AppDesignSystem.darkSecondaryLabel
                    : AppDesignSystem.lightSecondaryLabel,
              ),
            ),
          ),
          SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Text(
              'Carregando preview...',
              style: AppDesignSystem.caption1.copyWith(
                color: widget.isDark
                    ? AppDesignSystem.darkSecondaryLabel
                    : AppDesignSystem.lightSecondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card simples (sem metadados)
  Widget _buildSimpleLinkCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openUrl,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: AppDesignSystem.spacing8),
          padding: EdgeInsets.all(AppDesignSystem.spacing12),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppDesignSystem.darkFillTertiary
                : AppDesignSystem.lightFillTertiary,
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
            border: Border.all(
              color: widget.isDark
                  ? AppDesignSystem.darkSeparator
                  : AppDesignSystem.lightSeparator,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.link,
                size: 20,
                color: widget.isDark
                    ? AppDesignSystem.systemBlueDark
                    : AppDesignSystem.systemBlue,
              ),
              SizedBox(width: AppDesignSystem.spacing12),
              Expanded(
                child: Text(
                  widget.url,
                  style: AppDesignSystem.caption1.copyWith(
                    color: widget.isDark
                        ? AppDesignSystem.systemBlueDark
                        : AppDesignSystem.systemBlue,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 16,
                color: widget.isDark
                    ? AppDesignSystem.darkSecondaryLabel
                    : AppDesignSystem.lightSecondaryLabel,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  /// Card com preview completo
  Widget _buildPreviewCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openUrl,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: AppDesignSystem.spacing8),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppDesignSystem.darkSecondaryBackground
                : AppDesignSystem.lightGroupedSecondaryBackground,
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
            border: Border.all(
              color: widget.isDark
                  ? AppDesignSystem.darkSeparator
                  : AppDesignSystem.lightSeparator,
              width: 0.5,
            ),
            boxShadow: AppDesignSystem.shadowLevel1(widget.isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem (se disponível)
              if (_preview!.imageUrl != null) _buildPreviewImage(),

              // Conteúdo
              Padding(
                padding: EdgeInsets.all(AppDesignSystem.spacing12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    if (_preview!.title != null)
                      Text(
                        _preview!.title!,
                        style: AppDesignSystem.headline.copyWith(
                          color: widget.isDark
                              ? AppDesignSystem.darkPrimaryLabel
                              : AppDesignSystem.lightPrimaryLabel,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Descrição
                    if (_preview!.description != null) ...[
                      SizedBox(height: AppDesignSystem.spacing8),
                      Text(
                        _preview!.description!,
                        style: AppDesignSystem.caption1.copyWith(
                          color: widget.isDark
                              ? AppDesignSystem.darkSecondaryLabel
                              : AppDesignSystem.lightSecondaryLabel,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Site name e URL
                    SizedBox(height: AppDesignSystem.spacing8),
                    Row(
                      children: [
                        Icon(
                          Icons.link,
                          size: 14,
                          color: widget.isDark
                              ? AppDesignSystem.darkTertiaryLabel
                              : AppDesignSystem.lightTertiaryLabel,
                        ),
                        SizedBox(width: AppDesignSystem.spacing4),
                        Expanded(
                          child: Text(
                            _preview!.siteName ?? widget.url,
                            style: AppDesignSystem.caption2.copyWith(
                              color: widget.isDark
                                  ? AppDesignSystem.darkTertiaryLabel
                                  : AppDesignSystem.lightTertiaryLabel,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  /// Imagem do preview
  Widget _buildPreviewImage() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDesignSystem.cornerRadius12),
      ),
      child: AspectRatio(
        aspectRatio: 2.0,
        child: CachedNetworkImage(
          imageUrl: _preview!.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: widget.isDark
                ? AppDesignSystem.darkFillTertiary
                : AppDesignSystem.lightFillTertiary,
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isDark
                        ? AppDesignSystem.darkSecondaryLabel
                        : AppDesignSystem.lightSecondaryLabel,
                  ),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: widget.isDark
                ? AppDesignSystem.darkFillTertiary
                : AppDesignSystem.lightFillTertiary,
            child: Icon(
              Icons.broken_image,
              color: widget.isDark
                  ? AppDesignSystem.darkSecondaryLabel
                  : AppDesignSystem.lightSecondaryLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget que detecta e exibe previews de URLs em um texto
class TextWithLinkPreviews extends StatelessWidget {
  final String text;
  final bool isDark;

  const TextWithLinkPreviews({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final urls = LinkPreviewService.detectUrls(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto
        Text(
          text,
          style: AppDesignSystem.body.copyWith(
            color: isDark
                ? AppDesignSystem.darkPrimaryLabel
                : AppDesignSystem.lightPrimaryLabel,
          ),
        ),

        // Previews de links
        if (urls.isNotEmpty) ...[
          SizedBox(height: AppDesignSystem.spacing12),
          ...urls.map((url) => LinkPreviewWidget(
                url: url,
                isDark: isDark,
              )),
        ],
      ],
    );
  }
}
