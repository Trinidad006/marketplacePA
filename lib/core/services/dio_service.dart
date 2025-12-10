import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_constants.dart';

/// Servicio HTTP con Dio y retry policy
class DioService {
  DioService._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['SUPABASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Agregar interceptor de retry para operaciones críticas
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: AppConstants.maxRetryAttempts,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (error, attempt) {
          // Reintentar solo en errores de red o servidor
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
            return true;
          }
          
          // Reintentar en errores 5xx del servidor
          final statusCode = error.response?.statusCode;
          if (statusCode != null && statusCode >= 500) {
            return true;
          }
          
          return false;
        },
      ),
    );

    // Interceptor de logging en modo debug
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          // Solo log en modo debug
          assert(() {
            print(obj);
            return true;
          }());
        },
      ),
    );

    return dio;
  }

  /// Actualizar el token de autorización
  static void updateAuthToken(String? token) {
    if (token != null) {
      instance.options.headers['Authorization'] = 'Bearer $token';
    } else {
      instance.options.headers.remove('Authorization');
    }
  }
}

