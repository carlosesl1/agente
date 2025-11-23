import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/design_system.dart';

/// Indicador de status de mensagem
///
/// Exibe ícones e animações representando o estado da mensagem
class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final bool isDark;
  final double size;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    required this.isDark,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return _buildStatusIcon();
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case MessageStatus.sending:
        return _buildSendingIcon();

      case MessageStatus.sent:
        return _buildSentIcon();

      case MessageStatus.delivered:
        return _buildDeliveredIcon();

      case MessageStatus.error:
        return _buildErrorIcon();

      case MessageStatus.queued:
        return _buildQueuedIcon();
    }
  }

  /// Ícone de enviando (círculo animado)
  Widget _buildSendingIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          isDark
              ? AppDesignSystem.darkSecondaryLabel
              : AppDesignSystem.lightSecondaryLabel,
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).rotate(
          duration: 1000.ms,
        );
  }

  /// Ícone de enviado (check único)
  Widget _buildSentIcon() {
    return Icon(
      Icons.check,
      size: size,
      color: isDark
          ? AppDesignSystem.darkSecondaryLabel
          : AppDesignSystem.lightSecondaryLabel,
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.5, 0.5),
          curve: Curves.easeOut,
        );
  }

  /// Ícone de entregue (check duplo)
  Widget _buildDeliveredIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check,
          size: size * 0.8,
          color: isDark
              ? AppDesignSystem.systemBlueDark
              : AppDesignSystem.systemBlue,
        ),
        Transform.translate(
          offset: Offset(-size * 0.4, 0),
          child: Icon(
            Icons.check,
            size: size * 0.8,
            color: isDark
                ? AppDesignSystem.systemBlueDark
                : AppDesignSystem.systemBlue,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOut);
  }

  /// Ícone de erro (X vermelho)
  Widget _buildErrorIcon() {
    return Icon(
      Icons.error_outline,
      size: size,
      color: AppDesignSystem.systemRed,
    ).animate().fadeIn(duration: 300.ms).shake();
  }

  /// Ícone de na fila offline (relógio)
  Widget _buildQueuedIcon() {
    return Icon(
      Icons.schedule,
      size: size,
      color: isDark
          ? AppDesignSystem.systemOrange.withOpacity(0.8)
          : AppDesignSystem.systemOrange,
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 300.ms)
        .then()
        .shimmer(duration: 2000.ms);
  }
}

/// Status possíveis de uma mensagem
enum MessageStatus {
  /// Mensagem sendo enviada
  sending,

  /// Mensagem enviada ao servidor
  sent,

  /// Mensagem entregue ao destinatário
  delivered,

  /// Erro ao enviar mensagem
  error,

  /// Mensagem na fila offline (aguardando conexão)
  queued,
}

/// Widget de status de mensagem com texto descritivo
class MessageStatusText extends StatelessWidget {
  final MessageStatus status;
  final bool isDark;
  final String? errorMessage;

  const MessageStatusText({
    super.key,
    required this.status,
    required this.isDark,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MessageStatusIndicator(
          status: status,
          isDark: isDark,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          _getStatusText(),
          style: AppDesignSystem.caption2.copyWith(
            color: _getStatusColor(),
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    switch (status) {
      case MessageStatus.sending:
        return 'Enviando...';
      case MessageStatus.sent:
        return 'Enviado';
      case MessageStatus.delivered:
        return 'Entregue';
      case MessageStatus.error:
        return errorMessage ?? 'Erro ao enviar';
      case MessageStatus.queued:
        return 'Na fila';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case MessageStatus.sending:
        return isDark
            ? AppDesignSystem.darkSecondaryLabel
            : AppDesignSystem.lightSecondaryLabel;

      case MessageStatus.sent:
        return isDark
            ? AppDesignSystem.darkSecondaryLabel
            : AppDesignSystem.lightSecondaryLabel;

      case MessageStatus.delivered:
        return isDark
            ? AppDesignSystem.systemBlueDark
            : AppDesignSystem.systemBlue;

      case MessageStatus.error:
        return AppDesignSystem.systemRed;

      case MessageStatus.queued:
        return isDark
            ? AppDesignSystem.systemOrange.withOpacity(0.8)
            : AppDesignSystem.systemOrange;
    }
  }
}

/// Badge de contagem de mensagens na fila
class QueuedMessagesBadge extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback? onTap;

  const QueuedMessagesBadge({
    super.key,
    required this.count,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing12,
            vertical: AppDesignSystem.spacing8,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppDesignSystem.systemOrange.withOpacity(0.2)
                : AppDesignSystem.systemOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDesignSystem.cornerRadius12),
            border: Border.all(
              color: AppDesignSystem.systemOrange.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppDesignSystem.systemOrange,
              ),
              SizedBox(width: AppDesignSystem.spacing8),
              Text(
                '$count ${count == 1 ? "mensagem" : "mensagens"} na fila',
                style: AppDesignSystem.caption1.copyWith(
                  color: AppDesignSystem.systemOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onTap != null) ...[
                SizedBox(width: AppDesignSystem.spacing4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppDesignSystem.systemOrange,
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.2, end: 0);
  }
}
