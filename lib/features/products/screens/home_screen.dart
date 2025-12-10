import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/search_filter_bar.dart';

/// Pantalla principal con feed de productos
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Cargar productos y favoritos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().loadProducts(refresh: true);
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductsProvider>().loadProducts();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () {
        final provider = context.read<ProductsProvider>();
        provider.updateFilters(
          provider.filters.copyWith(searchQuery: query.isEmpty ? null : query),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await context.read<ProductsProvider>().loadProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isSeller = authProvider.isSeller;

    return Scaffold(
      floatingActionButton: authProvider.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () {
                debugPrint('🔴 Botón Publicar presionado');
                debugPrint('🔴 isSeller: $isSeller');
                if (isSeller) {
                  debugPrint('🔴 Navegando a ${AppRoutes.productForm}');
                  try {
                    // Intentar navegar por nombre primero
                    try {
                      context.pushNamed('product-form');
                      debugPrint('🔴 context.pushNamed ejecutado');
                    } catch (namedError) {
                      debugPrint('⚠️ pushNamed falló, intentando con path: $namedError');
                      context.push(AppRoutes.productForm);
                      debugPrint('🔴 context.push ejecutado');
                    }
                  } catch (e, stackTrace) {
                    debugPrint('❌ Error al navegar: $e');
                    debugPrint('📚 Stack trace: $stackTrace');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solo los vendedores pueden publicar productos'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Publicar'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ArtMarket',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Descubre arte único',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryLight,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Notificaciones badge
                      IconButton(
                        onPressed: () {
                          // TODO: Implementar notificaciones
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Barra de búsqueda y filtros
                  SearchFilterBar(
                    controller: _searchController,
                    onSearchChanged: _onSearchChanged,
                    currentFilters: productsProvider.filters,
                    onFiltersChanged: (filters) {
                      productsProvider.updateFilters(filters);
                    },
                  ),
                ],
              ),
            ),

            // Grid de productos
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.primaryColor,
                child: _buildProductGrid(productsProvider, favoritesProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(
    ProductsProvider productsProvider,
    FavoritesProvider favoritesProvider,
  ) {
    if (productsProvider.status == ProductsStatus.loading &&
        productsProvider.products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      );
    }

    if (productsProvider.status == ProductsStatus.error &&
        productsProvider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar productos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => productsProvider.loadProducts(refresh: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (productsProvider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppTheme.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
            ),
            if (productsProvider.filters.hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => productsProvider.clearFilters(),
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: productsProvider.products.length +
          (productsProvider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= productsProvider.products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final product = productsProvider.products[index];
        final isFavorite = favoritesProvider.isFavorite(product.id);

        return ProductCard(
          product: product,
          isFavorite: isFavorite,
          onTap: () => context.push('/product/${product.id}'),
          onFavoriteToggle: () => favoritesProvider.toggleFavorite(product),
        );
      },
    );
  }
}

