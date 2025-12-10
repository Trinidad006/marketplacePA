import 'package:equatable/equatable.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'user_profile.dart';
import 'product.dart';

/// Modelo de conversación de chat
class Conversation extends Equatable {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  // Relaciones opcionales
  final UserProfile? buyer;
  final UserProfile? seller;
  final Product? product;

  const Conversation({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    this.buyer,
    this.seller,
    this.product,
  });

  /// Crear desde JSON de Supabase
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      productId: json['product_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      buyer: json['buyer'] != null
          ? UserProfile.fromJson(json['buyer'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? UserProfile.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': productId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// JSON para inserción
  Map<String, dynamic> toInsertJson() {
    return {
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': productId,
    };
  }

  /// Timestamp relativo del último mensaje
  String get relativeTime {
    if (lastMessageAt == null) return '';
    return timeago.format(lastMessageAt!, locale: 'es');
  }

  /// Obtener el otro participante según el usuario actual
  UserProfile? getOtherParticipant(String currentUserId) {
    if (currentUserId == buyerId) return seller;
    if (currentUserId == sellerId) return buyer;
    return null;
  }

  /// Verificar si hay mensajes no leídos
  bool get hasUnread => unreadCount > 0;

  Conversation copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    String? productId,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
    UserProfile? buyer,
    UserProfile? seller,
    Product? product,
  }) {
    return Conversation(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      buyer: buyer ?? this.buyer,
      seller: seller ?? this.seller,
      product: product ?? this.product,
    );
  }

  @override
  List<Object?> get props => [
        id,
        buyerId,
        sellerId,
        productId,
        lastMessage,
        lastMessageAt,
        unreadCount,
        createdAt,
      ];
}

