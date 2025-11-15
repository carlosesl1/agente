import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assistant_model.dart';
import '../providers/assistant_provider.dart';
import '../services/assistant_service.dart';

/// Tela para criar ou editar um assistente
class AssistantEditScreen extends StatefulWidget {
  final AssistantModel? assistant; // null = criar novo

  const AssistantEditScreen({super.key, this.assistant});

  @override
  State<AssistantEditScreen> createState() => _AssistantEditScreenState();
}

class _AssistantEditScreenState extends State<AssistantEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _webhookController;
  late final TextEditingController _avatarController;

  late Color _selectedPrimaryColor;
  late Color _selectedSecondaryColor;

  bool _isLoading = false;
  bool get _isEditing => widget.assistant != null;

  @override
  void initState() {
    super.initState();

    // Inicializa controllers
    _nameController = TextEditingController(
      text: widget.assistant?.name ?? '',
    );
    _webhookController = TextEditingController(
      text: widget.assistant?.webhookUrl ?? '',
    );
    _avatarController = TextEditingController(
      text: widget.assistant?.avatarUrl ?? '',
    );

    // Inicializa cores
    _selectedPrimaryColor = widget.assistant?.primaryColor ??
        AssistantService.defaultColors[0];
    _selectedSecondaryColor = widget.assistant?.secondaryColor ??
        const Color(0xFF9E9E9E);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _webhookController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _saveAssistant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AssistantProvider>();

      if (_isEditing) {
        // Atualizar existente
        final updated = widget.assistant!.copyWith(
          name: _nameController.text.trim(),
          webhookUrl: _webhookController.text.trim(),
          avatarUrl: _avatarController.text.trim().isEmpty
              ? null
              : _avatarController.text.trim(),
          primaryColor: _selectedPrimaryColor,
          secondaryColor: _selectedSecondaryColor,
        );

        final success = await provider.updateAssistant(updated);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assistente atualizado!')),
          );
          Navigator.pop(context);
        }
      } else {
        // Criar novo
        final assistant = await provider.createAssistant(
          name: _nameController.text.trim(),
          webhookUrl: _webhookController.text.trim(),
          avatarUrl: _avatarController.text.trim().isEmpty
              ? null
              : _avatarController.text.trim(),
          primaryColor: _selectedPrimaryColor,
          secondaryColor: _selectedSecondaryColor,
        );

        if (assistant != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assistente criado!')),
          );
          // Seleciona o novo assistente
          provider.selectAssistant(assistant);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAssistant() async {
    if (!_isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Assistente'),
        content: Text(
          'Tem certeza que deseja deletar "${widget.assistant!.name}"?\n\n'
          'Todas as mensagens deste assistente serão mantidas, mas não estarão mais associadas a ele.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AssistantProvider>();
      final success = await provider.deleteAssistant(widget.assistant!.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assistente deletado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Assistente' : 'Novo Assistente'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteAssistant,
              tooltip: 'Deletar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview do avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _selectedPrimaryColor,
                backgroundImage: _avatarController.text.trim().isNotEmpty
                    ? NetworkImage(_avatarController.text.trim())
                    : null,
                child: _avatarController.text.trim().isEmpty
                    ? Text(
                        _nameController.text.isEmpty
                            ? '?'
                            : _nameController.text[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Assistente',
                hintText: 'Ex: Trabalho, Casa, Finanças',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite um nome';
                }
                return null;
              },
              onChanged: (_) => setState(() {}), // Atualiza preview
            ),
            const SizedBox(height: 16),

            // Webhook URL
            TextFormField(
              controller: _webhookController,
              decoration: const InputDecoration(
                labelText: 'Webhook URL (N8N)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite a URL do webhook';
                }
                if (!value.startsWith('http')) {
                  return 'URL deve começar com http:// ou https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Avatar URL (opcional)
            TextFormField(
              controller: _avatarController,
              decoration: const InputDecoration(
                labelText: 'Avatar URL (opcional)',
                hintText: 'https://... (deixe vazio para usar padrão)',
                prefixIcon: Icon(Icons.image_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}), // Atualiza preview
            ),
            const SizedBox(height: 24),

            // Seletor de cor primária
            const Text(
              'Cor Primária',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AssistantService.defaultColors.map((color) {
                final isSelected = color == _selectedPrimaryColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPrimaryColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Botão Salvar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAssistant,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _selectedPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Salvar Alterações' : 'Criar Assistente',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
