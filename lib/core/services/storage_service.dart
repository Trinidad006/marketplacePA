import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import 'supabase_service.dart';

/// Servicio para manejo de imágenes y Storage de Supabase
class StorageService {
  StorageService._();

  static const _uuid = Uuid();

  /// Subir imagen de producto con compresión y retry
  static Future<String?> uploadProductImage(
    File imageFile, {
    Function(double)? onProgress,
    int attempt = 1,
  }) async {
    try {
      // Comprimir imagen antes de subir
      final compressedBytes = await _compressImage(imageFile);
      
      if (compressedBytes == null) {
        throw Exception('Error al comprimir la imagen');
      }

      // Generar nombre único
      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      final filePath = '${SupabaseService.currentUserId}/$fileName';

      // Subir a Supabase Storage
      await SupabaseService.storage
          .from(AppConstants.productImagesBucket)
          .uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Obtener URL pública
      final publicUrl = SupabaseService.storage
          .from(AppConstants.productImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      // Retry automático hasta 3 intentos
      if (attempt < AppConstants.maxRetryAttempts) {
        await Future.delayed(Duration(seconds: attempt));
        return uploadProductImage(
          imageFile,
          onProgress: onProgress,
          attempt: attempt + 1,
        );
      }
      rethrow;
    }
  }

  /// Subir avatar de usuario
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final compressedBytes = await _compressImage(imageFile, quality: 80);
      
      if (compressedBytes == null) {
        throw Exception('Error al comprimir la imagen');
      }

      final fileName = '${SupabaseService.currentUserId}.jpg';

      await SupabaseService.storage
          .from(AppConstants.avatarsBucket)
          .uploadBinary(
            fileName,
            compressedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return SupabaseService.storage
          .from(AppConstants.avatarsBucket)
          .getPublicUrl(fileName);
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar imagen de producto
  static Future<void> deleteProductImage(String imageUrl) async {
    try {
      // Extraer el path del URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(AppConstants.productImagesBucket);
      
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await SupabaseService.storage
            .from(AppConstants.productImagesBucket)
            .remove([filePath]);
      }
    } catch (e) {
      // Ignorar errores de eliminación
    }
  }

  /// Comprimir imagen a máximo 1MB
  static Future<Uint8List?> _compressImage(
    File file, {
    int quality = AppConstants.imageQuality,
  }) async {
    final fileSize = await file.length();
    
    // Si ya es menor a 1MB, comprimir con calidad estándar
    int targetQuality = quality;
    if (fileSize > AppConstants.maxImageSizeBytes) {
      // Reducir calidad proporcionalmente
      targetQuality = (quality * AppConstants.maxImageSizeBytes / fileSize).round();
      targetQuality = targetQuality.clamp(20, quality);
    }

    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: targetQuality,
      format: CompressFormat.jpeg,
      minWidth: 1080,
      minHeight: 1080,
    );

    // Verificar que el resultado no supere 1MB
    if (result != null && result.length > AppConstants.maxImageSizeBytes) {
      // Comprimir más agresivamente
      return FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 30,
        format: CompressFormat.jpeg,
        minWidth: 800,
        minHeight: 800,
      );
    }

    return result;
  }
}

