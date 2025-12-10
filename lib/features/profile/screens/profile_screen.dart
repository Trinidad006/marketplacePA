import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla de perfil del usuario
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<FavoritesProvider>().clear();
      context.read<ChatProvider>().clear();
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.errorColor,
            size: 48,
          ),
        ),
        title: const Text(
          'Eliminar Cuenta',
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Se eliminarán todos tus datos, productos, favoritos y conversaciones permanentemente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar Cuenta'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      final isLoading = authProvider.status == AuthStatus.loading;

      if (isLoading) return;

      if (context.mounted) {
        // Limpiar providers
        context.read<FavoritesProvider>().clear();
        context.read<ChatProvider>().clear();
        
        // Eliminar cuenta
        final success = await authProvider.deleteAccount();
        
        if (context.mounted) {
          if (success) {
            context.go(AppRoutes.login);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tu cuenta ha sido eliminada'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.errorMessage ?? 'No se pudo eliminar la cuenta',
                ),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(
                user.fullName.isNotEmpty && !user.fullName.contains('@')
                    ? user.fullName
                    : 'Usuario',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.secondaryColor,
                    ),
              ),
              const SizedBox(height: 4),

              // Rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isSeller
                          ? Icons.storefront
                          : Icons.shopping_bag_outlined,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user.role.displayName,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tiempo en plataforma
              Text(
                'Miembro desde ${user.timeOnPlatform}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 32),

              // Bio
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
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
                        'Acerca de mí',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Debug: mostrar info del rol
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Rol en BD: ${user.role.value}'),
                    Text('isSeller: ${user.isSeller}'),
                    Text('isBuyer: ${user.isBuyer}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await context.read<AuthProvider>().reloadProfile();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Perfil recargado')),
                          );
                        }
                      },
                      child: const Text('Recargar Perfil'),
                    ),
                  ],
                ),
              ),

              // Opciones para vendedores
              if (user.isSeller) ...[
                _OptionTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Mis Productos',
                  subtitle: 'Gestiona tus productos publicados',
                  onTap: () => context.push(AppRoutes.myProducts),
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.add_box_outlined,
                  title: 'Publicar Producto',
                  subtitle: 'Agrega un nuevo producto',
                  onTap: () => context.push(AppRoutes.productForm),
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.analytics_outlined,
                  title: 'Estadísticas',
                  subtitle: 'Vistas y favoritos de tus productos',
                  onTap: () {
                    // TODO: Implementar pantalla de estadísticas
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Opciones generales
              _OptionTile(
                icon: Icons.person_outline,
                title: 'Editar Perfil',
                subtitle: 'Modifica tu información personal',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.notifications_outlined,
                title: 'Notificaciones',
                subtitle: 'Configura tus preferencias',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Próximamente: Configuración de notificaciones'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.help_outline,
                title: 'Ayuda y Soporte',
                subtitle: 'Preguntas frecuentes y contacto',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Próximamente: Centro de ayuda'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Cerrar sesión
              _OptionTile(
                icon: Icons.logout,
                title: 'Cerrar Sesión',
                subtitle: 'Salir de tu cuenta',
                isDestructive: true,
                onTap: () => _signOut(context),
              ),
              const SizedBox(height: 12),

              // Eliminar cuenta
              _OptionTile(
                icon: Icons.delete_forever_outlined,
                title: 'Eliminar Cuenta',
                subtitle: 'Eliminar permanentemente tu cuenta',
                isDestructive: true,
                onTap: () => _deleteAccount(context),
              ),
              const SizedBox(height: 32),

              // Versión
              Text(
                'ArtMarket v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight.withOpacity(0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDestructive
                            ? AppTheme.errorColor
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDestructive
                    ? AppTheme.errorColor.withOpacity(0.5)
                    : AppTheme.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

