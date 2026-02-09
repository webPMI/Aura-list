import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';
import 'database_service.dart';
import 'error_handler.dart';

/// Resultado de la exportacion de datos.
class DataExport {
  /// Datos exportados en formato JSON
  final Map<String, dynamic> data;

  /// Timestamp de la exportacion
  final DateTime exportedAt;

  /// ID del usuario
  final String? userId;

  /// Numero de tareas exportadas
  final int taskCount;

  /// Numero de notas exportadas
  final int noteCount;

  DataExport({
    required this.data,
    required this.exportedAt,
    this.userId,
    required this.taskCount,
    required this.noteCount,
  });

  /// Tamanio aproximado en bytes
  int get sizeInBytes => jsonEncode(data).length;

  /// Tamanio legible
  String get readableSize {
    final bytes = sizeInBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Gestor de cache de sesion.
///
/// Este servicio maneja:
/// - Limpieza de datos al cerrar sesion
/// - Preparacion de cache para nuevos usuarios
/// - Migracion de datos anonimos al vincular cuenta
/// - Exportacion de datos (cumplimiento GDPR)
/// - Validacion de propiedad de cache
class SessionCacheManager {
  final DatabaseService _databaseService;
  final ErrorHandler _errorHandler;

  /// Clave para almacenar el ID del usuario actual en SharedPreferences
  static const String _currentUserKey = 'current_user_id';

  /// Clave para almacenar la ultima sesion
  static const String _lastSessionKey = 'last_session_timestamp';

  /// Prefijo para datos de usuario especificos
  static const String _userDataPrefix = 'user_data_';

  SessionCacheManager(this._databaseService, this._errorHandler);

  /// Limpia los datos del usuario al cerrar sesion.
  ///
  /// [preservePreferences] - Si es true, mantiene configuraciones como tema
  Future<void> clearUserData({bool preservePreferences = false}) async {
    try {
      debugPrint('Limpiando datos de usuario...');

      // Guardar preferencias si se debe preservar
      UserPreferences? savedPrefs;
      if (preservePreferences) {
        savedPrefs = await _databaseService.getUserPreferences();
      }

      // Limpiar todos los datos locales
      await _databaseService.clearAllLocalData();

      // Restaurar preferencias si se guardaron
      if (savedPrefs != null) {
        await _databaseService.saveUserPreferences(savedPrefs);
      }

      // Limpiar SharedPreferences relacionadas con la sesion
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_lastSessionKey);

      debugPrint('Datos de usuario limpiados exitosamente');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al limpiar datos de usuario',
        userMessage: 'No se pudieron limpiar los datos',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Prepara el cache para un nuevo usuario.
  ///
  /// Se llama despues de iniciar sesion para configurar el entorno.
  Future<void> prepareForUser(String userId) async {
    if (userId.isEmpty) return;

    try {
      debugPrint('Preparando cache para usuario: $userId');

      // Guardar ID del usuario actual
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, userId);
      await prefs.setInt(_lastSessionKey, DateTime.now().millisecondsSinceEpoch);

      // Asegurar que las preferencias estan inicializadas
      await _databaseService.getUserPreferences();

      // Inicializar boxes de Hive si es necesario
      await _databaseService.init();

      debugPrint('Cache preparado para usuario: $userId');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al preparar cache',
        stackTrace: stack,
      );
    }
  }

  /// Migra datos anonimos cuando se vincula una cuenta.
  ///
  /// Preserva todos los datos locales y los asocia al nuevo usuario.
  Future<void> migrateAnonymousData(String oldUserId, String newUserId) async {
    if (oldUserId.isEmpty || newUserId.isEmpty) return;

    try {
      debugPrint('Migrando datos de $oldUserId a $newUserId...');

      // Los datos ya estan en Hive local, solo necesitamos:
      // 1. Actualizar el ID de usuario en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, newUserId);

      // 2. Marcar todas las tareas como pendientes de sincronizacion
      //    para que se suban con el nuevo usuario
      await _markAllForResync();

      // 3. Guardar metadatos de migracion
      await prefs.setString(
        '${_userDataPrefix}migrated_from',
        oldUserId,
      );
      await prefs.setInt(
        '${_userDataPrefix}migrated_at',
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('Migracion completada: $oldUserId -> $newUserId');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al migrar datos',
        userMessage: 'No se pudieron migrar los datos',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Exporta todos los datos del usuario antes de limpiar (GDPR).
  ///
  /// Retorna un objeto con todos los datos exportables.
  Future<DataExport> exportBeforeClear() async {
    try {
      debugPrint('Exportando datos de usuario...');

      final data = await _databaseService.exportAllData();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);

      // Contar registros
      final tasks = (data['tasks'] as List?) ?? [];
      final notes = (data['notes'] as List?) ?? [];

      final export = DataExport(
        data: data,
        exportedAt: DateTime.now(),
        userId: userId,
        taskCount: tasks.length,
        noteCount: notes.length,
      );

      debugPrint('Exportacion completada: ${export.taskCount} tareas, '
          '${export.noteCount} notas, ${export.readableSize}');

      return export;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al exportar datos',
        userMessage: 'No se pudieron exportar los datos',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Verifica si el cache pertenece al usuario actual.
  ///
  /// Retorna false si hay datos de otro usuario en cache.
  Future<bool> validateCacheOwnership(String userId) async {
    if (userId.isEmpty) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString(_currentUserKey);

      // Si no hay usuario en cache, es valido (nuevo usuario)
      if (cachedUserId == null || cachedUserId.isEmpty) {
        return true;
      }

      // Verificar si coincide con el usuario actual
      return cachedUserId == userId;
    } catch (e) {
      debugPrint('Error validando propiedad de cache: $e');
      return false;
    }
  }

  /// Obtiene el ID del usuario en cache actual.
  Future<String?> getCachedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentUserKey);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si hay una sesion anterior valida.
  Future<bool> hasPreviousSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_currentUserKey);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el timestamp de la ultima sesion.
  Future<DateTime?> getLastSessionTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSessionKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Limpia el cache si pertenece a otro usuario.
  ///
  /// Util para manejar cambios de cuenta en el mismo dispositivo.
  Future<void> clearIfDifferentUser(String newUserId) async {
    final isOwner = await validateCacheOwnership(newUserId);
    if (!isOwner) {
      debugPrint('Cache pertenece a otro usuario, limpiando...');
      await clearUserData(preservePreferences: true);
    }
  }

  /// Exporta datos como JSON string.
  Future<String> exportAsJson() async {
    final export = await exportBeforeClear();
    return const JsonEncoder.withIndent('  ').convert(export.data);
  }

  /// Obtiene estadisticas del cache actual.
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final types = ['daily', 'weekly', 'monthly', 'yearly', 'once'];
      int totalTasks = 0;

      for (final type in types) {
        final tasks = await _databaseService.getLocalTasks(type);
        totalTasks += tasks.length;
      }

      final notes = await _databaseService.getAllNotes();
      final pendingSync = await _databaseService.getTotalPendingSyncCount();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);
      final lastSession = prefs.getInt(_lastSessionKey);

      return {
        'totalTasks': totalTasks,
        'totalNotes': notes.length,
        'pendingSync': pendingSync,
        'currentUserId': userId,
        'lastSession': lastSession != null
            ? DateTime.fromMillisecondsSinceEpoch(lastSession).toIso8601String()
            : null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Invalida el cache forzando una re-sincronizacion.
  Future<void> invalidateCache() async {
    try {
      await _markAllForResync();
      debugPrint('Cache invalidado, se requerira re-sincronizacion');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al invalidar cache',
        stackTrace: stack,
      );
    }
  }

  // ==================== METODOS PRIVADOS ====================

  /// Marca todos los registros para re-sincronizacion.
  Future<void> _markAllForResync() async {
    try {
      // Las tareas y notas necesitan tener su firestoreId limpiado
      // para que se consideren como nuevas al sincronizar
      // Pero queremos mantener los datos, solo forzar re-sync

      // Esto se logra tocando lastUpdatedAt en cada registro
      final types = ['daily', 'weekly', 'monthly', 'yearly', 'once'];

      for (final type in types) {
        final tasks = await _databaseService.getLocalTasks(type);
        for (final task in tasks) {
          task.lastUpdatedAt = DateTime.now();
          if (task.isInBox) await task.save();
        }
      }

      final notes = await _databaseService.getAllNotes();
      for (final note in notes) {
        note.updatedAt = DateTime.now();
        if (note.isInBox) await note.save();
      }

      debugPrint('Todos los registros marcados para re-sincronizacion');
    } catch (e) {
      debugPrint('Error marcando registros para re-sync: $e');
    }
  }
}

/// Provider para SessionCacheManager
final sessionCacheProvider = Provider<SessionCacheManager>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  return SessionCacheManager(databaseService, errorHandler);
});
