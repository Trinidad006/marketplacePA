import 'package:flutter/foundation.dart';

import '../models/favorite.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

/// Provider de favoritos con optimistic updates
class FavoritesProvider extends ChangeNotifier {
  List<Favorite> _favorites = [];
  Set<String> _favoriteProductIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Favorite> get favorites => _favorites;
  Set<String> get favoriteProductIds => _favoriteProductIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Verificar si un producto está en favoritos
  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  /// Cargar favoritos del usuario
  Future<void> loadFavorites() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final response = await SupabaseService.favorites
          .select('''
            *,
            product:products(
              *,
              seller:user_profiles!seller_id(*)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _favorites = (response as List)
          .map((json) => Favorite.fromJson(json as Map<String, dynamic>))
          .toList();

      _favoriteProductIds = _favorites.map((f) => f.productId).toSet();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Alternar favorito con optimistic update
  Future<bool> toggleFavorite(Product product) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return false;

    final wasFavorite = isFavorite(product.id);

    // Optimistic update - cambiar estado inmediatamente
    if (wasFavorite) {
      _favoriteProductIds.remove(product.id);
      _favorites.removeWhere((f) => f.productId == product.id);
    } else {
      _favoriteProductIds.add(product.id);
      _favorites.insert(
        0,
        Favorite(
          userId: userId,
          productId: product.id,
          createdAt: DateTime.now(),
          product: product,
        ),
      );
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        // Eliminar de favoritos
        await SupabaseService.favorites
            .delete()
            .eq('user_id', userId)
            .eq('product_id', product.id);
      } else {
        // Agregar a favoritos
        await SupabaseService.favorites.insert({
          'user_id': userId,
          'product_id': product.id,
        });
      }
      return true;
    } catch (e) {
      // Revertir si hay error
      if (wasFavorite) {
        _favoriteProductIds.add(product.id);
        _favorites.insert(
          0,
          Favorite(
            userId: userId,
            productId: product.id,
            createdAt: DateTime.now(),
            product: product,
          ),
        );
      } else {
        _favoriteProductIds.remove(product.id);
        _favorites.removeWhere((f) => f.productId == product.id);
      }
      notifyListeners();

      _errorMessage = e.toString();
      return false;
    }
  }

  /// Obtener productos favoritos
  List<Product> get favoriteProducts {
    return _favorites
        .where((f) => f.product != null)
        .map((f) => f.product!)
        .toList();
  }

  /// Limpiar favoritos (al cerrar sesión)
  void clear() {
    _favorites = [];
    _favoriteProductIds = {};
    notifyListeners();
  }
}

