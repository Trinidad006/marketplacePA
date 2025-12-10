import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../products/widgets/product_card.dart';

/// Pantalla de perfil público del vendedor
class SellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  UserProfile? _seller;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Cargar perfil del vendedor
      final sellerResponse = await SupabaseService.userProfiles
          .select()
          .eq('id', widget.sellerId)
          .single();

      _seller = UserProfile.fromJson(sellerResponse);

      // Cargar productos del vendedor
      final productsResponse = await SupabaseService.products
          .select()
          .eq('seller_id', widget.sellerId)
          .order('created_at', ascending: false);

      _products = (productsResponse as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (_error != null || _seller == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
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
                'Error al cargar el perfil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadSellerData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSellerData,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            // Header con info del vendedor
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppTheme.backgroundLight,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.backgroundLight,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          // Avatar
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: _seller!.avatarUrl != null
                                ? CachedNetworkImageProvider(_seller!.avatarUrl!)
                                : null,
                            child: _seller!.avatarUrl == null
                                ? Text(
                                    _seller!.fullName.isNotEmpty
                                        ? _seller!.fullName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 36,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          // Nombre
                          Text(
                            _seller!.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppTheme.secondaryColor,
                                ),
                          ),
                          const SizedBox(height: 8),
                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatItem(
                                value: '${_products.length}',
                                label: 'Productos',
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                color: AppTheme.textSecondaryLight
                                    .withOpacity(0.3),
                              ),
                              _StatItem(
                                value: _seller!.timeOnPlatform,
                                label: 'En ArtMarket',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bio si existe
            if (_seller!.bio != null && _seller!.bio!.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sobre el artesano',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _seller!.bio!,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryLight,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Título de productos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Productos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_products.length}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Grid de productos
            _products.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
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
                            'Sin productos aún',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondaryLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _products[index];
                          final isFavorite =
                              favoritesProvider.isFavorite(product.id);

                          return ProductCard(
                            product: product,
                            isFavorite: isFavorite,
                            onTap: () => context.push('/product/${product.id}'),
                            onFavoriteToggle: () =>
                                favoritesProvider.toggleFavorite(product),
                          );
                        },
                        childCount: _products.length,
                      ),
                    ),
                  ),

            // Espacio inferior
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamilyHeading,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

