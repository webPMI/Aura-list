/// Servicio wrapper para Firebase Crashlytics.
///
/// Proporciona una interfaz simplificada para reportar errores y logs
/// a Firebase Crashlytics, con manejo graceful cuando Crashlytics
/// no esta disponible (modo offline o desarrollo).
///
/// Ejemplo de uso:
/// ```dart
/// final crashlytics = CrashlyticsService();
/// await crashlytics.init();
/// await crashlytics.recordError(error, stackTrace, fatal: false);
/// ```
library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'logger_service.dart';

/// Servicio para integracion con Firebase Crashlytics (Singleton)
///
/// Proporciona metodos para registrar errores, logs y datos de usuario
/// en Crashlytics para monitoreo de produccion.
class CrashlyticsService {
  // Singleton pattern
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  /// Indica si Crashlytics esta inicializado y disponible
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Referencia a la instancia de FirebaseCrashlytics
  FirebaseCrashlytics? _crashlytics;

  /// Logger para registrar operaciones del servicio
  final LoggerService _logger = LoggerService();
  static const String _tag = 'CrashlyticsService';

  /// Inicializa el servicio de Crashlytics
  ///
  /// Debe llamarse despues de Firebase.initializeApp()
  /// En modo debug, desactiva la recoleccion automatica de crashes.
  Future<void> init() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // En debug, desactivamos la recoleccion automatica
      if (kDebugMode) {
        await _crashlytics!.setCrashlyticsCollectionEnabled(false);
        _logger.info(_tag, 'Crashlytics initialized (collection disabled in debug mode)');
      } else {
        await _crashlytics!.setCrashlyticsCollectionEnabled(true);
        _logger.info(_tag, 'Crashlytics initialized (collection enabled)');
      }

      // Conectar con LoggerService para logs automaticos
      _logger.onCrashlyticsLog = _handleLogEntry;

      // Capturar errores de Flutter no manejados en produccion
      if (!kDebugMode) {
        FlutterError.onError = (errorDetails) {
          _crashlytics!.recordFlutterFatalError(errorDetails);
        };

        // Capturar errores asincronos no manejados
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics!.recordError(error, stack, fatal: true);
          return true;
        };
      }

      _isInitialized = true;
    } catch (e) {
      _logger.warning(
        _tag,
        'Failed to initialize Crashlytics (app will continue without crash reporting)',
        metadata: {'error': e.toString()},
      );
      _isInitialized = false;
      // No relanzamos - la app debe funcionar sin Crashlytics
    }
  }

  /// Registra un error en Crashlytics
  ///
  /// [error] - El error a registrar
  /// [stack] - Stack trace del error
  /// [fatal] - Si el error es fatal (terminara la app)
  /// [reason] - Razon adicional para contexto
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!_isInitialized || _crashlytics == null) {
      _logger.debug(_tag, 'Skipping recordError (Crashlytics not initialized)');
      return;
    }

    try {
      await _crashlytics!.recordError(
        error,
        stack,
        fatal: fatal,
        reason: reason,
      );

      _logger.debug(
        _tag,
        'Error recorded to Crashlytics',
        metadata: {
          'fatal': fatal,
          'reason': reason,
          'errorType': error.runtimeType.toString(),
        },
      );
    } catch (e) {
      _logger.warning(
        _tag,
        'Failed to record error to Crashlytics',
        metadata: {'originalError': error.toString()},
      );
    }
  }

  /// Registra un mensaje de log en Crashlytics
  ///
  /// Estos mensajes apareceran en el contexto del siguiente crash report.
  Future<void> log(String message) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.log(message);
    } catch (e) {
      // Silencioso - no queremos loops de logging
    }
  }

  /// Establece el ID del usuario para crash reports
  ///
  /// Util para identificar usuarios afectados por crashes.
  /// Pasa null para limpiar el ID.
  Future<void> setUserId(String? userId) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier(userId ?? '');
      _logger.debug(
        _tag,
        userId != null ? 'User ID set' : 'User ID cleared',
      );
    } catch (e) {
      _logger.warning(_tag, 'Failed to set user ID');
    }
  }

  /// Establece un valor personalizado para crash reports
  ///
  /// [key] - Nombre de la clave
  /// [value] - Valor (soporta String, int, double, bool)
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      _logger.warning(
        _tag,
        'Failed to set custom key',
        metadata: {'key': key},
      );
    }
  }

  /// Establece multiples valores personalizados a la vez
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (final entry in keys.entries) {
      await setCustomKey(entry.key, entry.value);
    }
  }

  /// Fuerza un crash de prueba (solo para desarrollo)
  ///
  /// ADVERTENCIA: Esto terminara la app inmediatamente.
  void testCrash() {
    if (!kDebugMode) {
      _logger.warning(_tag, 'Test crash blocked in production');
      return;
    }

    _logger.info(_tag, 'Triggering test crash...');
    _crashlytics?.crash();
  }

  /// Maneja entradas de LoggerService para enviar a Crashlytics
  Future<void> _handleLogEntry(LogEntry entry) async {
    if (!_isInitialized || _crashlytics == null) return;
    if (kDebugMode) return; // No enviar logs en debug

    // Solo enviar errores y criticos a Crashlytics
    if (entry.level == LogLevel.error || entry.level == LogLevel.critical) {
      // Formato del mensaje para Crashlytics
      final message = '[${entry.tag}] ${entry.message}';
      await log(message);

      // Si hay error original, registrarlo
      if (entry.error != null) {
        await recordError(
          entry.error,
          entry.stackTrace,
          fatal: entry.level == LogLevel.critical,
          reason: entry.tag,
        );
      }
    }
  }

  /// Registra informacion del dispositivo/sesion util para debugging
  Future<void> setSessionInfo({
    String? appVersion,
    String? buildNumber,
    String? environment,
  }) async {
    if (appVersion != null) await setCustomKey('app_version', appVersion);
    if (buildNumber != null) await setCustomKey('build_number', buildNumber);
    if (environment != null) await setCustomKey('environment', environment);
  }

  /// Indica si la recoleccion de datos esta habilitada
  Future<bool> isCrashlyticsCollectionEnabled() async {
    if (!_isInitialized || _crashlytics == null) return false;
    return _crashlytics!.isCrashlyticsCollectionEnabled;
  }

  /// Habilita o deshabilita la recoleccion de datos
  ///
  /// Util para cumplir con preferencias de privacidad del usuario.
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    if (!_isInitialized || _crashlytics == null) return;

    await _crashlytics!.setCrashlyticsCollectionEnabled(enabled);
    _logger.info(
      _tag,
      'Crashlytics collection ${enabled ? 'enabled' : 'disabled'}',
    );
  }
}
