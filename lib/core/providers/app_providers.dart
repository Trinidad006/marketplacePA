import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'auth_provider.dart';
import 'products_provider.dart';
import 'favorites_provider.dart';
import 'chat_provider.dart';

export 'auth_provider.dart';
export 'products_provider.dart';
export 'favorites_provider.dart';
export 'chat_provider.dart';

/// Configuración centralizada de todos los providers
class AppProviders {
  AppProviders._();

  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ];
}

