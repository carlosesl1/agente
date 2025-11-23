import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_themes.dart';
import '../theme/theme_provider.dart';
import '../theme/design_system.dart';
import '../screens/theme_selection_screen.dart';
import '../screens/stats_screen.dart';

/// Tela de configurações do aplicativo
///
/// Permite ao usuário configurar:
/// - URL do webhook N8N personalizada
/// - Outras configurações futuras
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _webhookController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasCustomUrl = false;
  String _defaultUrl = '';

  @override
  void initState() {
    super.initState();
    _loadWebhookUrl();
  }

  @override
  void dispose() {
    _webhookController.dispose();
    super.dispose();
  }

  /// Carrega a URL do webhook atual
  Future<void> _loadWebhookUrl() async {
    setState(() => _isLoading = true);

    try {
      final currentUrl = await PreferencesService.getN8nWebhookUrl();
      final hasCustom = await PreferencesService.hasCustomN8nWebhookUrl();
      final defaultUrl = PreferencesService.getDefaultN8nWebhookUrl();

      setState(() {
        _webhookController.text = currentUrl;
        _hasCustomUrl = hasCustom;
        _defaultUrl = defaultUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erro ao carregar configurações: $e');
    }
  }

  /// Salva a URL do webhook
  Future<void> _saveWebhookUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final url = _webhookController.text.trim();
      final success = await PreferencesService.setN8nWebhookUrl(url);

      if (success) {
        setState(() {
          _hasCustomUrl = true;
          _isSaving = false;
        });
        _showSuccessSnackBar('Webhook configurado com sucesso!');
      } else {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Erro ao salvar configuração');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Erro ao salvar: $e');
    }
  }

  /// Restaura a URL padrão
  Future<void> _restoreDefaultUrl() async {
    final confirmed = await _showConfirmDialog(
      'Restaurar Padrão',
      'Tem certeza que deseja restaurar a URL padrão?\n\nIsso removerá sua configuração personalizada.',
    );

    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final success = await PreferencesService.clearN8nWebhookUrl();

      if (success) {
        setState(() {
          _webhookController.text = _defaultUrl;
          _hasCustomUrl = false;
          _isSaving = false;
        });
        _showSuccessSnackBar('URL padrão restaurada!');
      } else {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Erro ao restaurar padrão');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Erro ao restaurar: $e');
    }
  }

  /// Copia a URL para a área de transferência
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _webhookController.text));
    _showSuccessSnackBar('URL copiada!');
  }

  /// Testa a conexão com o webhook
  Future<void> _testWebhook() async {
    _showInfoSnackBar('Teste de conexão será implementado em breve');
    // TODO: Implementar teste de conexão real
  }

  /// Mostra dialog de confirmação
  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Mostra snackbar de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostra snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostra snackbar de informação
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppThemes.darkBackground : AppThemes.lightBackground,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: isDark ? AppThemes.darkSurface : AppThemes.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(isDark),
                    const SizedBox(height: 24),
                    _buildAppearanceSection(isDark),
                    const SizedBox(height: 24),
                    _buildDataSection(isDark),
                    const SizedBox(height: 24),
                    _buildWebhookSection(isDark),
                    const SizedBox(height: 24),
                    _buildActionsSection(isDark),
                    const SizedBox(height: 24),
                    _buildAboutSection(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  /// Card de informações
  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemes.darkSurface : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sobre o Webhook N8N',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure aqui a URL do seu webhook N8N para personalizar as automações do app.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seção do webhook
  Widget _buildWebhookSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.webhook,
              color: isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              'URL do Webhook',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _webhookController,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'URL do Webhook N8N',
            labelStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
            hintText: 'https://seu-n8n.com/webhook/seu-endpoint',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            filled: true,
            fillColor: isDark ? AppThemes.darkSurface : Colors.white,
            prefixIcon: Icon(
              Icons.link,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.copy,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onPressed: _copyToClipboard,
              tooltip: 'Copiar URL',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppThemes.lightPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'A URL do webhook não pode estar vazia';
            }
            if (!PreferencesService.isValidWebhookUrl(value.trim())) {
              return 'URL inválida. Use o formato: https://seu-n8n.com/webhook/endpoint';
            }
            return null;
          },
        ),
        if (_hasCustomUrl) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Usando configuração personalizada',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Seção de ações
  Widget _buildActionsSection(bool isDark) {
    return Column(
      children: [
        // Botão Salvar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveWebhookUrl,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Salvando...' : 'Salvar Configuração'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemes.lightPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botão Restaurar Padrão
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isSaving || !_hasCustomUrl ? null : _restoreDefaultUrl,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar URL Padrão'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.orange[300] : Colors.orange[700],
              side: BorderSide(
                color: _hasCustomUrl
                    ? (isDark ? Colors.orange[300]! : Colors.orange[700]!)
                    : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Botão Testar Conexão
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _testWebhook,
            icon: const Icon(Icons.network_check),
            label: const Text('Testar Conexão'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.blue[300] : Colors.blue[700],
              side: BorderSide(
                color: isDark ? Colors.blue[300]! : Colors.blue[700]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Informações de ajuda
        _buildHelpSection(isDark),
      ],
    );
  }

  /// Seção de ajuda
  Widget _buildHelpSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemes.darkSurface : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Como configurar?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHelpItem('1. Acesse seu N8N', isDark),
          _buildHelpItem('2. Crie um workflow com nó "Webhook"', isDark),
          _buildHelpItem('3. Configure para aceitar POST requests', isDark),
          _buildHelpItem('4. Copie a "Production URL"', isDark),
          _buildHelpItem('5. Cole aqui e clique em "Salvar"', isDark),
        ],
      ),
    );
  }

  /// Item de ajuda
  Widget _buildHelpItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: isDark ? Colors.green[300] : Colors.green[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de aparência
  Widget _buildAppearanceSection(bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.palette,
              color: isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              'Aparência',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSelectionScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppThemes.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    themeProvider.themeIcon,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          themeProvider.themeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  /// Seção de dados
  Widget _buildDataSection(bool isDark) {
    final user = SupabaseService.getCurrentUser();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.data_usage,
              color: isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              'Dados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatsScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppThemes.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estatísticas e Gestão',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ver estatísticas de uso e gerenciar dados',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  /// Seção sobre
  Widget _buildAboutSection(bool isDark) {
    final user = SupabaseService.getCurrentUser();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info,
              color: isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              'Sobre',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppThemes.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              _buildAboutRow('Versão', '1.0.0', Icons.info_outline, isDark),
              const Divider(height: 24),
              _buildAboutRow(
                'Usuário',
                user?.email ?? 'Não autenticado',
                Icons.person_outline,
                isDark,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  /// Item da seção sobre
  Widget _buildAboutRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
