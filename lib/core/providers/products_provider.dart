import 'dart:io';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';

/// Estado de carga de productos
enum ProductsStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

/// Filtros de búsqueda
class ProductFilters {
  final String? searchQuery;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final bool onlyAvailable;
  final String sortBy;

  const ProductFilters({
    this.searchQuery,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.onlyAvailable = false,
    this.sortBy = 'recent',
  });

  ProductFilters copyWith({
    String? searchQuery,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? onlyAvailable,
    String? sortBy,
  }) {
    return ProductFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasFilters =>
      searchQuery != null ||
      category != null ||
      minPrice != null ||
      maxPrice != null ||
      onlyAvailable;

  void clear() {}
}

/// Provider de productos con ChangeNotifier
class ProductsProvider extends ChangeNotifier {
  ProductsStatus _status = ProductsStatus.initial;
  List<Product> _products = [];
  List<Product> _sellerProducts = [];
  Product? _selectedProduct;
  ProductFilters _filters = const ProductFilters();
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 0;

  ProductsStatus get status => _status;
  List<Product> get products => _products;
  List<Product> get sellerProducts => _sellerProducts;
  Product? get selectedProduct => _selectedProduct;
  ProductFilters get filters => _filters;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  /// Cargar productos con paginación (infinite scroll)
  Future<void> loadProducts({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
        _status = ProductsStatus.loading;
      } else if (!_hasMore || _status == ProductsStatus.loadingMore) {
        return;
      } else {
        _status = ProductsStatus.loadingMore;
      }
      notifyListeners();

      var query = SupabaseService.products.select('''
        *,
        seller:user_profiles!seller_id(*)
      ''');

      // Aplicar filtros
      if (_filters.searchQuery != null && _filters.searchQuery!.isNotEmpty) {
        query = query.ilike('name', '%${_filters.searchQuery}%');
      }
      if (_filters.category != null) {
        query = query.eq('category', _filters.category!);
      }
      if (_filters.minPrice != null) {
        query = query.gte('price', _filters.minPrice!);
      }
      if (_filters.maxPrice != null) {
        query = query.lte('price', _filters.maxPrice!);
      }
      if (_filters.onlyAvailable) {
        query = query.gt('stock', 0);
      }

      // Determinar ordenamiento y paginación
      final offset = _currentPage * AppConstants.pageSize;
      final String orderColumn;
      final bool ascending;
      
      switch (_filters.sortBy) {
        case 'price_asc':
          orderColumn = 'price';
          ascending = true;
        case 'price_desc':
          orderColumn = 'price';
          ascending = false;
        case 'popular':
          orderColumn = 'views_count';
          ascending = false;
        case 'recent':
        default:
          orderColumn = 'created_at';
          ascending = false;
      }

      final response = await query
          .order(orderColumn, ascending: ascending)
          .range(offset, offset + AppConstants.pageSize - 1);

      final newProducts = (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      if (refresh) {
        _products = newProducts;
      } else {
        // Evitar duplicados
        final existingIds = _products.map((p) => p.id).toSet();
        final uniqueProducts =
            newProducts.where((p) => !existingIds.contains(p.id)).toList();
        _products.addAll(uniqueProducts);
      }

      _hasMore = newProducts.length >= AppConstants.pageSize;
      _currentPage++;
      _status = ProductsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProductsStatus.error;
    }
    notifyListeners();
  }

  /// Actualizar filtros y recargar
  Future<void> updateFilters(ProductFilters newFilters) async {
    _filters = newFilters;
    await loadProducts(refresh: true);
  }

  /// Limpiar filtros
  Future<void> clearFilters() async {
    _filters = const ProductFilters();
    await loadProducts(refresh: true);
  }

  /// Cargar productos del vendedor actual
  Future<void> loadSellerProducts(String sellerId) async {
    try {
      _status = ProductsStatus.loading;
      notifyListeners();

      final response = await SupabaseService.products
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      _sellerProducts = (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      _status = ProductsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProductsStatus.error;
    }
    notifyListeners();
  }

  /// Obtener producto por ID
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await SupabaseService.products
          .select('''
            *,
            seller:user_profiles!seller_id(*)
          ''')
          .eq('id', productId)
          .single();

      _selectedProduct = Product.fromJson(response);

      // Incrementar vistas
      await _incrementViews(productId);

      notifyListeners();
      return _selectedProduct;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  /// Incrementar contador de vistas
  Future<void> _incrementViews(String productId) async {
    try {
      await SupabaseService.client.rpc(
        'increment_product_views',
        params: {'product_id': productId},
      );
    } catch (_) {
      // Ignorar errores de incremento
    }
  }

  /// Crear nuevo producto
  Future<Product?> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required List<File> images,
    bool isFeatured = false,
    Function(double)? onProgress,
  }) async {
    try {
      _status = ProductsStatus.loading;
      notifyListeners();

      final sellerId = SupabaseService.currentUserId;
      debugPrint('🛒 Creando producto - Seller ID: $sellerId');
      
      if (sellerId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que el usuario tenga rol de vendedor
      try {
        final profileResponse = await SupabaseService.userProfiles
            .select('role')
            .eq('id', sellerId)
            .maybeSingle();
        
        debugPrint('📋 Perfil del usuario: ${profileResponse?['role']}');
        
        if (profileResponse == null) {
          throw Exception('No se encontró el perfil del usuario');
        }
        
        final role = profileResponse['role'] as String?;
        if (role != 'seller') {
          debugPrint('❌ Usuario no es vendedor. Rol: $role');
          throw Exception('Solo los vendedores pueden crear productos. Tu rol actual es: $role');
        }
      } catch (e) {
        debugPrint('❌ Error al verificar rol: $e');
        rethrow;
      }

      // Verificar límite de destacados
      if (isFeatured) {
        final featuredCount = await _getFeaturedCount(sellerId);
        if (featuredCount >= AppConstants.maxFeaturedProducts) {
          throw Exception(
              'Máximo ${AppConstants.maxFeaturedProducts} productos destacados');
        }
      }

      debugPrint('📸 Subiendo ${images.length} imágenes...');
      // Subir imágenes
      final imageUrls = <String>[];
      for (int i = 0; i < images.length; i++) {
        debugPrint('📸 Subiendo imagen ${i + 1}/${images.length}');
        final url = await StorageService.uploadProductImage(
          images[i],
          onProgress: (progress) {
            onProgress?.call((i + progress) / images.length);
          },
        );
        if (url != null) {
          imageUrls.add(url);
          debugPrint('✅ Imagen ${i + 1} subida: $url');
        } else {
          debugPrint('⚠️ Imagen ${i + 1} no se pudo subir');
        }
      }

      if (imageUrls.isEmpty) {
        throw Exception('No se pudieron subir las imágenes');
      }

      debugPrint('💾 Creando producto en la base de datos...');
      final product = Product(
        id: '',
        sellerId: sellerId,
        name: name,
        description: description,
        price: price,
        category: category,
        stock: stock,
        images: imageUrls,
        isFeatured: isFeatured,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final productJson = product.toInsertJson();
      debugPrint('📦 Datos del producto: $productJson');

      final response = await SupabaseService.products
          .insert(productJson)
          .select()
          .single();

      debugPrint('✅ Producto creado exitosamente');
      final newProduct = Product.fromJson(response);
      _sellerProducts.insert(0, newProduct);
      _status = ProductsStatus.loaded;
      notifyListeners();
      return newProduct;
    } catch (e, stackTrace) {
      debugPrint('❌ Error al crear producto: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      _errorMessage = e.toString();
      _status = ProductsStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Actualizar producto existente
  Future<bool> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    List<String>? images,
    bool? isFeatured,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (category != null) updates['category'] = category;
      if (stock != null) updates['stock'] = stock;
      if (images != null) updates['images'] = images;
      if (isFeatured != null) updates['is_featured'] = isFeatured;

      await SupabaseService.products.update(updates).eq('id', productId);

      // Actualizar listas locales
      final index = _sellerProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _sellerProducts[index] = _sellerProducts[index].copyWith(
          name: name,
          description: description,
          price: price,
          category: category,
          stock: stock,
          images: images,
          isFeatured: isFeatured,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Eliminar producto
  Future<bool> deleteProduct(String productId) async {
    try {
      // Obtener producto para eliminar imágenes
      final product = _sellerProducts.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Producto no encontrado'),
      );

      // Eliminar imágenes del storage
      for (final imageUrl in product.images) {
        await StorageService.deleteProductImage(imageUrl);
      }

      // Eliminar de la base de datos
      await SupabaseService.products.delete().eq('id', productId);

      _sellerProducts.removeWhere((p) => p.id == productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Obtener cantidad de productos destacados del vendedor
  Future<int> _getFeaturedCount(String sellerId) async {
    final response = await SupabaseService.products
        .select('id')
        .eq('seller_id', sellerId)
        .eq('is_featured', true);
    return (response as List).length;
  }

  /// Limpiar producto seleccionado
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }
}

