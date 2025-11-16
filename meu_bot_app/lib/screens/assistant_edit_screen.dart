import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/assistant_model.dart';
import '../providers/assistant_provider.dart';
import '../services/assistant_service.dart';
import '../theme/theme_provider.dart';

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.7)),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedPrimaryColor, _selectedPrimaryColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _selectedPrimaryColor.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAssistant,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditing ? Icons.save_rounded : Icons.add_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Salvar Alterações' : 'Criar Assistente',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Assistente' : 'Novo Assistente'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteAssistant,
              tooltip: 'Deletar',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFFF093FB),
                  ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Preview do avatar com animação premium
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _selectedPrimaryColor.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
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
                                fontSize: 42,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        curve: Curves.elasticOut,
                      ),
                ),
                const SizedBox(height: 32),

                // Card Glassmorphism com formulário
                GlassmorphicContainer(
                  width: double.infinity,
                  height: 650,
                  borderRadius: 24,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0.2),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nome
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nome do Assistente',
                          hint: 'Ex: Trabalho, Casa, Finanças',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Digite um nome';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                        const SizedBox(height: 20),

                        // Webhook URL
                        _buildTextField(
                          controller: _webhookController,
                          label: 'Webhook URL (N8N)',
                          hint: 'https://...',
                          icon: Icons.link,
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
                        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                        const SizedBox(height: 20),

                        // Avatar URL (opcional)
                        _buildTextField(
                          controller: _avatarController,
                          label: 'Avatar URL (opcional)',
                          hint: 'https://... (deixe vazio para usar padrão)',
                          icon: Icons.image_outlined,
                          keyboardType: TextInputType.url,
                          onChanged: (_) => setState(() {}),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                        const SizedBox(height: 28),

                        // Seletor de cor primária
                        Text(
                          'Cor Primária',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
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
                                          color: Colors.white,
                                          width: 4,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: isSelected ? 15 : 8,
                                      spreadRadius: isSelected ? 3 : 0,
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      )
                                    : null,
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: (600 + (50 * index)).ms,
                                    duration: 400.ms,
                                  )
                                  .scale(
                                    begin: const Offset(0.5, 0.5),
                                    curve: Curves.elasticOut,
                                  ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 800.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Botão Salvar Premium
                _buildSaveButton()
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
