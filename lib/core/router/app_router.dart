import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/products/screens/home_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/products/screens/new_product_screen.dart';
import '../../features/products/screens/my_products_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/seller_profile_screen.dart';
import '../widgets/main_scaffold.dart';

/// Rutas de la aplicación
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';

  // Main (con shell)
  static const String home = '/home';
  static const String favorites = '/favorites';
  static const String conversations = '/conversations';
  static const String profile = '/profile';

  // Productos
  static const String productDetail = '/product/:id';
  static const String productForm = '/product/form';
  static const String myProducts = '/my-products';

  // Chat
  static const String chat = '/chat/:id';

  // Perfil de vendedor
  static const String sellerProfile = '/seller/:id';

  // Editar perfil
  static const String editProfile = '/profile/edit';
}

/// Configuración del router con go_router
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      try {
        final authProvider = context.read<AuthProvider>();
        final authStatus = authProvider.status;
        final isAuth = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register ||
            state.matchedLocation == AppRoutes.roleSelection ||
            state.matchedLocation == AppRoutes.splash;

        debugPrint('🔄 Redirect - Ruta: ${state.matchedLocation}, Status: $authStatus, IsAuth: $isAuth');

        // Si el auth está cargando o inicial, permitir continuar (no redirigir)
        if (authStatus == AuthStatus.loading || authStatus == AuthStatus.initial) {
          debugPrint('🔄 Auth en estado $authStatus, permitiendo navegación');
          return null;
        }

        // Si está autenticado y en ruta de auth, ir a home
        if (isAuth && isAuthRoute) {
          debugPrint('🔄 Usuario autenticado en ruta de auth, redirigiendo a home');
          return AppRoutes.home;
        }

        // Si no está autenticado y no está en ruta de auth, ir a login
        // EXCEPTO si está intentando acceder a productForm (se manejará en el widget)
        if (!isAuth && !isAuthRoute && state.matchedLocation != AppRoutes.productForm) {
          debugPrint('🔄 Usuario no autenticado, redirigiendo a login');
          return AppRoutes.login;
        }

        debugPrint('🔄 Permitir navegación a ${state.matchedLocation}');
        return null;
      } catch (e) {
        debugPrint('❌ Error en redirect: $e');
        // En caso de error, permitir la navegación para evitar bloqueos
        return null;
      }
    },
    routes: [
      // Rutas de autenticación
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Shell route para navegación principal
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.conversations,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConversationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Rutas fuera del shell
      // IMPORTANTE: /product/form debe ir ANTES de /product/:id
      // porque go_router puede confundir "form" con un :id
      GoRoute(
        path: '/product/form',
        name: 'product-form',
        builder: (context, state) {
          debugPrint('🔵 ========================================');
          debugPrint('🔵 Router builder para productForm llamado');
          debugPrint('🔵 State matchedLocation: ${state.matchedLocation}');
          debugPrint('🔵 State uri: ${state.uri}');
          debugPrint('🔵 State fullPath: ${state.uri.path}');
          debugPrint('🔵 ========================================');
          
          final productId = state.uri.queryParameters['edit'];
          debugPrint('🔵 productId: $productId');
          
          // Si hay productId, usar ProductFormScreen para editar
          // Si no, usar NewProductScreen para crear
          if (productId != null && productId.isNotEmpty) {
            debugPrint('🔵 Retornando ProductFormScreen con productId: $productId');
            return ProductFormScreen(productId: productId);
          } else {
            debugPrint('🔵 Retornando NewProductScreen (sin productId)');
            return const NewProductScreen();
          }
        },
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.myProducts,
        builder: (context, state) => const MyProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          return ChatScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: AppRoutes.sellerProfile,
        builder: (context, state) {
          final sellerId = state.pathParameters['id']!;
          return SellerProfileScreen(sellerId: sellerId);
        },
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}

