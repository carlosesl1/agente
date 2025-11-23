import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/design_system.dart';

/// Widget de mensagem com suporte a Markdown
///
/// Renderiza texto com formatação Markdown e permite copiar/compartilhar
class MarkdownMessageWidget extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool isUserMessage;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const MarkdownMessageWidget({
    super.key,
    required this.text,
    required this.isDark,
    this.isUserMessage = false,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: _buildMarkdownStyleSheet(),
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchUrl(href);
          }
        },
      ),
    );
  }

  /// Mostra opções de mensagem (copiar, compartilhar)
  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppDesignSystem.darkSecondaryBackground
          : AppDesignSystem.lightGroupedSecondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignSystem.cornerRadius20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: AppDesignSystem.spacing12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppDesignSystem.darkFillTertiary
                    : AppDesignSystem.lightFillTertiary,
                borderRadius:
                    BorderRadius.circular(AppDesignSystem.cornerRadius2),
              ),
            ),
            SizedBox(height: AppDesignSystem.spacing20),

            // Copiar
            ListTile(
              leading: Icon(
                Icons.copy,
                color: isDark
                    ? AppDesignSystem.systemBlueDark
                    : AppDesignSystem.systemBlue,
              ),
              title: Text(
                'Copiar',
                style: AppDesignSystem.body.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
              ),
              onTap: () {
                _copyToClipboard(context);
                Navigator.pop(context);
              },
            ),

            // Compartilhar
            ListTile(
              leading: Icon(
                Icons.share,
                color: isDark
                    ? AppDesignSystem.systemBlueDark
                    : AppDesignSystem.systemBlue,
              ),
              title: Text(
                'Compartilhar',
                style: AppDesignSystem.body.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
              ),
              onTap: () {
                _shareMessage();
                Navigator.pop(context);
              },
            ),

            SizedBox(height: AppDesignSystem.spacing16),
          ],
        ),
      ),
    );
  }

  /// Copia texto para clipboard
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: AppDesignSystem.spacing8),
            const Text('Texto copiado!'),
          ],
        ),
        backgroundColor: AppDesignSystem.systemGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    onCopy?.call();
  }

  /// Compartilha mensagem
  Future<void> _shareMessage() async {
    try {
      await Share.share(
        text,
        subject: 'Mensagem do Chat',
      );
      onShare?.call();
    } catch (e) {
      print('Erro ao compartilhar: $e');
    }
  }

  /// Abre URL
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('Erro ao abrir URL: $e');
    }
  }

  /// Constrói o estilo do Markdown
  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    final baseColor = isDark
        ? AppDesignSystem.darkPrimaryLabel
        : AppDesignSystem.lightPrimaryLabel;

    final codeBackground = isDark
        ? AppDesignSystem.darkFillTertiary
        : AppDesignSystem.lightFillTertiary;

    return MarkdownStyleSheet(
      // Parágrafos
      p: AppDesignSystem.body.copyWith(color: baseColor),

      // Headings
      h1: AppDesignSystem.largeTitle.copyWith(color: baseColor),
      h2: AppDesignSystem.title1.copyWith(color: baseColor),
      h3: AppDesignSystem.title2.copyWith(color: baseColor),
      h4: AppDesignSystem.title3.copyWith(color: baseColor),
      h5: AppDesignSystem.headline.copyWith(color: baseColor),
      h6: AppDesignSystem.subheadline.copyWith(color: baseColor),

      // Links
      a: AppDesignSystem.body.copyWith(
        color: isDark
            ? AppDesignSystem.systemBlueDark
            : AppDesignSystem.systemBlue,
        decoration: TextDecoration.underline,
      ),

      // Código inline
      code: AppDesignSystem.bodyMonospaced.copyWith(
        backgroundColor: codeBackground,
        color: isDark
            ? AppDesignSystem.systemOrange
            : AppDesignSystem.systemOrange,
      ),

      // Blocos de código
      codeblockDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius8),
        border: Border.all(
          color: isDark
              ? AppDesignSystem.darkSeparator
              : AppDesignSystem.lightSeparator,
          width: 0.5,
        ),
      ),
      codeblockPadding: EdgeInsets.all(AppDesignSystem.spacing12),

      // Blocos de citação
      blockquoteDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius8),
        border: Border(
          left: BorderSide(
            color: isDark
                ? AppDesignSystem.systemBlueDark
                : AppDesignSystem.systemBlue,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: EdgeInsets.all(AppDesignSystem.spacing12),

      // Listas
      listBullet: AppDesignSystem.body.copyWith(color: baseColor),

      // Espaçamento
      blockSpacing: AppDesignSystem.spacing12,
      listIndent: AppDesignSystem.spacing20,

      // Tabelas
      tableHead: AppDesignSystem.headline.copyWith(color: baseColor),
      tableBody: AppDesignSystem.body.copyWith(color: baseColor),
      tableBorder: TableBorder.all(
        color: isDark
            ? AppDesignSystem.darkSeparator
            : AppDesignSystem.lightSeparator,
        width: 0.5,
      ),
      tableCellsPadding: EdgeInsets.all(AppDesignSystem.spacing8),

      // Negrito e itálico
      strong: AppDesignSystem.body.copyWith(
        color: baseColor,
        fontWeight: FontWeight.bold,
      ),
      em: AppDesignSystem.body.copyWith(
        color: baseColor,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

/// Widget simplificado para mensagens de texto com ações rápidas
class MessageWithActions extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool isUserMessage;
  final bool enableMarkdown;

  const MessageWithActions({
    super.key,
    required this.text,
    required this.isDark,
    this.isUserMessage = false,
    this.enableMarkdown = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto da mensagem
        if (enableMarkdown)
          MarkdownMessageWidget(
            text: text,
            isDark: isDark,
            isUserMessage: isUserMessage,
          )
        else
          SelectableText(
            text,
            style: AppDesignSystem.body.copyWith(
              color: isDark
                  ? AppDesignSystem.darkPrimaryLabel
                  : AppDesignSystem.lightPrimaryLabel,
            ),
          ),
      ],
    );
  }
}
