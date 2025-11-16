import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';

/// Tela de configurações gerais do aplicativo
class SettingsGeneralScreen extends StatefulWidget {
  const SettingsGeneralScreen({super.key});

  @override
  State<SettingsGeneralScreen> createState() => _SettingsGeneralScreenState();
}

class _SettingsGeneralScreenState extends State<SettingsGeneralScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'pt_BR';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Carregar configurações do SharedPreferences
    setState(() {
      _notificationsEnabled = true;
      _selectedLanguage = 'pt_BR';
    });
  }

  Future<void> _saveSettings() async {
    // TODO: Salvar configurações no SharedPreferences
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Senha Atual',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nova Senha',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Nova Senha',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('As senhas não coincidem')),
                );
                return;
              }

              try {
                // TODO: Implementar mudança de senha com Supabase
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha alterada com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final currentUser = SupabaseService.getCurrentUser();
    final nameController = TextEditingController(
      text: currentUser?.userMetadata?['name'] ?? '',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // TODO: Atualizar perfil no Supabase
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil atualizado!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇧🇷'),
              title: const Text('Português (Brasil)'),
              trailing: _selectedLanguage == 'pt_BR'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = 'pt_BR');
                _saveSettings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Idioma alterado')),
                );
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English (US)'),
              trailing: _selectedLanguage == 'en_US'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = 'en_US');
                _saveSettings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language changed')),
                );
              },
            ),
            ListTile(
              leading: const Text('🇪🇸'),
              title: const Text('Español'),
              trailing: _selectedLanguage == 'es_ES'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = 'es_ES');
                _saveSettings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Idioma cambiado')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  String get _languageDisplay {
    switch (_selectedLanguage) {
      case 'pt_BR':
        return 'Português (Brasil)';
      case 'en_US':
        return 'English (US)';
      case 'es_ES':
        return 'Español';
      default:
        return 'Português (Brasil)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseService.getCurrentUser();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        elevation: 0,
      ),
      body: SettingsList(
        platform: DevicePlatform.iOS,
        darkTheme: const SettingsThemeData(
          settingsListBackground: Color(0xFF121212),
          titleTextColor: Colors.white,
        ),
        lightTheme: const SettingsThemeData(
          settingsListBackground: Color(0xFFF5F5F5),
        ),
        sections: [
          // Seção: Conta
          SettingsSection(
            title: const Text('Conta'),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                value: Text(currentUser?.email ?? 'Não disponível'),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.person_outline),
                title: const Text('Editar Perfil'),
                value: Text(
                  currentUser?.userMetadata?['name'] ?? 'Configurar nome',
                ),
                onPressed: (_) => _showEditProfileDialog(),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Alterar Senha'),
                onPressed: (_) => _showChangePasswordDialog(),
              ),
            ],
          ),

          // Seção: Preferências
          SettingsSection(
            title: const Text('Preferências'),
            tiles: [
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Notificações ativadas'
                            : 'Notificações desativadas',
                      ),
                    ),
                  );
                },
                initialValue: _notificationsEnabled,
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notificações'),
                description:
                    const Text('Receber notificações de novas mensagens'),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Idioma'),
                value: Text(_languageDisplay),
                onPressed: (_) => _showLanguageDialog(),
              ),
              SettingsTile(
                leading: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Tema'),
                value: const Text('Segue o sistema'),
                description: const Text('Tema automático baseado no celular'),
              ),
            ],
          ),

          // Seção: Sobre
          SettingsSection(
            title: const Text('Sobre'),
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Versão'),
                value: const Text('1.0.0'),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ajuda e Suporte'),
                onPressed: (_) {
                  // TODO: Abrir tela de ajuda
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Política de Privacidade'),
                onPressed: (_) {
                  // TODO: Abrir política de privacidade
                },
              ),
            ],
          ),

          // Seção: Ações
          SettingsSection(
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sair',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: (_) => _handleLogout(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
