import 'package:equatable/equatable.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

import 'user_profile.dart';

/// Modelo de mensaje de chat
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  // Relaciones opcionales
  final UserProfile? sender;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  /// Crear desde JSON de Supabase
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: json['sender'] != null
          ? UserProfile.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// JSON para inserción
  Map<String, dynamic> toInsertJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    };
  }

  /// Timestamp relativo ("hace 5 minutos", "ayer", etc.)
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24 && createdAt.day == now.day) {
      return DateFormat('HH:mm').format(createdAt);
    } else if (difference.inHours < 48) {
      return 'Ayer ${DateFormat('HH:mm').format(createdAt)}';
    } else if (difference.inDays < 7) {
      return timeago.format(createdAt, locale: 'es');
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }

  /// Hora formateada para mostrar en el chat
  String get formattedTime => DateFormat('HH:mm').format(createdAt);

  /// Fecha formateada para agrupar mensajes
  String get dateGroup {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (messageDate == today) {
      return 'Hoy';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else if (now.difference(createdAt).inDays < 7) {
      return DateFormat('EEEE', 'es').format(createdAt);
    } else {
      return DateFormat('d MMMM yyyy', 'es').format(createdAt);
    }
  }

  /// Verificar si es del usuario actual
  bool isFromUser(String userId) => senderId == userId;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    UserProfile? sender,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        isRead,
        createdAt,
      ];
}

