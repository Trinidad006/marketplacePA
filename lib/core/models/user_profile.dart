import 'package:equatable/equatable.dart';

import '../constants/app_constants.dart';

/// Modelo de perfil de usuario
class UserProfile extends Equatable {
  final String id;
  final UserRole role;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
  });

  /// Crear desde JSON de Supabase
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'buyer'),
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crear para inserción (sin id generado por auth)
  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'role': role.value,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }

  /// Verificar si es vendedor
  bool get isSeller => role == UserRole.seller;

  /// Verificar si es comprador
  bool get isBuyer => role == UserRole.buyer;

  /// Tiempo en la plataforma formateado
  String get timeOnPlatform {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'año' : 'años'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'mes' : 'meses'}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else {
      return 'Hoy';
    }
  }

  UserProfile copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, role, fullName, avatarUrl, bio, createdAt];
}

