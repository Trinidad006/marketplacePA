import 'package:equatable/equatable.dart';

import 'user_profile.dart';

/// Modelo de producto
class Product extends Equatable {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final List<String> images;
  final bool isFeatured;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relaciones opcionales
  final UserProfile? seller;
  final int? favoritesCount;
  final bool? isFavorite;

  const Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.stock,
    required this.images,
    this.isFeatured = false,
    this.viewsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.seller,
    this.favoritesCount,
    this.isFavorite,
  });

  /// Crear desde JSON de Supabase
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      stock: json['stock'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isFeatured: json['is_featured'] as bool? ?? false,
      viewsCount: json['views_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      seller: json['seller'] != null
          ? UserProfile.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      favoritesCount: json['favorites_count'] as int?,
      isFavorite: json['is_favorite'] as bool?,
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'images': images,
      'is_featured': isFeatured,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// JSON para inserción
  Map<String, dynamic> toInsertJson() {
    return {
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'images': images,
      'is_featured': isFeatured,
    };
  }

  /// JSON para actualización
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'images': images,
      'is_featured': isFeatured,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Verificar si está disponible
  bool get isAvailable => stock > 0;

  /// Precio formateado
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Primera imagen o placeholder
  String? get mainImage => images.isNotEmpty ? images.first : null;

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    List<String>? images,
    bool? isFeatured,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? seller,
    int? favoritesCount,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seller: seller ?? this.seller,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        name,
        description,
        price,
        category,
        stock,
        images,
        isFeatured,
        viewsCount,
        createdAt,
        updatedAt,
      ];
}

