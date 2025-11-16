import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/assistant_model.dart';
import '../providers/assistant_provider.dart';
import '../services/assistant_service.dart';
import '../theme/theme_provider.dart';
import '../theme/design_system.dart';

/// Tela minimalista para criar ou editar um assistente
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
        AppDesignSystem.systemGray;
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
            style: TextButton.styleFrom(foregroundColor: AppDesignSystem.systemRed),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppDesignSystem.darkPrimaryBackground
          : AppDesignSystem.lightPrimaryBackground,
      appBar: AppDesignSystem.appBar(
        title: _isEditing ? 'Editar Assistente' : 'Novo Assistente',
        isDark: isDark,
        actions: _isEditing
            ? [
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppDesignSystem.systemRed,
                  ),
                  onPressed: _isLoading ? null : _deleteAssistant,
                  tooltip: 'Deletar',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            children: [
              // Preview do avatar
              Center(
                child: AppDesignSystem.avatar(
                  imageUrl: _avatarController.text.trim().isEmpty
                      ? null
                      : _avatarController.text.trim(),
                  fallbackText: _nameController.text.isEmpty
                      ? '?'
                      : _nameController.text,
                  backgroundColor: _selectedPrimaryColor,
                  radius: 50,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),

              const SizedBox(height: AppDesignSystem.spacing32),

              // Nome
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite um nome';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
                style: AppDesignSystem.body.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
                decoration: AppDesignSystem.inputDecoration(
                  label: 'Nome do Assistente',
                  hint: 'Ex: Trabalho, Casa, Finanças',
                  isDark: isDark,
                  prefixIcon: Icons.person_outline,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: AppDesignSystem.spacing16),

              // Webhook URL
              TextFormField(
                controller: _webhookController,
                enabled: !_isLoading,
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
                style: AppDesignSystem.body.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
                decoration: AppDesignSystem.inputDecoration(
                  label: 'Webhook URL (N8N)',
                  hint: 'https://...',
                  isDark: isDark,
                  prefixIcon: Icons.link,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: AppDesignSystem.spacing16),

              // Avatar URL (opcional)
              TextFormField(
                controller: _avatarController,
                enabled: !_isLoading,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                style: AppDesignSystem.body.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
                decoration: AppDesignSystem.inputDecoration(
                  label: 'Avatar URL (opcional)',
                  hint: 'https://... (deixe vazio para usar padrão)',
                  isDark: isDark,
                  prefixIcon: Icons.image_outlined,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: AppDesignSystem.spacing32),

              // Seletor de cor primária
              Text(
                'Cor do Assistente',
                style: AppDesignSystem.title3.copyWith(
                  color: isDark
                      ? AppDesignSystem.darkPrimaryLabel
                      : AppDesignSystem.lightPrimaryLabel,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: AppDesignSystem.spacing16),

              Wrap(
                spacing: AppDesignSystem.spacing16,
                runSpacing: AppDesignSystem.spacing16,
                children: AssistantService.defaultColors
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final color = entry.value;
                  final isSelected = color == _selectedPrimaryColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPrimaryColor = color;
                      });
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: isDark
                                    ? AppDesignSystem.darkPrimaryLabel
                                    : AppDesignSystem.lightPrimaryLabel,
                                width: 3,
                              )
                            : null,
                        boxShadow: isSelected
                            ? AppDesignSystem.shadowLevel1(isDark)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            )
                          : null,
                    )
                        .animate()
                        .fadeIn(delay: (500 + (30 * index)).ms, duration: 300.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOut,
                        ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDesignSystem.spacing32),

              // Botão Salvar
              AppDesignSystem.primaryButton(
                text: _isEditing ? 'Salvar Alterações' : 'Criar Assistente',
                onPressed: _isLoading ? null : _saveAssistant,
                isDark: isDark,
                isLoading: _isLoading,
                icon: _isEditing ? Icons.save : Icons.add,
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
