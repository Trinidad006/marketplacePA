import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado para acceder a Supabase
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  
  static GoTrueClient get auth => client.auth;
  
  static SupabaseStorageClient get storage => client.storage;
  
  static RealtimeClient get realtime => client.realtime;

  /// Usuario actual autenticado
  static User? get currentUser => auth.currentUser;

  /// ID del usuario actual
  static String? get currentUserId => currentUser?.id;

  /// Verificar si el usuario está autenticado
  static bool get isAuthenticated => currentUser != null;

  /// Stream de cambios de autenticación
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  /// Tablas de la base de datos
  static SupabaseQueryBuilder get userProfiles => client.from('user_profiles');
  static SupabaseQueryBuilder get products => client.from('products');
  static SupabaseQueryBuilder get favorites => client.from('favorites');
  static SupabaseQueryBuilder get conversations => client.from('conversations');
  static SupabaseQueryBuilder get messages => client.from('messages');
}

