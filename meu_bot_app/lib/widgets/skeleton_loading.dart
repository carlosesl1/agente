import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading widgets
///
/// Placeholders animados para melhorar UX durante carregamento
class SkeletonLoading {
  /// Container base para skeleton (cinza com bordas arredondadas)
  static Widget container({
    required double width,
    required double height,
    double borderRadius = 8.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Skeleton circular (para avatares)
  static Widget circle({
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  /// Skeleton de linha de texto
  static Widget text({
    double width = double.infinity,
    double height = 16.0,
  }) {
    return container(
      width: width,
      height: height,
      borderRadius: 4.0,
    );
  }
}

/// Widget que adiciona efeito shimmer (brilho animado)
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Skeleton de mensagem do chat (lado direito - usuário)
class ChatMessageSkeletonUser extends StatelessWidget {
  const ChatMessageSkeletonUser({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Espaço vazio à esquerda
            const Spacer(flex: 2),
            // Mensagem (balão azul)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Balão de mensagem
                  SkeletonLoading.container(
                    width: double.infinity,
                    height: 60,
                    borderRadius: 20,
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  SkeletonLoading.text(
                    width: 60,
                    height: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Avatar
            SkeletonLoading.circle(size: 32),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de mensagem do chat (lado esquerdo - bot)
class ChatMessageSkeletonBot extends StatelessWidget {
  const ChatMessageSkeletonBot({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            SkeletonLoading.circle(size: 32),
            const SizedBox(width: 8),
            // Mensagem (balão cinza)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balão de mensagem
                  SkeletonLoading.container(
                    width: double.infinity,
                    height: 60,
                    borderRadius: 20,
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  SkeletonLoading.text(
                    width: 60,
                    height: 12,
                  ),
                ],
              ),
            ),
            // Espaço vazio à direita
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de lista de mensagens do chat
class ChatHistorySkeletonLoading extends StatelessWidget {
  final int messageCount;

  const ChatHistorySkeletonLoading({
    super.key,
    this.messageCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true, // Chat começa no fim
      itemCount: messageCount,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) {
        // Alterna entre mensagens do usuário e do bot
        final isUserMessage = index % 2 == 0;

        return isUserMessage
            ? const ChatMessageSkeletonUser()
            : const ChatMessageSkeletonBot();
      },
    );
  }
}

/// Skeleton para resposta do bot (digitando...)
class BotTypingSkeletonLoading extends StatelessWidget {
  const BotTypingSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar do bot
            SkeletonLoading.circle(size: 32),
            const SizedBox(width: 12),
            // Indicador de digitando
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoading.text(width: 80, height: 12),
                const SizedBox(height: 4),
                SkeletonLoading.container(
                  width: 60,
                  height: 30,
                  borderRadius: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para tela de loading geral
class GeneralLoadingSkeletonScreen extends StatelessWidget {
  final String? message;

  const GeneralLoadingSkeletonScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shimmer circular spinner
          ShimmerWrapper(
            child: SkeletonLoading.circle(size: 60),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            ShimmerWrapper(
              child: SkeletonLoading.text(
                width: 200,
                height: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton para card de item
class CardSkeletonLoading extends StatelessWidget {
  final double height;

  const CardSkeletonLoading({
    super.key,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              SkeletonLoading.text(width: double.infinity, height: 20),
              const SizedBox(height: 12),
              // Descrição linha 1
              SkeletonLoading.text(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              // Descrição linha 2
              SkeletonLoading.text(width: 200, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton para lista de cards
class CardListSkeletonLoading extends StatelessWidget {
  final int itemCount;
  final double cardHeight;

  const CardListSkeletonLoading({
    super.key,
    this.itemCount = 5,
    this.cardHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return CardSkeletonLoading(height: cardHeight);
      },
    );
  }
}

/// Skeleton para perfil de usuário
class UserProfileSkeletonLoading extends StatelessWidget {
  const UserProfileSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar grande
            SkeletonLoading.circle(size: 100),
            const SizedBox(height: 24),
            // Nome
            SkeletonLoading.text(width: 150, height: 24),
            const SizedBox(height: 12),
            // Email
            SkeletonLoading.text(width: 200, height: 16),
            const SizedBox(height: 32),
            // Bio linha 1
            SkeletonLoading.text(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            // Bio linha 2
            SkeletonLoading.text(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            // Bio linha 3
            SkeletonLoading.text(width: 250, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton para lista com imagens
class ImageListSkeletonLoading extends StatelessWidget {
  final int itemCount;

  const ImageListSkeletonLoading({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerWrapper(
          child: SkeletonLoading.container(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 12,
          ),
        );
      },
    );
  }
}

/// Skeleton para formulário
class FormSkeletonLoading extends StatelessWidget {
  final int fieldCount;

  const FormSkeletonLoading({
    super.key,
    this.fieldCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            fieldCount,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  SkeletonLoading.text(width: 100, height: 14),
                  const SizedBox(height: 8),
                  // Input field
                  SkeletonLoading.container(
                    width: double.infinity,
                    height: 48,
                    borderRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
