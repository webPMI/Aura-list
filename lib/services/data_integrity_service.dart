import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import 'conflict_resolver.dart';
import 'database_service.dart';
import 'error_handler.dart';

/// Resultado de una verificacion de integridad.
class IntegrityCheck {
  /// Numero de tareas locales
  final int localTaskCount;

  /// Numero de tareas remotas
  final int remoteTaskCount;

  /// Numero de notas locales
  final int localNoteCount;

  /// Numero de notas remotas
  final int remoteNoteCount;

  /// IDs de registros que existen localmente pero no en la nube
  final List<String> missingInCloud;

  /// IDs de registros que existen en la nube pero no localmente
  final List<String> missingLocally;

  /// IDs de registros con conflictos
  final List<String> conflicts;

  /// Timestamp de la verificacion
  final DateTime checkedAt;

  IntegrityCheck({
    required this.localTaskCount,
    required this.remoteTaskCount,
    required this.localNoteCount,
    required this.remoteNoteCount,
    required this.missingInCloud,
    required this.missingLocally,
    required this.conflicts,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  /// Verifica si los datos son consistentes
  bool get isConsistent =>
      missingInCloud.isEmpty && missingLocally.isEmpty && conflicts.isEmpty;

  /// Numero total de problemas encontrados
  int get totalIssues =>
      missingInCloud.length + missingLocally.length + conflicts.length;

  /// Resumen en espanol
  String get summary {
    if (isConsistent) {
      return 'Datos sincronizados correctamente';
    }
    final issues = <String>[];
    if (missingInCloud.isNotEmpty) {
      issues.add('${missingInCloud.length} registros sin sincronizar');
    }
    if (missingLocally.isNotEmpty) {
      issues.add('${missingLocally.length} registros pendientes de descargar');
    }
    if (conflicts.isNotEmpty) {
      issues.add('${conflicts.length} conflictos detectados');
    }
    return issues.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'localTaskCount': localTaskCount,
      'remoteTaskCount': remoteTaskCount,
      'localNoteCount': localNoteCount,
      'remoteNoteCount': remoteNoteCount,
      'missingInCloud': missingInCloud,
      'missingLocally': missingLocally,
      'conflicts': conflicts,
      'checkedAt': checkedAt.toIso8601String(),
      'isConsistent': isConsistent,
    };
  }
}

/// Registro huerfano (existe en un lado pero no en el otro).
class OrphanedRecord {
  /// ID del registro
  final String id;

  /// Tipo: 'task' o 'note'
  final String type;

  /// Donde existe: 'local' o 'remote'
  final String existsIn;

  /// Datos del registro si disponibles
  final Map<String, dynamic>? data;

  /// Ultima actualizacion conocida
  final DateTime? lastUpdated;

  OrphanedRecord({
    required this.id,
    required this.type,
    required this.existsIn,
    this.data,
    this.lastUpdated,
  });

  /// Descripcion en espanol
  String get description {
    final location = existsIn == 'local' ? 'solo localmente' : 'solo en la nube';
    final typeStr = type == 'task' ? 'Tarea' : 'Nota';
    return '$typeStr existe $location';
  }
}

/// Conjunto de registros duplicados.
class DuplicateSet {
  /// IDs de los registros duplicados
  final List<String> ids;

  /// Tipo: 'task' o 'note'
  final String type;

  /// Titulo o identificador comun
  final String commonIdentifier;

  /// El registro que se recomienda mantener
  final String recommendedKeep;

  DuplicateSet({
    required this.ids,
    required this.type,
    required this.commonIdentifier,
    required this.recommendedKeep,
  });

  int get duplicateCount => ids.length - 1;
}

/// Resultado de una reconciliacion.
class ReconciliationResult {
  /// Numero de registros sincronizados a la nube
  final int syncedToCloud;

  /// Numero de registros descargados de la nube
  final int downloadedFromCloud;

  /// Numero de conflictos resueltos
  final int conflictsResolved;

  /// Numero de errores encontrados
  final int errors;

  /// Mensajes de error
  final List<String> errorMessages;

  /// Duracion de la reconciliacion
  final Duration duration;

  ReconciliationResult({
    required this.syncedToCloud,
    required this.downloadedFromCloud,
    required this.conflictsResolved,
    required this.errors,
    required this.errorMessages,
    required this.duration,
  });

  bool get hasErrors => errors > 0;

  String get summary {
    if (hasErrors) {
      return 'Reconciliacion completada con $errors errores';
    }
    final actions = <String>[];
    if (syncedToCloud > 0) actions.add('$syncedToCloud subidos');
    if (downloadedFromCloud > 0) actions.add('$downloadedFromCloud descargados');
    if (conflictsResolved > 0) actions.add('$conflictsResolved conflictos resueltos');
    if (actions.isEmpty) return 'Sin cambios necesarios';
    return actions.join(', ');
  }
}

/// Servicio para verificar y mantener la integridad de datos
/// entre almacenamiento local (Hive) y la nube (Firebase).
class DataIntegrityService {
  final DatabaseService _databaseService;
  final ConflictResolver _conflictResolver;
  final ErrorHandler _errorHandler;

  DataIntegrityService(
    this._databaseService,
    this._conflictResolver,
    this._errorHandler,
  );

  /// Realiza una verificacion completa de integridad.
  Future<IntegrityCheck> performFullCheck(String userId) async {
    if (userId.isEmpty) {
      return IntegrityCheck(
        localTaskCount: 0,
        remoteTaskCount: 0,
        localNoteCount: 0,
        remoteNoteCount: 0,
        missingInCloud: [],
        missingLocally: [],
        conflicts: [],
      );
    }

    try {
      final firestore = _databaseService.firestore;
      if (firestore == null) {
        // Sin Firebase, solo contar registros locales
        final localTasks = await _getLocalTasks();
        final localNotes = await _getLocalNotes();

        return IntegrityCheck(
          localTaskCount: localTasks.length,
          remoteTaskCount: 0,
          localNoteCount: localNotes.length,
          remoteNoteCount: 0,
          missingInCloud: localTasks
              .where((t) => t.firestoreId.isNotEmpty)
              .map((t) => t.firestoreId)
              .toList(),
          missingLocally: [],
          conflicts: [],
        );
      }

      // Obtener datos locales
      final localTasks = await _getLocalTasks();
      final localNotes = await _getLocalNotes();

      // Obtener datos remotos
      final remoteTasks = await _getRemoteTasks(firestore, userId);
      final remoteNotes = await _getRemoteNotes(firestore, userId);

      // Crear sets para comparacion rapida
      final localTaskIds = localTasks
          .where((t) => t.firestoreId.isNotEmpty)
          .map((t) => t.firestoreId)
          .toSet();
      final remoteTaskIds = remoteTasks.keys.toSet();

      final localNoteIds = localNotes
          .where((n) => n.firestoreId.isNotEmpty)
          .map((n) => n.firestoreId)
          .toSet();
      final remoteNoteIds = remoteNotes.keys.toSet();

      // Encontrar diferencias
      final tasksMissingInCloud = localTaskIds.difference(remoteTaskIds).toList();
      final tasksMissingLocally = remoteTaskIds.difference(localTaskIds).toList();

      final notesMissingInCloud = localNoteIds.difference(remoteNoteIds).toList();
      final notesMissingLocally = remoteNoteIds.difference(localNoteIds).toList();

      // Detectar conflictos
      final conflicts = <String>[];
      for (final task in localTasks) {
        if (task.firestoreId.isEmpty) continue;
        final remoteData = remoteTasks[task.firestoreId];
        if (remoteData != null) {
          final remoteTask = Task.fromFirestore(task.firestoreId, remoteData);
          if (_conflictResolver.hasConflict(
            task.lastUpdatedAt,
            remoteTask.lastUpdatedAt,
          )) {
            conflicts.add('task:${task.firestoreId}');
          }
        }
      }

      for (final note in localNotes) {
        if (note.firestoreId.isEmpty) continue;
        final remoteData = remoteNotes[note.firestoreId];
        if (remoteData != null) {
          final remoteNote = Note.fromFirestore(note.firestoreId, remoteData);
          if (_conflictResolver.hasConflict(
            note.updatedAt,
            remoteNote.updatedAt,
          )) {
            conflicts.add('note:${note.firestoreId}');
          }
        }
      }

      return IntegrityCheck(
        localTaskCount: localTasks.length,
        remoteTaskCount: remoteTasks.length,
        localNoteCount: localNotes.length,
        remoteNoteCount: remoteNotes.length,
        missingInCloud: [...tasksMissingInCloud, ...notesMissingInCloud],
        missingLocally: [...tasksMissingLocally, ...notesMissingLocally],
        conflicts: conflicts,
      );
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.error,
        message: 'Error al verificar integridad de datos',
        userMessage: 'No se pudo verificar la sincronizacion',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Encuentra registros huerfanos.
  Future<List<OrphanedRecord>> findOrphanedRecords(String userId) async {
    final check = await performFullCheck(userId);
    final orphans = <OrphanedRecord>[];

    // Registros que solo existen localmente
    for (final id in check.missingInCloud) {
      final isTask = !id.startsWith('note:');
      orphans.add(OrphanedRecord(
        id: id,
        type: isTask ? 'task' : 'note',
        existsIn: 'local',
      ));
    }

    // Registros que solo existen remotamente
    for (final id in check.missingLocally) {
      final isTask = !id.startsWith('note:');
      orphans.add(OrphanedRecord(
        id: id,
        type: isTask ? 'task' : 'note',
        existsIn: 'remote',
      ));
    }

    return orphans;
  }

  /// Reconcilia diferencias entre local y remoto.
  Future<ReconciliationResult> reconcile(String userId) async {
    final startTime = DateTime.now();
    int syncedToCloud = 0;
    int downloadedFromCloud = 0;
    int conflictsResolved = 0;
    int errors = 0;
    final errorMessages = <String>[];

    if (userId.isEmpty) {
      return ReconciliationResult(
        syncedToCloud: 0,
        downloadedFromCloud: 0,
        conflictsResolved: 0,
        errors: 0,
        errorMessages: [],
        duration: DateTime.now().difference(startTime),
      );
    }

    try {
      final firestore = _databaseService.firestore;
      if (firestore == null) {
        return ReconciliationResult(
          syncedToCloud: 0,
          downloadedFromCloud: 0,
          conflictsResolved: 0,
          errors: 0,
          errorMessages: ['Firebase no disponible'],
          duration: DateTime.now().difference(startTime),
        );
      }

      final check = await performFullCheck(userId);

      // Subir registros faltantes en la nube
      for (final id in check.missingInCloud) {
        try {
          // Buscar el registro local y subirlo
          final localTasks = await _getLocalTasks();
          final task = localTasks.where((t) => t.firestoreId == id).firstOrNull;
          if (task != null) {
            await _databaseService.syncTaskToCloud(task, userId);
            syncedToCloud++;
          } else {
            final localNotes = await _getLocalNotes();
            final note = localNotes.where((n) => n.firestoreId == id).firstOrNull;
            if (note != null) {
              await _databaseService.syncNoteToCloud(note, userId);
              syncedToCloud++;
            }
          }
        } catch (e) {
          errors++;
          errorMessages.add('Error al subir $id: $e');
        }
      }

      // Descargar registros faltantes localmente
      for (final id in check.missingLocally) {
        try {
          // Determinar si es tarea o nota basado en el prefijo
          final isTask = !id.contains('note:');
          if (isTask) {
            final remoteTasks = await _getRemoteTasks(firestore, userId);
            final remoteData = remoteTasks[id];
            if (remoteData != null) {
              final task = Task.fromFirestore(id, remoteData);
              await _databaseService.saveTaskLocally(task);
              downloadedFromCloud++;
            }
          } else {
            final noteId = id.replaceFirst('note:', '');
            final remoteNotes = await _getRemoteNotes(firestore, userId);
            final remoteData = remoteNotes[noteId];
            if (remoteData != null) {
              final note = Note.fromFirestore(noteId, remoteData);
              await _databaseService.saveNoteLocally(note);
              downloadedFromCloud++;
            }
          }
        } catch (e) {
          errors++;
          errorMessages.add('Error al descargar $id: $e');
        }
      }

      // Resolver conflictos
      for (final conflictId in check.conflicts) {
        try {
          final parts = conflictId.split(':');
          final type = parts[0];
          final id = parts[1];

          if (type == 'task') {
            await _resolveTaskConflict(firestore, userId, id);
          } else {
            await _resolveNoteConflict(firestore, userId, id);
          }
          conflictsResolved++;
        } catch (e) {
          errors++;
          errorMessages.add('Error al resolver conflicto $conflictId: $e');
        }
      }
    } catch (e, stack) {
      errors++;
      errorMessages.add('Error general: $e');
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error en reconciliacion',
        stackTrace: stack,
      );
    }

    return ReconciliationResult(
      syncedToCloud: syncedToCloud,
      downloadedFromCloud: downloadedFromCloud,
      conflictsResolved: conflictsResolved,
      errors: errors,
      errorMessages: errorMessages,
      duration: DateTime.now().difference(startTime),
    );
  }

  /// Encuentra registros duplicados localmente.
  Future<List<DuplicateSet>> findDuplicates() async {
    final duplicates = <DuplicateSet>[];

    try {
      final tasks = await _getLocalTasks();
      final notes = await _getLocalNotes();

      // Buscar tareas con titulos duplicados
      final taskTitleMap = <String, List<Task>>{};
      for (final task in tasks) {
        if (!task.deleted) {
          final key = '${task.title.toLowerCase().trim()}_${task.type}';
          taskTitleMap.putIfAbsent(key, () => []).add(task);
        }
      }

      for (final entry in taskTitleMap.entries) {
        if (entry.value.length > 1) {
          // Ordenar por fecha de creacion (mas reciente primero)
          entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          duplicates.add(DuplicateSet(
            ids: entry.value.map((t) => t.key.toString()).toList(),
            type: 'task',
            commonIdentifier: entry.value.first.title,
            recommendedKeep: entry.value.first.key.toString(),
          ));
        }
      }

      // Buscar notas con titulos duplicados
      final noteTitleMap = <String, List<Note>>{};
      for (final note in notes) {
        if (!note.deleted) {
          final key = note.title.toLowerCase().trim();
          noteTitleMap.putIfAbsent(key, () => []).add(note);
        }
      }

      for (final entry in noteTitleMap.entries) {
        if (entry.value.length > 1) {
          entry.value.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          duplicates.add(DuplicateSet(
            ids: entry.value.map((n) => n.key.toString()).toList(),
            type: 'note',
            commonIdentifier: entry.value.first.title,
            recommendedKeep: entry.value.first.key.toString(),
          ));
        }
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al buscar duplicados',
        stackTrace: stack,
      );
    }

    return duplicates;
  }

  /// Elimina registros duplicados, manteniendo el mas reciente.
  Future<int> removeDuplicates() async {
    int removed = 0;

    try {
      final duplicateSets = await findDuplicates();

      for (final set in duplicateSets) {
        for (final id in set.ids) {
          if (id != set.recommendedKeep) {
            try {
              if (set.type == 'task') {
                await _databaseService.deleteTaskLocally(int.parse(id));
              } else {
                await _databaseService.deleteNoteLocally(int.parse(id));
              }
              removed++;
            } catch (e) {
              debugPrint('Error eliminando duplicado $id: $e');
            }
          }
        }
      }

      if (removed > 0) {
        debugPrint('Eliminados $removed registros duplicados');
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar duplicados',
        stackTrace: stack,
      );
    }

    return removed;
  }

  /// Verifica la consistencia de los datos con un checksum simple.
  Future<bool> verifyDataChecksum(String userId) async {
    try {
      final check = await performFullCheck(userId);
      return check.isConsistent;
    } catch (e) {
      return false;
    }
  }

  // ==================== METODOS PRIVADOS ====================

  Future<List<Task>> _getLocalTasks() async {
    // Obtener tareas de todos los tipos
    final types = ['daily', 'weekly', 'monthly', 'yearly', 'once'];
    final allTasks = <Task>[];

    for (final type in types) {
      final tasks = await _databaseService.getLocalTasks(type);
      allTasks.addAll(tasks);
    }

    return allTasks;
  }

  Future<List<Note>> _getLocalNotes() async {
    return await _databaseService.getAllNotes();
  }

  Future<Map<String, Map<String, dynamic>>> _getRemoteTasks(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .get()
          .timeout(const Duration(seconds: 15));

      return {
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };
    } catch (e) {
      debugPrint('Error obteniendo tareas remotas: $e');
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getRemoteNotes(
    FirebaseFirestore firestore,
    String userId,
  ) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get()
          .timeout(const Duration(seconds: 15));

      return {
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };
    } catch (e) {
      debugPrint('Error obteniendo notas remotas: $e');
      return {};
    }
  }

  Future<void> _resolveTaskConflict(
    FirebaseFirestore firestore,
    String userId,
    String firestoreId,
  ) async {
    final localTasks = await _getLocalTasks();
    final localTask = localTasks.where((t) => t.firestoreId == firestoreId).firstOrNull;
    if (localTask == null) return;

    final remoteData = await firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(firestoreId)
        .get();

    if (!remoteData.exists) return;

    final remoteTask = Task.fromFirestore(firestoreId, remoteData.data()!);
    final resolution = _conflictResolver.resolveTaskConflict(localTask, remoteTask);

    // Guardar version resuelta localmente
    localTask.updateInPlace(
      title: resolution.resolved.title,
      isCompleted: resolution.resolved.isCompleted,
      category: resolution.resolved.category,
      priority: resolution.resolved.priority,
      motivation: resolution.resolved.motivation,
      reward: resolution.resolved.reward,
      dueDate: resolution.resolved.dueDate,
      dueTimeMinutes: resolution.resolved.dueTimeMinutes,
      deadline: resolution.resolved.deadline,
      lastUpdatedAt: DateTime.now(),
    );
    await localTask.save();

    // Sincronizar con la nube
    await _databaseService.syncTaskToCloud(localTask, userId);
  }

  Future<void> _resolveNoteConflict(
    FirebaseFirestore firestore,
    String userId,
    String firestoreId,
  ) async {
    final localNotes = await _getLocalNotes();
    final localNote = localNotes.where((n) => n.firestoreId == firestoreId).firstOrNull;
    if (localNote == null) return;

    final remoteData = await firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(firestoreId)
        .get();

    if (!remoteData.exists) return;

    final remoteNote = Note.fromFirestore(firestoreId, remoteData.data()!);
    final resolution = _conflictResolver.resolveNoteConflict(localNote, remoteNote);

    // Guardar version resuelta localmente
    localNote.updateInPlace(
      title: resolution.resolved.title,
      content: resolution.resolved.content,
      color: resolution.resolved.color,
      isPinned: resolution.resolved.isPinned,
      tags: resolution.resolved.tags,
      updatedAt: DateTime.now(),
    );
    await localNote.save();

    // Sincronizar con la nube
    await _databaseService.syncNoteToCloud(localNote, userId);
  }
}

/// Provider para DataIntegrityService
final dataIntegrityProvider = Provider<DataIntegrityService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final conflictResolver = ref.watch(conflictResolverProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  return DataIntegrityService(databaseService, conflictResolver, errorHandler);
});
