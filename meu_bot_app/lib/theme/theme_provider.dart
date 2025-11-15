import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gerenciar o tema do app (claro/escuro)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  /// Modo de tema atual
  ThemeMode _themeMode = ThemeMode.system;

  /// Getter para o modo de tema
  ThemeMode get themeMode => _themeMode;

  /// Verifica se está em modo escuro
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Se for system, retorna baseado no brightness do sistema
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Inicializa o provider e carrega preferência salva
  Future<void> initialize() async {
    await _loadThemePreference();
  }

  /// Carrega a preferência de tema salva
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }

        print('🎨 Tema carregado: $savedTheme');
      } else {
        print('🎨 Usando tema padrão: system');
      }
    } catch (e) {
      print('⚠️  Erro ao carregar tema: $e');
    }
  }

  /// Salva a preferência de tema
  Future<void> _saveThemePreference(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme);
      print('💾 Tema salvo: $theme');
    } catch (e) {
      print('⚠️  Erro ao salvar tema: $e');
    }
  }

  /// Alterna para tema claro
  Future<void> setLightMode() async {
    _themeMode = ThemeMode.light;
    await _saveThemePreference('light');
    notifyListeners();
  }

  /// Alterna para tema escuro
  Future<void> setDarkMode() async {
    _themeMode = ThemeMode.dark;
    await _saveThemePreference('dark');
    notifyListeners();
  }

  /// Alterna para tema do sistema
  Future<void> setSystemMode() async {
    _themeMode = ThemeMode.system;
    await _saveThemePreference('system');
    notifyListeners();
  }

  /// Toggle entre claro e escuro (ignora system)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light ||
        (_themeMode == ThemeMode.system && !isDarkMode)) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }

  /// Define o tema diretamente
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeString = 'system';
        break;
    }

    await _saveThemePreference(themeString);
    notifyListeners();
  }

  /// Retorna descrição amigável do tema atual
  String get themeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  /// Retorna ícone correspondente ao tema
  IconData get themeIcon {
    if (isDarkMode) {
      return Icons.dark_mode;
    } else {
      return Icons.light_mode;
    }
  }
}
