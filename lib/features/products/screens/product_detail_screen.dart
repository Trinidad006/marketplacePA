import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/product.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla de detalle de producto con galería de imágenes
class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().getProductById(widget.productId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _contactSeller(Product product) async {
    final chatProvider = context.read<ChatProvider>();
    final conversation = await chatProvider.startConversation(product);
    if (conversation != null && mounted) {
      context.push('/chat/${conversation.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final authProvider = context.watch<AuthProvider>();
    final product = productsProvider.selectedProduct;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    final isFavorite = favoritesProvider.isFavorite(product.id);
    final isOwnProduct = authProvider.userProfile?.id == product.sellerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar con imagen
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppTheme.backgroundLight,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => favoritesProvider.toggleFavorite(product),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color:
                        isFavorite ? AppTheme.favoriteColor : AppTheme.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Galería de imágenes
                  PageView.builder(
                    controller: _pageController,
                    itemCount: product.images.isNotEmpty ? product.images.length : 1,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      if (product.images.isEmpty) {
                        return Container(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          child: const Icon(
                            Icons.palette_outlined,
                            size: 80,
                            color: AppTheme.textSecondaryLight,
                          ),
                        );
                      }
                      return CachedNetworkImage(
                        imageUrl: product.images[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      );
                    },
                  ),
                  // Indicadores de página
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(product.images.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? AppTheme.primaryColor
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y estado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: AppTheme.primaryColor,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Destacado',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      // Vistas
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.viewsCount}',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nombre
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.secondaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Precio
                  Text(
                    product.formattedPrice,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Stock
                  Row(
                    children: [
                      Icon(
                        product.isAvailable
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: product.isAvailable
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.isAvailable
                            ? '${product.stock} disponibles'
                            : 'Agotado',
                        style: TextStyle(
                          color: product.isAvailable
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Descripción
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryLight,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Vendedor
                  if (product.seller != null) ...[
                    Text(
                      'Vendedor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => context.push('/seller/${product.sellerId}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: product.seller!.avatarUrl != null
                                  ? CachedNetworkImageProvider(
                                      product.seller!.avatarUrl!)
                                  : null,
                              child: product.seller!.avatarUrl == null
                                  ? Text(
                                      product.seller!.fullName.isNotEmpty
                                          ? product.seller!.fullName[0]
                                              .toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.seller!.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'En ArtMarket desde ${product.seller!.timeOnPlatform}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Espacio para el botón fijo
                ],
              ),
            ),
          ),
        ],
      ),
      // Botón de contactar
      bottomSheet: !isOwnProduct
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: product.isAvailable
                      ? () => _contactSeller(product)
                      : null,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contactar vendedor'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

