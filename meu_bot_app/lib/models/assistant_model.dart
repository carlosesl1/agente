import 'package:flutter/material.dart';

/// Modelo de dados para um Assistente
///
/// Representa um assistente virtual configurável com webhook, cores e avatar personalizados
class AssistantModel {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String webhookUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AssistantModel({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.webhookUrl,
    required this.primaryColor,
    required this.secondaryColor,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Cria um AssistantModel a partir de JSON do Supabase
  factory AssistantModel.fromJson(Map<String, dynamic> json) {
    return AssistantModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      webhookUrl: json['webhook_url'] as String,
      primaryColor: Color(json['primary_color'] as int),
      secondaryColor: Color(json['secondary_color'] as int),
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Converte o modelo para JSON para o Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'avatar_url': avatarUrl,
      'webhook_url': webhookUrl,
      'primary_color': primaryColor.value,
      'secondary_color': secondaryColor.value,
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Cria uma cópia do modelo com campos atualizados
  AssistantModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatarUrl,
    String? webhookUrl,
    Color? primaryColor,
    Color? secondaryColor,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssistantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retorna avatar padrão baseado no nome
  String get defaultAvatarUrl {
    final encodedName = Uri.encodeComponent(name);
    final colorHex = primaryColor.value.toRadixString(16).substring(2);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=$colorHex&color=fff&bold=true';
  }

  /// URL do avatar (usa padrão se não tiver customizado)
  String get effectiveAvatarUrl => avatarUrl ?? defaultAvatarUrl;

  @override
  String toString() {
    return 'AssistantModel(id: $id, name: $name, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AssistantModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
