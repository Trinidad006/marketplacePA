/// Constantes de la aplicación ArtMarket
class AppConstants {
  AppConstants._();

  // Paginación
  static const int pageSize = 20;
  static const int maxFeaturedProducts = 3;
  static const int maxProductImages = 3;

  // Debounce
  static const int searchDebounceMs = 300;

  // Validación
  static const int minDescriptionLength = 50;
  static const double minPrice = 0.01;
  static const int maxRetryAttempts = 3;

  // Imágenes
  static const int maxImageSizeBytes = 1024 * 1024; // 1MB
  static const int imageQuality = 70;

  // Storage
  static const String productImagesBucket = 'product-images';
  static const String avatarsBucket = 'avatars';

  // Categorías de productos
  static const List<String> productCategories = [
    'Cerámica',
    'Textiles',
    'Joyería',
    'Madera',
    'Vidrio',
    'Cuero',
    'Metal',
    'Papel',
    'Pintura',
    'Escultura',
    'Otros',
  ];

  // Opciones de ordenamiento
  static const Map<String, String> sortOptions = {
    'recent': 'Más recientes',
    'price_asc': 'Menor precio',
    'price_desc': 'Mayor precio',
    'popular': 'Más populares',
  };
}

/// Roles de usuario
enum UserRole {
  buyer('buyer', 'Comprador'),
  seller('seller', 'Vendedor');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.buyer,
    );
  }
}

