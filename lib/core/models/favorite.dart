import 'package:equatable/equatable.dart';

import 'product.dart';

/// Modelo de favorito
class Favorite extends Equatable {
  final String userId;
  final String productId;
  final DateTime createdAt;

  // Relaciones opcionales
  final Product? product;

  const Favorite({
    required this.userId,
    required this.productId,
    required this.createdAt,
    this.product,
  });

  /// Crear desde JSON de Supabase
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// JSON para inserción
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'product_id': productId,
    };
  }

  @override
  List<Object?> get props => [userId, productId, createdAt];
}

