import 'package:flutter/material.dart';
import '../models/assistant_model.dart';
import '../services/assistant_service.dart';

/// Provider para gerenciar assistentes e assistente ativo
class AssistantProvider with ChangeNotifier {
  List<AssistantModel> _assistants = [];
  AssistantModel? _currentAssistant;
  bool _isLoading = false;

  List<AssistantModel> get assistants => _assistants;
  AssistantModel? get currentAssistant => _currentAssistant;
  bool get isLoading => _isLoading;

  /// Carrega todos os assistentes do usuário
  Future<void> loadAssistants() async {
    _isLoading = true;
    notifyListeners();

    try {
      _assistants = await AssistantService.loadAssistants();

      // Se não tem assistente selecionado e existe pelo menos um, seleciona o primeiro
      if (_currentAssistant == null && _assistants.isNotEmpty) {
        _currentAssistant = _assistants.first;
      }

      // Se não tem nenhum assistente, cria um padrão
      if (_assistants.isEmpty) {
        final defaultAssistant = await AssistantService.createDefaultAssistant();
        if (defaultAssistant != null) {
          _assistants.add(defaultAssistant);
          _currentAssistant = defaultAssistant;
        }
      }
    } catch (e) {
      print('✗ Erro ao carregar assistentes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Seleciona um assistente como ativo
  void selectAssistant(AssistantModel assistant) {
    _currentAssistant = assistant;
    // Zera contador de não lidas ao selecionar
    AssistantService.resetUnreadCount(assistant.id);

    // Atualiza o contador localmente
    final index = _assistants.indexWhere((a) => a.id == assistant.id);
    if (index != -1) {
      _assistants[index] = assistant.copyWith(unreadCount: 0);
    }

    notifyListeners();
  }

  /// Cria um novo assistente
  Future<AssistantModel?> createAssistant({
    required String name,
    String? avatarUrl,
    required String webhookUrl,
    Color primaryColor = const Color(0xFF2196F3),
    Color secondaryColor = const Color(0xFF9E9E9E),
  }) async {
    final assistant = await AssistantService.createAssistant(
      name: name,
      avatarUrl: avatarUrl,
      webhookUrl: webhookUrl,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );

    if (assistant != null) {
      _assistants.add(assistant);
      notifyListeners();
    }

    return assistant;
  }

  /// Atualiza um assistente existente
  Future<bool> updateAssistant(AssistantModel assistant) async {
    final success = await AssistantService.updateAssistant(assistant);

    if (success) {
      final index = _assistants.indexWhere((a) => a.id == assistant.id);
      if (index != -1) {
        _assistants[index] = assistant;

        // Se for o assistente atual, atualiza também
        if (_currentAssistant?.id == assistant.id) {
          _currentAssistant = assistant;
        }

        notifyListeners();
      }
    }

    return success;
  }

  /// Deleta um assistente
  Future<bool> deleteAssistant(String assistantId) async {
    final success = await AssistantService.deleteAssistant(assistantId);

    if (success) {
      _assistants.removeWhere((a) => a.id == assistantId);

      // Se deletou o assistente atual, seleciona outro
      if (_currentAssistant?.id == assistantId) {
        _currentAssistant = _assistants.isNotEmpty ? _assistants.first : null;
      }

      notifyListeners();
    }

    return success;
  }

  /// Incrementa contador de não lidas de um assistente
  void incrementUnreadCount(String assistantId) {
    final index = _assistants.indexWhere((a) => a.id == assistantId);
    if (index != -1) {
      final assistant = _assistants[index];
      _assistants[index] = assistant.copyWith(
        unreadCount: assistant.unreadCount + 1,
      );
      notifyListeners();

      // Atualiza no servidor
      AssistantService.incrementUnreadCount(assistantId);
    }
  }

  /// Atualiza webhook do assistente atual
  Future<bool> updateCurrentWebhook(String webhookUrl) async {
    if (_currentAssistant == null) return false;

    final updated = _currentAssistant!.copyWith(webhookUrl: webhookUrl);
    return await updateAssistant(updated);
  }
}
