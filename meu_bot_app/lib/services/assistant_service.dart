import 'package:flutter/material.dart';
import '../models/assistant_model.dart';
import '../theme/design_system.dart';
import 'supabase_service.dart';

/// Serviço para gerenciar assistentes virtuais
///
/// Fornece CRUD completo para assistentes personalizados
class AssistantService {
  /// Instância singleton do Supabase
  static final _supabase = SupabaseService.client;

  /// Cores padrão disponíveis para assistentes
  static const List<Color> defaultColors = [
    Color(0xFF2196F3), // Azul
    Color(0xFF4CAF50), // Verde
    Color(0xFFF44336), // Vermelho
    Color(0xFFFF9800), // Laranja
    Color(0xFF9C27B0), // Roxo
    Color(0xFF00BCD4), // Ciano
    Color(0xFFFFEB3B), // Amarelo
    Color(0xFFE91E63), // Pink
  ];

  /// Carrega todos os assistentes do usuário atual
  static Future<List<AssistantModel>> loadAssistants() async {
    try {
      final userId = SupabaseService.getCurrentUser()?.id;
      if (userId == null) {
        print('⚠️ Usuário não autenticado');
        return [];
      }

      print('📥 Carregando assistentes do usuário $userId...');

      final response = await _supabase
          .from('assistants')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      print('✓ ${data.length} assistentes carregados');

      return data.map((json) => AssistantModel.fromJson(json)).toList();
    } catch (e) {
      print('✗ Erro ao carregar assistentes: $e');
      return [];
    }
  }

  /// Cria um novo assistente
  static Future<AssistantModel?> createAssistant({
    required String name,
    String? avatarUrl,
    required String webhookUrl,
    Color primaryColor = const Color(0xFF2196F3),
    Color secondaryColor = const Color(0xFF9E9E9E),
  }) async {
    try {
      final userId = SupabaseService.getCurrentUser()?.id;
      if (userId == null) {
        print('⚠️ Usuário não autenticado');
        return null;
      }

      print('📝 Criando assistente "$name"...');

      final data = {
        'user_id': userId,
        'name': name,
        'avatar_url': avatarUrl,
        'webhook_url': webhookUrl,
        'primary_color': primaryColor.value,
        'secondary_color': secondaryColor.value,
        'unread_count': 0,
      };

      final response = await _supabase
          .from('assistants')
          .insert(data)
          .select()
          .single();

      print('✓ Assistente criado: ${response['id']}');

      return AssistantModel.fromJson(response);
    } catch (e) {
      print('✗ Erro ao criar assistente: $e');
      return null;
    }
  }

  /// Atualiza um assistente existente
  static Future<bool> updateAssistant(AssistantModel assistant) async {
    try {
      print('📝 Atualizando assistente "${assistant.name}"...');

      await _supabase
          .from('assistants')
          .update({
            'name': assistant.name,
            'avatar_url': assistant.avatarUrl,
            'webhook_url': assistant.webhookUrl,
            'primary_color': assistant.primaryColor.value,
            'secondary_color': assistant.secondaryColor.value,
          })
          .eq('id', assistant.id);

      print('✓ Assistente atualizado');

      return true;
    } catch (e) {
      print('✗ Erro ao atualizar assistente: $e');
      return false;
    }
  }

  /// Deleta um assistente
  static Future<bool> deleteAssistant(String assistantId) async {
    try {
      print('🗑️ Deletando assistente $assistantId...');

      await _supabase.from('assistants').delete().eq('id', assistantId);

      print('✓ Assistente deletado');

      return true;
    } catch (e) {
      print('✗ Erro ao deletar assistente: $e');
      return false;
    }
  }

  /// Incrementa contador de mensagens não lidas
  static Future<void> incrementUnreadCount(String assistantId) async {
    try {
      await _supabase.rpc('increment_unread_count', params: {
        'assistant_id_param': assistantId,
      });
    } catch (e) {
      print('✗ Erro ao incrementar contador: $e');
    }
  }

  /// Zera contador de mensagens não lidas
  static Future<void> resetUnreadCount(String assistantId) async {
    try {
      await _supabase
          .from('assistants')
          .update({'unread_count': 0})
          .eq('id', assistantId);
    } catch (e) {
      print('✗ Erro ao resetar contador: $e');
    }
  }

  /// Cria assistente padrão para novo usuário
  static Future<AssistantModel?> createDefaultAssistant() async {
    return await createAssistant(
      name: 'Assistente Geral',
      webhookUrl: '', // Deve ser configurado nas settings
      primaryColor: defaultColors[0],
      secondaryColor: AppDesignSystem.systemGray,
    );
  }
}
