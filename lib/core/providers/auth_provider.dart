import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

/// Estado de autenticación
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Provider de autenticación con ChangeNotifier
class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserProfile? _userProfile;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isSeller => _userProfile?.isSeller ?? false;
  bool get isBuyer => _userProfile?.isBuyer ?? false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Escuchar cambios de autenticación
    SupabaseService.authStateChanges.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn) {
        _loadUserProfile();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        _userProfile = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    // Verificar sesión existente
    if (SupabaseService.isAuthenticated) {
      await _loadUserProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final userId = SupabaseService.currentUserId;
      final user = SupabaseService.currentUser;
      if (userId == null || user == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      var response = await SupabaseService.userProfiles
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('📋 Perfil cargado: ${response != null ? "Sí" : "No"}');
      if (response != null) {
        debugPrint('📋 Rol en BD: ${response['role']}');
        debugPrint('📋 Nombre: ${response['full_name']}');
      }

      // Fallback: si no existe el perfil, crearlo (para usuarios legacy)
      if (response == null) {
        final metadata = user.userMetadata ?? {};
        final fullName = metadata['full_name'] as String? ?? 
                         user.email?.split('@').first ?? 
                         'Usuario';
        // Usar el rol de los metadata, pero si no existe, intentar detectarlo del email o usar 'buyer'
        var role = metadata['role'] as String?;
        // Si no hay rol en metadata, usar 'buyer' por defecto
        if (role == null || (role != 'seller' && role != 'buyer')) {
          role = 'buyer';
        }
        
        debugPrint('🔧 Creando perfil fallback - Rol: $role, Nombre: $fullName');
        
        debugPrint('🔧 Perfil no existe, creando para: $userId');
        debugPrint('🔧 Nombre: $fullName, Rol: $role');
        
        // Crear perfil directamente (la política RLS permite INSERT si auth.uid() = id)
        try {
          await SupabaseService.userProfiles.insert({
            'id': userId,
            'full_name': fullName,
            'role': role,
          });
          debugPrint('✅ Perfil creado via INSERT');
        } catch (insertError) {
          debugPrint('❌ INSERT falló: $insertError');
          rethrow;
        }
        
        response = await SupabaseService.userProfiles
            .select()
            .eq('id', userId)
            .maybeSingle();
      }

      if (response != null) {
        _userProfile = UserProfile.fromJson(response);
        debugPrint('✅ Perfil cargado - Rol: ${_userProfile!.role.value}, isSeller: ${_userProfile!.isSeller}');
        
        // Verificar que el rol en el perfil coincida con los metadata del usuario
        final metadata = user.userMetadata ?? {};
        final metadataRole = metadata['role'] as String?;
        if (metadataRole != null && 
            metadataRole != _userProfile!.role.value && 
            (metadataRole == 'seller' || metadataRole == 'buyer')) {
          debugPrint('⚠️ Rol en metadata ($metadataRole) diferente al perfil (${_userProfile!.role.value}), actualizando...');
          try {
            await SupabaseService.userProfiles
                .update({'role': metadataRole})
                .eq('id', userId);
            // Recargar el perfil actualizado
            final updatedResponse = await SupabaseService.userProfiles
                .select()
                .eq('id', userId)
                .maybeSingle();
            if (updatedResponse != null) {
              _userProfile = UserProfile.fromJson(updatedResponse);
              debugPrint('✅ Rol actualizado a: ${_userProfile!.role.value}');
            }
          } catch (e) {
            debugPrint('❌ Error al actualizar rol: $e');
          }
        }
        
        _status = AuthStatus.authenticated;
      } else {
        _errorMessage = 'No se pudo cargar el perfil';
        _status = AuthStatus.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  /// Registrar nuevo usuario
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Crear usuario en Supabase Auth
      final response = await SupabaseService.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
        data: {
          'full_name': fullName,
          'role': role == UserRole.seller ? 'seller' : 'buyer',
        },
      );

      if (response.user == null) {
        throw Exception('Error al crear el usuario');
      }

      debugPrint('✅ Usuario registrado: ${response.user!.id}');
      debugPrint('📧 Rol seleccionado: ${role == UserRole.seller ? 'seller' : 'buyer'}');
      
      // Verificar si el perfil ya existe (usuario re-registrado)
      final existingProfile = await SupabaseService.userProfiles
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();
      
      final roleStr = role == UserRole.seller ? 'seller' : 'buyer';
      
      if (existingProfile != null) {
        // Si el perfil existe, actualizar el rol
        debugPrint('⚠️ Perfil ya existe, actualizando rol a: $roleStr');
        await SupabaseService.userProfiles
            .update({'role': roleStr})
            .eq('id', response.user!.id);
      } else {
        // El trigger debería crear el perfil, pero por si acaso esperamos un poco
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Verificar si el trigger lo creó
        final profileCheck = await SupabaseService.userProfiles
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
        
        if (profileCheck == null) {
          debugPrint('⚠️ Trigger no creó perfil, el usuario debe verificar email primero');
          debugPrint('📧 El perfil se creará cuando verifiques tu email e inicies sesión');
        } else {
          // Verificar que el rol sea correcto
          if (profileCheck['role'] != roleStr) {
            debugPrint('⚠️ Rol incorrecto en perfil, actualizando...');
            await SupabaseService.userProfiles
                .update({'role': roleStr})
                .eq('id', response.user!.id);
          }
          debugPrint('✅ Perfil creado con rol: $roleStr');
        }
      }

      debugPrint('📧 Verifica tu email para poder iniciar sesión');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Iniciar sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Iniciando login para: $email');
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔐 Llamando signInWithPassword...');
      await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('🔐 signInWithPassword completado');

      debugPrint('🔐 Cargando perfil...');
      await _loadUserProfile();
      debugPrint('🔐 Perfil cargado, status: $_status');
      
      return _status == AuthStatus.authenticated;
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.message}');
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Error general: $e');
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await SupabaseService.auth.signOut();
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  /// Recargar perfil desde la BD
  Future<void> reloadProfile() async {
    await _loadUserProfile();
  }

  /// Eliminar cuenta
  Future<bool> deleteAccount() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Eliminar perfil (el usuario se elimina desde el dashboard de Supabase o via trigger)
      // Por ahora eliminamos el perfil y cerramos sesión
      await SupabaseService.userProfiles.delete().eq('id', userId);
      
      // Cerrar sesión
      await signOut();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error al eliminar cuenta: $e');
      _errorMessage = 'No se pudo eliminar la cuenta. Contacta al soporte.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Actualizar perfil
  Future<bool> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      if (_userProfile == null) return false;

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      await SupabaseService.userProfiles
          .update(updates)
          .eq('id', _userProfile!.id);

      _userProfile = _userProfile!.copyWith(
        fullName: fullName ?? _userProfile!.fullName,
        avatarUrl: avatarUrl ?? _userProfile!.avatarUrl,
        bio: bio ?? _userProfile!.bio,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Traducir errores de autenticación
  String _translateAuthError(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('invalid login credentials') || 
        lowerMessage.contains('invalid credentials')) {
      return 'Credenciales inválidas';
    } else if (lowerMessage.contains('email not confirmed') ||
               lowerMessage.contains('email not verified')) {
      return 'Por favor, confirma tu email';
    } else if (lowerMessage.contains('user already registered') ||
               lowerMessage.contains('email already exists') ||
               lowerMessage.contains('already registered') ||
               lowerMessage.contains('already exists')) {
      return 'Este email ya está registrado. Inicia sesión en su lugar.';
    } else if (lowerMessage.contains('password') && 
               (lowerMessage.contains('short') || lowerMessage.contains('minimum'))) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (lowerMessage.contains('invalid email')) {
      return 'El formato del email no es válido';
    }
    return message;
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _userProfile != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}

