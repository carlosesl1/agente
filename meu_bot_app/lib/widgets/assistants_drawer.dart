import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assistant_model.dart';
import '../providers/assistant_provider.dart';
import '../screens/assistant_edit_screen.dart';
import '../screens/settings_screen.dart';

/// Drawer lateral com lista de assistentes
class AssistantsDrawer extends StatelessWidget {
  const AssistantsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            const Divider(height: 1),

            // Lista de assistentes
            Expanded(
              child: _buildAssistantsList(context),
            ),

            const Divider(height: 1),

            // Botão Novo Assistente
            _buildNewAssistantButton(context),

            // Botão Configurações
            _buildSettingsButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Meus Assistentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantsList(BuildContext context) {
    return Consumer<AssistantProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.assistants.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Nenhum assistente criado.\nToque em "+" para criar um.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.assistants.length,
          itemBuilder: (context, index) {
            final assistant = provider.assistants[index];
            final isSelected = provider.currentAssistant?.id == assistant.id;

            return _buildAssistantTile(
              context,
              assistant,
              isSelected,
              provider,
            );
          },
        );
      },
    );
  }

  Widget _buildAssistantTile(
    BuildContext context,
    AssistantModel assistant,
    bool isSelected,
    AssistantProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? assistant.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: assistant.primaryColor, width: 2)
            : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: assistant.primaryColor,
              backgroundImage: assistant.avatarUrl != null
                  ? NetworkImage(assistant.effectiveAvatarUrl)
                  : null,
              child: assistant.avatarUrl == null
                  ? Text(
                      assistant.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // Badge de mensagens não lidas
            if (assistant.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    assistant.unreadCount > 99
                        ? '99+'
                        : assistant.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          assistant.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: assistant.unreadCount > 0
            ? Text(
                '${assistant.unreadCount} ${assistant.unreadCount == 1 ? 'mensagem nova' : 'mensagens novas'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () {
            Navigator.pop(context); // Fecha o drawer
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AssistantEditScreen(
                  assistant: assistant,
                ),
              ),
            );
          },
        ),
        onTap: () {
          provider.selectAssistant(assistant);
          Navigator.pop(context); // Fecha o drawer
        },
      ),
    );
  }

  Widget _buildNewAssistantButton(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.add,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: const Text(
        'Novo Assistente',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Navigator.pop(context); // Fecha o drawer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AssistantEditScreen(),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings_outlined),
      title: const Text('Configurações'),
      onTap: () {
        Navigator.pop(context); // Fecha o drawer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
      },
    );
  }
}
